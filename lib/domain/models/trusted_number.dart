import 'dart:convert';

/// Represents a trusted phone number that can send recovery commands
class TrustedNumber {
  final String id;
  final String label;
  final String phoneNumber;
  final DateTime addedAt;

  const TrustedNumber({
    required this.id,
    required this.label,
    required this.phoneNumber,
    required this.addedAt,
  });

  TrustedNumber copyWith({
    String? id,
    String? label,
    String? phoneNumber,
    DateTime? addedAt,
  }) {
    return TrustedNumber(
      id: id ?? this.id,
      label: label ?? this.label,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      addedAt: addedAt ?? this.addedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'label': label,
      'phoneNumber': phoneNumber,
      'addedAt': addedAt.toIso8601String(),
    };
  }

  factory TrustedNumber.fromMap(Map<String, dynamic> map) {
    return TrustedNumber(
      id: map['id'] as String,
      label: map['label'] as String,
      phoneNumber: map['phoneNumber'] as String,
      addedAt: DateTime.parse(map['addedAt'] as String),
    );
  }

  String toJson() => jsonEncode(toMap());
  factory TrustedNumber.fromJson(String source) =>
      TrustedNumber.fromMap(jsonDecode(source) as Map<String, dynamic>);

  @override
  String toString() =>
      'TrustedNumber(id: $id, label: $label, phoneNumber: $phoneNumber)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrustedNumber &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
