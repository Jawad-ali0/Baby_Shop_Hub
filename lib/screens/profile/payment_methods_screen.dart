import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../models/user.dart';
import '../../widgets/error_toast.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _cardHolderNameController = TextEditingController();
  final _expiryMonthController = TextEditingController();
  final _expiryYearController = TextEditingController();
  final _cvvController = TextEditingController();
  String _selectedCardType = 'visa';
  bool _isDefault = false;
  bool _isEditing = false;
  String? _editingPaymentMethodId;

  final List<String> _months = [
    '01', '02', '03', '04', '05', '06',
    '07', '08', '09', '10', '11', '12'
  ];
  
  final List<String> _years = List.generate(10, (index) => 
    (DateTime.now().year + index).toString()
  );

  @override
  void dispose() {
    _cardNumberController.dispose();
    _cardHolderNameController.dispose();
    _expiryMonthController.dispose();
    _expiryYearController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  void _showAddEditPaymentMethodDialog([PaymentMethod? paymentMethod]) {
    if (paymentMethod != null) {
      // Editing existing payment method
      _isEditing = true;
      _editingPaymentMethodId = paymentMethod.id;
      _cardNumberController.text = '**** **** **** ${paymentMethod.lastFourDigits}';
      _cardHolderNameController.text = paymentMethod.cardHolderName;
      _expiryMonthController.text = paymentMethod.expiryDate.split('/')[0];
      _expiryYearController.text = paymentMethod.expiryDate.split('/')[1];
      _cvvController.text = '***';
      _selectedCardType = paymentMethod.type;
      _isDefault = paymentMethod.isDefault;
    } else {
      // Adding new payment method
      _isEditing = false;
      _editingPaymentMethodId = null;
      _cardNumberController.clear();
      _cardHolderNameController.clear();
      _expiryMonthController.clear();
      _expiryYearController.clear();
      _cvvController.clear();
      _selectedCardType = 'visa';
      _isDefault = false;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_isEditing ? 'Edit Payment Method' : 'Add Payment Method'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Card Type Selection
                DropdownButtonFormField<String>(
                  value: _selectedCardType,
                  decoration: const InputDecoration(
                    labelText: 'Card Type',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'visa', child: Text('Visa')),
                    DropdownMenuItem(value: 'mastercard', child: Text('Mastercard')),
                    DropdownMenuItem(value: 'amex', child: Text('American Express')),
                    DropdownMenuItem(value: 'discover', child: Text('Discover')),
                    DropdownMenuItem(value: 'rupay', child: Text('RuPay')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedCardType = value!;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select card type';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Card Number
                TextFormField(
                  controller: _cardNumberController,
                  decoration: InputDecoration(
                    labelText: 'Card Number',
                    border: const OutlineInputBorder(),
                    prefixIcon: _getCardIcon(_selectedCardType),
                    hintText: '1234 5678 9012 3456',
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 19,
                  enabled: !_isEditing,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Card number is required';
                    }
                    if (!_isEditing && value.replaceAll(' ', '').length < 13) {
                      return 'Please enter a valid card number';
                    }
                    return null;
                  },
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(19),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Card Holder Name
                TextFormField(
                  controller: _cardHolderNameController,
                  decoration: const InputDecoration(
                    labelText: 'Card Holder Name',
                    border: OutlineInputBorder(),
                    hintText: 'John Doe',
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Card holder name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Expiry Date and CVV Row
                Row(
                  children: [
                    // Expiry Month
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _expiryMonthController.text.isEmpty ? null : _expiryMonthController.text,
                        decoration: const InputDecoration(
                          labelText: 'Month',
                          border: OutlineInputBorder(),
                        ),
                        items: _months.map((month) => 
                          DropdownMenuItem(value: month, child: Text(month))
                        ).toList(),
                        onChanged: (value) {
                          setState(() {
                            _expiryMonthController.text = value!;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Month is required';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    // Expiry Year
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _expiryYearController.text.isEmpty ? null : _expiryYearController.text,
                        decoration: const InputDecoration(
                          labelText: 'Year',
                          border: OutlineInputBorder(),
                        ),
                        items: _years.map((year) => 
                          DropdownMenuItem(value: year, child: Text(year))
                        ).toList(),
                        onChanged: (value) {
                          setState(() {
                            _expiryYearController.text = value!;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Year is required';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    // CVV
                    Expanded(
                      child: TextFormField(
                        controller: _cvvController,
                        decoration: const InputDecoration(
                          labelText: 'CVV',
                          border: OutlineInputBorder(),
                          hintText: '123',
                        ),
                        keyboardType: TextInputType.number,
                        maxLength: 4,
                        enabled: !_isEditing,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'CVV is required';
                          }
                          if (!_isEditing && value.length < 3) {
                            return 'Please enter valid CVV';
                          }
                          return null;
                        },
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(4),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Set as Default Checkbox
                CheckboxListTile(
                  title: const Text('Set as default payment method'),
                  value: _isDefault,
                  onChanged: (value) {
                    setState(() {
                      _isDefault = value ?? false;
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _savePaymentMethod,
            child: Text(_isEditing ? 'Update' : 'Add'),
          ),
        ],
      ),
    );
  }

  Icon _getCardIcon(String cardType) {
    switch (cardType) {
      case 'visa':
        return const Icon(Icons.credit_card, color: Colors.blue);
      case 'mastercard':
        return const Icon(Icons.credit_card, color: Colors.orange);
      case 'amex':
        return const Icon(Icons.credit_card, color: Colors.green);
      case 'discover':
        return const Icon(Icons.credit_card, color: Colors.red);
      case 'rupay':
        return const Icon(Icons.credit_card, color: Colors.indigo);
      default:
        return const Icon(Icons.credit_card);
    }
  }

  Future<void> _savePaymentMethod() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final auth = context.read<AuthService>();
      
      // Generate a mock card number for demo purposes
      final lastFourDigits = _isEditing ? 
        _cardNumberController.text.split(' ').last :
        _cardNumberController.text.replaceAll(' ', '').substring(_cardNumberController.text.replaceAll(' ', '').length - 4);
      
      final newPaymentMethod = PaymentMethod(
        id: _editingPaymentMethodId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        type: _selectedCardType,
        lastFourDigits: lastFourDigits,
        cardHolderName: _cardHolderNameController.text.trim(),
        expiryDate: '${_expiryMonthController.text}/${_expiryYearController.text}',
        isDefault: _isDefault,
      );

      if (_isEditing) {
        await auth.updatePaymentMethod(newPaymentMethod);
        ErrorToast.showSuccess(
          context,
          message: 'Payment method updated successfully!',
        );
      } else {
        await auth.addPaymentMethod(newPaymentMethod);
        ErrorToast.showSuccess(
          context,
          message: 'Payment method added successfully!',
        );
      }

      Navigator.of(context).pop();
      setState(() {});
    } catch (e) {
      ErrorToast.show(
        context,
        message: 'Failed to ${_isEditing ? 'update' : 'add'} payment method: ${e.toString()}',
      );
    }
  }

  Future<void> _deletePaymentMethod(PaymentMethod paymentMethod) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Payment Method'),
        content: Text(
          'Are you sure you want to delete this payment method?\n\n'
          '${paymentMethod.type.toUpperCase()} •••• ${paymentMethod.lastFourDigits}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final auth = context.read<AuthService>();
        await auth.removePaymentMethod(paymentMethod.id);
        ErrorToast.showSuccess(
          context,
          message: 'Payment method deleted successfully!',
        );
        setState(() {});
      } catch (e) {
        ErrorToast.show(
          context,
          message: 'Failed to delete payment method: ${e.toString()}',
        );
      }
    }
  }

  Future<void> _setDefaultPaymentMethod(PaymentMethod paymentMethod) async {
    try {
      final auth = context.read<AuthService>();
      final updatedPaymentMethod = paymentMethod.copyWith(isDefault: true);
      await auth.updatePaymentMethod(updatedPaymentMethod);
      ErrorToast.showSuccess(
        context,
        message: 'Default payment method updated!',
      );
      setState(() {});
    } catch (e) {
      ErrorToast.show(
        context,
        message: 'Failed to update default payment method: ${e.toString()}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Payment Methods'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditPaymentMethodDialog(),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        child: const Icon(Icons.add),
      ),
      body: Consumer<AuthService>(
        builder: (context, auth, child) {
          final paymentMethods = auth.userModel?.paymentMethods ?? [];

          if (paymentMethods.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.credit_card_off_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No payment methods yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add your first payment method to get started',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _showAddEditPaymentMethodDialog(),
                    icon: const Icon(Icons.add_card),
                    label: const Text('Add Payment Method'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: paymentMethods.length,
            itemBuilder: (context, index) {
              final paymentMethod = paymentMethods[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: paymentMethod.isDefault
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.surfaceVariant,
                    child: Icon(
                      paymentMethod.isDefault ? Icons.star : _getCardIcon(paymentMethod.type).icon,
                      color: paymentMethod.isDefault
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  title: Text(
                    paymentMethod.isDefault ? 'Default Payment Method' : '${paymentMethod.type.toUpperCase()} Card',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '•••• ${paymentMethod.lastFourDigits}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                      Text(
                        paymentMethod.cardHolderName,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                      Text(
                        'Expires: ${paymentMethod.expiryDate}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                      if (paymentMethod.isDefault)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
        child: Text(
                            'Default',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          _showAddEditPaymentMethodDialog(paymentMethod);
                          break;
                        case 'delete':
                          _deletePaymentMethod(paymentMethod);
                          break;
                        case 'default':
                          if (!paymentMethod.isDefault) {
                            _setDefaultPaymentMethod(paymentMethod);
                          }
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      if (!paymentMethod.isDefault)
                        const PopupMenuItem(
                          value: 'default',
                          child: Row(
                            children: [
                              Icon(Icons.star_outline),
                              SizedBox(width: 8),
                              Text('Set as Default'),
                            ],
                          ),
                        ),
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
