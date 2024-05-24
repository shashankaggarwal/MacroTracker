import 'package:http/http.dart' as http;
import 'dart:convert';
import 'storage_service.dart';
import 'package:frontend/models/user_profile.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';


class ApiService {
  static const String baseUrl = 'http://192.168.1.3:8000/api';
  final StorageService _storage = StorageService();

 Future<String> _getAuthToken() async {
  var token = await _storage.read(key: 'token');
  if (token == null) {
    await _refreshToken(); // Attempt to refresh the token if it's not found
    token = await _storage.read(key: 'token'); // Re-fetch the token after refresh
    if (token == null) throw Exception('Authentication token not found. Please log in.');
  }
  return token;
}


  Future<void> _refreshToken() async {
    var refreshToken = await _storage.read(key: 'refresh_token');
    if (refreshToken == null) throw Exception('Refresh token not found. Please log in again.');

    var refreshUrl = Uri.parse('$baseUrl/token/refresh/');
    var response = await http.post(
      refreshUrl,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'refresh': refreshToken}),
    );
    var responseData = json.decode(response.body);
    if (response.statusCode == 200 && responseData['access'] != null) {
      await _storage.write(key: 'token', value: responseData['access']);
    } else {
      throw Exception('Failed to refresh token. Server responded with status code: ${response.statusCode} and body: ${response.body}');
    }
  }

Future<dynamic> _processResponse(http.Response response, {int retryCount = 0}) async {
  var data = json.decode(response.body);

  // Handle successful response with data extraction from 'results' for pagination
  if (response.statusCode == 200 || response.statusCode == 201) {
    if (data is Map<String, dynamic> && data.containsKey('results')) {
      // Return the list contained in 'results', handling pagination properly
      return data['results'];
    } else {
      // Handle cases where the response is successful but not paginated
      return data;
    }
  } else if (response.statusCode == 401) {
    // Retry logic for unauthorized access
    if (retryCount >= 3) {
      throw Exception('Unauthorized after multiple attempts. Please check credentials or session state.');
    }
    await _refreshToken();
    return await _retryPreviousRequest(response.request as http.Request, retryCount + 1);
  } else if (response.statusCode == 404) {
    // Specific error for not found resources
    throw Exception('Not found: No matching records found for the provided ID.');
  } else {
    // General error handling for other HTTP status codes
    print('Request failed with status: ${response.statusCode}. Response body: ${response.body}');
    throw Exception('Request failed with status: ${response.statusCode} and body: ${response.body}');
  }
}


Future<dynamic> _retryPreviousRequest(http.Request request, int retryCount) async {
  var token = await _getAuthToken();
  request.headers['Authorization'] = 'Bearer $token';

  var newRequest = http.Request(request.method, request.url)
    ..headers.addAll(request.headers)
    ..body = request.body; // Ensure this is an http.Request to access 'body'

  var response = await http.Response.fromStream(await newRequest.send());
  return await _processResponse(response, retryCount: retryCount);
}

  Future<void> resetPassword(String email) async {
  var resetPasswordUrl = Uri.parse('${ApiService.baseUrl}/password_reset/');
  var response = await http.post(
    resetPasswordUrl,
    headers: {'Content-Type': 'application/json'},
    body: json.encode({'email': email}),
  );
  await _processResponse(response);
}

  // Authentication Methods
  Future<String> loginUser(String username, String password) async {
    var loginUrl = Uri.parse('$baseUrl/login/');
    var response = await http.post(
      loginUrl,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'username': username, 'password': password}),
    );
    var responseData = await _processResponse(response);
    if (responseData.containsKey('access')) {
      await _storage.write(key: 'token', value: responseData['access']);
      if (responseData.containsKey('refresh')) {
        await _storage.write(key: 'refresh_token', value: responseData['refresh']);
      }
      return responseData['access'];
    } else {
      throw Exception("Token not found in response");
    }
  }

  Future<Map<String, dynamic>> registerUser(String username, String email, String password) async {
  var registerUrl = Uri.parse('$baseUrl/users/');
  var response = await http.post(
    registerUrl,
    headers: {'Content-Type': 'application/json'},
    body: json.encode({
      'username': username,
      'email': email,
      'password': password
    }),
  );
  var responseData = json.decode(response.body);
  if (response.statusCode == 200 || response.statusCode == 201) {
    // Store both user and profile IDs if separate or just user ID
    // Assuming responseData contains 'user_id' and 'profile_id'
    await _storage.write(key: 'userId', value: responseData['user_id'].toString());
    if (responseData.containsKey('profile_id')) {
      await _storage.write(key: 'profileId', value: responseData['profile_id'].toString());
    }
    await _storage.write(key: 'token', value: responseData['access']);
    await _storage.write(key: 'refresh_token', value: responseData['refresh']);
    return responseData;
  } else {
    throw Exception('Registration failed with status: ${response.statusCode} and body: ${response.body}');
  }
}


  Future<void> clearCredentials() async {
    await _storage.deleteAll();
  }

  // Profile Methods
  Future<List<dynamic>> fetchProfiles() async {
  var token = await _getAuthToken();
  var profileUrl = Uri.parse('$baseUrl/profiles/');
  var response = await http.get(profileUrl, headers: {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  });
  return await _processResponse(response);
}

Future<void> updateProfile(int profileId, Map<String, dynamic> updatedData) async {
  var token = await _getAuthToken();
  var updateUrl = Uri.parse('$baseUrl/profiles/$profileId/');
  try {
    var response = await http.put(
      updateUrl,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(updatedData)
    );
    var responseData = await _processResponse(response);

    // If the response data includes updated profile information, update the state.
    if (responseData != null && responseData is Map<String, dynamic>) {
      // This assumes that the backend responds with the updated profile data.
      // You might need to adjust the key depending on your API's response structure.
      var updatedUserProfile = UserProfile.fromJson(responseData);
      // Assuming you have access to the AuthState and can call copyWith.
      // This might be managed within the AuthController instead.
      print('Profile updated for user ID: ${updatedUserProfile.userId}');
    }

  } catch (e) {
    print('An error occurred updating profile ID $profileId: $e');
    throw Exception('Failed to update profile: $e');
  }
}
  // Food Logs Methods
  Future<List<dynamic>> fetchFoodLogs({DateTime? date, DateTime? startDate, DateTime? endDate}) async {
  var token = await _getAuthToken();
  Map<String, String> queryParameters = {};

  if (date != null) {
    String formattedDate = DateFormat('yyyy-MM-dd').format(date);
    queryParameters['date'] = formattedDate;
  } else if (startDate != null && endDate != null) {
    String formattedStartDate = DateFormat('yyyy-MM-dd').format(startDate);
    String formattedEndDate = DateFormat('yyyy-MM-dd').format(endDate);
    queryParameters['start_date'] = formattedStartDate;
    queryParameters['end_date'] = formattedEndDate;
  }

  var logsUrl = Uri.parse('$baseUrl/food_logs/').replace(queryParameters: queryParameters);
  var response = await http.get(logsUrl, headers: {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  });
  var result = await _processResponse(response);
  debugPrint('Fetched logs: ${jsonEncode(result)}');
  return result;
}

  Future<void> createFoodLog(Map<String, dynamic> foodLogData) async {
  var token = await _getAuthToken();
  debugPrint('Using token: $token'); // Print the token to verify its correctness

  var foodLogsUrl = Uri.parse('$baseUrl/food_logs/');
  debugPrint('Request URL: $foodLogsUrl'); // Confirm the URL

  // Serialize the request body and print it to ensure it matches backend expectations
  var requestBody = json.encode(foodLogData);
  debugPrint('Sending body: $requestBody');

  var response = await http.post(
    foodLogsUrl,
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
    body: requestBody,
  );

  // Print out the response status and body to understand what the server returns
  debugPrint('HTTP Status: ${response.statusCode}');
  debugPrint('HTTP Body: ${response.body}');

  await _processResponse(response);
}



  Future<void> updateFoodLog(int logId, Map<String, dynamic> updateData) async {
    var token = await _getAuthToken();
    var logUrl = Uri.parse('$baseUrl/food_logs/$logId/');
    var response = await http.put(
      logUrl,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(updateData),
    );
    await _processResponse(response);
  }

 Future<void> deleteFoodLog(int logId) async {
  var token = await _getAuthToken();
  var logUrl = Uri.parse('$baseUrl/food_logs/$logId/');
  var response = await http.delete(
    logUrl,
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
  );

  if (response.statusCode == 204) {
    // 204 No Content indicates successful deletion
    return;
  } else {
    await _processResponse(response);
  }
}
  
  // Notifications Methods
  Future<List<dynamic>> fetchNotifications() async {
    var token = await _getAuthToken();
    var notificationUrl = Uri.parse('$baseUrl/notifications/');
    var response = await http.get(notificationUrl, headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    });
    return await _processResponse(response);
  }

  Future<void> createNotification(Map<String, dynamic> notificationData) async {
    var token = await _getAuthToken();
    var notificationUrl = Uri.parse('$baseUrl/notifications/');
    var response = await http.post(
      notificationUrl,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(notificationData),
    );
    await _processResponse(response);
  }

  Future<void> updateNotification(int notificationId, Map<String, dynamic> updateData) async {
    var token = await _getAuthToken();
    var notificationUrl = Uri.parse('$baseUrl/notifications/$notificationId/');
    var response = await http.put(
      notificationUrl,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(updateData),
    );
    await _processResponse(response);
  }

  Future<void> deleteNotification(int notificationId) async {
    var token = await _getAuthToken();
    var notificationUrl = Uri.parse('$baseUrl/notifications/$notificationId/');
    var response = await http.delete(
      notificationUrl,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    await _processResponse(response);
  }

  // Insights Methods
  Future<List<dynamic>> fetchInsights() async {
    var token = await _getAuthToken();
    var insightsUrl = Uri.parse('$baseUrl/insights/');
    var response = await http.get(insightsUrl, headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    });
    return await _processResponse(response);
  }

// Search food items by a query string
Future<List<Map<String, dynamic>>> searchFoodItems(String query) async {
  var token = await _getAuthToken();
  var url = Uri.parse('$baseUrl/food_items/?search=$query');
  var response = await http.get(url, headers: {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  });
  // Assuming response.body is a JSON-encoded string of an array.
  if (response.statusCode == 200) {
    return List<Map<String, dynamic>>.from(json.decode(response.body));
  } else {
    throw Exception('Failed to load food items');
  }
}


// Create a new food item
Future<Map<String, dynamic>> createFoodItem(Map<String, dynamic> foodItemData) async {
  var token = await _getAuthToken();
  var url = Uri.parse('$baseUrl/food_items/');
  var response = await http.post(url, headers: {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  }, body: json.encode(foodItemData));
  return await _processResponse(response);
}

// Update an existing food item
Future<void> updateFoodItem(int itemId, Map<String, dynamic> foodItemData) async {
  var token = await _getAuthToken();
  var url = Uri.parse('$baseUrl/food_items/$itemId/');
  var response = await http.patch(url, headers: {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  }, body: json.encode(foodItemData));
  await _processResponse(response);
}

// Add this method inside the ApiService class
// Delete an existing food item
Future<void> deleteFoodItem(int itemId) async {
  var token = await _getAuthToken();
  var url = Uri.parse('$baseUrl/food_items/$itemId/');
  var response = await http.delete(url, headers: {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  });
  await _processResponse(response);
}
  
}


