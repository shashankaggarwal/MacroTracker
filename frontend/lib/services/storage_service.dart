// storage_service.dart

// Conditional imports
import 'storage_service_stub.dart'
    if (dart.library.io) 'storage_service_mobile.dart' // Targets iOS and Android
    if (dart.library.html) 'storage_service_web.dart'; // Targets Web

// The abstract class that defines the storage interface
abstract class StorageService {
  Future<void> write({required String key, required String value});
  Future<String?> read({required String key});
  Future<void> deleteAll();

  // Factory constructor to create the appropriate implementation
  factory StorageService() {
    return getStorageService();
  }
}
