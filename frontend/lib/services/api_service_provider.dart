// File: lib/services/api_service_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_service.dart';

final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();  // Assuming ApiService doesn't require any parameters
});
