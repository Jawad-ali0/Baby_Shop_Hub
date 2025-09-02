import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class Review {
  final String id;
  final String productId;
  final String userId;
  final String userName;
  final String userEmail;
  final double rating;
  final String comment;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isVerified;

  Review({
    required this.id,
    required this.productId,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.rating,
    required this.comment,
    required this.createdAt,
    required this.updatedAt,
    this.isVerified = false,
  });

  factory Review.fromJson(Map<String, dynamic> json) => Review(
    id: json['id'] as String,
    productId: json['productId'] as String,
    userId: json['userId'] as String,
    userName: json['userName'] as String,
    userEmail: json['userEmail'] as String,
    rating: (json['rating'] as num).toDouble(),
    comment: json['comment'] as String,
    createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(json['updatedAt'] as int),
    isVerified: json['isVerified'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'productId': productId,
    'userId': userId,
    'userName': userName,
    'userEmail': userEmail,
    'rating': rating,
    'comment': comment,
    'createdAt': createdAt.millisecondsSinceEpoch,
    'updatedAt': updatedAt.millisecondsSinceEpoch,
    'isVerified': isVerified,
  };

  Review copyWith({
    String? id,
    String? productId,
    String? userId,
    String? userName,
    String? userEmail,
    double? rating,
    String? comment,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isVerified,
  }) => Review(
    id: id ?? this.id,
    productId: productId ?? this.productId,
    userId: userId ?? this.userId,
    userName: userName ?? this.userName,
    userEmail: userEmail ?? this.userEmail,
    rating: rating ?? this.rating,
    comment: comment ?? this.comment,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    isVerified: isVerified ?? this.isVerified,
  );
}

class ReviewService extends ChangeNotifier {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  List<Review> _reviews = [];
  bool _isLoading = false;
  String? _error;

  List<Review> get reviews => _reviews;
  bool get isLoading => _isLoading;
  String? get error => _error;

  StreamSubscription<DatabaseEvent>? _reviewsSubscription;

  void initialize() {
    _loadReviews();
  }

  void _loadReviews() {
    _isLoading = true;
    _error = null;
    notifyListeners();

    _reviewsSubscription = _db
        .child('reviews')
        .onValue
        .listen(
          (event) {
            _isLoading = false;
            final data = event.snapshot.value as Map<dynamic, dynamic>?;

            if (data != null) {
              _reviews = data.entries
                  .map(
                    (entry) => Review.fromJson(
                      Map<String, dynamic>.from(entry.value as Map),
                    ),
                  )
                  .toList();
              // Sort by creation date, newest first
              _reviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            } else {
              _reviews = [];
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

  Future<void> addReview({
    required String productId,
    required String userId,
    required String userName,
    required String userEmail,
    required double rating,
    required String comment,
  }) async {
    try {
      final reviewId = _db.child('reviews').push().key!;
      final now = DateTime.now();

      final review = Review(
        id: reviewId,
        productId: productId,
        userId: userId,
        userName: userName,
        userEmail: userEmail,
        rating: rating,
        comment: comment,
        createdAt: now,
        updatedAt: now,
      );

      await _db.child('reviews').child(reviewId).set(review.toJson());

      // Update product rating
      await _updateProductRating(productId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateReview(
    String reviewId, {
    double? rating,
    String? comment,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      };

      if (rating != null) updates['rating'] = rating;
      if (comment != null) updates['comment'] = comment;

      await _db.child('reviews').child(reviewId).update(updates);

      // Update product rating if rating changed
      if (rating != null) {
        final review = _reviews.firstWhere((r) => r.id == reviewId);
        await _updateProductRating(review.productId);
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteReview(String reviewId) async {
    try {
      final review = _reviews.firstWhere((r) => r.id == reviewId);
      await _db.child('reviews').child(reviewId).remove();

      // Update product rating
      await _updateProductRating(review.productId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> _updateProductRating(String productId) async {
    try {
      final productReviews = _reviews
          .where((r) => r.productId == productId)
          .toList();

      if (productReviews.isNotEmpty) {
        final averageRating =
            productReviews.fold(0.0, (sum, review) => sum + review.rating) /
            productReviews.length;
        final reviewCount = productReviews.length;

        final updates = <String, dynamic>{
          'rating': averageRating,
          'reviewCount': reviewCount,
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
        };

        // Ensure no null values are sent to Firebase
        updates.removeWhere((key, value) => value == null);

        await _db.child('products').child(productId).update(updates);
      }
    } catch (e) {
      // Handle error silently for product rating update
      print('Error updating product rating: $e');
    }
  }

  List<Review> getReviewsForProduct(String productId) {
    return _reviews.where((review) => review.productId == productId).toList();
  }

  List<Review> getReviewsByUser(String userId) {
    return _reviews.where((review) => review.userId == userId).toList();
  }

  Review? getReviewById(String reviewId) {
    try {
      return _reviews.firstWhere((review) => review.id == reviewId);
    } catch (e) {
      return null;
    }
  }

  bool hasUserReviewedProduct(String userId, String productId) {
    return _reviews.any(
      (review) => review.userId == userId && review.productId == productId,
    );
  }

  double getAverageRatingForProduct(String productId) {
    final productReviews = getReviewsForProduct(productId);
    if (productReviews.isEmpty) return 0.0;

    return productReviews.fold(0.0, (sum, review) => sum + review.rating) /
        productReviews.length;
  }

  int getReviewCountForProduct(String productId) {
    return getReviewsForProduct(productId).length;
  }

  // Additional methods for product detail screen
  void listenForProduct(String productId) {
    // This method can be used to listen for reviews of a specific product
    // For now, we'll just initialize the service
    initialize();
  }

  List<Review> getReviewsFor(String productId) {
    return getReviewsForProduct(productId);
  }

  Future<void> submitReview({
    required String productId,
    required String userId,
    required String userName,
    required String userEmail,
    required double rating,
    required String comment,
  }) async {
    return addReview(
      productId: productId,
      userId: userId,
      userName: userName,
      userEmail: userEmail,
      rating: rating,
      comment: comment,
    );
  }

  @override
  void dispose() {
    _reviewsSubscription?.cancel();
    super.dispose();
  }
}
