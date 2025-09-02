import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _nameController.text = user?.displayName ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 12),
              Text('Email: ${FirebaseAuth.instance.currentUser?.email ?? ''}'),
              const SizedBox(height: 24),
              const Text(
                'Addresses',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Consumer<AuthService>(
                builder: (context, auth, child) {
                  return Wrap(
                    spacing: 6,
                    children: [
                      for (final a in auth.userModel?.addresses ?? [])
                        Chip(
                          label: Text(a.fullAddress),
                          onDeleted: () async {
                            await context.read<AuthService>().removeAddress(
                              a.id,
                            );
                          },
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              const Text(
                'Payment Methods',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Consumer<AuthService>(
                builder: (context, auth, child) {
                  return Wrap(
                    spacing: 6,
                    children: [
                      for (final p in auth.userModel?.paymentMethods ?? [])
                        Chip(
                          label: Text('${p.type} •••• ${p.lastFourDigits}'),
                          onDeleted: () async {
                            await context
                                .read<AuthService>()
                                .removePaymentMethod(p.id);
                          },
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final auth = context.read<AuthService>();
                  final user = auth.userModel;
                  if (user != null) {
                    await auth.updateProfile(
                      name: _nameController.text.trim(),
                      addresses: user.addresses,
                      paymentMethods: user.paymentMethods,
                    );
                  }
                  _nameController.clear();
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Profile updated')),
                  );
                },
                child: const Text('Save'),
              ),
              const SizedBox(height: 16),

              // Admin Section
              Consumer<AuthService>(
                builder: (context, auth, child) {
                  if (auth.userModel?.role == 'admin') {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(height: 32),
                        Row(
                          children: [
                            Icon(
                              Icons.admin_panel_settings,
                              color: Colors.blue.shade600,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Admin Panel',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () =>
                                Navigator.of(context).pushNamed('/admin'),
                            icon: const Icon(Icons.admin_panel_settings),
                            label: const Text('Go to Admin Panel'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade600,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                      ],
                    );
                  } else {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(height: 32),
                        Row(
                          children: [
                            Icon(
                              Icons.admin_panel_settings,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Admin Access',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'You need admin privileges to access the admin panel',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              await auth.updateUserRole('admin');
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'You are now an admin! Refresh the page.',
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.admin_panel_settings),
                            label: const Text('Make Me Admin (Development)'),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.blue.shade600,
                              foregroundColor: Colors.blue.shade600,
                            ),
                          ),
                        ),
                      ],
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
