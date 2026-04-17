import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/datasources/auth_service.dart';
import '../../data/models/user_profile.dart';
import '../../domain/models/trusted_number.dart';
import 'dart:async';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  
  User? _user;
  UserProfile? _profile;
  StreamSubscription<UserProfile?>? _profileSubscription;
  
  bool _isInitializing = true;
  bool _isLoading = false;
  String? _errorMessage;
  String? _mobileNumber;
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

  void _init() {
    _authService.authStateChanges.listen((User? authUser) async {
      _user = authUser;
      
      // Cancel previous profile subscription
      await _profileSubscription?.cancel();

      if (authUser != null) {
        // Cache UID for native access
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('flutter.user_uid', authUser.uid);
        
        // Load legacy mobile number if exists (for migration)
        _mobileNumber = prefs.getString('mobile_${authUser.uid}');

        // Start listening to Firestore profile
        _profileSubscription = _authService.userProfileStream(authUser.uid).listen((profile) async {
          _profile = profile;
          if (profile != null) {
            final p = await SharedPreferences.getInstance();
            await p.setBool('flutter.is_premium', profile.isPremium);
            await p.setString('flutter.created_at', profile.createdAt.toIso8601String());
            if (profile.protectionExpiry != null) {
              await p.setString('flutter.protection_expiry', profile.protectionExpiry!.toIso8601String());
            } else {
              await p.remove('flutter.protection_expiry');
            }
          }
          onProfileChanged?.call(profile);
          notifyListeners();
        });
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
      final credential = await _authService.registerWithEmailAndPassword(email: email, password: password);
      
      if (credential.user != null) {
        // Update Firebase Profile Name
        await _authService.updateProfile(displayName: name);
        
        // Create Firestore User Document
        final profile = UserProfile(
          uid: credential.user!.uid,
          name: name,
          email: email,
          mobile: mobile,
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
    _setLoading(true);
    _clearError();
    try {
      await _authService.updateProfile(displayName: name);
      if (_user != null) {
        await _authService.updateUserProfile(_user!.uid, {
          'name': name,
          'mobile': mobile,
        });
      }
      await reloadUser();
    } catch (e) {
      _errorMessage = e.toString();
    }
    _setLoading(false);
  }

  Future<void> extendProtection(int hours) async {
    if (_user == null) return;
    _setLoading(true);
    try {
      await _authService.extendProtection(_user!.uid, hours);
      // Profile stream will automatically update _profile
    } catch (e) {
      _errorMessage = e.toString();
    }
    _setLoading(false);
  }

  Future<void> updateTrustedNumbers(List<TrustedNumber> numbers) async {
    if (_user == null) return;
    try {
      await _authService.updateUserProfile(_user!.uid, {
        'trustedNumbers': numbers.map((n) => n.toMap()).toList(),
      });
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateTriggerKeyword(String keyword) async {
    if (_user == null) return;
    try {
      await _authService.updateUserProfile(_user!.uid, {
        'triggerKeyword': keyword,
      });
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }
}
