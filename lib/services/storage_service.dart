import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';

class StorageService extends ChangeNotifier {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  bool _isUploading = false;
  String? _error;

  bool get isUploading => _isUploading;
  String? get error => _error;

  Future<String> uploadImage({
    required File imageFile,
    required String path,
    String? fileName,
  }) async {
    try {
      _isUploading = true;
      _error = null;
      notifyListeners();

      final ref = _storage
          .ref()
          .child(path)
          .child(fileName ?? DateTime.now().millisecondsSinceEpoch.toString());
      final uploadTask = ref.putFile(imageFile);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      _isUploading = false;
      notifyListeners();

      return downloadUrl;
    } catch (e) {
      _isUploading = false;
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<String> uploadBase64Image({
    required String base64String,
    required String path,
    String? fileName,
  }) async {
    try {
      _isUploading = true;
      _error = null;
      notifyListeners();

      final bytes = base64Decode(base64String);
      final ref = _storage
          .ref()
          .child(path)
          .child(fileName ?? DateTime.now().millisecondsSinceEpoch.toString());
      final uploadTask = ref.putData(bytes);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      _isUploading = false;
      notifyListeners();

      return downloadUrl;
    } catch (e) {
      _isUploading = false;
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Image picker methods
  Future<File?> pickImageFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<File?> takePhotoWithCamera() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  // Product image upload method
  Future<String> uploadProductImage({
    required File imageFile,
    String? fileName,
  }) async {
    return uploadImage(
      imageFile: imageFile,
      path: 'product_images',
      fileName: fileName,
    );
  }

  // Storage availability check
  Future<bool> isStorageAvailable() async {
    try {
      // Try to access Firebase Storage
      await _storage.ref().listAll();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Test storage connection
  Future<bool> testStorageConnection() async {
    try {
      // Create a test reference and try to list
      final testRef = _storage.ref().child('test');
      await testRef.listAll();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Check storage health
  Future<Map<String, dynamic>> checkStorageHealth() async {
    try {
      final startTime = DateTime.now();

      // Test basic connectivity
      await _storage.ref().listAll();

      final endTime = DateTime.now();
      final responseTime = endTime.difference(startTime).inMilliseconds;

      return {
        'status': 'healthy',
        'responseTime': responseTime,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'status': 'unhealthy',
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  // Test Firebase connectivity
  Future<bool> testFirebaseConnectivity() async {
    try {
      // Test Firebase Storage connectivity
      await _storage.ref().listAll();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
