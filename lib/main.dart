import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/cart_service.dart';
import 'services/product_service.dart';
import 'services/order_service.dart';
import 'services/checkout_service.dart';
import 'services/support_service.dart';
import 'services/review_service.dart';
import 'services/theme_service.dart';
import 'services/connectivity_service.dart';
import 'screens/splash_screen.dart';
import 'routes/app_router.dart';
import 'widgets/offline_banner.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => CartService()),
        ChangeNotifierProvider(create: (_) => ProductService()),
        ChangeNotifierProvider(create: (_) => OrderService()),
        ChangeNotifierProvider(create: (_) => CheckoutService()),
        ChangeNotifierProvider(create: (_) => SupportService()),
        ChangeNotifierProvider(create: (_) => ReviewService()),
        ChangeNotifierProvider(create: (_) => ThemeService()),
        ChangeNotifierProvider(create: (_) => ConnectivityService()),
      ],
      child: Consumer<ThemeService>(
        builder: (context, theme, _) {
          final baseTheme = ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF6366F1),
            ),
            useMaterial3: true,
            brightness: theme.isDark ? Brightness.dark : Brightness.light,
          );
          final themed = theme.isHighContrast
              ? baseTheme.copyWith(
                  textTheme: baseTheme.textTheme.apply(
                    bodyColor: Colors.black,
                    displayColor: Colors.black,
                  ),
                  colorScheme: baseTheme.colorScheme.copyWith(
                    primary: const Color(0xFF000000),
                    secondary: const Color(0xFF000000),
                  ),
                )
              : baseTheme;

          return MaterialApp(
            title: 'Baby Shop Hub',
            theme: themed,
            home: const SplashScreen(),
            routes: AppRouter.routes,
            onGenerateRoute: AppRouter.onGenerateRoute,
            onUnknownRoute: (settings) {
              print('❌ MaterialApp: Unknown route requested: ${settings.name}');
              print(
                '❌ MaterialApp: Available routes: ${AppRouter.routes.keys.toList()}',
              );
              return MaterialPageRoute(
                builder: (_) => Scaffold(
                  body: Center(
                    child: Text('Route not found: ${settings.name}'),
                  ),
                ),
              );
            },
            debugShowCheckedModeBanner: false,
            builder: (context, child) {
              print(
                '🔍 MaterialApp: Building with routes: ${AppRouter.routes.keys.toList()}',
              );
              return Column(
                children: [
                  const OfflineBanner(),
                  Expanded(child: child!),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
