import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/customer.dart';
import '../../../providers/customer_provider.dart';
import '../../../widgets/custom_text_field.dart';

class AddCustomerDialog extends StatefulWidget {
  const AddCustomerDialog({super.key});

  @override
  State<AddCustomerDialog> createState() => _AddCustomerDialogState();
}

class _AddCustomerDialogState extends State<AddCustomerDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _balanceController = TextEditingController(text: '0');

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  void _addCustomer() {
    if (_formKey.currentState!.validate()) {
      final customer = Customer(
        name: _nameController.text,
        phone: _phoneController.text,
        address: _addressController.text,
        balance: double.tryParse(_balanceController.text) ?? 0,
      );

      Provider.of<CustomerProvider>(
        context,
        listen: false,
      ).addCustomer(customer);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Yeni Müşteri Ekle'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomTextField(
                labelText: 'Müşteri Adı',
                controller: _nameController,
                prefixIcon: Icons.person,
                isRequired: true,
              ),
              CustomTextField(
                labelText: 'Telefon',
                controller: _phoneController,
                prefixIcon: Icons.phone,
                keyboardType: TextInputType.phone,
              ),
              CustomTextField(
                labelText: 'Adres',
                controller: _addressController,
                prefixIcon: Icons.home,
              ),
              CustomTextField(
                labelText: 'Başlangıç Borç',
                controller: _balanceController,
                prefixIcon: Icons.account_balance_wallet,
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('İptal'),
        ),
        ElevatedButton(onPressed: _addCustomer, child: const Text('Kaydet')),
      ],
    );
  }
}
