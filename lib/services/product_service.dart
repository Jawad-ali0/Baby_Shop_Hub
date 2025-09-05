import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/product.dart';

class ProductService extends ChangeNotifier {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  List<Product> _products = [];
  bool _isLoading = false;
  String? _error;

  List<Product> get products => _products;
  List<Product> get activeProducts =>
      _products.where((p) => p.isActive).toList();
  bool get isLoading => _isLoading;
  String? get error => _error;

  StreamSubscription<DatabaseEvent>? _productsSubscription;

  void initialize() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Clean up any corrupted products first
      await cleanupCorruptedProducts();

      // Ensure basic products exist
      await _ensureBasicProducts();

      // Load products from Firebase
      _loadProducts();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _ensureBasicProducts() async {
    try {
      final snapshot = await _db.child('products').get();
      if (snapshot.value == null || (snapshot.value as Map).isEmpty) {
        await _createBasicProducts();
      }
    } catch (e) {
      debugPrint('Error ensuring basic products: $e');
    }
  }

  Future<void> _createBasicProducts() async {
    final basicProducts = [
      {
        'id': 'basic_1',
        'name': 'Organic Cotton Onesie',
        'description':
            'Soft, breathable organic cotton onesie perfect for your little one.',
        'price': 15.99,
        'category': 'Clothing',
        'imageUrl':
            'data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iNDAwIiBoZWlnaHQ9IjQwMCIgdmlld0JveD0iMCAwIDQwMCA0MDAiIGZpbGw9Im5vbmUiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI+CjxyZWN0IHdpZHRoPSI0MDAiIGhlaWdodD0iNDAwIiBmaWxsPSIjRjNGNEY2Ii8+CjxjaXJjbGUgY3g9IjIwMCIgY3k9IjIwMCIgcj0iODAiIGZpbGw9IiM2MzY2RjEiLz4KPHN2ZyB4PSIxNjAiIHk9IjE2MCIgd2lkdGg9IjgwIiBoZWlnaHQ9IjgwIiB2aWV3Qm94PSIwIDAgMjQgMjQiIGZpbGw9Im5vbmUiPgo8cGF0aCBkPSJNMTIgMkM2LjQ4IDIgMiA2LjQ4IDIgMTJTNi40OCAyMiAxMiAyMlMyMiAxNy41MiAyMiAxMlMxNy41MiAyIDEyIDJaTTEzIDE3SDExVjE1SDEzVjE3Wk0xMyAxM0gxMVY3SDEzVjEzWiIgZmlsbD0id2hpdGUiLz4KPC9zdmc+Cjwvc3ZnPgo=',
        'stock': 50,
        'sellerId': 'admin',
        'sellerName': 'Baby Shop Hub',
        'tags': ['organic', 'cotton', 'onesie'],
        'specifications': {'size': '0-3M', 'material': '100% Organic Cotton'},
        'isActive': true,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      },
      {
        'id': 'basic_2',
        'name': 'Wooden Building Blocks',
        'description':
            'Safe, non-toxic wooden building blocks for early development.',
        'price': 24.99,
        'category': 'Toys',
        'imageUrl':
            'data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iNDAwIiBoZWlnaHQ9IjQwMCIgdmlld0JveD0iMCAwIDQwMCA0MDAiIGZpbGw9Im5vbmUiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI+CjxyZWN0IHdpZHRoPSI0MDAiIGhlaWdodD0iNDAwIiBmaWxsPSIjRjNGNEY2Ii8+CjxyZWN0IHg9IjEwMCIgeT0iMTAwIiB3aWR0aD0iMjAwIiBoZWlnaHQ9IjIwMCIgcng9IjIwIiBmaWxsPSIjMTBCOTgxIi8+CjxzdmcgeD0iMTUwIiB5PSIxNTAiIHdpZHRoPSIxMDAiIGhlaWdodD0iMTAwIiB2aWV3Qm94PSIwIDAgMjQgMjQiIGZpbGw9Im5vbmUiPgo8cGF0aCBkPSJNMTIgMkM2LjQ4IDIgMiA2LjQ4IDIgMTJTNi40OCAyMiAxMiAyMlMyMiAxNy41MiAyMiAxMlMxNy41MiAyIDEyIDJaTTEzIDE3SDExVjE1SDEzVjE3Wk0xMyAxM0gxMVY3SDEzVjEzWiIgZmlsbD0id2hpdGUiLz4KPC9zdmc+Cjwvc3ZnPgo=',
        'stock': 30,
        'sellerId': 'admin',
        'sellerName': 'Baby Shop Hub',
        'tags': ['wooden', 'blocks', 'educational'],
        'specifications': {'age': '12M+', 'material': 'Natural Wood'},
        'isActive': true,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      },
      {
        'id': 'basic_3',
        'name': 'Gentle Baby Shampoo',
        'description': 'Hypoallergenic baby shampoo with natural ingredients.',
        'price': 12.99,
        'category': 'Bath',
        'imageUrl':
            'data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iNDAwIiBoZWlnaHQ9IjQwMCIgdmlld0JveD0iMCAwIDQwMCA0MDAiIGZpbGw9Im5vbmUiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI+CjxyZWN0IHdpZHRoPSI0MDAiIGhlaWdodD0iNDAwIiBmaWxsPSIjRjNGNEY2Ii8+CjxjaXJjbGUgY3g9IjIwMCIgY3k9IjIwMCIgcj0iMTAwIiBmaWxsPSIjRjU5RTBCIi8+CjxzdmcgeD0iMTUwIiB5PSIxNTAiIHdpZHRoPSIxMDAiIGhlaWdodD0iMTAwIiB2aWV3Qm94PSIwIDAgMjQgMjQiIGZpbGw9Im5vbmUiPgo8cGF0aCBkPSJNMTIgMkM2LjQ4IDIgMiA2LjQ4IDIgMTJTNi40OCAyMiAxMiAyMlMyMiAxNy41MiAyMiAxMlMxNy41MiAyIDEyIDJaTTEzIDE3SDExVjE1SDEzVjE3Wk0xMyAxM0gxMVY3SDEzVjEzWiIgZmlsbD0id2hpdGUiLz4KPC9zdmc+Cjwvc3ZnPgo=',
        'stock': 40,
        'sellerId': 'admin',
        'sellerName': 'Baby Shop Hub',
        'tags': ['shampoo', 'gentle', 'natural'],
        'specifications': {'volume': '250ml', 'age': '0M+'},
        'isActive': true,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      },
      {
        'id': 'basic_4',
        'name': 'Premium Diapers',
        'description':
            'Ultra-absorbent diapers with soft, breathable material.',
        'price': 29.99,
        'category': 'Diapers',
        'imageUrl':
            'data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iNDAwIiBoZWlnaHQ9IjQwMCIgdmlld0JveD0iMCAwIDQwMCA0MDAiIGZpbGw9Im5vbmUiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI+CjxyZWN0IHdpZHRoPSI0MDAiIGhlaWdodD0iNDAwIiBmaWxsPSIjRjNGNEY2Ii8+CjxyZWN0IHg9IjEwMCIgeT0iMTAwIiB3aWR0aD0iMjAwIiBoZWlnaHQ9IjIwMCIgcng9IjMwIiBmaWxsPSIjRjU5RTBCIi8+CjxzdmcgeD0iMTUwIiB5PSIxNTAiIHdpZHRoPSIxMDAiIGhlaWdodD0iMTAwIiB2aWV3Qm94PSIwIDAgMjQgMjQiIGZpbGw9Im5vbmUiPgo8cGF0aCBkPSJNMTIgMkM2LjQ4IDIgMiA2LjQ4IDIgMTJTNi40OCAyMiAxMiAyMlMyMiAxNy41MiAyMiAxMlMxNy41MiAyIDEyIDJaTTEzIDE3SDExVjE1SDEzVjE3Wk0xMyAxM0gxMVY3SDEzVjEzWiIgZmlsbD0id2hpdGUiLz4KPC9zdmc+Cjwvc3ZnPgo=',
        'stock': 100,
        'sellerId': 'admin',
        'sellerName': 'Baby Shop Hub',
        'tags': ['diapers', 'premium', 'absorbent'],
        'specifications': {'size': '3-6M', 'count': '64 pieces'},
        'isActive': true,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      },
      {
        'id': 'basic_5',
        'name': 'Baby Food Starter Pack',
        'description': 'Organic baby food purees for introducing solid foods.',
        'price': 19.99,
        'category': 'Food',
        'imageUrl':
            'data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iNDAwIiBoZWlnaHQ9IjQwMCIgdmlld0JveD0iMCAwIDQwMCA0MDAiIGZpbGw9Im5vbmUiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI+CjxyZWN0IHdpZHRoPSI0MDAiIGhlaWdodD0iNDAwIiBmaWxsPSIjRjNGNEY2Ii8+CjxjaXJjbGUgY3g9IjIwMCIgY3k9IjIwMCIgcj0iMTAwIiBmaWxsPSIjRjU5RTBCIi8+CjxzdmcgeD0iMTUwIiB5PSIxNTAiIHdpZHRoPSIxMDAiIGhlaWdodD0iMTAwIiB2aWV3Qm94PSIwIDAgMjQgMjQiIGZpbGw9Im5vbmUiPgo8cGF0aCBkPSJNMTIgMkM2LjQ4IDIgMiA2LjQ4IDIgMTJTNi40OCAyMiAxMiAyMlMyMiAxNy41MiAyMiAxMlMxNy41MiAyIDEyIDJaTTEzIDE3SDExVjE1SDEzVjE3Wk0xMyAxM0gxMVY3SDEzVjEzWiIgZmlsbD0id2hpdGUiLz4KPC9zdmc+Cjwvc3ZnPgo=',
        'stock': 25,
        'sellerId': 'admin',
        'sellerName': 'Baby Shop Hub',
        'tags': ['organic', 'baby food', 'puree'],
        'specifications': {'age': '6M+', 'count': '12 jars'},
        'isActive': true,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      },
      {
        'id': 'basic_4',
        'name': 'Premium Baby Stroller',
        'description':
            'High-quality baby stroller with advanced safety features.',
        'price': 299.99,
        'category': 'Transport',
        'imageUrl':
            'data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iNDAwIiBoZWlnaHQ9IjQwMCIgdmlld0JveD0iMCAwIDQwMCA0MDAiIGZpbGw9Im5vbmUiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI+CjxyZWN0IHdpZHRoPSI0MDAiIGhlaWdodD0iNDAwIiBmaWxsPSIjRjNGNEY2Ii8+CjxyZWN0IHg9IjEwMCIgeT0iMTAwIiB3aWR0aD0iMjAwIiBoZWlnaHQ9IjIwMCIgcng9IjIwIiBmaWxsPSIjRjU5RTBCIi8+CjxzdmcgeD0iMTUwIiB5PSIxNTAiIHdpZHRoPSIxMDAiIGhlaWdodD0iMTAwIiB2aWV3Qm94PSIwIDAgMjQgMjQiIGZpbGw9Im5vbmUiPgo8cGF0aCBkPSJNMTIgMkM2LjQ4IDIgMiA2LjQ4IDIgMTJTNi40OCAyMiAxMiAyMlMyMiAxNy41MiAyMiAxMlMxNy41MiAyIDEyIDJaTTEzIDE3SDExVjE1SDEzVjE3Wk0xMyAxM0gxMVY3SDEzVjEzWiIgZmlsbD0id2hpdGUiLz4KPC9zdmc+Cjwvc3ZnPgo=',
        'stock': 0, // Out of stock product
        'sellerId': 'admin',
        'sellerName': 'Baby Shop Hub',
        'tags': ['stroller', 'premium', 'safety'],
        'specifications': {'age': '0-36M', 'weight': '15kg', 'foldable': 'Yes'},
        'isActive': true,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      },
    ];

    try {
      for (final productData in basicProducts) {
        await _db
            .child('products')
            .child(productData['id'] as String)
            .set(productData);
      }
      debugPrint('Basic products created successfully');
    } catch (e) {
      debugPrint('Error creating basic products: $e');
    }
  }

  void _loadProducts() {
    _productsSubscription?.cancel();
    _productsSubscription = _db
        .child('products')
        .onValue
        .listen(
          (event) {
            _isLoading = false;
            final data = event.snapshot.value as Map<dynamic, dynamic>?;

            if (data != null) {
              _products = data.entries
                  .map((entry) {
                    try {
                      final productData = Map<String, dynamic>.from(
                        entry.value as Map,
                      );
                      if (!productData.containsKey('id')) {
                        productData['id'] = entry.key;
                      }

                      // Validate required fields before parsing
                      if (productData['name'] == null ||
                          productData['name'].toString().isEmpty) {
                        debugPrint(
                          'Warning: Product ${entry.key} has null/empty name, skipping...',
                        );
                        return null;
                      }

                      return Product.fromJson(productData);
                    } catch (e) {
                      debugPrint('Error parsing product ${entry.key}: $e');
                      debugPrint('Product data: ${entry.value}');
                      return null;
                    }
                  })
                  .where((product) => product != null)
                  .cast<Product>()
                  .toList();

              // Sort by creation date, newest first
              _products.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            } else {
              _products = [];
            }

            _error = null;
            notifyListeners();
          },
          onError: (error) {
            _isLoading = false;
            _error = error.toString();
            notifyListeners();
          },
        );
  }

  Future<void> addProduct(Product product) async {
    try {
      final productId = _db.child('products').push().key!;
      final newProduct = product.copyWith(id: productId);

      // Ensure no null values are sent to Firebase
      final productData = newProduct.toJson();
      productData.removeWhere((key, value) => value == null);

      await _db.child('products').child(productId).set(productData);

      // Refresh products list
      _loadProducts();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateProduct(Product product) async {
    try {
      // Ensure no null values are sent to Firebase
      final productData = product.toJson();
      productData.removeWhere((key, value) => value == null);

      await _db.child('products').child(product.id).update(productData);

      // Refresh products list
      _loadProducts();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteProduct(String productId) async {
    try {
      await _db.child('products').child(productId).remove();

      // Refresh products list
      _loadProducts();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateProductStatus(String productId, bool isActive) async {
    try {
      await _db.child('products').child(productId).update({
        'isActive': isActive,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });

      // Refresh products list
      _loadProducts();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Clean up corrupted products and ensure data integrity
  Future<void> cleanupCorruptedProducts() async {
    try {
      final snapshot = await _db.child('products').get();
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        final corruptedProducts = <String>[];

        for (final entry in data.entries) {
          try {
            final productData = Map<String, dynamic>.from(entry.value as Map);

            // Check for required fields
            if (productData['name'] == null ||
                productData['name'].toString().isEmpty ||
                productData['price'] == null ||
                productData['category'] == null) {
              corruptedProducts.add(entry.key);
              debugPrint('Found corrupted product: ${entry.key} - ${entry.value}');
            }
          } catch (e) {
            corruptedProducts.add(entry.key);
            debugPrint('Error validating product ${entry.key}: $e');
          }
        }

        // Remove corrupted products
        for (final productId in corruptedProducts) {
          await _db.child('products').child(productId).remove();
          debugPrint('Removed corrupted product: $productId');
        }

        if (corruptedProducts.isNotEmpty) {
          debugPrint('Cleaned up ${corruptedProducts.length} corrupted products');
          // Refresh products list
          _loadProducts();
        }
      }
    } catch (e) {
      debugPrint('Error cleaning up corrupted products: $e');
    }
  }

  Product? getProductById(String productId) {
    try {
      return _products.firstWhere((product) => product.id == productId);
    } catch (e) {
      return null;
    }
  }

  List<Product> getProductsByCategory(String category) {
    return _products
        .where(
          (product) => product.category.toLowerCase() == category.toLowerCase(),
        )
        .toList();
  }

  List<Product> searchProducts(String query) {
    final lowercaseQuery = query.toLowerCase();
    return _products
        .where(
          (product) =>
              product.name.toLowerCase().contains(lowercaseQuery) ||
              product.description.toLowerCase().contains(lowercaseQuery) ||
              product.category.toLowerCase().contains(lowercaseQuery) ||
              product.tags.any(
                (tag) => tag.toLowerCase().contains(lowercaseQuery),
              ),
        )
        .toList();
  }

  /// Get detailed information about products and parsing status
  Map<String, dynamic> getProductStats() {
    try {
      _db.child('products').get();

      return {
        'totalProducts': _products.length,
        'activeProducts': _products.where((p) => p.isActive).length,
        'outOfStockProducts': _products.where((p) => p.stock <= 0).length,
        'base64Images': _products
            .where((p) => p.imageUrl.startsWith('data:image/'))
            .length,
        'networkImages': _products
            .where(
              (p) =>
                  !p.imageUrl.startsWith('data:image/') &&
                  p.imageUrl.isNotEmpty,
            )
            .length,
        'noImages': _products.where((p) => p.imageUrl.isEmpty).length,
        'lastError': _error,
        'isLoading': _isLoading,
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// Test product parsing and provide detailed debugging information
  Future<Map<String, dynamic>> testProductParsing() async {
    try {
      final snapshot = await _db.child('products').get();
      if (!snapshot.exists) return {'error': 'No products found in database'};

      final data = snapshot.value as Map<dynamic, dynamic>;
      final results = <String, dynamic>{};
      final errors = <String, String>{};
      final warnings = <String, String>{};

      for (final entry in data.entries) {
        try {
          final productData = Map<String, dynamic>.from(entry.value as Map);

          // Check for null/empty required fields
          if (productData['name'] == null ||
              productData['name'].toString().isEmpty) {
            warnings[entry.key] = 'Missing or empty name';
            continue;
          }

          if (productData['price'] == null) {
            warnings[entry.key] = 'Missing price';
            continue;
          }

          if (productData['category'] == null ||
              productData['category'].toString().isEmpty) {
            warnings[entry.key] = 'Missing or empty category';
            continue;
          }

          // Try to parse the product
          final product = Product.fromJson(productData);
          results[entry.key] = {
            'name': product.name,
            'price': product.price,
            'category': product.category,
            'stock': product.stock,
            'hasImage': product.imageUrl.isNotEmpty,
            'isBase64Image': product.imageUrl.startsWith('data:image/'),
          };
        } catch (e) {
          errors[entry.key] = e.toString();
        }
      }

      return {
        'success': true,
        'totalProducts': data.length,
        'successfullyParsed': results.length,
        'errors': errors,
        'warnings': warnings,
        'results': results,
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// Repair a specific product by providing default values for missing fields
  Future<bool> repairProduct(String productId) async {
    try {
      final snapshot = await _db.child('products').child(productId).get();
      if (!snapshot.exists) return false;

      final productData = Map<String, dynamic>.from(snapshot.value as Map);
      final repairedData = <String, dynamic>{};

      // Copy existing data
      repairedData.addAll(productData);

      // Fix missing required fields with defaults
      if (repairedData['name'] == null ||
          repairedData['name'].toString().isEmpty) {
        repairedData['name'] = 'Unnamed Product';
      }

      if (repairedData['description'] == null ||
          repairedData['description'].toString().isEmpty) {
        repairedData['description'] = 'No description available';
      }

      if (repairedData['price'] == null) {
        repairedData['price'] = 0.0;
      }

      if (repairedData['category'] == null ||
          repairedData['category'].toString().isEmpty) {
        repairedData['category'] = 'Uncategorized';
      }

      if (repairedData['stock'] == null) {
        repairedData['stock'] = 0;
      }

      if (repairedData['rating'] == null) {
        repairedData['rating'] = 0.0;
      }

      if (repairedData['reviewCount'] == null) {
        repairedData['reviewCount'] = 0;
      }

      if (repairedData['sellerId'] == null ||
          repairedData['sellerId'].toString().isEmpty) {
        repairedData['sellerId'] = 'unknown_seller';
      }

      if (repairedData['sellerName'] == null ||
          repairedData['sellerName'].toString().isEmpty) {
        repairedData['sellerName'] = 'Unknown Seller';
      }

      if (repairedData['createdAt'] == null) {
        repairedData['createdAt'] = DateTime.now().millisecondsSinceEpoch;
      }

      if (repairedData['updatedAt'] == null) {
        repairedData['updatedAt'] = DateTime.now().millisecondsSinceEpoch;
      }

      if (repairedData['isActive'] == null) {
        repairedData['isActive'] = true;
      }

      if (repairedData['tags'] == null) {
        repairedData['tags'] = [];
      }

      if (repairedData['specifications'] == null) {
        repairedData['specifications'] = {};
      }

      // Update the product in Firebase
      await _db.child('products').child(productId).set(repairedData);

      // Refresh products list
      _loadProducts();

      return true;
    } catch (e) {
      debugPrint('Error repairing product $productId: $e');
      return false;
    }
  }

  @override
  void dispose() {
    _productsSubscription?.cancel();
    super.dispose();
  }
}
