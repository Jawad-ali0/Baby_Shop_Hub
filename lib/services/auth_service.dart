import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import '../models/user.dart';
import 'cart_service.dart';
import 'order_service.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  User? _currentUser;
  UserModel? _userModel;
  StreamSubscription<User?>? _authStateSubscription;
  StreamSubscription<DatabaseEvent>? _profileSubscription;

  CartService? _cartService;
  OrderService? _orderService;

  User? get currentUser => _currentUser;
  UserModel? get userModel => _userModel;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _userModel == null && _currentUser != null;

  void initialize() {
    _authStateSubscription = _auth.authStateChanges().listen((User? user) {
      _currentUser = user;
      if (user != null) {
        _loadUserProfile(user.uid);
      } else {
        _userModel = null;
        _profileSubscription?.cancel();
      }
      notifyListeners();
    });
  }

  void setCartService(CartService cartService) {
    _cartService = cartService;
    if (_currentUser != null) {
      _cartService!.initialize(_currentUser!.uid);
    }
  }

  void setOrderService(OrderService orderService) {
    _orderService = orderService;
    if (_currentUser != null) {
      _orderService!.initialize(_currentUser!.uid);
    }
  }

  void _loadUserProfile(String userId) {
    _profileSubscription?.cancel();
    _profileSubscription = _db
        .child('users')
        .child(userId)
        .onValue
        .listen(
          (event) {
            if (event.snapshot.value != null) {
              try {
                final data = Map<String, dynamic>.from(
                  event.snapshot.value as Map,
                );
                _userModel = UserModel.fromJson(data);

                // Initialize connected services
                if (_cartService != null) {
                  _cartService!.initialize(userId);
                }
                if (_orderService != null) {
                  _orderService!.initialize(userId);
                }
              } catch (e) {
                print('Error parsing user profile: $e');
                _userModel = null;
              }
            } else {
              _userModel = null;
            }
            notifyListeners();
          },
          onError: (error) {
            print('Error loading user profile: $error');
            _userModel = null;
            notifyListeners();
          },
        );
  }

  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Create user profile in database
        final user = UserModel(
          uid: credential.user!.uid,
          name: name,
          email: email,
          role: 'user',
          addresses: [],
          paymentMethods: [],
          createdAt: DateTime.now().millisecondsSinceEpoch,
        );

        await _db.child('users').child(credential.user!.uid).set(user.toJson());
      }

      return credential;
    } catch (e) {
      rethrow;
    }
  }

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      _userModel = null;
      _currentUser = null;

      // Clear connected services
      if (_cartService != null) {
        _cartService!.clearCart();
      }
      if (_orderService != null) {
        _orderService!.dispose();
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateProfile({
    required String name,
    required List<Address> addresses,
    required List<PaymentMethod> paymentMethods,
  }) async {
    if (_currentUser == null || _userModel == null) return;

    try {
      final updates = <String, dynamic>{
        'name': name,
        'addresses': addresses.map((a) => a.toJson()).toList(),
        'paymentMethods': paymentMethods.map((p) => p.toJson()).toList(),
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      };

      // Ensure no null values are sent to Firebase
      updates.removeWhere((key, value) => value == null);

      await _db.child('users').child(_currentUser!.uid).update(updates);

      // Update local model
      _userModel = _userModel!.copyWith(
        name: name,
        addresses: addresses,
        paymentMethods: paymentMethods,
      );

      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateUserRole(String role) async {
    if (_currentUser == null || _userModel == null) return;

    try {
      final updates = <String, dynamic>{
        'role': role,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      };

      // Ensure no null values are sent to Firebase
      updates.removeWhere((key, value) => value == null);

      await _db.child('users').child(_currentUser!.uid).update(updates);

      // Update local model
      _userModel = _userModel!.copyWith(role: role);

      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  // Address management methods
  Future<void> addAddress(Address address) async {
    if (_currentUser == null || _userModel == null) return;

    try {
      final addresses = List<Address>.from(_userModel!.addresses);
      addresses.add(address);

      await updateProfile(
        name: _userModel!.name,
        addresses: addresses,
        paymentMethods: _userModel!.paymentMethods,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> removeAddress(String addressId) async {
    if (_currentUser == null || _userModel == null) return;

    try {
      final addresses = _userModel!.addresses
          .where((a) => a.id != addressId)
          .toList();

      await updateProfile(
        name: _userModel!.name,
        addresses: addresses,
        paymentMethods: _userModel!.paymentMethods,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateAddress(Address address) async {
    if (_currentUser == null || _userModel == null) return;

    try {
      final addresses = _userModel!.addresses
          .map((a) => a.id == address.id ? address : a)
          .toList();

      await updateProfile(
        name: _userModel!.name,
        addresses: addresses,
        paymentMethods: _userModel!.paymentMethods,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Payment method management methods
  Future<void> addPaymentMethod(PaymentMethod paymentMethod) async {
    if (_currentUser == null || _userModel == null) return;

    try {
      final paymentMethods = List<PaymentMethod>.from(
        _userModel!.paymentMethods,
      );
      paymentMethods.add(paymentMethod);

      await updateProfile(
        name: _userModel!.name,
        addresses: _userModel!.addresses,
        paymentMethods: paymentMethods,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> removePaymentMethod(String paymentMethodId) async {
    if (_currentUser == null || _userModel == null) return;

    try {
      final paymentMethods = _userModel!.paymentMethods
          .where((p) => p.id != paymentMethodId)
          .toList();

      await updateProfile(
        name: _userModel!.name,
        addresses: _userModel!.addresses,
        paymentMethods: paymentMethods,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updatePaymentMethod(PaymentMethod paymentMethod) async {
    if (_currentUser == null || _userModel == null) return;

    try {
      final paymentMethods = _userModel!.paymentMethods
          .map((p) => p.id == paymentMethod.id ? paymentMethod : p)
          .toList();

      await updateProfile(
        name: _userModel!.name,
        addresses: _userModel!.addresses,
        paymentMethods: paymentMethods,
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    _profileSubscription?.cancel();
    super.dispose();
  }
}
