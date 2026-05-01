import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/datasources/auth_service.dart';
import '../../data/models/user_profile.dart';
import '../../domain/models/trusted_number.dart';
import '../../core/utils/phone_utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'dart:io';
import 'package:uuid/uuid.dart';
import 'package:device_info_plus/device_info_plus.dart';

class AuthProvider extends ChangeNotifier {
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
  void Function(UserProfile?)? onProfileChanged;

  AuthProvider(this._authService) {
    _init();
  }

  User? get user => _user;
  UserProfile? get profile => _profile;
  bool get isAuthenticated => _user != null;
  bool get isEmailVerified => _user?.emailVerified ?? false;
  bool get isInitializing => _isInitializing;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get mobileNumber => _profile?.mobile ?? _mobileNumber;
  bool get hasDeviceConflict => _deviceConflict;

  void _init() {
    _authService.authStateChanges.listen((User? authUser) async {
      _user = authUser;
      
      // Cancel previous profile subscription
      await _profileSubscription?.cancel();

      if (authUser != null) {
        // Cache UID for native access
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('flutter.user_uid', authUser.uid);
        
        // 1. Check if we already fetched today
        final lastFetchTime = prefs.getInt('last_profile_fetch_${authUser.uid}') ?? 0;
        final now = DateTime.now().millisecondsSinceEpoch;
        final bool isFirstTimeToday = (now - lastFetchTime) > 86400000; // 24 hours

        // 2. Ensure Profile Exists & Sync Metadata
        if (isFirstTimeToday) {
          await _authService.ensureUserProfileExists(authUser);
          await _syncDeviceMetadata(authUser.uid);
          await prefs.setInt('last_profile_fetch_${authUser.uid}', now);
        }

        // 3. Start listening to Firestore profile
        // Even if we are "fetching once", we keep the stream open for the session 
        // to handle real-time changes while the app is active.
        _profileSubscription = _authService.userProfileStream(authUser.uid).listen(
          (profile) async {
            _profile = profile;
            if (profile != null) {
              _localDeviceId ??= await _getOrCreateDeviceId();
              
              // Device conflict check
              if (profile.currentDeviceId != null && profile.currentDeviceId != _localDeviceId) {
                _deviceConflict = true;
              } else {
                _deviceConflict = false;
              }

              final p = await SharedPreferences.getInstance();
              await p.setBool('flutter.is_premium', profile.isPremium);
              await p.setString('flutter.created_at', profile.createdAt.toIso8601String());
              if (profile.protectionExpiry != null) {
                await p.setString('flutter.protection_expiry', profile.protectionExpiry!.toIso8601String());
              }
            }
            onProfileChanged?.call(profile);
            notifyListeners();
          },
          onError: (error) {
            debugPrint('Profile Stream Error: $error');
            _errorMessage = 'Failed to sync profile: Insufficient Permissions.';
            notifyListeners();
          },
        );
      } else {
        _profile = null;
        _mobileNumber = null;
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('flutter.user_uid');
      }
      _isInitializing = false;
      notifyListeners();
    });
  }

  Future<void> signIn(String email, String password) async {
    _setLoading(true);
    _clearError();
    try {
      await _authService.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        _errorMessage = 'This email is not registered. Please register first.';
      } else if (e.code == 'wrong-password') {
        _errorMessage = 'Incorrect password.';
      } else if (e.code == 'invalid-credential') {
        // Modern Firebase merges not-found and wrong-password into invalid-credential by default
        _errorMessage = 'Incorrect password or this email is not registered. Please register first.';
      } else {
        _errorMessage = e.message ?? 'An error occurred during sign in.';
      }
    } catch (e) {
      _errorMessage = e.toString();
    }
    _setLoading(false);
  }

  Future<void> register(String email, String password, String name, String mobile) async {
    _setLoading(true);
    _clearError();
    try {
      final prefs = await SharedPreferences.getInstance();
      final isoCode = prefs.getString('cached_iso_country_code');
      final formattedMobile = PhoneUtils.formatWithCountryCode(mobile.trim(), isoCode);

      final credential = await _authService.registerWithEmailAndPassword(email: email, password: password);
      
      if (credential.user != null) {
        // Update Firebase Profile Name
        await _authService.updateProfile(displayName: name);
        
        // Create Firestore User Document
        final profile = UserProfile(
          uid: credential.user!.uid,
          name: name,
          email: email,
          mobile: formattedMobile,
          createdAt: DateTime.now(),
        );
        await _authService.setUserProfile(profile);

        // Cache UID for native access
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('flutter.user_uid', credential.user!.uid);
        
        // Automatically send verification email on registration
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
      await _authService.signOut();
    } catch (e) {
      _errorMessage = e.toString();
    }
    _setLoading(false);
  }

  Future<bool> sendPasswordReset(String email) async {
    _setLoading(true);
    _clearError();
    bool success = false;
    try {
      await _authService.sendPasswordResetEmail(email);
      success = true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = e.message ?? 'Failed to send password reset email.';
    } catch (e) {
      _errorMessage = e.toString();
    }
    _setLoading(false);
    return success;
  }

  Future<void> resendVerificationEmail() async {
    _setLoading(true);
    _clearError();
    try {
      await _authService.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      _errorMessage = e.message ?? 'Failed to resend verification email.';
    } catch (e) {
      _errorMessage = e.toString();
    }
    _setLoading(false);
  }

  Future<void> reloadUser() async {
    _clearError();
    try {
      await _authService.reloadUser();
      _user = _authService.currentUser; // Update the pointer with the latest instance
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to refresh user status.';
      notifyListeners();
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> updateAdditionalInfo(String name, String mobile) async {
    if (_user == null) {
      _errorMessage = "You must be signed in to update profile.";
      notifyListeners();
      return;
    }

    _setLoading(true);
    _clearError();
    try {
      final prefs = await SharedPreferences.getInstance();
      final isoCode = prefs.getString('cached_iso_country_code');
      final formattedMobile = PhoneUtils.formatWithCountryCode(mobile.trim(), isoCode);

      // Single call to handle both Auth and Firestore
      await _authService.updateFullProfile(_user!.uid, name: name, mobile: formattedMobile);
      
      // Refresh Auth User state without blocking too long
      await reloadUser().timeout(const Duration(seconds: 5), onTimeout: () {});
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateTrustedNumbers(List<TrustedNumber> numbers) async {
    if (_user == null) return;
    try {
      await _authService.updateUserProfile(_user!.uid, {
        'trustedNumbers': numbers.map((n) => n.toMap()).toList(),
      });
      if (_profile != null) {
        _profile = _profile!.copyWith(trustedNumbers: numbers);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error syncing trusted numbers: $e');
    }
  }

  Future<void> updateTriggerKeyword(String keyword) async {
    if (_user == null) return;
    try {
      await _authService.updateUserProfile(_user!.uid, {
        'triggerKeyword': keyword,
      });
      if (_profile != null) {
        _profile = _profile!.copyWith(triggerKeyword: keyword);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error syncing trigger keyword: $e');
    }
  }

  Future<void> setAsPrimaryDevice() async {
    if (_user == null || _localDeviceId == null) return;
    _setLoading(true);
    try {
      await _authService.updateUserProfile(_user!.uid, {
        'currentDeviceId': _localDeviceId,
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

  Future<void> extendProtection(int hours) async {
    if (_user == null) return;
    _setLoading(true);
    try {
      await _authService.extendProtection(_user!.uid, hours);

      // Immediately write the new expiry to SharedPreferences so the native
      // Kotlin CommandParser can read it without waiting for the Firestore stream.
      final currentExpiry = _profile?.protectionExpiry;
      final base = (currentExpiry != null && currentExpiry.isAfter(DateTime.now()))
          ? currentExpiry
          : DateTime.now();
      final newExpiry = base.add(Duration(hours: hours));
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('flutter.protection_expiry', newExpiry.toIso8601String());
      debugPrint('extendProtection: wrote new expiry=$newExpiry to SharedPreferences');

      // Profile stream will automatically update _profile from Firestore
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
    } catch (e) {
      debugPrint('Metadata sync failed: $e');
    }
  }

  Future<void> updateLocation(double lat, double lon) async {
    if (_user == null) return;
    try {
      await _authService.updateLocation(_user!.uid, latitude: lat, longitude: lon);
    } catch (e) {
      debugPrint('Location sync failed: $e');
    }
  }
}
