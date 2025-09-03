import 'package:flutter/material.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/main_navigation_screen.dart';
import '../screens/cart/cart_screen.dart';
import '../screens/orders/orders_screen.dart';
import '../screens/profile/profile_management_screen.dart';
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/support/support_screen.dart';
import '../screens/checkout/checkout_screen.dart';
import '../screens/product/product_detail_screen.dart';
import '../screens/orders/order_confirmation_screen.dart';
// Removed demo routes to keep production build clean
import '../models/product.dart';
import '../screens/profile/edit_profile_screen.dart';
import '../screens/profile/manage_addresses_screen.dart';
import '../screens/profile/payment_methods_screen.dart';
import '../screens/support/help_center_screen.dart';

class AppRouter {
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String cart = '/cart';
  static const String orders = '/orders';
  static const String profile = '/profile';
  static const String admin = '/admin';
  static const String support = '/support';
  static const String checkout = '/checkout';
  static const String productDetail = '/product-detail';
  static const String orderConfirmation = '/order-confirmation';
  // Demo routes removed
  static const String editProfile = '/edit-profile';
  static const String manageAddresses = '/manage-addresses';
  static const String paymentMethods = '/payment-methods';
  static const String helpCenter = '/help-center';

  static Map<String, WidgetBuilder> get routes {
    print('🔍 AppRouter: Generating routes map');
    return {
      login: (_) {
        print('🔍 AppRouter: Creating LoginScreen for route: $login');
        return const LoginScreen();
      },
      register: (_) {
        print('🔍 AppRouter: Creating RegisterScreen for route: $register');
        return const RegisterScreen();
      },
      home: (_) {
        print('🔍 AppRouter: Creating MainNavigationScreen for route: $home');
        return const MainNavigationScreen();
      },
      cart: (_) {
        print('🔍 AppRouter: Creating CartScreen for route: $cart');
        return const CartScreen();
      },
      orders: (_) {
        print('🔍 AppRouter: Creating OrdersScreen for route: $orders');
        return const OrdersScreen();
      },
      profile: (_) {
        print(
          '🔍 AppRouter: Creating ProfileManagementScreen for route: $profile',
        );
        return const ProfileManagementScreen();
      },
      admin: (_) {
        print('🔍 AppRouter: Creating AdminDashboardScreen for route: $admin');
        return const AdminDashboardScreen();
      },
      support: (_) {
        print('🔍 AppRouter: Creating SupportScreen for route: $support');
        return const SupportScreen();
      },
      checkout: (_) {
        print('🔍 AppRouter: Creating CheckoutScreen for route: $checkout');
        return const CheckoutScreen();
      },
      // Demo routes removed
      editProfile: (_) => const EditProfileScreen(),
      manageAddresses: (_) => const ManageAddressesScreen(),
      paymentMethods: (_) => const PaymentMethodsScreen(),
      helpCenter: (_) => const HelpCenterScreen(),
    };
  }

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    print('🔍 AppRouter: onGenerateRoute called with name: ${settings.name}');

    // Handle special routes with arguments
    switch (settings.name) {
      case productDetail:
        final args = settings.arguments as Map<String, dynamic>?;
        if (args != null && args['product'] != null) {
          final product = args['product'] as Product;
          return MaterialPageRoute(
            builder: (_) => ProductDetailScreen(product: product),
          );
        }
        break;

      case orderConfirmation:
        final orderId = settings.arguments as String?;
        if (orderId != null) {
          return MaterialPageRoute(
            builder: (_) => OrderConfirmationScreen(orderId: orderId),
          );
        }
        break;

      // Handle static routes as fallback
      case login:
        print('🔍 AppRouter: Fallback handling for login route');
        return MaterialPageRoute(builder: (_) => const LoginScreen());

      case register:
        print('🔍 AppRouter: Fallback handling for register route');
        return MaterialPageRoute(builder: (_) => const RegisterScreen());

      case home:
        print('🔍 AppRouter: Fallback handling for home route');
        return MaterialPageRoute(builder: (_) => const MainNavigationScreen());

      case cart:
        print('🔍 AppRouter: Fallback handling for cart route');
        return MaterialPageRoute(builder: (_) => const CartScreen());

      case orders:
        print('🔍 AppRouter: Fallback handling for orders route');
        return MaterialPageRoute(builder: (_) => const OrdersScreen());

      case profile:
        print('🔍 AppRouter: Fallback handling for profile route');
        return MaterialPageRoute(
          builder: (_) => const ProfileManagementScreen(),
        );

      case admin:
        print('🔍 AppRouter: Fallback handling for admin route');
        return MaterialPageRoute(builder: (_) => const AdminDashboardScreen());

      case support:
        print('🔍 AppRouter: Fallback handling for support route');
        return MaterialPageRoute(builder: (_) => const SupportScreen());

      case checkout:
        print('🔍 AppRouter: Fallback handling for checkout route');
        return MaterialPageRoute(builder: (_) => const CheckoutScreen());

      default:
        print('🔍 AppRouter: No route found for: ${settings.name}');
        break;
    }

    return null;
  }
}
