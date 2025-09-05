import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/order.dart';

class OrderService extends ChangeNotifier {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  List<OrderModel> _orders = [];
  bool _isLoading = false;
  String? _error;

  List<OrderModel> get orders => _orders;
  bool get isLoading => _isLoading;
  String? get error => _error;

  StreamSubscription<DatabaseEvent>? _ordersSubscription;
  String? _currentUserId;

  void initialize(String userId) {
    _currentUserId = userId;
    _loadOrders();
  }

  void _loadOrders() {
    if (_currentUserId == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    _ordersSubscription = _db
        .child('orders')
        .orderByChild('userId')
        .equalTo(_currentUserId)
        .onValue
        .listen(
          (event) {
            _isLoading = false;
            final data = event.snapshot.value as Map<dynamic, dynamic>?;

            if (data != null) {
              _orders = data.entries
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
                        debugPrint(
                          'Warning: Order data is not a Map: ${entry.value}',
                        );
                        return null;
                      }
                    } catch (e) {
                      debugPrint('Error parsing order ${entry.key}: $e');
                      return null;
                    }
                  })
                  .where((order) => order != null)
                  .cast<OrderModel>()
                  .toList();
              // Sort by creation date, newest first
              _orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            } else {
              _orders = [];
            }

            notifyListeners();
          },
          onError: (error) {
            _isLoading = false;
            _error = error.toString();
            notifyListeners();
          },
        );
  }

  Future<String> createOrder({
    required String userId,
    required String userEmail,
    required String userName,
    required List<OrderItem> items,
    required String shippingAddress,
    required String billingAddress,
    required String paymentMethod,
    String? notes,
  }) async {
    try {
      final orderId = _db.child('orders').push().key!;
      final now = DateTime.now();

      final subtotal = items.fold(0.0, (sum, item) => sum + item.total);
      final tax = subtotal * 0.08; // 8% tax
      final shipping = subtotal > 50 ? 0.0 : 9.99; // Free shipping over $50
      final total = subtotal + tax + shipping;

      final order = OrderModel(
        id: orderId,
        userId: userId,
        userEmail: userEmail,
        userName: userName,
        items: items,
        subtotal: subtotal,
        tax: tax,
        shipping: shipping,
        total: total,
        status: OrderStatus.pending,
        paymentStatus: PaymentStatus.pending,
        shippingAddress: shippingAddress,
        billingAddress: billingAddress,
        paymentMethod: paymentMethod,
        createdAt: now,
        updatedAt: now,
        notes: notes,
      );

      await _db.child('orders').child(orderId).set(order.toJson());
      return orderId;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    try {
      final updates = <String, dynamic>{
        'status': status.name,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      };

      // Ensure no null values are sent to Firebase
      updates.removeWhere((key, value) => value == null);

      await _db.child('orders').child(orderId).update(updates);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updatePaymentStatus(String orderId, PaymentStatus status) async {
    try {
      final updates = <String, dynamic>{
        'paymentStatus': status.name,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      };

      // Ensure no null values are sent to Firebase
      updates.removeWhere((key, value) => value == null);

      await _db.child('orders').child(orderId).update(updates);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> addTrackingNumber(String orderId, String trackingNumber) async {
    try {
      final updates = <String, dynamic>{
        'trackingNumber': trackingNumber,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      };

      // Ensure no null values are sent to Firebase
      updates.removeWhere((key, value) => value == null);

      await _db.child('orders').child(orderId).update(updates);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  OrderModel? getOrderById(String orderId) {
    try {
      return _orders.firstWhere((order) => order.id == orderId);
    } catch (e) {
      return null;
    }
  }

  List<OrderModel> getOrdersByStatus(OrderStatus status) {
    return _orders.where((order) => order.status == status).toList();
  }

  List<OrderModel> getRecentOrders({int limit = 5}) {
    return _orders.take(limit).toList();
  }

  // Admin functions
  Future<void> loadAllOrders() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _ordersSubscription?.cancel();
      _ordersSubscription = _db
          .child('orders')
          .onValue
          .listen(
            (event) {
              _isLoading = false;
              final data = event.snapshot.value as Map<dynamic, dynamic>?;

              if (data != null) {
                _orders = data.entries
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
                          debugPrint(
                            'Warning: Order data is not a Map: ${entry.value}',
                          );
                          return null;
                        }
                      } catch (e) {
                        debugPrint('Error parsing order ${entry.key}: $e');
                        return null;
                      }
                    })
                    .where((order) => order != null)
                    .cast<OrderModel>()
                    .toList();
                // Sort by creation date, newest first
                _orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
              } else {
                _orders = [];
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
    _ordersSubscription?.cancel();
    super.dispose();
  }
}
