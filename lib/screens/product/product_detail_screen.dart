import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/product.dart';
import '../../services/cart_service.dart';
import '../../services/auth_service.dart';
import '../../services/review_service.dart';
import '../../routes/app_router.dart';
import '../../widgets/base64_image_widget.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;
  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _selectedQuantity = 1;
  double _userRating = 0.0;
  final TextEditingController _reviewController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final reviewService = context.read<ReviewService?>();
      reviewService?.listenForProduct(widget.product.id);
    });
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          widget.product.name,
          style: const TextStyle(
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_border, color: Color(0xFF6366F1)),
            onPressed: () {
              // TODO: Implement wishlist functionality
            },
          ),
          IconButton(
            icon: const Icon(Icons.share, color: Color(0xFF6366F1)),
            onPressed: () {
              // TODO: Implement share functionality
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            SizedBox(
              height: 300,
              width: double.infinity,
              child: _buildProductImage(),
            ),

            // Product Info
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Name and Price
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.product.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ),
                      Text(
                        'Rs. ${widget.product.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Rating and Reviews
                  Row(
                    children: [
                      ...List.generate(5, (index) {
                        final starIndex = index + 1;
                        final isFull = widget.product.rating >= starIndex;
                        final isHalf =
                            !isFull &&
                            widget.product.rating >= (starIndex - 0.5);
                        return Padding(
                          padding: const EdgeInsets.only(right: 2),
                          child: Icon(
                            isFull
                                ? Icons.star
                                : (isHalf
                                      ? Icons.star_half
                                      : Icons.star_border),
                            color: Colors.amber[600],
                            size: 20,
                          ),
                        );
                      }),
                      const SizedBox(width: 8),
                      Text(
                        widget.product.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '(${widget.product.reviewCount} reviews)',
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Description
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.product.description,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF64748B),
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Category and Stock
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.category,
                                size: 16,
                                color: Color(0xFF6366F1),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                widget.product.category,
                                style: const TextStyle(
                                  color: Color(0xFF6366F1),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: widget.product.stock > 0
                              ? const Color(0xFFD1FAE5)
                              : const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.inventory,
                              size: 16,
                              color: widget.product.stock > 0
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFEF4444),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              widget.product.stock > 0
                                  ? '${widget.product.stock} in stock'
                                  : 'Out of stock',
                              style: TextStyle(
                                color: widget.product.stock > 0
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFEF4444),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Quantity Selector
                  if (widget.product.stock > 0) ...[
                    const Text(
                      'Quantity',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        IconButton(
                          onPressed: _selectedQuantity > 1
                              ? () => setState(() => _selectedQuantity--)
                              : null,
                          icon: const Icon(Icons.remove_circle_outline),
                          color: _selectedQuantity > 1
                              ? const Color(0xFF6366F1)
                              : Colors.grey,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$_selectedQuantity',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: _selectedQuantity < widget.product.stock
                              ? () => setState(() => _selectedQuantity++)
                              : null,
                          icon: const Icon(Icons.add_circle_outline),
                          color: _selectedQuantity < widget.product.stock
                              ? const Color(0xFF6366F1)
                              : Colors.grey,
                        ),
                        const Spacer(),
                        Text(
                          'Rs. ${(widget.product.price * _selectedQuantity).toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    // Out of stock message
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFEF4444)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.cancel,
                            color: Color(0xFFEF4444),
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'This product is currently out of stock',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFEF4444),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Reviews Section
                  Consumer<ReviewService>(
                    builder: (context, reviewService, child) {
                      final reviews = reviewService.getReviewsFor(
                        widget.product.id,
                      );
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Customer Reviews',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              Text(
                                '${reviews.length} reviews',
                                style: const TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (reviews.isEmpty)
                            const Text(
                              'No reviews yet. Be the first to review!',
                              style: TextStyle(color: Color(0xFF64748B)),
                            )
                          else
                            Column(
                              children: reviews
                                  .take(5)
                                  .map(
                                    (r) => Container(
                                      width: double.infinity,
                                      margin: const EdgeInsets.only(bottom: 12),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF8FAFC),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: const Color(0xFFE2E8F0),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                r.userName,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  color: Color(0xFF1E293B),
                                                ),
                                              ),
                                              Text(
                                                '${r.createdAt.year}-${r.createdAt.month.toString().padLeft(2, '0')}-${r.createdAt.day.toString().padLeft(2, '0')}',
                                                style: const TextStyle(
                                                  color: Color(0xFF94A3B8),
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: List.generate(
                                              5,
                                              (i) => Icon(
                                                i + 1 <= r.rating
                                                    ? Icons.star
                                                    : Icons.star_border,
                                                color: Colors.amber[600],
                                                size: 18,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            r.comment,
                                            style: const TextStyle(
                                              color: Color(0xFF334155),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),

                          const SizedBox(height: 16),

                          // Add Review Form (logged-in users only)
                          Consumer<AuthService>(
                            builder: (context, auth, _) {
                              final user = auth.currentUser;
                              final hasReviewed = user == null
                                  ? false
                                  : reviewService.hasUserReviewedProduct(
                                      user.uid,
                                      widget.product.id,
                                    );

                              if (user == null) {
                                return SizedBox(
                                  width: double.infinity,
                                  height: 44,
                                  child: OutlinedButton(
                                    onPressed: () => Navigator.pushNamed(
                                      context,
                                      AppRouter.login,
                                    ),
                                    child: const Text(
                                      'Login to write a review',
                                    ),
                                  ),
                                );
                              }

                              if (hasReviewed) {
                                return const Text(
                                  'You have already reviewed this product.',
                                  style: TextStyle(
                                    color: Color(0xFF16A34A),
                                    fontWeight: FontWeight.w600,
                                  ),
                                );
                              }

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Write a review',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: List.generate(5, (i) {
                                      final starValue = (i + 1).toDouble();
                                      return IconButton(
                                        onPressed: () => setState(
                                          () => _userRating = starValue,
                                        ),
                                        icon: Icon(
                                          _userRating >= starValue
                                              ? Icons.star
                                              : Icons.star_border,
                                          color: Colors.amber[600],
                                        ),
                                      );
                                    }),
                                  ),
                                  TextField(
                                    controller: _reviewController,
                                    minLines: 2,
                                    maxLines: 4,
                                    decoration: const InputDecoration(
                                      hintText:
                                          'Share your thoughts about this product...',
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 44,
                                    child: ElevatedButton(
                                      onPressed: () async {
                                        if (_userRating == 0.0) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Please select a star rating',
                                              ),
                                            ),
                                          );
                                          return;
                                        }
                                        final comment = _reviewController.text
                                            .trim();
                                        try {
                                          await reviewService.submitReview(
                                            productId: widget.product.id,
                                            userId: user.uid,
                                            userName:
                                                user.displayName ?? 'Anonymous',
                                            userEmail: user.email ?? '',
                                            rating: _userRating,
                                            comment: comment.isEmpty
                                                ? 'No comment provided.'
                                                : comment,
                                          );
                                          setState(() {
                                            _userRating = 0.0;
                                            _reviewController.clear();
                                          });
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text('Review submitted'),
                                            ),
                                          );
                                        } catch (e) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Failed to submit review: $e',
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                      child: const Text('Submit Review'),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      );
                    },
                  ),

                  // Add to Cart Button
                  Consumer<AuthService>(
                    builder: (context, auth, child) {
                      if (auth.currentUser == null) {
                        return SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton.icon(
                            onPressed: () =>
                                Navigator.pushNamed(context, AppRouter.login),
                            icon: const Icon(Icons.login),
                            label: const Text(
                              'Login to Add to Cart',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6366F1),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                          ),
                        );
                      }

                      return Consumer<CartService>(
                        builder: (context, cart, child) {
                          final isInCart = cart.items.any(
                            (item) => item.productId == widget.product.id,
                          );

                          if (isInCart) {
                            return Container(
                              width: double.infinity,
                              height: 56,
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Center(
                                child: Text(
                                  'Added to Cart',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            );
                          }

                          return SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton.icon(
                              onPressed: widget.product.stock > 0
                                  ? () {
                                      cart.addToCart(
                                        widget.product,
                                        quantity: _selectedQuantity,
                                      );
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            '${widget.product.name} added to cart!',
                                          ),
                                          backgroundColor: const Color(
                                            0xFF10B981,
                                          ),
                                          duration: const Duration(seconds: 2),
                                        ),
                                      );
                                    }
                                  : null,
                              icon: const Icon(Icons.add_shopping_cart),
                              label: Text(
                                widget.product.stock > 0
                                    ? 'Add to Cart'
                                    : 'Out of Stock',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: widget.product.stock > 0
                                    ? const Color(0xFF6366F1)
                                    : Colors.grey,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductImage() {
    if (widget.product.imageUrl.isEmpty) {
      return Container(
        color: const Color(0xFFF1F5F9),
        child: const Center(
          child: Icon(Icons.image_outlined, size: 80, color: Color(0xFF94A3B8)),
        ),
      );
    }

    // Check if it's a Base64 image
    if (widget.product.imageUrl.startsWith('data:image/')) {
      return Base64ImageWidget(
        base64String: widget.product.imageUrl,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        errorWidget: Container(
          color: const Color(0xFFF1F5F9),
          child: const Center(
            child: Icon(Icons.broken_image, size: 80, color: Color(0xFF94A3B8)),
          ),
        ),
      );
    }

    // Check if it's a local asset (starts with 'assets/')
    if (widget.product.imageUrl.startsWith('assets/')) {
      return Image.asset(
        widget.product.imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: const Color(0xFFF1F5F9),
            child: const Center(
              child: Icon(
                Icons.broken_image,
                size: 80,
                color: Color(0xFF94A3B8),
              ),
            ),
          );
        },
      );
    }

    // Otherwise treat as network image
    if (kIsWeb) {
      return Image.network(
        widget.product.imageUrl,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: const Color(0xFFF1F5F9),
            child: const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF6366F1),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => Container(
          color: const Color(0xFFF1F5F9),
          child: const Center(
            child: Icon(Icons.broken_image, size: 80, color: Color(0xFF94A3B8)),
          ),
        ),
      );
    } else {
      return CachedNetworkImage(
        imageUrl: widget.product.imageUrl,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: const Color(0xFFF1F5F9),
          child: const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFF6366F1),
            ),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          color: const Color(0xFFF1F5F9),
          child: const Center(
            child: Icon(Icons.broken_image, size: 80, color: Color(0xFF94A3B8)),
          ),
        ),
      );
    }
  }
}
