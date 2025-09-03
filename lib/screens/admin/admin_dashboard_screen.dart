import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/product_service.dart';
import '../../services/order_service.dart';
import '../../services/support_service.dart';
import '../../services/theme_service.dart';
import '../../models/order.dart';
import '../../models/product.dart';
import '../../models/support_ticket.dart';
import '../../widgets/error_toast.dart';
import '../../widgets/loading_overlay.dart';
import 'base64_product_form_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _productSortBy = 'name';
  String _productFilter = 'all';
  final Set<String> _selectedProducts = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // Load all orders for admin view
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderService>().loadAllOrders();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Admin Dashboard',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Consumer<ThemeService>(
            builder: (context, theme, _) {
              return IconButton(
                icon: Icon(
                  theme.effectiveIsDark ? Icons.light_mode : Icons.dark_mode,
                  color: Theme.of(context).colorScheme.primary,
                ),
                onPressed: () => theme.toggleDarkMode(),
                tooltip: theme.effectiveIsDark
                    ? 'Switch to Light Mode'
                    : 'Switch to Dark Mode',
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Theme.of(context).colorScheme.primary,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Theme.of(
            context,
          ).colorScheme.onSurface.withOpacity(0.6),
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Products'),
            Tab(text: 'Orders'),
            Tab(text: 'Support'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildProductsTab(),
          _buildOrdersTab(),
          _buildSupportTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dashboard Overview',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 24),

            // Statistics Cards
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Products',
                    '${context.watch<ProductService>().products.length}',
                    Icons.inventory,
                    const Color(0xFF6366F1),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Total Orders',
                    '${context.watch<OrderService>().orders.length}',
                    Icons.shopping_bag,
                    const Color(0xFF10B981),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Pending Orders',
                    '${context.watch<OrderService>().orders.where((o) => o.status == OrderStatus.pending).length}',
                    Icons.pending,
                    const Color(0xFFF59E0B),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Support Tickets',
                    '${context.watch<SupportService>().tickets.length}',
                    Icons.support_agent,
                    const Color(0xFFEF4444),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsTab() {
    final products = context.watch<ProductService>().products;
    final filteredProducts = _getFilteredAndSortedProducts(products);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title and controls section
          Row(
            children: [
              const Text(
                'Products',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const Spacer(),
              if (_selectedProducts.isNotEmpty) ...[
                Text(
                  '${_selectedProducts.length} selected',
                  style: const TextStyle(
                    color: Color(0xFF6366F1),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _selectedProducts.length == 1
                      ? () => _bulkActivateProducts()
                      : null,
                  icon: const Icon(Icons.check_circle, size: 16),
                  label: const Text('Activate'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _selectedProducts.length == 1
                      ? () => _bulkDeactivateProducts()
                      : null,
                  icon: const Icon(Icons.pause_circle, size: 16),
                  label: const Text('Deactivate'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF59E0B),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _bulkDeleteProducts(),
                  icon: const Icon(Icons.delete, size: 16),
                  label: const Text('Delete'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => setState(() => _selectedProducts.clear()),
                  child: const Text('Clear'),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),

          // Filter and sort controls
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                SizedBox(
                  width: 200,
                  child: DropdownButtonFormField<String>(
                    initialValue: _productFilter,
                    decoration: const InputDecoration(
                      labelText: 'Filter',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'all',
                        child: Text('All Products'),
                      ),
                      DropdownMenuItem(
                        value: 'active',
                        child: Text('Active Only'),
                      ),
                      DropdownMenuItem(
                        value: 'inactive',
                        child: Text('Inactive Only'),
                      ),
                      DropdownMenuItem(
                        value: 'out_of_stock',
                        child: Text('Out of Stock'),
                      ),
                    ],
                    onChanged: (value) =>
                        setState(() => _productFilter = value!),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 200,
                  child: DropdownButtonFormField<String>(
                    initialValue: _productSortBy,
                    decoration: const InputDecoration(
                      labelText: 'Sort By',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'name', child: Text('Name A-Z')),
                      DropdownMenuItem(
                        value: 'name_desc',
                        child: Text('Name Z-A'),
                      ),
                      DropdownMenuItem(
                        value: 'price',
                        child: Text('Price Low-High'),
                      ),
                      DropdownMenuItem(
                        value: 'price_desc',
                        child: Text('Price High-Low'),
                      ),
                      DropdownMenuItem(
                        value: 'stock',
                        child: Text('Stock Low-High'),
                      ),
                      DropdownMenuItem(
                        value: 'created',
                        child: Text('Newest First'),
                      ),
                    ],
                    onChanged: (value) =>
                        setState(() => _productSortBy = value!),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const Base64ProductFormScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Product'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Products list
          Expanded(
            child: filteredProducts.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 64,
                          color: Color(0xFF94A3B8),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No products found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Try adjusting your filters or add a new product',
                          style: TextStyle(color: Color(0xFF94A3B8)),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = filteredProducts[index];
                      final isSelected = _selectedProducts.contains(product.id);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: CheckboxListTile(
                          value: isSelected,
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                _selectedProducts.add(product.id);
                              } else {
                                _selectedProducts.remove(product.id);
                              }
                            });
                          },
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  product.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: product.isActive
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFF6B7280),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  product.isActive ? 'Active' : 'Inactive',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                'Price: \$${product.price.toStringAsFixed(2)}',
                              ),
                              Text('Stock: ${product.stock} units'),
                              if (product.stock == 0)
                                const Text(
                                  'OUT OF STOCK',
                                  style: TextStyle(
                                    color: Color(0xFFEF4444),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                            ],
                          ),
                          secondary: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: () => _editProduct(product),
                                icon: const Icon(Icons.edit),
                                tooltip: 'Edit Product',
                              ),
                              IconButton(
                                onPressed: () => _deleteProduct(product),
                                icon: const Icon(Icons.delete),
                                tooltip: 'Delete Product',
                                color: const Color(0xFFEF4444),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  List<Product> _getFilteredAndSortedProducts(List<Product> products) {
    // Apply filter
    List<Product> filtered = products.where((product) {
      switch (_productFilter) {
        case 'active':
          return product.isActive;
        case 'inactive':
          return !product.isActive;
        case 'out_of_stock':
          return product.stock == 0;
        case 'all':
        default:
          return true;
      }
    }).toList();

    // Apply sorting
    filtered.sort((a, b) {
      switch (_productSortBy) {
        case 'name':
          return a.name.compareTo(b.name);
        case 'name_desc':
          return b.name.compareTo(a.name);
        case 'price':
          return a.price.compareTo(b.price);
        case 'price_desc':
          return b.price.compareTo(a.price);
        case 'stock':
          return a.stock.compareTo(b.stock);
        case 'created':
          return b.createdAt.compareTo(a.createdAt);
        default:
          return 0;
      }
    });

    return filtered;
  }

  void _editProduct(Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Base64ProductFormScreen(product: product),
      ),
    );
  }

  void _deleteProduct(Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await context.read<ProductService>().deleteProduct(product.id);
                if (!mounted) return;
                ErrorToast.showSuccess(
                  context,
                  message: 'Product deleted successfully',
                );
              } catch (e) {
                if (!mounted) return;
                ErrorToast.show(
                  context,
                  message: 'Failed to delete product: $e',
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _bulkActivateProducts() async {
    if (_selectedProducts.isEmpty) return;

    try {
      LoadingOverlayController.show(context, message: 'Activating products...');

      for (String productId in _selectedProducts) {
        await context.read<ProductService>().updateProductStatus(
          productId,
          true,
        );
      }
      setState(() => _selectedProducts.clear());
      LoadingOverlayController.hide(context);
      ErrorToast.showSuccess(
        context,
        message: 'Products activated successfully',
      );
    } catch (e) {
      LoadingOverlayController.hide(context);
      ErrorToast.show(
        context,
        message: 'Failed to activate products: $e',
        actionText: 'Retry',
        onAction: _bulkActivateProducts,
      );
    }
  }

  void _bulkDeactivateProducts() async {
    if (_selectedProducts.isEmpty) return;

    try {
      LoadingOverlayController.show(
        context,
        message: 'Deactivating products...',
      );

      for (String productId in _selectedProducts) {
        await context.read<ProductService>().updateProductStatus(
          productId,
          false,
        );
      }
      setState(() => _selectedProducts.clear());
      LoadingOverlayController.hide(context);
      ErrorToast.showSuccess(
        context,
        message: 'Products deactivated successfully',
      );
    } catch (e) {
      LoadingOverlayController.hide(context);
      ErrorToast.show(
        context,
        message: 'Failed to deactivate products: $e',
        actionText: 'Retry',
        onAction: _bulkDeactivateProducts,
      );
    }
  }

  void _bulkDeleteProducts() async {
    if (_selectedProducts.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Products'),
        content: Text(
          'Are you sure you want to delete ${_selectedProducts.length} products? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                LoadingOverlayController.show(
                  context,
                  message: 'Deleting products...',
                );

                for (String productId in _selectedProducts) {
                  await context.read<ProductService>().deleteProduct(productId);
                }
                setState(() => _selectedProducts.clear());
                LoadingOverlayController.hide(context);
                ErrorToast.showSuccess(
                  context,
                  message: 'Products deleted successfully',
                );
              } catch (e) {
                LoadingOverlayController.hide(context);
                ErrorToast.show(
                  context,
                  message: 'Failed to delete products: $e',
                  actionText: 'Retry',
                  onAction: _bulkDeleteProducts,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersTab() {
    final orders = context.watch<OrderService>().orders;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Orders',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getOrderStatusColor(order.status),
                      child: Icon(
                        _getOrderStatusIcon(order.status),
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      'Order #${order.id.substring(order.id.length - 6)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    subtitle: Text(
                      '${order.items.length} items • Rs. ${order.totalAmount.toStringAsFixed(2)}\nStatus: ${order.status}',
                      style: const TextStyle(color: Color(0xFF64748B)),
                    ),
                    isThreeLine: true,
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) => _handleOrderAction(value, order),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'update_status',
                          child: Row(
                            children: [
                              Icon(Icons.update, size: 20),
                              SizedBox(width: 8),
                              Text('Update Status'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'add_tracking',
                          child: Row(
                            children: [
                              Icon(Icons.local_shipping, size: 20),
                              SizedBox(width: 8),
                              Text('Add Tracking'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'view_details',
                          child: Row(
                            children: [
                              Icon(Icons.visibility, size: 20),
                              SizedBox(width: 8),
                              Text('View Details'),
                            ],
                          ),
                        ),
                      ],
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            order.createdAt.toLocal().toString().split('.')[0],
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                          if (order.trackingNumber != null)
                            Text(
                              'Track: ${order.trackingNumber}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFF10B981),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportTab() {
    final tickets = context.watch<SupportService>().tickets;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Support Tickets',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: tickets.length,
              itemBuilder: (context, index) {
                final ticket = tickets[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getTicketStatusColor(ticket.status),
                      child: Icon(
                        _getTicketStatusIcon(ticket.status),
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      ticket.subject,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    subtitle: Text(
                      ticket.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Color(0xFF64748B)),
                    ),
                    trailing: Text(
                      ticket.status.name.toUpperCase(),
                      style: TextStyle(
                        color: _getTicketStatusColor(ticket.status),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _getOrderStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return const Color(0xFFF59E0B);
      case OrderStatus.processing:
        return const Color(0xFF6366F1);
      case OrderStatus.shipped:
        return const Color(0xFF10B981);
      case OrderStatus.delivered:
        return const Color(0xFF10B981);
      case OrderStatus.cancelled:
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF94A3B8);
    }
  }

  IconData _getOrderStatusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Icons.pending;
      case OrderStatus.processing:
        return Icons.sync;
      case OrderStatus.shipped:
        return Icons.local_shipping;
      case OrderStatus.delivered:
        return Icons.check_circle;
      case OrderStatus.cancelled:
        return Icons.cancel;
      default:
        return Icons.shopping_bag;
    }
  }

  Color _getTicketStatusColor(SupportTicketStatus status) {
    switch (status) {
      case SupportTicketStatus.open:
        return const Color(0xFF6366F1);
      case SupportTicketStatus.inProgress:
        return const Color(0xFFF59E0B);
      case SupportTicketStatus.resolved:
        return const Color(0xFF10B981);
      case SupportTicketStatus.closed:
        return const Color(0xFF94A3B8);
    }
  }

  IconData _getTicketStatusIcon(SupportTicketStatus status) {
    switch (status) {
      case SupportTicketStatus.open:
        return Icons.support_agent;
      case SupportTicketStatus.inProgress:
        return Icons.sync;
      case SupportTicketStatus.resolved:
        return Icons.check_circle;
      case SupportTicketStatus.closed:
        return Icons.close;
    }
  }

  // Handle order actions
  void _handleOrderAction(String action, OrderModel order) {
    switch (action) {
      case 'update_status':
        _showUpdateStatusDialog(order);
        break;
      case 'add_tracking':
        _showAddTrackingDialog(order);
        break;
      case 'view_details':
        _showOrderDetails(order);
        break;
    }
  }

  // Show update status dialog
  void _showUpdateStatusDialog(OrderModel order) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Update Order Status'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: OrderStatus.values.map((status) {
              return ListTile(
                title: Text(status.name.toUpperCase()),
                leading: Radio<OrderStatus>(
                  value: status,
                  groupValue: order.status,
                  onChanged: (OrderStatus? value) {
                    if (value != null) {
                      Navigator.of(context).pop();
                      _updateOrderStatus(order, value);
                    }
                  },
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  // Update order status
  Future<void> _updateOrderStatus(
    OrderModel order,
    OrderStatus newStatus,
  ) async {
    try {
      await OrderService().updateOrderStatus(order.id, newStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order status updated to ${newStatus.name}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update order status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Show add tracking dialog
  void _showAddTrackingDialog(OrderModel order) {
    final trackingController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Tracking Number'),
          content: TextField(
            controller: trackingController,
            decoration: const InputDecoration(
              labelText: 'Tracking Number',
              hintText: 'Enter tracking number',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (trackingController.text.isNotEmpty) {
                  Navigator.of(context).pop();
                  _addTrackingNumber(order, trackingController.text);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  // Add tracking number
  Future<void> _addTrackingNumber(
    OrderModel order,
    String trackingNumber,
  ) async {
    try {
      await OrderService().addTrackingNumber(order.id, trackingNumber);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tracking number added: $trackingNumber'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add tracking number: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Show order details
  void _showOrderDetails(OrderModel order) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Order #${order.id.substring(order.id.length - 6)}'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Status: ${order.status.name.toUpperCase()}'),
                Text('Total: Rs. ${order.totalAmount.toStringAsFixed(2)}'),
                Text('Items: ${order.items.length}'),
                if (order.trackingNumber != null)
                  Text('Tracking: ${order.trackingNumber}'),
                const SizedBox(height: 16),
                const Text(
                  'Items:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ...order.items.map(
                  (item) => Text('• ${item.productName} x${item.quantity}'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
