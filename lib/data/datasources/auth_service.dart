import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Stream of user auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Current user
  User? get currentUser => _auth.currentUser;

  /// Get reference to users collection
  CollectionReference get _usersCollection => _firestore.collection('users');

  /// Stream of user profile data
  Stream<UserProfile?> userProfileStream(String uid) {
    return _usersCollection.doc(uid).snapshots().map((doc) {
      if (doc.exists) {
        return UserProfile.fromFirestore(doc);
      }
      return null;
    });
  }

  /// Get user profile once
  Future<UserProfile?> getUserProfile(String uid) async {
    final doc = await _usersCollection.doc(uid).get();
    if (doc.exists) {
      return UserProfile.fromFirestore(doc);
    }
    return null;
  }

  /// Create or set user profile
  Future<void> setUserProfile(UserProfile profile) async {
    await _usersCollection.doc(profile.uid).set(profile.toFirestore(), SetOptions(merge: true));
  }

  /// Ensure profile exists in Firestore, create with defaults if not
  Future<void> ensureUserProfileExists(User user, {String? name, String? mobile}) async {
    final doc = await _usersCollection.doc(user.uid).get();
    if (!doc.exists) {
      final profile = UserProfile(
        uid: user.uid,
        name: name ?? user.displayName ?? 'User',
        email: user.email ?? '',
        mobile: mobile ?? '',
        createdAt: DateTime.now(),
      );
      await setUserProfile(profile);
    } else {
      // Document exists, just update last active timestamp
      await _usersCollection.doc(user.uid).update({
        'lastActive': FieldValue.serverTimestamp(),
      }).catchError((_) {}); // Ignore if fails due to offline
    }
  }

  /// Update location and set timestamp
  Future<void> updateLocation(String uid, {required double latitude, required double longitude}) async {
    await _usersCollection.doc(uid).set({
      'lastLatitude': latitude,
      'lastLongitude': longitude,
      'locationUpdatedAt': FieldValue.serverTimestamp(),
      'lastActive': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Update device metadata
  Future<void> updateDeviceMetadata(String uid, Map<String, dynamic> metadata) async {
    await _usersCollection.doc(uid).set(metadata, SetOptions(merge: true));
  }

  /// Update specific fields in user profile
  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    await _usersCollection.doc(uid).update(data);
  }

  /// Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Register with email and password
  Future<UserCredential> registerWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Update Profile (both Auth and Firestore)
  Future<void> updateFullProfile(String uid, {required String name, required String mobile}) async {
    // 1. Update Firebase Auth (if current user matches)
    if (currentUser != null && currentUser!.uid == uid) {
      await currentUser!.updateDisplayName(name);
    }

    // 2. Update Firestore
    await _usersCollection.doc(uid).update({
      'name': name,
      'mobile': mobile,
    });
  }

  /// Update Profile Display Name (Firebase Auth)
  Future<void> updateProfile({String? displayName}) async {
    if (currentUser != null) {
      await currentUser!.updateDisplayName(displayName);
      await currentUser!.reload();
      
      // Also update in Firestore if document exists
      await _usersCollection.doc(currentUser!.uid).set({
        'name': displayName,
      }, SetOptions(merge: true));
    }
  }

  /// Extend protection by X hours
  Future<void> extendProtection(String uid, int hours) async {
    final doc = await _usersCollection.doc(uid).get();
    if (doc.exists) {
      final profile = UserProfile.fromFirestore(doc);
      DateTime currentExpiry = profile.protectionExpiry ?? DateTime.now();
      if (currentExpiry.isBefore(DateTime.now())) {
        currentExpiry = DateTime.now();
      }
      final newExpiry = currentExpiry.add(Duration(hours: hours));
      await _usersCollection.doc(uid).update({
        'protectionExpiry': Timestamp.fromDate(newExpiry),
      });
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  /// Send email verification
  Future<void> sendEmailVerification() async {
    if (currentUser != null && !currentUser!.emailVerified) {
      await currentUser!.sendEmailVerification();
    }
  }

  /// Reload user
  Future<void> reloadUser() async {
    if (currentUser != null) {
      await currentUser!.reload();
    }
  }
}
