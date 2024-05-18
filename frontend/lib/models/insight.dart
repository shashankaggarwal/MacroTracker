import 'user_profile.dart'; // Make sure to import the UserProfile class

class Insight {
  final int id;
  final UserProfile userProfile; // Using UserProfile instead of User
  final String insightType;
  final String value;
  final DateTime generatedAt;

  Insight({
    required this.id,
    required this.userProfile,
    required this.insightType,
    required this.value,
    required this.generatedAt,
  });

  factory Insight.fromJson(Map<String, dynamic> json) {
    return Insight(
      id: json['id'] as int,
      userProfile: UserProfile.fromJson(json['user']),
      insightType: json['insight_type'] as String,
      value: json['value'] as String,
      generatedAt: DateTime.parse(json['generated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': userProfile.toJson(),
      'insight_type': insightType,
      'value': value,
      'generated_at': generatedAt.toIso8601String(),
    };
  }
}
