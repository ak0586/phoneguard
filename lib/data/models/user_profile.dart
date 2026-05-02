import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/trusted_number.dart';

class UserProfile {
  final String uid;
  final String name;
  final String email;
  final String mobile;
  final String subscriptionType; // none, monthly, yearly
  final String subscriptionStatus; // active, expired, cancelled, none
  final String? purchaseToken;
  final bool isPremium;
  final DateTime? protectionExpiry;
  final double? lastLatitude;
  final double? lastLongitude;
  final DateTime? locationUpdatedAt;
  final DateTime createdAt;
  final List<TrustedNumber> trustedNumbers;
  final String? triggerKeyword;
  final String? currentDeviceId;
  final String? photoUrl;
  
  // Extra metadata
  final String? deviceModel;
  final String? osVersion;
  final String? lastIp;
  final DateTime? lastActive;
  final String role; // user, admin
  final int adsWatchedToday;
  final String? lastAdDate;

  UserProfile({
    required this.uid,
    required this.name,
    required this.email,
    required this.mobile,
    this.subscriptionType = 'none',
    this.subscriptionStatus = 'none',
    this.purchaseToken,
    this.isPremium = false,
    this.protectionExpiry,
    this.lastLatitude,
    this.lastLongitude,
    this.locationUpdatedAt,
    required this.createdAt,
    this.trustedNumbers = const [],
    this.triggerKeyword,
    this.currentDeviceId,
    this.photoUrl,
    this.deviceModel,
    this.osVersion,
    this.lastIp,
    this.lastActive,
    this.role = 'user',
    this.adsWatchedToday = 0,
    this.lastAdDate,
  });

  factory UserProfile.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserProfile(
      uid: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      mobile: data['mobile'] ?? '',
      subscriptionType: data['subscriptionType'] ?? 'none',
      subscriptionStatus: data['subscriptionStatus'] ?? 'none',
      purchaseToken: data['purchaseToken'] as String?,
      isPremium: data['isPremium'] ?? false,
      protectionExpiry: (data['protectionExpiry'] as Timestamp?)?.toDate(),
      lastLatitude: (data['lastLatitude'] as num?)?.toDouble(),
      lastLongitude: (data['lastLongitude'] as num?)?.toDouble(),
      locationUpdatedAt: (data['locationUpdatedAt'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      trustedNumbers: (data['trustedNumbers'] as List?)
              ?.map((e) => TrustedNumber.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      triggerKeyword: data['triggerKeyword'] as String?,
      currentDeviceId: data['currentDeviceId'] as String?,
      photoUrl: data['photoUrl'] as String?,
      deviceModel: data['deviceModel'] as String?,
      osVersion: data['osVersion'] as String?,
      lastIp: data['lastIp'] as String?,
      lastActive: (data['lastActive'] as Timestamp?)?.toDate(),
      role: data['role'] ?? 'user',
      adsWatchedToday: data['adsWatchedToday'] ?? 0,
      lastAdDate: data['lastAdDate'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'mobile': mobile,
      'subscriptionType': subscriptionType,
      'subscriptionStatus': subscriptionStatus,
      'purchaseToken': purchaseToken,
      'isPremium': isPremium,
      'protectionExpiry': protectionExpiry?.toIso8601String(),
      'lastLatitude': lastLatitude,
      'lastLongitude': lastLongitude,
      'locationUpdatedAt': locationUpdatedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'trustedNumbers': trustedNumbers.map((n) => n.toMap()).toList(),
      'triggerKeyword': triggerKeyword,
      'currentDeviceId': currentDeviceId,
      'photoUrl': photoUrl,
      'deviceModel': deviceModel,
      'osVersion': osVersion,
      'lastIp': lastIp,
      'lastActive': lastActive?.toIso8601String(),
      'role': role,
      'adsWatchedToday': adsWatchedToday,
      'lastAdDate': lastAdDate,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      mobile: map['mobile'] ?? '',
      subscriptionType: map['subscriptionType'] ?? 'none',
      subscriptionStatus: map['subscriptionStatus'] ?? 'none',
      purchaseToken: map['purchaseToken'] as String?,
      isPremium: map['isPremium'] ?? false,
      protectionExpiry: map['protectionExpiry'] != null ? DateTime.parse(map['protectionExpiry']) : null,
      lastLatitude: (map['lastLatitude'] as num?)?.toDouble(),
      lastLongitude: (map['lastLongitude'] as num?)?.toDouble(),
      locationUpdatedAt: map['locationUpdatedAt'] != null ? DateTime.parse(map['locationUpdatedAt']) : null,
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : DateTime.now(),
      trustedNumbers: (map['trustedNumbers'] as List?)
              ?.map((e) => TrustedNumber.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      triggerKeyword: map['triggerKeyword'] as String?,
      currentDeviceId: map['currentDeviceId'] as String?,
      photoUrl: map['photoUrl'] as String?,
      deviceModel: map['deviceModel'] as String?,
      osVersion: map['osVersion'] as String?,
      lastIp: map['lastIp'] as String?,
      lastActive: map['lastActive'] != null ? DateTime.parse(map['lastActive']) : null,
      role: map['role'] ?? 'user',
      adsWatchedToday: map['adsWatchedToday'] ?? 0,
      lastAdDate: map['lastAdDate'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'mobile': mobile,
      'subscriptionType': subscriptionType,
      'subscriptionStatus': subscriptionStatus,
      'purchaseToken': purchaseToken,
      'isPremium': isPremium,
      'protectionExpiry': protectionExpiry != null ? Timestamp.fromDate(protectionExpiry!) : null,
      'lastLatitude': lastLatitude,
      'lastLongitude': lastLongitude,
      'locationUpdatedAt': locationUpdatedAt != null ? Timestamp.fromDate(locationUpdatedAt!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'trustedNumbers': trustedNumbers.map((n) => n.toMap()).toList(),
      'triggerKeyword': triggerKeyword,
      'currentDeviceId': currentDeviceId,
      'photoUrl': photoUrl,
      'deviceModel': deviceModel,
      'osVersion': osVersion,
      'lastIp': lastIp,
      'lastActive': lastActive != null ? Timestamp.fromDate(lastActive!) : FieldValue.serverTimestamp(),
      'role': role,
      'adsWatchedToday': adsWatchedToday,
      'lastAdDate': lastAdDate,
    };
  }

  UserProfile copyWith({
    String? name,
    String? mobile,
    String? subscriptionType,
    String? subscriptionStatus,
    String? purchaseToken,
    bool? isPremium,
    DateTime? protectionExpiry,
    double? lastLatitude,
    double? lastLongitude,
    DateTime? locationUpdatedAt,
    List<TrustedNumber>? trustedNumbers,
    String? triggerKeyword,
    String? currentDeviceId,
    String? photoUrl,
    String? deviceModel,
    String? osVersion,
    String? lastIp,
    DateTime? lastActive,
    String? role,
    int? adsWatchedToday,
    String? lastAdDate,
  }) {
    return UserProfile(
      uid: uid,
      name: name ?? this.name,
      email: email,
      mobile: mobile ?? this.mobile,
      subscriptionType: subscriptionType ?? this.subscriptionType,
      subscriptionStatus: subscriptionStatus ?? this.subscriptionStatus,
      purchaseToken: purchaseToken ?? this.purchaseToken,
      isPremium: isPremium ?? this.isPremium,
      protectionExpiry: protectionExpiry ?? this.protectionExpiry,
      lastLatitude: lastLatitude ?? this.lastLatitude,
      lastLongitude: lastLongitude ?? this.lastLongitude,
      locationUpdatedAt: locationUpdatedAt ?? this.locationUpdatedAt,
      createdAt: createdAt,
      trustedNumbers: trustedNumbers ?? this.trustedNumbers,
      triggerKeyword: triggerKeyword ?? this.triggerKeyword,
      currentDeviceId: currentDeviceId ?? this.currentDeviceId,
      photoUrl: photoUrl ?? this.photoUrl,
      deviceModel: deviceModel ?? this.deviceModel,
      osVersion: osVersion ?? this.osVersion,
      lastIp: lastIp ?? this.lastIp,
      lastActive: lastActive ?? this.lastActive,
      role: role ?? this.role,
      adsWatchedToday: adsWatchedToday ?? this.adsWatchedToday,
      lastAdDate: lastAdDate ?? this.lastAdDate,
    );
  }
}
