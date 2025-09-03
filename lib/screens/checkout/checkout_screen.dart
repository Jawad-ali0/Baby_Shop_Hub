import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/checkout_service.dart';
import '../../services/cart_service.dart';
import '../../models/user.dart';
import '../../routes/app_router.dart';
import '../../widgets/loading_overlay.dart';
import '../../widgets/error_toast.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    // Initialize services if needed
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Checkout',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF6366F1)),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: Consumer<CheckoutService>(
        builder: (context, checkout, child) {
          return Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Theme(
              data: Theme.of(context).copyWith(
                colorScheme: Theme.of(
                  context,
                ).colorScheme.copyWith(primary: const Color(0xFF6366F1)),
              ),
              child: Stepper(
                currentStep: _currentStep,
                onStepContinue: () {
                  if (_currentStep < 2) {
                    setState(() {
                      _currentStep++;
                    });
                  } else {
                    _processOrder();
                  }
                },
                onStepCancel: () {
                  if (_currentStep > 0) {
                    setState(() {
                      _currentStep--;
                    });
                  }
                },
                steps: [
                  Step(
                    title: const Text(
                      'Shipping Address',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    content: _buildAddressStep(),
                    isActive: _currentStep >= 0,
                  ),
                  Step(
                    title: const Text(
                      'Payment Method',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    content: _buildPaymentStep(),
                    isActive: _currentStep >= 1,
                  ),
                  Step(
                    title: const Text(
                      'Review & Place Order',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    content: _buildReviewStep(),
                    isActive: _currentStep >= 2,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAddressStep() {
    final auth = context.watch<AuthService>();
    final checkout = context.watch<CheckoutService>();

    if (auth.userModel?.addresses.isEmpty ?? true) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          children: [
            Icon(Icons.location_off, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'No addresses found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please add an address first to continue',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, AppRouter.profile),
              icon: const Icon(Icons.add_location),
              label: const Text('Add Address'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: auth.userModel!.addresses.map((address) {
        final isSelected = checkout.selectedAddress?.id == address.id;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFEEF2FF) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF6366F1)
                  : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: InkWell(
            onTap: () => checkout.setAddress(address),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF6366F1)
                            : Colors.grey.shade400,
                        width: 2,
                      ),
                      color: isSelected
                          ? const Color(0xFF6366F1)
                          : Colors.transparent,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, size: 12, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          address.isDefault
                              ? 'Default Address'
                              : 'Address ${address.id.substring(0, 4)}',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? const Color(0xFF6366F1)
                                : const Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${address.street}, ${address.city}, ${address.state} ${address.zipCode}',
                          style: TextStyle(
                            color: isSelected
                                ? const Color(0xFF6366F1)
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPaymentStep() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.payment, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cash on Delivery (COD)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pay when you receive your order',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
              ],
            ),
          ),
          const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 24),
        ],
      ),
    );
  }

  Widget _buildReviewStep() {
    final checkout = context.watch<CheckoutService>();
    final cart = context.watch<CartService>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Order Summary',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              ...cart.items.map(
                (item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: item.productImage.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  item.productImage,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(
                                        Icons.image,
                                        color: Color(0xFF94A3B8),
                                      ),
                                ),
                              )
                            : const Icon(Icons.image, color: Color(0xFF94A3B8)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.productName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            Text(
                              'Qty: ${item.quantity}',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        'Rs. ${(item.price * item.quantity).toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _buildPriceRow(
                'Subtotal',
                'Rs. ${cart.totalAmount.toStringAsFixed(2)}',
              ),
              const SizedBox(height: 8),
              _buildPriceRow(
                'Tax',
                'Rs. ${(cart.totalAmount * 0.05).toStringAsFixed(2)}',
              ),
              const SizedBox(height: 8),
              _buildPriceRow('Shipping', 'Rs. 100.00'),
              const Divider(height: 24),
              _buildPriceRow(
                'Total',
                'Rs. ${(cart.totalAmount * 1.05 + 100).toStringAsFixed(2)}',
                isTotal: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        if (checkout.selectedAddress != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFC7D2FE)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Shipping Address',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4338CA),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${checkout.selectedAddress!.isDefault ? 'Default Address' : 'Address ${checkout.selectedAddress!.id.substring(0, 4)}'}\n${checkout.selectedAddress!.street}, ${checkout.selectedAddress!.city}, ${checkout.selectedAddress!.state} ${checkout.selectedAddress!.zipCode}',
                  style: const TextStyle(
                    color: Color(0xFF4338CA),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPriceRow(String label, String amount, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isTotal ? const Color(0xFF1E293B) : const Color(0xFF64748B),
            fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            color: isTotal ? const Color(0xFF10B981) : const Color(0xFF1E293B),
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
            fontSize: isTotal ? 18 : 16,
          ),
        ),
      ],
    );
  }

  Future<void> _processOrder() async {
    final auth = context.read<AuthService>();
    final checkout = context.read<CheckoutService>();
    final cart = context.read<CartService>();

    if (checkout.selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a shipping address'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    if (cart.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your cart is empty'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    try {
      // Show loading overlay
      LoadingOverlayController.show(
        context,
        message: 'Processing your order...',
      );

      // Create a default payment method for COD
      final paymentMethod = PaymentMethod(
        id: 'cod_${DateTime.now().millisecondsSinceEpoch}',
        type: 'Cash on Delivery',
        lastFourDigits: 'COD',
        cardHolderName: auth.userModel?.name ?? 'User',
        expiryDate: 'N/A',
        isDefault: true,
      );

      // Process the checkout
      final orderId = await checkout.processCheckout(
        userId: auth.currentUser?.uid ?? auth.userModel?.uid ?? 'demo_user_123',
        userEmail:
            auth.currentUser?.email ??
            auth.userModel?.email ??
            'demo@babyshophub.com',
        userName: auth.userModel?.name ?? 'Demo User',
        cartItems: cart.items,
        shippingAddress: checkout.selectedAddress!,
        billingAddress: checkout.selectedAddress!,
        paymentMethod: paymentMethod,
        notes: 'Order placed via mobile app',
      );

      // Clear the cart after successful order
      await cart.clearCart();

      // Show success message
      if (mounted) {
        // Hide loading overlay
        LoadingOverlayController.hide(context);

        ErrorToast.showSuccess(
          context,
          message: 'Order placed successfully! Order ID: $orderId',
        );

        // Navigate to order confirmation screen
        Navigator.pushReplacementNamed(
          context,
          AppRouter.orderConfirmation,
          arguments: orderId,
        );
      }
    } catch (e) {
      if (mounted) {
        // Hide loading overlay
        LoadingOverlayController.hide(context);

        ErrorToast.show(
          context,
          message: 'Failed to place order: ${e.toString()}',
          actionText: 'Retry',
          onAction: () => _processOrder(),
        );
      }
    }
  }
}
