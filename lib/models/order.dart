enum OrderStatus {
  pending,
  confirmed,
  processing,
  shipped,
  delivered,
  cancelled,
  returned,
}

enum PaymentStatus { pending, paid, failed, refunded }

class OrderModel {
  final String id;
  final String userId;
  final String userEmail;
  final String userName;
  final List<OrderItem> items;
  final double subtotal;
  final double tax;
  final double shipping;
  final double total;
  final OrderStatus status;
  final PaymentStatus paymentStatus;
  final String shippingAddress;
  final String billingAddress;
  final String paymentMethod;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? trackingNumber;
  final String? notes;

  OrderModel({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.userName,
    required this.items,
    required this.subtotal,
    required this.tax,
    required this.shipping,
    required this.total,
    required this.status,
    required this.paymentStatus,
    required this.shippingAddress,
    required this.billingAddress,
    required this.paymentMethod,
    required this.createdAt,
    required this.updatedAt,
    this.trackingNumber,
    this.notes,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) => OrderModel(
    id: json['id'] as String,
    userId: json['userId'] as String,
    userEmail: json['userEmail'] as String,
    userName: json['userName'] as String,
    items: (json['items'] as List)
        .map((e) => OrderItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(),
    subtotal: (json['subtotal'] as num).toDouble(),
    tax: (json['tax'] as num).toDouble(),
    shipping: (json['shipping'] as num).toDouble(),
    total: (json['total'] as num).toDouble(),
    status: OrderStatus.values.firstWhere(
      (e) => e.name == json['status'],
      orElse: () => OrderStatus.pending,
    ),
    paymentStatus: PaymentStatus.values.firstWhere(
      (e) => e.name == json['paymentStatus'],
      orElse: () => PaymentStatus.pending,
    ),
    shippingAddress: json['shippingAddress'] as String,
    billingAddress: json['billingAddress'] as String,
    paymentMethod: json['paymentMethod'] as String,
    createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(json['updatedAt'] as int),
    trackingNumber: json['trackingNumber'] as String?,
    notes: json['notes'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'userEmail': userEmail,
    'userName': userName,
    'items': items.map((e) => e.toJson()).toList(),
    'subtotal': subtotal,
    'tax': tax,
    'shipping': shipping,
    'total': total,
    'status': status.name,
    'paymentStatus': paymentStatus.name,
    'shippingAddress': shippingAddress,
    'billingAddress': billingAddress,
    'paymentMethod': paymentMethod,
    'createdAt': createdAt.millisecondsSinceEpoch,
    'updatedAt': updatedAt.millisecondsSinceEpoch,
    'trackingNumber': trackingNumber,
    'notes': notes,
  };

  OrderModel copyWith({
    String? id,
    String? userId,
    String? userEmail,
    String? userName,
    List<OrderItem>? items,
    double? subtotal,
    double? tax,
    double? shipping,
    double? total,
    OrderStatus? status,
    PaymentStatus? paymentStatus,
    String? shippingAddress,
    String? billingAddress,
    String? paymentMethod,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? trackingNumber,
    String? notes,
  }) => OrderModel(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    userEmail: userEmail ?? this.userEmail,
    userName: userName ?? this.userName,
    items: items ?? this.items,
    subtotal: subtotal ?? this.subtotal,
    tax: tax ?? this.tax,
    shipping: shipping ?? this.shipping,
    total: total ?? this.total,
    status: status ?? this.status,
    paymentStatus: paymentStatus ?? this.paymentStatus,
    shippingAddress: shippingAddress ?? this.shippingAddress,
    billingAddress: billingAddress ?? this.billingAddress,
    paymentMethod: paymentMethod ?? this.paymentMethod,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    trackingNumber: trackingNumber ?? this.trackingNumber,
    notes: notes ?? this.notes,
  );

  String get formattedTotal => '\$${total.toStringAsFixed(2)}';
  String get formattedSubtotal => '\$${subtotal.toStringAsFixed(2)}';
  String get formattedTax => '\$${tax.toStringAsFixed(2)}';
  String get formattedShipping => '\$${shipping.toStringAsFixed(2)}';
  String get statusDisplayName => status.name.toUpperCase();
  String get paymentStatusDisplayName => paymentStatus.name.toUpperCase();
  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);
  double get totalAmount => total;
}

class OrderItem {
  final String productId;
  final String productName;
  final String productImage;
  final double price;
  final int quantity;
  final double total;

  OrderItem({
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.price,
    required this.quantity,
    required this.total,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
    productId: json['productId'] as String,
    productName: json['productName'] as String,
    productImage: json['productImage'] as String,
    price: (json['price'] as num).toDouble(),
    quantity: json['quantity'] as int,
    total: (json['total'] as num).toDouble(),
  );

  Map<String, dynamic> toJson() => {
    'productId': productId,
    'productName': productName,
    'productImage': productImage,
    'price': price,
    'quantity': quantity,
    'total': total,
  };

  OrderItem copyWith({
    String? productId,
    String? productName,
    String? productImage,
    double? price,
    int? quantity,
    double? total,
  }) => OrderItem(
    productId: productId ?? this.productId,
    productName: productName ?? this.productName,
    productImage: productImage ?? this.productImage,
    price: price ?? this.price,
    quantity: quantity ?? this.quantity,
    total: total ?? this.total,
  );

  String get formattedPrice => '\$${price.toStringAsFixed(2)}';
  String get formattedTotal => '\$${total.toStringAsFixed(2)}';
}
