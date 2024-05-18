import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../services/api_service_provider.dart';
import '../models/user_profile.dart';
import '../services/storage_service.dart';

class AuthState {
  final bool isLoggedIn;
  final String token;
  final UserProfile? userProfile;

  AuthState({this.isLoggedIn = false, this.token = '', this.userProfile});

  AuthState copyWith({bool? isLoggedIn, String? token, UserProfile? userProfile}) {
    return AuthState(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      token: token ?? this.token,
      userProfile: userProfile ?? this.userProfile,
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  final ApiService apiService;
  final StorageService _storage = StorageService();

  AuthController({required this.apiService}) : super(AuthState());

  Future<void> login(String username, String password) async {
    print('Attempting login for user: $username');
    try {
      final token = await apiService.loginUser(username, password);
      print('Login response token: $token');
      if (token.isNotEmpty) {
        await _storage.write(key: 'token', value: token);
        print('State before login: isLoggedIn=${state.isLoggedIn}, token=${state.token}, userProfile=${state.userProfile?.username}');
        state = state.copyWith(isLoggedIn: true, token: token);
        print('User $username logged in with token: $token');
        print('State after login: isLoggedIn=${state.isLoggedIn}, token=${state.token}, userProfile=${state.userProfile?.username}');
      } else {
        print('Received empty token for user $username');
        throw Exception('Token is empty or not received');
      }
    } catch (e) {
      print('Login failed for user $username with error: $e');
      state = state.copyWith(isLoggedIn: false, token: '');
      throw Exception('Login Failed: ${e.toString()}');
    }
  }
  
  Future<void> register(String username, String email, String password) async {
    print('Attempting registration for user: $username');
    try {
      var response = await apiService.registerUser(username, email, password);
      print('Registration response: $response');

      final String? accessToken = response['access'];
      final String? refreshToken = response['refresh'];

      if (accessToken == null || accessToken.isEmpty) {
        print('Access token is empty or not received for user $username');
        throw Exception('Access token is empty or not received.');
      }
      if (refreshToken == null || refreshToken.isEmpty) {
        print('Refresh token is empty or not received for user $username');
        throw Exception('Refresh token is empty or not received.');
      }

      var userProfile = UserProfile.fromJson({
        'id': response['id'],
        'username': response['username'],
        'email': response['email'],
        'is_staff': response['is_staff'],
        'is_active': response['is_active'],
        'date_joined': response['date_joined'],
        'profile': response['profile'], // This should include the nested goals data
        'access': accessToken,
        'refresh': refreshToken,
      });

      await _storage.write(key: 'token', value: accessToken);
      await _storage.write(key: 'refresh_token', value: refreshToken);

      state = state.copyWith(isLoggedIn: true, userProfile: userProfile, token: accessToken);
      print('User $username registered and logged in.');
    } catch (e, stackTrace) {
      print('Registration error for user $username: $e');
      print('Stack trace: $stackTrace');
      throw Exception('Registration Failed: $e');
    }
  }

  Future<void> updateProfile(int profileId, Map<String, dynamic> updatedData) async {
    print('Attempting to update profile for profile ID: $profileId');
    try {
      final userProfile = state.userProfile;
      if (userProfile == null) {
        print('No user profile to update for profile ID: $profileId');
        throw Exception('No user profile to update.');
      }

      await apiService.updateProfile(userProfile.profileId, updatedData);
      final updatedUserProfile = userProfile.copyWith(
        calorieGoal: updatedData['calorie_goal'],
        carbsGoal: updatedData['carbs_goal'],
        proteinGoal: updatedData['protein_goal'],
        fatGoal: updatedData['fat_goal'],
      );

      state = state.copyWith(userProfile: updatedUserProfile);
      print('Profile updated for user ID: ${userProfile.userId}');
    } catch (e) {
      print('Profile update failed for profile ID: $profileId: $e');
      throw Exception('Profile Update Failed: $e');
    }
  }

  void logout() {
    print('Logging out user.');
    state = AuthState(isLoggedIn: false, token: '');
    _storage.deleteAll();
    apiService.clearCredentials();
    print('User logged out successfully.');
  }

  Future<void> resetPassword(String email) async {
    print('Attempting password reset for email: $email');
    try {
      await apiService.resetPassword(email);
      print('Password reset email sent to $email');
    } catch (e) {
      print('Password reset failed for email $email: $e');
      throw Exception('Password Reset Failed: $e');
    }
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  ApiService apiService = ref.read(apiServiceProvider);
  return AuthController(apiService: apiService);
});
