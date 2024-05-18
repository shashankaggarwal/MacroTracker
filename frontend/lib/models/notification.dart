import 'user_profile.dart'; // Import the UserProfile class

class Notification {
  final int id;
  final UserProfile userProfile; // Using UserProfile instead of User
  final String message;
  final String notificationType;
  final DateTime createdAt;

  Notification({
    required this.id,
    required this.userProfile,
    required this.message,
    required this.notificationType,
    required this.createdAt,
  });

  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      id: json['id'] as int,
      userProfile: UserProfile.fromJson(json['user']), // Deserialize the UserProfile object
      message: json['message'] as String,
      notificationType: json['notification_type'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': userProfile.toJson(), // Serialize the UserProfile object
      'message': message,
      'notification_type': notificationType,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
