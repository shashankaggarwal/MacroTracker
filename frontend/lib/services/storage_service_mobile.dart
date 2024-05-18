// storage_service_mobile.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'storage_service.dart';

// The mobile implementation of StorageService
class MobileStorageService implements StorageService {
  final _secureStorage = FlutterSecureStorage();

  @override
  Future<void> write({required String key, required String value}) async {
    await _secureStorage.write(key: key, value: value);
  }

  @override
  Future<String?> read({required String key}) async {
    return await _secureStorage.read(key: key);
  }

  @override
  Future<void> deleteAll() async {
    await _secureStorage.deleteAll();
  }
}

// The factory method that creates an instance of the mobile storage service
StorageService getStorageService() => MobileStorageService();
