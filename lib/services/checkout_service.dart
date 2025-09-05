import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/order.dart';
import '../models/user.dart';
import 'cart_service.dart';

class CheckoutService extends ChangeNotifier {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  bool _isProcessing = false;
  String? _error;
  String? _currentOrderId;
  Address? _selectedAddress;
  PaymentMethod? _selectedPaymentMethod;
  List<CartItem> _cartItems = [];
  bool _isCashOnDelivery = true;

  bool get isProcessing => _isProcessing;
  String? get error => _error;
  String? get currentOrderId => _currentOrderId;
  Address? get selectedAddress => _selectedAddress;
  PaymentMethod? get selectedPaymentMethod => _selectedPaymentMethod;
  List<CartItem> get cartItems => _cartItems;
  bool get isCashOnDelivery => _isCashOnDelivery;

  Future<String> processCheckout({
    required String userId,
    required String userEmail,
    required String userName,
    required List<CartItem> cartItems,
    required Address shippingAddress,
    required Address billingAddress,
    required PaymentMethod paymentMethod,
    String? notes,
  }) async {
    _isProcessing = true;
    _error = null;
    notifyListeners();

    try {
      // Convert cart items to order items
      final orderItems = cartItems
          .map(
            (cartItem) => OrderItem(
              productId: cartItem.productId,
              productName: cartItem.productName,
              productImage: cartItem.productImage,
              price: cartItem.price,
              quantity: cartItem.quantity,
              total: cartItem.total,
            ),
          )
          .toList();

      // Calculate totals
      final subtotal = cartItems.fold(0.0, (sum, item) => sum + item.total);
      final tax = subtotal * 0.05; // 5% tax (consistent with checkout screen)
      final shipping = subtotal > 1000
          ? 0.0
          : 100.0; // Free shipping over Rs. 1000, otherwise Rs. 100
      final total = subtotal + tax + shipping;

      // Create order
      final orderId = _db.child('orders').push().key!;
      final now = DateTime.now();

      final order = OrderModel(
        id: orderId,
        userId: userId,
        userEmail: userEmail,
        userName: userName,
        items: orderItems,
        subtotal: subtotal,
        tax: tax,
        shipping: shipping,
        total: total,
        status: OrderStatus.pending,
        paymentStatus: PaymentStatus.pending,
        shippingAddress: shippingAddress.fullAddress,
        billingAddress: billingAddress.fullAddress,
        paymentMethod:
            '${paymentMethod.type} ending in ${paymentMethod.lastFourDigits}',
        createdAt: now,
        updatedAt: now,
        notes: notes,
      );

      // Save order to database
      await _db.child('orders').child(orderId).set(order.toJson());

      // Process payment (simulated)
      await _processPayment(orderId, total, paymentMethod);

      // Update order status
      final orderUpdates = <String, dynamic>{
        'status': OrderStatus.confirmed.name,
        'paymentStatus': PaymentStatus.paid.name,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      };

      // Ensure no null values are sent to Firebase
      orderUpdates.removeWhere((key, value) => value == null);

      await _db.child('orders').child(orderId).update(orderUpdates);

      _currentOrderId = orderId;
      _isProcessing = false;
      notifyListeners();

      return orderId;
    } catch (e) {
      _isProcessing = false;
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> _processPayment(
    String orderId,
    double amount,
    PaymentMethod paymentMethod,
  ) async {
    // Simulate payment processing delay
    await Future.delayed(const Duration(seconds: 2));

    // In a real app, you would integrate with a payment processor like Stripe, PayPal, etc.
    // For now, we'll simulate a successful payment
    debugPrint(
      'Processing payment of \$${amount.toStringAsFixed(2)} with ${paymentMethod.type} ending in ${paymentMethod.lastFourDigits}',
    );
  }

  Future<void> cancelOrder(String orderId) async {
    try {
      final updates = <String, dynamic>{
        'status': OrderStatus.cancelled.name,
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

  Future<void> refundOrder(String orderId) async {
    try {
      final updates = <String, dynamic>{
        'paymentStatus': PaymentStatus.refunded.name,
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

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void setAddress(Address address) {
    _selectedAddress = address;
    notifyListeners();
  }

  void setPaymentMethod(PaymentMethod paymentMethod) {
    _selectedPaymentMethod = paymentMethod;
    _isCashOnDelivery = false;
    notifyListeners();
  }

  void setCashOnDelivery() {
    _isCashOnDelivery = true;
    _selectedPaymentMethod = null;
    notifyListeners();
  }

  void setCartItems(List<CartItem> items) {
    _cartItems = items;
    notifyListeners();
  }

  void reset() {
    _isProcessing = false;
    _error = null;
    _currentOrderId = null;
    _selectedAddress = null;
    _selectedPaymentMethod = null;
    _cartItems = [];
    _isCashOnDelivery = true;
    notifyListeners();
  }
}
