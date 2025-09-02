import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/product.dart';

class CartItem {
  final String productId;
  final String productName;
  final String productImage;
  final double price;
  int quantity;

  CartItem({
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.price,
    this.quantity = 1,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
    productId: json['productId'] as String,
    productName: json['productName'] as String,
    productImage: json['productImage'] as String,
    price: (json['price'] as num).toDouble(),
    quantity: json['quantity'] as int,
  );

  Map<String, dynamic> toJson() => {
    'productId': productId,
    'productName': productName,
    'productImage': productImage,
    'price': price,
    'quantity': quantity,
  };

  CartItem copyWith({
    String? productId,
    String? productName,
    String? productImage,
    double? price,
    int? quantity,
  }) => CartItem(
    productId: productId ?? this.productId,
    productName: productName ?? this.productName,
    productImage: productImage ?? this.productImage,
    price: price ?? this.price,
    quantity: quantity ?? this.quantity,
  );

  double get total => price * quantity;
  String get formattedPrice => '\$${price.toStringAsFixed(2)}';
  String get formattedTotal => '\$${total.toStringAsFixed(2)}';
}

class CartService extends ChangeNotifier {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  List<CartItem> _items = [];
  bool _isLoading = false;
  String? _error;

  List<CartItem> get items => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);
  double get totalAmount => _items.fold(0.0, (sum, item) => sum + item.total);
  String get formattedTotalAmount => '\$${totalAmount.toStringAsFixed(2)}';
  bool get isEmpty => _items.isEmpty;

  StreamSubscription<DatabaseEvent>? _cartSubscription;
  String? _currentUserId;

  void initialize(String userId) {
    print('🚀 CartService: Initializing with user ID: $userId');
    _currentUserId = userId;
    if (userId.isNotEmpty) {
      print('✅ CartService: User ID set, loading cart...');
      _loadCart();
    } else {
      print('❌ CartService: Empty user ID, clearing cart');
      _items = [];
      _isLoading = false;
      _error = null;
      notifyListeners();
    }
  }

  void _loadCart() {
    print('🔄 CartService: Loading cart for user: $_currentUserId');

    if (_currentUserId == null) {
      print('❌ CartService: No user ID, cannot load cart');
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    print(
      '📡 CartService: Setting up Firebase listener for path: carts/$_currentUserId',
    );
    _cartSubscription = _db
        .child('carts')
        .child(_currentUserId!)
        .onValue
        .listen(
          (event) {
            print('📡 CartService: Received Firebase event: ${event.type}');
            _isLoading = false;
            final data = event.snapshot.value as Map<dynamic, dynamic>?;

            if (data != null) {
              print('📦 CartService: Cart data received: ${data.length} items');
              _items = data.entries
                  .map(
                    (entry) => CartItem.fromJson(
                      Map<String, dynamic>.from(entry.value as Map),
                    ),
                  )
                  .toList();
              print('✅ CartService: Cart loaded with ${_items.length} items');
            } else {
              print('📭 CartService: No cart data found, cart is empty');
              _items = [];
            }

            notifyListeners();
          },
          onError: (error) {
            print('❌ CartService: Error loading cart: $error');
            _isLoading = false;
            _error = error.toString();
            notifyListeners();
          },
        );
  }

  Future<void> addToCart(Product product, {int quantity = 1}) async {
    print('🛒 CartService: Adding product to cart: ${product.name}');
    print('🛒 CartService: Current user ID: $_currentUserId');

    if (_currentUserId == null) {
      print('❌ CartService: No user ID, cannot add to cart');
      return;
    }

    try {
      final existingItemIndex = _items.indexWhere(
        (item) => item.productId == product.id,
      );

      if (existingItemIndex != -1) {
        // Update existing item
        print('🔄 CartService: Updating existing item quantity');
        final existingItem = _items[existingItemIndex];
        final newQuantity = existingItem.quantity + quantity;
        await _updateCartItem(product.id, newQuantity);
      } else {
        // Add new item
        print('➕ CartService: Adding new item to cart');
        final cartItem = CartItem(
          productId: product.id,
          productName: product.name,
          productImage: product.imageUrl,
          price: product.price,
          quantity: quantity,
        );

        print(
          '💾 CartService: Saving to Firebase at path: carts/$_currentUserId/${product.id}',
        );

        // Ensure no null values are sent to Firebase
        final cartItemData = cartItem.toJson();
        cartItemData.removeWhere((key, value) => value == null);

        await _db
            .child('carts')
            .child(_currentUserId!)
            .child(product.id)
            .set(cartItemData);
        print('✅ CartService: Product saved to Firebase successfully');
      }
    } catch (e) {
      print('❌ CartService: Error adding to cart: $e');
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> removeFromCart(String productId) async {
    if (_currentUserId == null) return;

    try {
      await _db.child('carts').child(_currentUserId!).child(productId).remove();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateQuantity(String productId, int quantity) async {
    if (_currentUserId == null) return;

    if (quantity <= 0) {
      await removeFromCart(productId);
    } else {
      await _updateCartItem(productId, quantity);
    }
  }

  Future<void> _updateCartItem(String productId, int quantity) async {
    if (_currentUserId == null) return;

    try {
      final updates = <String, dynamic>{'quantity': quantity};

      // Ensure no null values are sent to Firebase
      updates.removeWhere((key, value) => value == null);

      await _db
          .child('carts')
          .child(_currentUserId!)
          .child(productId)
          .update(updates);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> clearCart() async {
    if (_currentUserId == null) return;

    try {
      await _db.child('carts').child(_currentUserId!).remove();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  CartItem? getCartItem(String productId) {
    try {
      return _items.firstWhere((item) => item.productId == productId);
    } catch (e) {
      return null;
    }
  }

  bool isInCart(String productId) {
    return _items.any((item) => item.productId == productId);
  }

  int getProductQuantity(String productId) {
    final item = getCartItem(productId);
    return item?.quantity ?? 0;
  }

  Future<void> incrementQuantity(String productId) async {
    final currentQuantity = getProductQuantity(productId);
    await updateQuantity(productId, currentQuantity + 1);
  }

  Future<void> decrementQuantity(String productId) async {
    final currentQuantity = getProductQuantity(productId);
    await updateQuantity(productId, currentQuantity - 1);
  }

  @override
  void dispose() {
    _cartSubscription?.cancel();
    super.dispose();
  }
}
