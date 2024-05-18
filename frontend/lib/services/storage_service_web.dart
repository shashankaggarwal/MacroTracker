// storage_service_web.dart
import 'dart:html' as html;
import 'storage_service.dart';

// The web implementation of StorageService
class WebStorageService implements StorageService {
  @override
  Future<void> write({required String key, required String value}) async {
    html.window.localStorage[key] = value;
  }

  @override
  Future<String?> read({required String key}) async {
    return html.window.localStorage[key];
  }

  @override
  Future<void> deleteAll() async {
    html.window.localStorage.clear();
  }
}

// The factory method that creates an instance of the web storage service
StorageService getStorageService() => WebStorageService();
