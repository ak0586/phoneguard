import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/trusted_number.dart';

class UserProfile {
  final String uid;
  final String name;
  final String email;
  final String mobile;
  final String subscriptionType;
  final bool isPremium;
  final DateTime? protectionExpiry;
  final double? lastLatitude;
  final double? lastLongitude;
  final DateTime? locationUpdatedAt;
  final DateTime createdAt;
  final List<TrustedNumber> trustedNumbers;
  final String? triggerKeyword;

  UserProfile({
    required this.uid,
    required this.name,
    required this.email,
    required this.mobile,
    this.subscriptionType = 'none',
    this.isPremium = false,
    this.protectionExpiry,
    this.lastLatitude,
    this.lastLongitude,
    this.locationUpdatedAt,
    required this.createdAt,
    this.trustedNumbers = const [],
    this.triggerKeyword,
  });

  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserProfile(
      uid: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      mobile: data['mobile'] ?? '',
      subscriptionType: data['subscriptionType'] ?? 'none',
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
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'mobile': mobile,
      'subscriptionType': subscriptionType,
      'isPremium': isPremium,
      'protectionExpiry': protectionExpiry != null ? Timestamp.fromDate(protectionExpiry!) : null,
      'lastLatitude': lastLatitude,
      'lastLongitude': lastLongitude,
      'locationUpdatedAt': locationUpdatedAt != null ? Timestamp.fromDate(locationUpdatedAt!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'trustedNumbers': trustedNumbers.map((n) => n.toMap()).toList(),
      'triggerKeyword': triggerKeyword,
    };
  }

  UserProfile copyWith({
    String? name,
    String? mobile,
    String? subscriptionType,
    bool? isPremium,
    DateTime? protectionExpiry,
    double? lastLatitude,
    double? lastLongitude,
    DateTime? locationUpdatedAt,
    List<TrustedNumber>? trustedNumbers,
    String? triggerKeyword,
  }) {
    return UserProfile(
      uid: uid,
      name: name ?? this.name,
      email: email,
      mobile: mobile ?? this.mobile,
      subscriptionType: subscriptionType ?? this.subscriptionType,
      isPremium: isPremium ?? this.isPremium,
      protectionExpiry: protectionExpiry ?? this.protectionExpiry,
      lastLatitude: lastLatitude ?? this.lastLatitude,
      lastLongitude: lastLongitude ?? this.lastLongitude,
      locationUpdatedAt: locationUpdatedAt ?? this.locationUpdatedAt,
      createdAt: createdAt,
      trustedNumbers: trustedNumbers ?? this.trustedNumbers,
      triggerKeyword: triggerKeyword ?? this.triggerKeyword,
    );
  }
}
