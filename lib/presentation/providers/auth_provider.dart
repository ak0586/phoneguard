import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:uuid/uuid.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

import '../../data/datasources/auth_service.dart';
import '../../data/models/user_profile.dart';
import '../../domain/models/trusted_number.dart';
import '../../core/utils/phone_utils.dart';
import '../../data/datasources/native_service.dart';

class AuthProvider extends ChangeNotifier with WidgetsBindingObserver {
  final AuthService _authService;
  
  User? _user;
  UserProfile? _profile;
  StreamSubscription<UserProfile?>? _profileSubscription;
  
  bool _isInitializing = true;
  bool _isLoading = false;
  String? _errorMessage;
  String? _mobileNumber;
  String? _localDeviceId;
  bool _deviceConflict = false;
  bool _disposed = false;
  void Function(UserProfile?)? onProfileChanged;

  AuthProvider(this._authService) {
    _init();
    WidgetsBinding.instance.addObserver(this);
  }

  User? get user => _user;
  UserProfile? get profile => _profile;
  bool get isAuthenticated => _user != null;
  bool get isEmailVerified {
    if (_user == null) return false;
    // Google/Social users are typically pre-verified
    if (_user!.providerData.any((p) => p.providerId != 'password')) return true;
    return _user!.emailVerified;
  }
  bool get isInitializing => _isInitializing;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get mobileNumber => _profile?.mobile ?? _mobileNumber;
  bool get hasDeviceConflict => _deviceConflict;
  
  bool get canWatchAd {
    if (_profile == null) return false;
    if (_profile!.isPremium) return false;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    if (_profile!.lastAdDate != today) return true;
    return _profile!.adsWatchedToday < 6;
  }

  void _init() {
    _authService.authStateChanges.listen((User? authUser) async {
      _user = authUser;
      
      await _profileSubscription?.cancel();

      if (authUser != null) {
        // 1. Load cached profile immediately to unblock UI
        debugPrint('Auth: Loading cached profile for ${authUser.uid}');
        await _loadCachedProfile(authUser.uid);
        
        // 2. We have some state (even if cached), mark as not initializing
        _isInitializing = false;
        debugPrint('Auth: Initialized with user: ${authUser.email}');
        notifyListeners();

        // 3. Start Firestore sync and device updates in background (don't await)
        _syncBackgroundData(authUser);
      } else {
        debugPrint('Auth: No user logged in');
        _profile = null;
        _mobileNumber = null;
        _isInitializing = false;
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('user_uid');
        await prefs.remove('cached_user_profile');
        NativeService().stopFirestoreCommandService();
        notifyListeners();
      }
    });
  }

  Future<void> _syncBackgroundData(User authUser) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_uid', authUser.uid);
      
      // These are important but shouldn't block the initial screen load
      _authService.ensureUserProfileExists(authUser).catchError((e) => debugPrint('Sync Error: $e'));
      _syncDeviceMetadata(authUser.uid).catchError((e) => debugPrint('Metadata Sync Error: $e'));

      _profileSubscription = _authService.userProfileStream(authUser.uid).listen(
        (profile) async {
          if (_disposed) return;
          if (profile != null) {
            _profile = profile;
            _cacheProfile(profile);
            
            _localDeviceId ??= await _getOrCreateDeviceId();
            final currentModel = await _getDeviceModel();
            
            // Conflict if ID mismatch AND Model mismatch
            // (If ID is different but Model is same, it might be a reinstall, so we update ID)
            if (profile.currentDeviceId == null) {
              await setAsPrimaryDevice();
            } else if (profile.currentDeviceId != _localDeviceId && profile.deviceModel != currentModel) {
              _deviceConflict = true;
            } else {
              _deviceConflict = false;
              // Silently update ID if model matches but ID changed (reinstall scenario)
              if (profile.currentDeviceId != _localDeviceId) {
                 _authService.updateUserProfile(profile.uid, {'currentDeviceId': _localDeviceId});
              }
            }

            final p = await SharedPreferences.getInstance();
            await p.setBool('is_premium', profile.isPremium);
            await p.setString('created_at', profile.createdAt.toIso8601String());
            if (profile.protectionExpiry != null) {
              await p.setString('protection_expiry', profile.protectionExpiry!.toIso8601String());
            }
          }
          onProfileChanged?.call(profile);
          notifyListeners();
        },
        onError: (error) {
          if (_disposed) return;
          debugPrint('Profile Stream Error: $error');
          // If we have cached data, we don't strictly need to show an error here
        },
      );
      NativeService().startFirestoreCommandService();
      NativeService().startRecoveryService(); // Ensures ContentObserver monitors ALL SMS
    } catch (e) {
      debugPrint('Background sync setup error: $e');
    }
  }

  Future<void> _loadCachedProfile(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString('cached_user_profile');
      if (cachedJson != null) {
        final Map<String, dynamic> map = jsonDecode(cachedJson);
        final cachedProfile = UserProfile.fromMap(map);
        if (cachedProfile.uid == uid) {
          _profile = cachedProfile;
          debugPrint('Loaded cached profile for $uid');
        }
      }
    } catch (e) {
      debugPrint('Failed to load cached profile: $e');
    }
  }

  Future<void> _cacheProfile(UserProfile profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(profile.toMap());
      await prefs.setString('cached_user_profile', json);
    } catch (e) {
      debugPrint('Failed to cache profile: $e');
    }
  }

  Future<void> signIn(String email, String password) async {
    _setLoading(true);
    _clearError();
    try {
      final credential = await _authService.signInWithEmailAndPassword(email: email, password: password);
      if (credential.user != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_uid', credential.user!.uid);
        await NativeService().startFirestoreCommandService();
        await NativeService().startRecoveryService();
      }
    } on FirebaseAuthException catch (e) {
      _errorMessage = (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential')
          ? 'Incorrect password or this email is not registered.'
          : e.message ?? 'An error occurred during sign in.';
    } catch (e) {
      _errorMessage = e.toString();
    }
    _setLoading(false);
  }

  Future<void> signInWithGoogle() async {
    _setLoading(true);
    _clearError();
    try {
      final credential = await _authService.signInWithGoogle();
      if (credential.user != null) {
        await _authService.ensureUserProfileExists(credential.user!, name: credential.user!.displayName);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_uid', credential.user!.uid);
        await NativeService().startFirestoreCommandService();
        await NativeService().startRecoveryService();
      }
    } on FirebaseAuthException catch (e) {
      if (e.code != 'ERROR_ABORTED_BY_USER') {
        _errorMessage = e.message ?? 'An error occurred during Google Sign-In.';
      }
    } catch (e) {
      _errorMessage = e.toString();
    }
    _setLoading(false);
  }

  Future<void> register(String email, String password, String name, String mobile, {File? profileImage}) async {
    _setLoading(true);
    _clearError();
    try {
      final prefs = await SharedPreferences.getInstance();
      final isoCode = prefs.getString('cached_iso_country_code');
      final formattedMobile = PhoneUtils.formatWithCountryCode(mobile.trim(), isoCode);

      final credential = await _authService.registerWithEmailAndPassword(email: email, password: password);
      if (credential.user != null) {
        String? photoUrl;
        if (profileImage != null) {
          final result = await FlutterImageCompress.compressWithFile(
            profileImage.absolute.path,
            format: CompressFormat.webp,
            quality: 70,
            minWidth: 200,
            minHeight: 200,
          );
          if (result != null) {
            photoUrl = 'data:image/webp;base64,${base64Encode(result)}';
            // We store only in Firestore to avoid "photo URL too long" error in Firebase Auth
          }
        }

        await _authService.updateProfile(displayName: name);
        final profile = UserProfile(
          uid: credential.user!.uid,
          name: name,
          email: email,
          mobile: formattedMobile,
          photoUrl: photoUrl,
          createdAt: DateTime.now(),
        );
        await _authService.setUserProfile(profile);
        await prefs.setString('user_uid', credential.user!.uid);
        await NativeService().startFirestoreCommandService();
        await NativeService().startRecoveryService();
        if (!credential.user!.emailVerified) {
          await credential.user!.sendEmailVerification();
        }
      }
    } on FirebaseAuthException catch (e) {
      _errorMessage = e.message ?? 'An error occurred during registration.';
    } catch (e) {
      _errorMessage = e.toString();
    }
    _setLoading(false);
  }

  Future<void> signOut() async {
    _setLoading(true);
    _clearError();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_uid');
      NativeService().stopFirestoreCommandService();
      await _authService.signOut();
    } catch (e) {
      _errorMessage = e.toString();
    }
    _setLoading(false);
  }

  Future<bool> sendPasswordReset(String email) async {
    _setLoading(true);
    _clearError();
    try {
      await _authService.sendPasswordResetEmail(email);
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<void> resendVerificationEmail() async {
    _setLoading(true);
    try {
      await _authService.sendEmailVerification();
    } catch (e) {
      _errorMessage = e.toString();
    }
    _setLoading(false);
  }

  Future<void> reloadUser() async {
    try {
      await _authService.reloadUser();
      _user = _authService.currentUser;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> updateAdditionalInfo(String name, String mobile) async {
    if (_user == null) return;
    _setLoading(true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final isoCode = prefs.getString('cached_iso_country_code');
      final formattedMobile = PhoneUtils.formatWithCountryCode(mobile.trim(), isoCode);
      await _authService.updateFullProfile(_user!.uid, name: name, mobile: formattedMobile);
      await reloadUser();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateTrustedNumbers(List<TrustedNumber> numbers) async {
    if (_user == null) return;
    try {
      await _authService.updateUserProfile(_user!.uid, {'trustedNumbers': numbers.map((n) => n.toMap()).toList()});
    } catch (_) {}
  }

  Future<void> updateTriggerKeyword(String keyword) async {
    if (_user == null) return;
    try {
      await _authService.updateUserProfile(_user!.uid, {'triggerKeyword': keyword});
    } catch (_) {}
  }

  Future<void> setAsPrimaryDevice() async {
    if (_user == null || _localDeviceId == null) return;
    _setLoading(true);
    try {
      final deviceInfo = DeviceInfoPlugin();
      String model = 'Unknown Device';
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        model = '${androidInfo.manufacturer} ${androidInfo.model}';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        model = iosInfo.name;
      }

      await _authService.updateUserProfile(_user!.uid, {
        'currentDeviceId': _localDeviceId,
        'deviceModel': model,
      });
      _deviceConflict = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to switch device: $e';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<String> _getOrCreateDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? id = prefs.getString('local_device_id');
    if (id == null) {
      id = const Uuid().v4();
      await prefs.setString('local_device_id', id);
    }
    return id;
  }

  Future<String> _getDeviceModel() async {
    final deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      return '${androidInfo.manufacturer} ${androidInfo.model}';
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      return iosInfo.name;
    }
    return 'Unknown';
  }

  Future<void> extendProtection(int hours) async {
    if (_user == null) return;
    if (hours == 8) hours = 4; // Update from legacy 8 to 4 for ads
    
    _setLoading(true);
    try {
      await _authService.extendProtection(_user!.uid, hours);
      
      final currentExpiry = _profile?.protectionExpiry;
      final base = (currentExpiry != null && currentExpiry.isAfter(DateTime.now())) ? currentExpiry : DateTime.now();
      final newExpiry = base.add(Duration(hours: hours));
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('flutter.protection_expiry', newExpiry.toIso8601String());
      await prefs.setInt('flutter.ads_watched_today', (_profile?.adsWatchedToday ?? 0) + 1);

      await FirebaseAnalytics.instance.logEvent(
        name: 'extend_protection',
        parameters: {'hours': hours, 'uid': _user?.uid ?? 'unknown'},
      );

      if (hours >= 24) {
        await FirebaseAnalytics.instance.logPurchase(
          value: hours.toDouble(),
          currency: 'HRS',
          items: [
            AnalyticsEventItem(itemName: 'Protection Extension', itemCategory: 'Security', quantity: hours),
          ],
        );
      }
    } catch (e) {
      _errorMessage = e.toString();
    }
    _setLoading(false);
  }

  Future<void> _syncDeviceMetadata(String uid) async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      String model = 'Unknown';
      String os = 'Unknown';

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        model = '${androidInfo.manufacturer} ${androidInfo.model}';
        os = 'Android ${androidInfo.version.release} (SDK ${androidInfo.version.sdkInt})';
      }

      await _authService.updateDeviceMetadata(uid, {
        'deviceModel': model,
        'osVersion': os,
        'lastActive': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> deleteAccount(String password) async {
    _setLoading(true);
    _clearError();
    try {
      await _authService.deleteAccount(password);
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = (e.code == 'wrong-password') ? 'Incorrect password.' : e.message;
      _setLoading(false);
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<void> uploadProfileImage(File imageFile) async {
    final user = _authService.currentUser;
    if (user == null) return;

    _setLoading(true);
    _clearError();
    try {
      final result = await FlutterImageCompress.compressWithFile(
        imageFile.absolute.path,
        format: CompressFormat.webp,
        quality: 70,
        minWidth: 200,
        minHeight: 200,
      );
      
      if (result == null) throw Exception('Compression failed');
      
      final base64Image = 'data:image/webp;base64,${base64Encode(result)}';
      
      // Update Firestore only (Firebase Auth has a length limit for photoURL)
      await _authService.updateUserProfile(user.uid, {
        'photoUrl': base64Image,
      });

      // Refresh local profile
      await reloadUser();
    } catch (e) {
      _errorMessage = e.toString();
    }
    _setLoading(false);
  }

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && isAuthenticated && !isEmailVerified) {
      debugPrint('Auth: App resumed, reloading user to check verification status...');
      reloadUser();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _profileSubscription?.cancel();
    super.dispose();
  }
}
