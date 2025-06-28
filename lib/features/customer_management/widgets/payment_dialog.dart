import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../models/customer.dart';
import '../../../models/sale.dart';
import '../../../providers/customer_provider.dart';
import '../../../providers/sales_provider.dart';
import '../../../services/database/database_helper.dart';
import '../../../core/utils/logger.dart';

class PaymentDialog extends StatefulWidget {
  final Customer customer;
  const PaymentDialog({super.key, required this.customer});

  @override
  State<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  final _paymentController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isDebt = false; // false = Ödeme, true = Borç
  bool _isSubmitting = false;

  void _clearForm() {
    _paymentController.clear();
    _notesController.clear();
    setState(() {
      _isDebt = false;
    });
  }

  void _submitPayment() async {
    final amount = double.tryParse(_paymentController.text);
    if (amount == null || amount <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8.w),
                Text('Lütfen geçerli bir tutar girin.'),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final customerProvider = Provider.of<CustomerProvider>(
        context,
        listen: false,
      );
      final salesProvider = Provider.of<SalesProvider>(context, listen: false);

      final updateAmount = _isDebt ? amount : -amount;
      final notes =
          _notesController.text.isNotEmpty
              ? _notesController.text
              : (_isDebt ? 'Borç eklendi' : 'Ödeme alındı');

      Logger.debug('Payment submission started:');
      Logger.debug('Customer ID: ${widget.customer.id}');
      Logger.debug('Customer Name: ${widget.customer.name}');
      Logger.debug('Current Balance: ${widget.customer.balance}');
      Logger.debug('Update Amount: $updateAmount');
      Logger.debug('Is Debt: $_isDebt');

      // Atomic transaction: Update customer balance and add sale record
      final dbHelper = DatabaseHelper();
      await dbHelper.executeInTransaction((txn) async {
        // 1. Update customer balance
        await customerProvider.updateBalance(widget.customer.id!, updateAmount);

        // 2. Create sale record
        final saleRecord = Sale(
          customerId: widget.customer.id,
          customerName: widget.customer.name,
          amount: amount,
          date: DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
          isPaid: !_isDebt, // If debt, then not paid. If payment, then paid.
          productName: _isDebt ? 'Borç Kaydı' : 'Ödeme Alındı',
          quantity: 1,
          unit: 'işlem',
          unitPrice: amount,
          notes: notes,
          saleType: 'customer',
        );

        await salesProvider.addSale(saleRecord);

        Logger.info('Transaction completed successfully');
      });

      // Success - update UI
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8.w),
                Text(
                  _isDebt ? 'Borç başarıyla eklendi' : 'Ödeme başarıyla alındı',
                ),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      // Clear form but keep dialog open
      _clearForm();

      // Refresh customer data to reflect changes
      await customerProvider.loadCustomers();

      Logger.info('Customer data refreshed');
    } catch (e) {
      Logger.error('Payment submission error', e);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8.w),
                Expanded(child: Text('İşlem sırasında hata oluştu: $e')),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Container(
        width: double.maxFinite,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Başlık
              Row(
                children: [
                  Icon(
                    CupertinoIcons.money_dollar_circle,
                    color: colorScheme.primary,
                    size: 28.w,
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      'Ödeme/Borç: ${widget.customer.name}',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, size: 24.w),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),

              SizedBox(height: 16.h),

              // Mevcut bakiye kartı
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color:
                      widget.customer.balance > 0
                          ? colorScheme.errorContainer.withAlpha(77)
                          : colorScheme.primaryContainer.withAlpha(77),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color:
                        widget.customer.balance > 0
                            ? colorScheme.error.withAlpha(128)
                            : colorScheme.primary.withAlpha(128),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'Mevcut Bakiye',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      '${widget.customer.balance.toStringAsFixed(2)} ₺',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color:
                            widget.customer.balance > 0
                                ? colorScheme.error
                                : colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 20.h),

              // Tutar girişi
              TextField(
                controller: _paymentController,
                decoration: InputDecoration(
                  labelText: 'Tutar',
                  hintText: '0.00',
                  prefixIcon: Icon(Icons.attach_money, size: 20.w),
                  suffixText: '₺',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),

              SizedBox(height: 16.h),

              // Açıklama girişi
              TextField(
                controller: _notesController,
                decoration: InputDecoration(
                  labelText: 'Açıklama (Opsiyonel)',
                  hintText: 'İşlem açıklaması...',
                  prefixIcon: Icon(Icons.note_alt, size: 20.w),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                maxLines: 2,
              ),

              SizedBox(height: 20.h),

              // İşlem tipi seçimi
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: colorScheme.outline.withAlpha(128)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: RadioListTile<bool>(
                        title: Row(
                          children: [
                            Icon(
                              CupertinoIcons.money_dollar,
                              color: colorScheme.primary,
                              size: 20.w,
                            ),
                            SizedBox(width: 4.w),
                            Expanded(
                              child: Text(
                                'Ödeme Al',
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                        value: false,
                        groupValue: _isDebt,
                        onChanged: (val) => setState(() => _isDebt = val!),
                        activeColor: colorScheme.primary,
                        contentPadding: EdgeInsets.symmetric(horizontal: 8.w),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 60.h,
                      color: colorScheme.outline.withAlpha(77),
                    ),
                    Expanded(
                      child: RadioListTile<bool>(
                        title: Row(
                          children: [
                            Icon(
                              CupertinoIcons.creditcard,
                              color: colorScheme.error,
                              size: 20.w,
                            ),
                            SizedBox(width: 4.w),
                            Expanded(
                              child: Text(
                                'Borç Ekle',
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                        value: true,
                        groupValue: _isDebt,
                        onChanged: (val) => setState(() => _isDebt = val!),
                        activeColor: colorScheme.error,
                        contentPadding: EdgeInsets.symmetric(horizontal: 8.w),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24.h),

              // Butonlar
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _clearForm,
                      child: Text('Temizle'),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitPayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _isDebt ? colorScheme.error : colorScheme.primary,
                        foregroundColor:
                            _isDebt
                                ? colorScheme.onError
                                : colorScheme.onPrimary,
                      ),
                      child:
                          _isSubmitting
                              ? SizedBox(
                                height: 20.h,
                                width: 20.w,
                                child: CircularProgressIndicator(
                                  color: colorScheme.onPrimary,
                                  strokeWidth: 2,
                                ),
                              )
                              : Text(
                                _isDebt ? 'Borç Ekle' : 'Ödeme Al',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 12.h),

              // Bilgi notu
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withAlpha(77),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: colorScheme.primary,
                      size: 16.w,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        'İşlem sonrası başka işlem yapmak için form temizlenecek, dialog açık kalacak.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
