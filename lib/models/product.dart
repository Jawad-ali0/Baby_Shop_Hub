class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final String category;
  final int stock;
  final double rating;
  final int reviewCount;
  final String sellerId;
  final String sellerName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final List<String> tags;
  final Map<String, dynamic> specifications;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.category,
    required this.stock,
    required this.rating,
    required this.reviewCount,
    required this.sellerId,
    required this.sellerName,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
    this.tags = const [],
    this.specifications = const {},
  });

  factory Product.fromJson(Map<String, dynamic> json) => Product(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    description: json['description'] as String? ?? '',
    price: (json['price'] as num?)?.toDouble() ?? 0.0,
    imageUrl: json['imageUrl'] as String? ?? '',
    category: json['category'] as String? ?? '',
    stock: json['stock'] as int? ?? 0,
    rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
    reviewCount: json['reviewCount'] as int? ?? 0,
    sellerId: json['sellerId'] as String? ?? '',
    sellerName: json['sellerName'] as String? ?? '',
    createdAt: json['createdAt'] is int
        ? DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int)
        : DateTime.now(),
    updatedAt: json['updatedAt'] is int
        ? DateTime.fromMillisecondsSinceEpoch(json['updatedAt'] as int)
        : DateTime.now(),
    isActive: json['isActive'] as bool? ?? true,
    tags: (json['tags'] as List?)?.cast<String>() ?? [],
    specifications: Map<String, dynamic>.from(
      json['specifications'] as Map? ?? {},
    ),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'price': price,
    'imageUrl': imageUrl,
    'category': category,
    'stock': stock,
    'rating': rating,
    'reviewCount': reviewCount,
    'sellerId': sellerId,
    'sellerName': sellerName,
    'createdAt': createdAt.millisecondsSinceEpoch,
    'updatedAt': updatedAt.millisecondsSinceEpoch,
    'isActive': isActive,
    'tags': tags,
    'specifications': specifications,
  };

  Product copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    String? imageUrl,
    String? category,
    int? stock,
    double? rating,
    int? reviewCount,
    String? sellerId,
    String? sellerName,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    List<String>? tags,
    Map<String, dynamic>? specifications,
  }) => Product(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description ?? this.description,
    price: price ?? this.price,
    imageUrl: imageUrl ?? this.imageUrl,
    category: category ?? this.category,
    stock: stock ?? this.stock,
    rating: rating ?? this.rating,
    reviewCount: reviewCount ?? this.reviewCount,
    sellerId: sellerId ?? this.sellerId,
    sellerName: sellerName ?? this.sellerName,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    isActive: isActive ?? this.isActive,
    tags: tags ?? this.tags,
    specifications: specifications ?? this.specifications,
  );

  String get formattedPrice => '\$${price.toStringAsFixed(2)}';
  String get stockStatus => stock > 0 ? 'In Stock' : 'Out of Stock';
  bool get isInStock => stock > 0;
  double get averageRating => rating;
}
