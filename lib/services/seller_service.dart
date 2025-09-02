import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/product.dart';
import '../models/order.dart';

class Seller {
  final String id;
  final String name;
  final String email;
  final String businessName;
  final String businessAddress;
  final String phoneNumber;
  final String businessLicense;
  final bool isVerified;
  final double rating;
  final int totalSales;
  final DateTime createdAt;
  final DateTime updatedAt;

  Seller({
    required this.id,
    required this.name,
    required this.email,
    required this.businessName,
    required this.businessAddress,
    required this.phoneNumber,
    required this.businessLicense,
    this.isVerified = false,
    this.rating = 0.0,
    this.totalSales = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Seller.fromJson(Map<String, dynamic> json) => Seller(
    id: json['id'] as String,
    name: json['name'] as String,
    email: json['email'] as String,
    businessName: json['businessName'] as String,
    businessAddress: json['businessAddress'] as String,
    phoneNumber: json['phoneNumber'] as String,
    businessLicense: json['businessLicense'] as String,
    isVerified: json['isVerified'] as bool? ?? false,
    rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
    totalSales: json['totalSales'] as int? ?? 0,
    createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(json['updatedAt'] as int),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'businessName': businessName,
    'businessAddress': businessAddress,
    'phoneNumber': phoneNumber,
    'businessLicense': businessLicense,
    'isVerified': isVerified,
    'rating': rating,
    'totalSales': totalSales,
    'createdAt': createdAt.millisecondsSinceEpoch,
    'updatedAt': updatedAt.millisecondsSinceEpoch,
  };

  Seller copyWith({
    String? id,
    String? name,
    String? email,
    String? businessName,
    String? businessAddress,
    String? phoneNumber,
    String? businessLicense,
    bool? isVerified,
    double? rating,
    int? totalSales,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Seller(
    id: id ?? this.id,
    name: name ?? this.name,
    email: email ?? this.email,
    businessName: businessName ?? this.businessName,
    businessAddress: businessAddress ?? this.businessAddress,
    phoneNumber: phoneNumber ?? this.phoneNumber,
    businessLicense: businessLicense ?? this.businessLicense,
    isVerified: isVerified ?? this.isVerified,
    rating: rating ?? this.rating,
    totalSales: totalSales ?? this.totalSales,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}

class SellerService extends ChangeNotifier {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  List<Seller> _sellers = [];
  List<Product> _sellerProducts = [];
  List<OrderModel> _sellerOrders = [];
  bool _isLoading = false;
  String? _error;

  List<Seller> get sellers => _sellers;
  List<Product> get sellerProducts => _sellerProducts;
  List<OrderModel> get sellerOrders => _sellerOrders;
  bool get isLoading => _isLoading;
  String? get error => _error;

  StreamSubscription<DatabaseEvent>? _sellersSubscription;
  StreamSubscription<DatabaseEvent>? _productsSubscription;
  StreamSubscription<DatabaseEvent>? _ordersSubscription;
  String? _currentSellerId;

  void initialize(String sellerId) {
    _currentSellerId = sellerId;
    _loadSellerData();
  }

  void _loadSellerData() {
    if (_currentSellerId == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    // Load seller products
    _productsSubscription = _db
        .child('products')
        .orderByChild('sellerId')
        .equalTo(_currentSellerId)
        .onValue
        .listen(
          (event) {
            final data = event.snapshot.value as Map<dynamic, dynamic>?;

            if (data != null) {
              _sellerProducts = data.entries
                  .map(
                    (entry) => Product.fromJson(
                      Map<String, dynamic>.from(entry.value as Map),
                    ),
                  )
                  .where((product) => product.isActive)
                  .toList();
            } else {
              _sellerProducts = [];
            }

            notifyListeners();
          },
          onError: (error) {
            _error = error.toString();
            notifyListeners();
          },
        );

    // Load seller orders
    _ordersSubscription = _db
        .child('orders')
        .onValue
        .listen(
          (event) {
            final data = event.snapshot.value as Map<dynamic, dynamic>?;

            if (data != null) {
              _sellerOrders = data.entries
                  .map((entry) {
                    try {
                      // Ensure the entry value is a Map and contains order data
                      if (entry.value is Map) {
                        final orderData = Map<String, dynamic>.from(
                          entry.value as Map,
                        );
                        // Add the order ID from the key if it's not in the data
                        if (!orderData.containsKey('id')) {
                          orderData['id'] = entry.key;
                        }
                        return OrderModel.fromJson(orderData);
                      } else {
                        print(
                          'Warning: Order data is not a Map: ${entry.value}',
                        );
                        return null;
                      }
                    } catch (e) {
                      print('Error parsing order ${entry.key}: $e');
                      return null;
                    }
                  })
                  .where((order) => order != null)
                  .cast<OrderModel>()
                  .where(
                    (order) => order.items.any(
                      (item) => _sellerProducts.any(
                        (product) => product.id == item.productId,
                      ),
                    ),
                  )
                  .toList();
              // Sort by creation date, newest first
              _sellerOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            } else {
              _sellerOrders = [];
            }

            _isLoading = false;
            notifyListeners();
          },
          onError: (error) {
            _isLoading = false;
            _error = error.toString();
            notifyListeners();
          },
        );
  }

  Future<void> registerSeller({
    required String userId,
    required String name,
    required String email,
    required String businessName,
    required String businessAddress,
    required String phoneNumber,
    required String businessLicense,
  }) async {
    try {
      final now = DateTime.now();

      final seller = Seller(
        id: userId,
        name: name,
        email: email,
        businessName: businessName,
        businessAddress: businessAddress,
        phoneNumber: phoneNumber,
        businessLicense: businessLicense,
        createdAt: now,
        updatedAt: now,
      );

      await _db.child('sellers').child(userId).set(seller.toJson());
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateSellerProfile({
    required String sellerId,
    String? name,
    String? email,
    String? businessName,
    String? businessAddress,
    String? phoneNumber,
    String? businessLicense,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      };

      if (name != null) updates['name'] = name;
      if (email != null) updates['email'] = email;
      if (businessName != null) updates['businessName'] = businessName;
      if (businessAddress != null) updates['businessAddress'] = businessAddress;
      if (phoneNumber != null) updates['phoneNumber'] = phoneNumber;
      if (businessLicense != null) updates['businessLicense'] = businessLicense;

      await _db.child('sellers').child(sellerId).update(updates);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> verifySeller(String sellerId) async {
    try {
      final updates = <String, dynamic>{
        'isVerified': true,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      };

      // Ensure no null values are sent to Firebase
      updates.removeWhere((key, value) => value == null);

      await _db.child('sellers').child(sellerId).update(updates);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Seller? getSellerById(String sellerId) {
    try {
      return _sellers.firstWhere((seller) => seller.id == sellerId);
    } catch (e) {
      return null;
    }
  }

  List<Product> getProductsBySeller(String sellerId) {
    return _sellerProducts
        .where((product) => product.sellerId == sellerId)
        .toList();
  }

  List<OrderModel> getOrdersBySeller(String sellerId) {
    return _sellerOrders
        .where(
          (order) => order.items.any(
            (item) => _sellerProducts.any(
              (product) =>
                  product.id == item.productId && product.sellerId == sellerId,
            ),
          ),
        )
        .toList();
  }

  double getTotalSales(String sellerId) {
    final sellerOrders = getOrdersBySeller(sellerId);
    return sellerOrders.fold(0.0, (sum, order) => sum + order.total);
  }

  int getTotalProductsSold(String sellerId) {
    final sellerOrders = getOrdersBySeller(sellerId);
    return sellerOrders.fold(
      0,
      (sum, order) =>
          sum +
          order.items
              .where(
                (item) => _sellerProducts.any(
                  (product) =>
                      product.id == item.productId &&
                      product.sellerId == sellerId,
                ),
              )
              .fold(0, (itemSum, item) => itemSum + item.quantity),
    );
  }

  // Admin functions
  Future<void> loadAllSellers() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _sellersSubscription?.cancel();
      _sellersSubscription = _db
          .child('sellers')
          .onValue
          .listen(
            (event) {
              _isLoading = false;
              final data = event.snapshot.value as Map<dynamic, dynamic>?;

              if (data != null) {
                _sellers = data.entries
                    .map(
                      (entry) => Seller.fromJson(
                        Map<String, dynamic>.from(entry.value as Map),
                      ),
                    )
                    .toList();
                // Sort by creation date, newest first
                _sellers.sort((a, b) => b.createdAt.compareTo(a.createdAt));
              } else {
                _sellers = [];
              }

              notifyListeners();
            },
            onError: (error) {
              _isLoading = false;
              _error = error.toString();
              notifyListeners();
            },
          );
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _sellersSubscription?.cancel();
    _productsSubscription?.cancel();
    _ordersSubscription?.cancel();
    super.dispose();
  }
}
