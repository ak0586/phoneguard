import 'dart:convert';

/// Represents a recovery action log entry
class ActivityLog {
  final String id;
  final DateTime timestamp;
  final String senderNumber;
  final String command;
  final String result;
  final bool success;

  const ActivityLog({
    required this.id,
    required this.timestamp,
    required this.senderNumber,
    required this.command,
    required this.result,
    required this.success,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'senderNumber': senderNumber,
      'command': command,
      'result': result,
      'success': success,
    };
  }

  factory ActivityLog.fromMap(Map<String, dynamic> map) {
    return ActivityLog(
      id: map['id'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
      senderNumber: map['senderNumber'] as String,
      command: map['command'] as String,
      result: map['result'] as String,
      success: map['success'] as bool,
    );
  }

  String toJson() => jsonEncode(toMap());
  factory ActivityLog.fromJson(String source) =>
      ActivityLog.fromMap(jsonDecode(source) as Map<String, dynamic>);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActivityLog &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
