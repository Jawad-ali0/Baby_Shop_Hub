import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/product_service.dart';
import '../../services/cart_service.dart';
import '../../services/connectivity_service.dart';
import '../../services/theme_service.dart';
import '../../routes/app_router.dart';
import '../../widgets/error_toast.dart';
import '../../widgets/shimmer_widget.dart';
import '../product/product_detail_screen.dart';
import 'widgets/product_card.dart';
import 'widgets/category_filter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedCategory = 'All';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _searchController.addListener(() {
      final next = _searchController.text.trim();
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 250), () {
        if (_searchQuery != next) {
          setState(() {
            _searchQuery = next;
          });
        }
      });
    });
  }

  void _loadProducts() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductService>().initialize();
    });
  }

  Future<void> _refresh() async {
    final connectivity = context.read<ConnectivityService>();
    if (!connectivity.isOnline) {
      ErrorToast.showInfo(
        context,
        message: 'You\'re offline. Showing cached products.',
      );
      return;
    }

    try {
      context.read<ProductService>().initialize();
      ErrorToast.showSuccess(
        context,
        message: 'Products refreshed successfully!',
      );
    } catch (e) {
      ErrorToast.show(
        context,
        message: 'Failed to refresh products: ${e.toString()}',
        actionText: 'Retry',
        onAction: _refresh,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Baby Shop Hub',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        actions: [
          Consumer<ThemeService>(
            builder: (context, theme, _) {
              return IconButton(
                icon: Icon(
                  theme.isDark ? Icons.light_mode : Icons.dark_mode,
                  color: Theme.of(context).colorScheme.primary,
                ),
                onPressed: () => theme.toggleDarkMode(),
                tooltip: theme.isDark
                    ? 'Switch to Light Mode'
                    : 'Switch to Dark Mode',
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.shopping_cart, color: Color(0xFF6366F1)),
            onPressed: () {
              final auth = context.read<AuthService>();
              if (auth.currentUser != null) {
                Navigator.pushNamed(context, AppRouter.cart);
              } else {
                Navigator.pushNamed(context, AppRouter.login);
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.shadow.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search for baby products...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF94A3B8)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                suffixIcon: _searchQuery.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear, color: Color(0xFF94A3B8)),
                        onPressed: () {
                          _searchController.clear();
                        },
                      ),
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => FocusScope.of(context).unfocus(),
            ),
          ),

          // Category Filter
          CategoryFilter(
            selectedCategory: _selectedCategory,
            onCategoryChanged: (category) {
              setState(() {
                _selectedCategory = category;
              });
            },
          ),

          // Products List
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: Consumer<ProductService>(
                builder: (context, productService, child) {
                  if (productService.isLoading) {
                    return ShimmerList(
                      itemCount: 6,
                      itemBuilder: (context, index) =>
                          const ShimmerProductCard(),
                    );
                  }

                  if (productService.error != null) {
                    return ListView(
                      children: [
                        const SizedBox(height: 80),
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Error loading products',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                productService.error!,
                                style: TextStyle(color: Colors.grey.shade500),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              TextButton.icon(
                                onPressed: _refresh,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }

                  var products = productService.activeProducts;

                  // Filter by category if not "All"
                  if (_selectedCategory != 'All') {
                    products = products
                        .where(
                          (product) =>
                              product.category.toLowerCase() ==
                              _selectedCategory.toLowerCase(),
                        )
                        .toList();
                  }

                  // Filter by search query
                  if (_searchQuery.isNotEmpty) {
                    final q = _searchQuery.toLowerCase();
                    products = products
                        .where(
                          (p) =>
                              p.name.toLowerCase().contains(q) ||
                              p.category.toLowerCase().contains(q) ||
                              p.description.toLowerCase().contains(q),
                        )
                        .toList();
                  }

                  if (products.isEmpty) {
                    return ListView(
                      children: [
                        const SizedBox(height: 80),
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.inventory_2_outlined,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No products found',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _searchQuery.isEmpty
                                    ? 'Try selecting a different category'
                                    : 'Try a different search term',
                                style: TextStyle(color: Colors.grey.shade500),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.75,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return ProductCard(
                        product: product,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ProductDetailScreen(product: product),
                            ),
                          );
                        },
                        onAddToCart: () {
                          final auth = context.read<AuthService>();
                          if (auth.currentUser != null) {
                            context.read<CartService>().addToCart(product);
                            ErrorToast.showSuccess(
                              context,
                              message: '${product.name} added to cart',
                            );
                          } else {
                            Navigator.pushNamed(context, AppRouter.login);
                          }
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }
}
