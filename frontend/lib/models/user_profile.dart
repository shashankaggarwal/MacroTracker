import 'package:flutter/foundation.dart';

@immutable
class UserProfile {
  final int userId;
  final int profileId;
  final String username;
  final String email;
  final bool isStaff;
  final bool isActive;
  final DateTime? dateJoined;
  final int calorieGoal;
  final int carbsGoal;
  final int proteinGoal;
  final int fatGoal;
  final String accessToken;
  final String refreshToken;

  UserProfile({
    required this.userId,
    required this.profileId,
    required this.username,
    required this.email,
    required this.isStaff,
    required this.isActive,
    this.dateJoined,
    required this.calorieGoal,
    required this.carbsGoal,
    required this.proteinGoal,
    required this.fatGoal,
    required this.accessToken,
    required this.refreshToken,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    debugPrint('Converting JSON to UserProfile with raw JSON: $json');
    try {
      return UserProfile(
        userId: json['user_id'] as int? ?? -1,
        profileId: json['id'] as int? ?? -1,
        username: json['username'] as String? ?? 'N/A',
        email: json['email'] as String? ?? 'N/A',
        isStaff: json['is_staff'] as bool? ?? false,
        isActive: json['is_active'] as bool? ?? false,
        dateJoined: json['date_joined'] != null ? DateTime.parse(json['date_joined'] as String) : null,
        calorieGoal: json['calorie_goal'] as int? ?? 0,
        carbsGoal: json['carbs_goal'] as int? ?? 0,
        proteinGoal: json['protein_goal'] as int? ?? 0,
        fatGoal: json['fat_goal'] as int? ?? 0,
        accessToken: json['access_token'] as String? ?? '',
        refreshToken: json['refresh_token'] as String? ?? '',
      );
    } catch (e, stack) {
      debugPrint('Failed to create UserProfile from JSON with error: $e\nStacktrace: $stack');
      rethrow;
    }
  }

  UserProfile copyWith({
    int? userId,
    int? profileId,
    String? username,
    String? email,
    bool? isStaff,
    bool? isActive,
    DateTime? dateJoined,
    int? calorieGoal,
    int? carbsGoal,
    int? proteinGoal,
    int? fatGoal,
    String? accessToken,
    String? refreshToken,
  }) {
    return UserProfile(
      userId: userId ?? this.userId,
      profileId: profileId ?? this.profileId,
      username: username ?? this.username,
      email: email ?? this.email,
      isStaff: isStaff ?? this.isStaff,
      isActive: isActive ?? this.isActive,
      dateJoined: dateJoined ?? this.dateJoined,
      calorieGoal: calorieGoal ?? this.calorieGoal,
      carbsGoal: carbsGoal ?? this.carbsGoal,
      proteinGoal: proteinGoal ?? this.proteinGoal,
      fatGoal: fatGoal ?? this.fatGoal,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
    );
  }

  @override
  String toString() {
    return 'UserProfile(userId: $userId, profileId: $profileId, username: $username, email: $email, isStaff: $isStaff, isActive: $isActive, dateJoined: $dateJoined, calorieGoal: $calorieGoal, carbsGoal: $carbsGoal, proteinGoal: $proteinGoal, fatGoal: $fatGoal, accessToken: $accessToken, refreshToken: $refreshToken)';
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'profileId': profileId,
      'username': username,
      'email': email,
      'isStaff': isStaff,
      'isActive': isActive,
      'dateJoined': dateJoined?.toIso8601String(),
      'calorieGoal': calorieGoal,
      'carbsGoal': carbsGoal,
      'proteinGoal': proteinGoal,
      'fatGoal': fatGoal,
      'accessToken': accessToken,
      'refreshToken': refreshToken,
    };
  }
}
