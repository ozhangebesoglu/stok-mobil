import 'package:flutter/material.dart';
import '../../../models/customer.dart';

class CustomerListTab extends StatelessWidget {
  final List<Customer> customers;
  final ValueChanged<String> onSearchChanged;
  final void Function(Customer) onShowCustomerHistory;
  final void Function(Customer) onShowPaymentDialog;
  final void Function(Customer) onShowDeleteDialog;

  const CustomerListTab({
    super.key,
    required this.customers,
    required this.onSearchChanged,
    required this.onShowCustomerHistory,
    required this.onShowPaymentDialog,
    required this.onShowDeleteDialog,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            decoration: const InputDecoration(
              labelText: 'Müşteri Ara',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: onSearchChanged,
          ),
        ),
        Expanded(
          child:
              customers.isEmpty
                  ? const Center(child: Text('Müşteri bulunamadı.'))
                  : ListView.builder(
                    itemCount: customers.length,
                    itemBuilder: (context, index) {
                      final customer = customers[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        child: ListTile(
                          title: Text(customer.name),
                          subtitle: Text(
                            'Bakiye: ${customer.balance.toStringAsFixed(2)} ₺',
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'history') {
                                onShowCustomerHistory(customer);
                              } else if (value == 'payment') {
                                onShowPaymentDialog(customer);
                              } else if (value == 'delete') {
                                onShowDeleteDialog(customer);
                              }
                            },
                            itemBuilder:
                                (context) => [
                                  const PopupMenuItem(
                                    value: 'history',
                                    child: Text('İşlem Geçmişi'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'payment',
                                    child: Text('Ödeme/Borç'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Sil'),
                                  ),
                                ],
                          ),
                        ),
                      );
                    },
                  ),
        ),
      ],
    );
  }
}
