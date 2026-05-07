import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_profile.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  AuthService() {
    _googleSignIn.initialize();
  }

  /// Stream of user auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Current user
  User? get currentUser => _auth.currentUser;

  /// Get reference to users collection
  CollectionReference<Map<String, dynamic>> get _usersCollection => _firestore.collection('users');

  /// Stream of user profile data
  Stream<UserProfile?> userProfileStream(String uid) {
    return _usersCollection.doc(uid).snapshots().map((DocumentSnapshot<Map<String, dynamic>> doc) {
      if (doc.exists) {
        return UserProfile.fromFirestore(doc);
      }
      return null;
    });
  }

  /// Get user profile once
  Future<UserProfile?> getUserProfile(String uid) async {
    final DocumentSnapshot<Map<String, dynamic>> doc = await _usersCollection.doc(uid).get();
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

  /// Sign in with Google
  Future<UserCredential> signInWithGoogle() async {
    // Ensure initialized
    await _googleSignIn.initialize();
    
    final GoogleSignInAccount? googleUser = await _googleSignIn.authenticate();
    
    if (googleUser == null) {
      throw FirebaseAuthException(
        code: 'ERROR_ABORTED_BY_USER',
        message: 'Sign in aborted by user',
      );
    }

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    
    // Explicitly authorize scopes to get the access token in 7.x
    final String? idToken = googleAuth.idToken;
    final String? accessToken = (await googleUser.authorizationClient.authorizeScopes(['email'])).accessToken;

    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: accessToken,
      idToken: idToken,
    );

    return await _auth.signInWithCredential(credential);
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
    final DocumentSnapshot<Map<String, dynamic>> doc = await _usersCollection.doc(uid).get();
    if (doc.exists) {
      final profile = UserProfile.fromFirestore(doc);
      DateTime currentExpiry = profile.protectionExpiry ?? DateTime.now();
      if (currentExpiry.isBefore(DateTime.now())) {
        currentExpiry = DateTime.now();
      }
      final newExpiry = currentExpiry.add(Duration(hours: hours));
      
      final today = DateTime.now().toIso8601String().substring(0, 10);
      int newCount = (profile.lastAdDate == today) ? (profile.adsWatchedToday + 1) : 1;

      await _usersCollection.doc(uid).update({
        'protectionExpiry': Timestamp.fromDate(newExpiry),
        'adsWatchedToday': newCount,
        'lastAdDate': today,
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

  /// Send a remote command to a device via Firestore
  Future<void> sendRemoteCommand(String uid, String action) async {
    await _usersCollection.doc(uid).set({
      'pendingCommand': {
        'action': action,
        'issuedAt': FieldValue.serverTimestamp(),
      }
    }, SetOptions(merge: true));
  }

  /// Watch for the result of the last remote command
  Stream<Map<String, dynamic>?> watchCommandResult(String uid) {
    return _usersCollection.doc(uid).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        if (data.containsKey('commandResult')) {
          return data['commandResult'] as Map<String, dynamic>;
        }
      }
      return null;
    });
  }

  /// Stream intrusion photos
  Stream<List<Map<String, dynamic>>> intrusionPhotosStream(String uid) {
    return _usersCollection.doc(uid).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        if (data.containsKey('intrusionPhotos')) {
          return List<Map<String, dynamic>>.from(data['intrusionPhotos'] as List);
        }
      }
      return [];
    });
  }

  /// Clear intrusion photos
  Future<void> clearIntrusionPhotos(String uid) async {
    await _usersCollection.doc(uid).update({
      'intrusionPhotos': FieldValue.delete(),
    });
  }

  /// Delete a specific intrusion photo
  Future<void> deleteIntrusionPhoto(String uid, Map<String, dynamic> photo) async {
    await _usersCollection.doc(uid).update({
      'intrusionPhotos': FieldValue.arrayRemove([photo]),
    });
  }

  // ─── Activity Logs ───────────────────────────────────────────────────────

  /// Upload a single log to Firestore
  Future<void> uploadLog(String uid, Map<String, dynamic> logData) async {
    final logId = logData['id'] as String;
    await _usersCollection.doc(uid).collection('activity_logs').doc(logId).set(logData);
  }

  /// Fetch latest logs from Firestore
  Future<List<Map<String, dynamic>>> fetchRemoteLogs(String uid, {int limit = 50}) async {
    final snapshot = await _usersCollection
        .doc(uid)
        .collection('activity_logs')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .get();
    
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  /// Delete a single log from Firestore
  Future<void> deleteRemoteLog(String uid, String logId) async {
    await _usersCollection.doc(uid).collection('activity_logs').doc(logId).delete();
  }

  /// Clear all logs in Firestore
  Future<void> clearRemoteLogs(String uid) async {
    final logs = await _usersCollection.doc(uid).collection('activity_logs').get();
    final batch = _firestore.batch();
    for (var doc in logs.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  /// Delete account with password re-authentication
  Future<void> deleteAccount(String password) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user logged in');

    // Re-authenticate
    AuthCredential credential = EmailAuthProvider.credential(
      email: user.email!,
      password: password,
    );
    
    await user.reauthenticateWithCredential(credential);

    // Delete Firestore data
    await _usersCollection.doc(user.uid).delete();

    // Delete Auth account
    await user.delete();
  }
}
