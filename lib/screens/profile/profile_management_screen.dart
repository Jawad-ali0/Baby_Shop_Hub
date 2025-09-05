import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/theme_service.dart';
import '../../routes/app_router.dart';

class ProfileManagementScreen extends StatelessWidget {
  const ProfileManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Profile',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Consumer<AuthService>(
        builder: (context, auth, child) {
          if (auth.currentUser == null) {
            return _buildUnauthenticatedView(context);
          }

          return _buildAuthenticatedView(context, auth);
        },
      ),
    );
  }

  Widget _buildUnauthenticatedView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(60),
              ),
              child: const Icon(
                Icons.person_outline,
                size: 60,
                color: Color(0xFF6366F1),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Welcome to Baby Shop Hub',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Please login or create an account to manage your profile, view orders, and access exclusive features.',
              style: TextStyle(fontSize: 16, color: Color(0xFF64748B)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  debugPrint('🔍 ProfileScreen: Login button pressed');
                  debugPrint(
                    '🔍 ProfileScreen: Requesting route: ${AppRouter.login}',
                  );
                  Navigator.pushNamed(context, AppRouter.login);
                },
                icon: const Icon(Icons.login),
                label: const Text(
                  'Login',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  debugPrint('🔍 ProfileScreen: Register button pressed');
                  debugPrint(
                    '🔍 ProfileScreen: Requesting route: ${AppRouter.register}',
                  );
                  Navigator.pushNamed(context, AppRouter.register);
                },
                icon: const Icon(Icons.person_add),
                label: const Text(
                  'Create Account',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF6366F1),
                  side: const BorderSide(color: Color(0xFF6366F1), width: 2),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthenticatedView(BuildContext context, AuthService auth) {
    final user = auth.userModel;
    if (user == null) return const SizedBox.shrink();

    final theme = context.watch<ThemeService>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // User Profile Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
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
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: const Color(0xFF6366F1),
                  child: Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  user.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  user.email,
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 16),
                Column(
                  children: [
                    Text(
                      'Theme Settings',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FilterChip(
                          label: const Text('System'),
                          selected: theme.useSystemTheme,
                          onSelected: (_) => theme.toggleSystemTheme(),
                          avatar: Icon(
                            Icons.brightness_auto,
                            size: 16,
                            color: theme.useSystemTheme
                                ? Theme.of(context).colorScheme.onPrimary
                                : Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilterChip(
                          label: const Text('Light'),
                          selected: !theme.useSystemTheme && !theme.isDark,
                          onSelected: (_) => theme.setThemeMode(false),
                          avatar: Icon(
                            Icons.light_mode,
                            size: 16,
                            color: (!theme.useSystemTheme && !theme.isDark)
                                ? Theme.of(context).colorScheme.onPrimary
                                : Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilterChip(
                          label: const Text('Dark'),
                          selected: !theme.useSystemTheme && theme.isDark,
                          onSelected: (_) => theme.setThemeMode(true),
                          avatar: Icon(
                            Icons.dark_mode,
                            size: 16,
                            color: (!theme.useSystemTheme && theme.isDark)
                                ? Theme.of(context).colorScheme.onPrimary
                                : Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    FilterChip(
                      label: const Text('High contrast'),
                      selected: theme.isHighContrast,
                      onSelected: (_) => theme.toggleHighContrast(),
                      avatar: Icon(
                        Icons.contrast,
                        size: 16,
                        color: theme.isHighContrast
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Profile Options
          _buildProfileSection(
            title: 'Account Settings',
            items: [
              _buildProfileItem(
                icon: Icons.person_outline,
                title: 'Edit Profile',
                subtitle: 'Update your personal information',
                onTap: () {
                  Navigator.pushNamed(context, AppRouter.editProfile);
                },
              ),
              _buildProfileItem(
                icon: Icons.location_on_outlined,
                title: 'Manage Addresses',
                subtitle:
                    '${user.addresses.length} address${user.addresses.length != 1 ? 'es' : ''}',
                onTap: () {
                  Navigator.pushNamed(context, AppRouter.manageAddresses);
                },
              ),
              _buildProfileItem(
                icon: Icons.payment_outlined,
                title: 'Payment Methods',
                subtitle:
                    '${user.paymentMethods.length} payment method${user.paymentMethods.length != 1 ? 's' : ''}',
                onTap: () {
                  Navigator.pushNamed(context, AppRouter.paymentMethods);
                },
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Admin Section
          if (user.role == 'admin')
            _buildProfileSection(
              title: 'Admin Tools',
              items: [
                _buildProfileItem(
                  icon: Icons.admin_panel_settings,
                  title: 'Admin Dashboard',
                  subtitle: 'Manage products, orders, and users',
                  onTap: () {
                    Navigator.pushNamed(context, AppRouter.admin);
                  },
                ),
              ],
            ),

          const SizedBox(height: 24),

          // Support Section
          _buildProfileSection(
            title: 'Support & Help',
            items: [
              _buildProfileItem(
                icon: Icons.support_agent_outlined,
                title: 'Customer Support',
                subtitle: 'Get help with your orders',
                onTap: () {
                  Navigator.pushNamed(context, AppRouter.support);
                },
              ),
              _buildProfileItem(
                icon: Icons.help_outline,
                title: 'Help Center',
                subtitle: 'FAQs and guides',
                onTap: () {
                  Navigator.pushNamed(context, AppRouter.helpCenter);
                },
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Logout Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showLogoutDialog(context, auth),
              icon: const Icon(Icons.logout, color: Color(0xFFEF4444)),
              label: const Text(
                'Sign Out',
                style: TextStyle(
                  color: Color(0xFFEF4444),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFEF4444), width: 2),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSection({
    required String title,
    required List<Widget> items,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
          ),
          ...items,
        ],
      ),
    );
  }

  Widget _buildProfileItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFEEF2FF),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: const Color(0xFF6366F1)),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1E293B),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
      ),
      trailing: const Icon(Icons.chevron_right, color: Color(0xFF94A3B8)),
      onTap: onTap,
    );
  }

  void _showLogoutDialog(BuildContext context, AuthService auth) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Sign Out'),
          content: const Text('Are you sure you want to sign out?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await auth.signOut();
                if (context.mounted) {
                  Navigator.pushReplacementNamed(context, AppRouter.home);
                }
              },
              child: const Text(
                'Sign Out',
                style: TextStyle(color: Color(0xFFEF4444)),
              ),
            ),
          ],
        );
      },
    );
  }
}
