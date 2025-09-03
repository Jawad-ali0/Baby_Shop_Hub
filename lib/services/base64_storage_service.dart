import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_database/firebase_database.dart';
import 'package:image_picker/image_picker.dart';
import '../models/product.dart';

class Base64StorageService {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();
  final ImagePicker _picker = ImagePicker();

  /// Convert image file to Base64 string
  Future<String> imageToBase64(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final base64String = base64Encode(bytes);
      return 'data:image/jpeg;base64,$base64String';
    } catch (e) {
      throw Exception('Failed to convert image to Base64: $e');
    }
  }

  /// Pick image from gallery and convert to Base64
  Future<String?> pickImageAndConvertToBase64() async {
    try {
      if (kIsWeb) {
        // Web implementation - simplified approach using image_picker
        final XFile? image = await _picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 800,
          maxHeight: 800,
          imageQuality: 80,
        );

        if (image != null) {
          try {
            // For web, read bytes directly from XFile
            final bytes = await image.readAsBytes();
            final base64String = base64Encode(bytes);
            return 'data:image/jpeg;base64,$base64String';
          } catch (e) {
            // Fallback: try to get the path and convert
            if (image.path.isNotEmpty) {
              final base64String = base64Encode(await image.readAsBytes());
              return 'data:image/jpeg;base64,$base64String';
            } else {
              throw Exception('Unable to read image data on web platform');
            }
          }
        }
        return null;
      } else {
        // Mobile implementation
        final XFile? image = await _picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 800,
          maxHeight: 800,
          imageQuality: 80,
        );

        if (image != null) {
          final file = File(image.path);
          return await imageToBase64(file);
        }
        return null;
      }
    } catch (e) {
      throw Exception('Failed to pick and convert image: $e');
    }
  }

  /// Take photo with camera and convert to Base64
  Future<String?> takePhotoAndConvertToBase64() async {
    try {
      if (kIsWeb) {
        // Web implementation - camera might not be available
        throw Exception('Camera is not supported on web platform');
      } else {
        // Mobile implementation
        final XFile? image = await _picker.pickImage(
          source: ImageSource.camera,
          maxWidth: 800,
          maxHeight: 800,
          imageQuality: 80,
        );

        if (image != null) {
          final file = File(image.path);
          return await imageToBase64(file);
        }
        return null;
      }
    } catch (e) {
      throw Exception('Failed to take photo and convert: $e');
    }
  }

  /// Store product with Base64 image in Firebase
  Future<void> storeProductWithBase64Image({
    required String name,
    required String description,
    required double price,
    required String category,
    required int stock,
    required String base64Image,
    String? sellerId,
    String? sellerName,
  }) async {
    try {
      final productId = 'product_${DateTime.now().millisecondsSinceEpoch}';

      final product = Product(
        id: productId,
        name: name,
        description: description,
        price: price,
        imageUrl: base64Image, // Store Base64 as imageUrl
        category: category,
        stock: stock,
        rating: 0.0,
        reviewCount: 0,
        sellerId: sellerId ?? 'default_seller',
        sellerName: sellerName ?? 'Default Seller',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: true,
        tags: [],
        specifications: {},
      );

      // Ensure no null values are sent to Firebase
      final productData = product.toJson();
      productData.removeWhere((key, value) => value == null);

      await _db.child('products').child(productId).set(productData);
      print('✅ Product stored with Base64 image: $name');
    } catch (e) {
      throw Exception('Failed to store product: $e');
    }
  }

  /// Get all products from Firebase
  Future<List<Product>> getAllProducts() async {
    try {
      final snapshot = await _db.child('products').get();
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        return data.entries.map((entry) {
          return Product.fromJson(
            Map<String, dynamic>.from(entry.value as Map),
          );
        }).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to get products: $e');
    }
  }

  /// Delete product from Firebase
  Future<void> deleteProduct(String productId) async {
    try {
      await _db.child('products').child(productId).remove();
      print('✅ Product deleted: $productId');
    } catch (e) {
      throw Exception('Failed to delete product: $e');
    }
  }

  /// Update product in Firebase
  Future<void> updateProduct(Product product) async {
    try {
      final updatedProduct = product.copyWith(updatedAt: DateTime.now());
      await _db
          .child('products')
          .child(product.id)
          .set(updatedProduct.toJson());
      print('✅ Product updated: ${product.name}');
    } catch (e) {
      throw Exception('Failed to update product: $e');
    }
  }

  /// Check if Base64 string is valid image
  bool isValidBase64Image(String base64String) {
    try {
      if (!base64String.startsWith('data:image/')) return false;
      final base64Data = base64String.split(',')[1];
      base64Decode(base64Data);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get image info (size, format)
  Map<String, dynamic> getImageInfo(String base64String) {
    try {
      final base64Data = base64String.split(',')[1];
      final bytes = base64Decode(base64Data);

      return {
        'originalSizeMB': (bytes.length / (1024 * 1024)).toStringAsFixed(2),
        'base64SizeMB': (base64String.length / (1024 * 1024)).toStringAsFixed(
          2,
        ),
        'sizeIncreasePercent': ((base64String.length / bytes.length - 1) * 100)
            .toStringAsFixed(1),
        'base64SizeChars': base64String.length,
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// Simplified web image picker using image_picker with better error handling
  Future<String?> pickWebImageSimple() async {
    if (!kIsWeb) {
      throw Exception('This method is only available on web platform');
    }

    try {
      // Try to use image_picker with minimal options
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 400, // Smaller size for web
        maxHeight: 400,
        imageQuality: 70, // Lower quality for web
      );

      if (image != null) {
        try {
          // Try to read bytes directly
          final bytes = await image.readAsBytes();
          final base64String = base64Encode(bytes);
          return 'data:image/jpeg;base64,$base64String';
        } catch (e) {
          // If direct reading fails, try alternative approach
          print('Direct reading failed, trying alternative: $e');

          if (image.path.isNotEmpty) {
            final bytes = await image.readAsBytes();
            final base64String = base64Encode(bytes);
            return 'data:image/jpeg;base64,$base64String';
          } else {
            throw Exception('Unable to read image data from XFile');
          }
        }
      }
      return null;
    } catch (e) {
      throw Exception('Failed to pick web image (simple method): $e');
    }
  }
}
