import 'package:flutter/material.dart';
import '../../../models/product.dart';
import '../../../widgets/optimized_image_widget.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final VoidCallback onAddToCart;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  color: Theme.of(context).colorScheme.surfaceVariant.withValues(alpha: 0.3),
                ),
                child: OptimizedProductImage(
                  imageUrl: product.imageUrl,
                  width: double.infinity,
                  height: double.infinity,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
              ),
            ),

            // Product Info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Name
                  Text(
                    product.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Product Category
                  Text(
                    product.category,
                    style: TextStyle(
                      fontSize: 12, 
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Rating row
                  Row(
                    children: [
                      ...List.generate(5, (index) {
                        final starIndex = index + 1;
                        final isFull = product.rating >= starIndex;
                        final isHalf =
                            !isFull && product.rating >= (starIndex - 0.5);
                        return Padding(
                          padding: const EdgeInsets.only(right: 1),
                          child: Icon(
                            isFull
                                ? Icons.star
                                : (isHalf
                                      ? Icons.star_half
                                      : Icons.star_border),
                            color: Colors.amber[600],
                            size: 14,
                          ),
                        );
                      }),
                      const SizedBox(width: 6),
                      Text(
                        product.rating.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '(${product.reviewCount})',
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Stock Status
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: product.stock > 0
                          ? const Color(0xFFD1FAE5)
                          : const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          product.stock > 0 ? Icons.check_circle : Icons.cancel,
                          size: 12,
                          color: product.stock > 0
                              ? const Color(0xFF10B981)
                              : const Color(0xFFEF4444),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          product.stock > 0
                              ? '${product.stock} in stock'
                              : 'Out of stock',
                          style: TextStyle(
                            fontSize: 10,
                            color: product.stock > 0
                                ? const Color(0xFF10B981)
                                : const Color(0xFFEF4444),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Price and Add to Cart
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Rs. ${product.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF10B981),
                        ),
                      ),
                      IconButton(
                        onPressed: product.stock > 0 ? onAddToCart : null,
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: product.stock > 0
                                ? const Color(0xFF6366F1)
                                : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            product.stock > 0
                                ? Icons.add_shopping_cart
                                : Icons.block,
                            color: product.stock > 0
                                ? Colors.white
                                : Colors.grey.shade600,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
