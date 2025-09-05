import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/cart_service.dart';
import '../../routes/app_router.dart';
import '../../services/auth_service.dart';
import '../../widgets/optimized_image_widget.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartService>();

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Shopping Cart',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF6366F1)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: cart.items.isEmpty
                ? _buildEmptyCart(context)
                : _buildCartItems(cart),
          ),
          if (cart.items.isNotEmpty) _buildCheckoutSection(cart, context),
        ],
      ),
    );
  }

  Widget _buildEmptyCart(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shopping_cart_outlined,
              size: 64,
              color: Color(0xFF6366F1),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Your cart is empty',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add some products to get started!',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.shopping_bag_outlined),
            label: const Text('Start Shopping'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItems(CartService cart) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: cart.items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final item = cart.items[i];
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Product Image
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: item.productImage.isNotEmpty
                      ? OptimizedProductImage(
                          imageUrl: item.productImage,
                          width: 80,
                          height: 80,
                          borderRadius: BorderRadius.circular(12),
                        )
                      : const Icon(Icons.image, color: Color(0xFF94A3B8)),
                ),
                const SizedBox(width: 16),

                // Product Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.productName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Rs. ${item.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF10B981),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Quantity Controls
                      Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEF2FF),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.remove,
                                size: 18,
                                color: Color(0xFF6366F1),
                              ),
                              onPressed: () => cart.updateQuantity(
                                item.productId,
                                item.quantity - 1,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 36,
                                minHeight: 36,
                              ),
                              padding: EdgeInsets.zero,
                            ),
                          ),
                          Container(
                            width: 40,
                            alignment: Alignment.center,
                            child: Text(
                              item.quantity.toString(),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEF2FF),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.add,
                                size: 18,
                                color: Color(0xFF6366F1),
                              ),
                              onPressed: () => cart.updateQuantity(
                                item.productId,
                                item.quantity + 1,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 36,
                                minHeight: 36,
                              ),
                              padding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Remove Button
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Color(0xFFEF4444),
                  ),
                  onPressed: () => cart.removeFromCart(item.productId),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCheckoutSection(CartService cart, BuildContext context) {
    final subtotal = cart.totalAmount;
    final tax = subtotal * 0.05; // 5% tax (consistent with checkout)
    final shipping = subtotal > 1000
        ? 0.0
        : 100.0; // Free shipping over Rs. 1000
    final total = subtotal + tax + shipping;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Price Breakdown
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildPriceRow('Subtotal', subtotal),
                const SizedBox(height: 8),
                _buildPriceRow('Tax (5%)', tax),
                const SizedBox(height: 8),
                _buildPriceRow('Shipping', shipping),
                const Divider(height: 24),
                _buildPriceRow('Total', total, isTotal: true),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Checkout Button
          ElevatedButton(
            onPressed: () {
              final auth = context.read<AuthService>();
              if (auth.currentUser == null) {
                Navigator.pushNamed(context, AppRouter.login);
                return;
              }
              Navigator.pushNamed(context, AppRouter.checkout);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Proceed to Checkout',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, double amount, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 18 : 16,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color: isTotal ? const Color(0xFF1E293B) : const Color(0xFF64748B),
          ),
        ),
        Text(
          'Rs. ${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: isTotal ? 18 : 16,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color: isTotal ? const Color(0xFF10B981) : const Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }
}
