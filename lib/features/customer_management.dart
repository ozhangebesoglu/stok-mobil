import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../models/customer.dart';
import '../providers/customer_provider.dart';
import '../widgets/custom_text_field.dart';
import 'customer_management/widgets/customer_history_dialog.dart';
import 'customer_management/widgets/payment_dialog.dart';
import 'customer_management/tabs/customer_list_tab.dart';

class CustomerManagementPage extends StatefulWidget {
  const CustomerManagementPage({super.key});

  @override
  State<CustomerManagementPage> createState() => _CustomerManagementPageState();
}

class _CustomerManagementPageState extends State<CustomerManagementPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _balanceController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CustomerProvider>(context, listen: false).loadCustomers();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  void _showAddCustomerDialog(BuildContext context) {
    // Formun ilk açılışında değerleri temizle
    _nameController.clear();
    _phoneController.clear();
    _addressController.clear();
    _balanceController.text = '0';

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.person_add, color: Colors.blue),
                SizedBox(width: 10),
                Text('Yeni Müşteri Ekle'),
              ],
            ),
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
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('İptal'),
              ),
              ElevatedButton(
                onPressed: _addCustomer,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.save, size: 16),
                    SizedBox(width: 8),
                    Text('Kaydet'),
                  ],
                ),
              ),
            ],
          ),
    );
  }

  void _addCustomer() {
    if (_formKey.currentState!.validate()) {
      try {
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

        // Success feedback
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8.w),
                Text('Müşteri başarıyla eklendi'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 10),
                Text('Müşteri eklenirken hata oluştu: $e'),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  // Müşteri işlem geçmişi
  void _showCustomerHistoryDialog(Customer customer) {
    showDialog(
      context: context,
      builder: (context) => CustomerHistoryDialog(customer: customer),
    );
  }

  // Müşteri için ödeme/borç dialogu
  void _showPaymentDialog(Customer customer, BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => PaymentDialog(customer: customer),
    );
  }

  // Müşteri silme işlevi
  void _showDeleteCustomerDialog(Customer customer) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.warning, color: Colors.red),
                SizedBox(width: 10),
                Text('Müşteri Silme Onayı'),
              ],
            ),
            content: RichText(
              text: TextSpan(
                style: TextStyle(color: Colors.black, fontSize: 16),
                children: [
                  TextSpan(text: 'Müşteri: '),
                  TextSpan(
                    text: customer.name,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: ' silinecek.'),
                  if (customer.balance > 0)
                    TextSpan(
                      text:
                          '\n\nDikkat: Bu müşterinin ${customer.balance.toStringAsFixed(2)} ₺ bakiyesi bulunuyor!',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('İptal'),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    await Provider.of<CustomerProvider>(
                      context,
                      listen: false,
                    ).deleteCustomer(customer.id!);

                    if (context.mounted) {
                      Navigator.of(context).pop();

                      // Success feedback
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.white),
                              SizedBox(width: 8.w),
                              Text('Müşteri başarıyla silindi'),
                            ],
                          ),
                          backgroundColor: Colors.green,
                          behavior: SnackBarBehavior.floating,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              Icon(Icons.error, color: Colors.white),
                              SizedBox(width: 10),
                              Text('Müşteri silinirken hata oluştu: $e'),
                            ],
                          ),
                          backgroundColor: Colors.red,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: Text('Sil'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final customerProvider = Provider.of<CustomerProvider>(context);
    final filteredCustomers =
        customerProvider.customers
            .where(
              (customer) => customer.name.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ),
            )
            .toList();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Müşteri & Borç Takibi',
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(CupertinoIcons.back, size: 24.w),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: CustomerListTab(
        customers: filteredCustomers,
        onSearchChanged: (query) => setState(() => _searchQuery = query),
        onShowCustomerHistory: _showCustomerHistoryDialog,
        onShowPaymentDialog:
            (customer) => _showPaymentDialog(customer, context),
        onShowDeleteDialog: _showDeleteCustomerDialog,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddCustomerDialog(context),
        backgroundColor: Colors.red,
        tooltip: 'Müşteri Ekle',
        child: Icon(Icons.person_add, size: 24.w),
      ),
    );
  }
}
