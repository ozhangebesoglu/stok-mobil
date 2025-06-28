import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../models/customer.dart';
import '../../../services/database/database_helper.dart';
import '../../../core/utils/date_formatter.dart';

class CustomerHistoryDialog extends StatefulWidget {
  final Customer customer;

  const CustomerHistoryDialog({super.key, required this.customer});

  @override
  State<CustomerHistoryDialog> createState() => _CustomerHistoryDialogState();
}

class _CustomerHistoryDialogState extends State<CustomerHistoryDialog> {
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCustomerHistory();
  }

  Future<void> _loadCustomerHistory() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final transactions = await _loadCustomerTransactions(widget.customer.id!);

      setState(() {
        _transactions = transactions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'İşlem geçmişi yüklenirken hata: $e';
      });
    }
  }

  Future<List<Map<String, dynamic>>> _loadCustomerTransactions(
    int customerId,
  ) async {
    final db = await DatabaseHelper().database;

    // Satışları ve ödemeleri birleştirerek tüm işlem geçmişini alalım
    final sales = await db.rawQuery(
      '''
      SELECT 
        'sale' as type,
        productName,
        amount,
        date,
        isPaid,
        notes
      FROM sales 
      WHERE customerId = ?
      ORDER BY date DESC
    ''',
      [customerId],
    );

    return sales;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: EdgeInsets.all(24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(theme),
            SizedBox(height: 24.h),
            Expanded(child: _buildContent(theme)),
            SizedBox(height: 16.h),
            _buildCloseButton(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Icon(
            Icons.history,
            color: theme.colorScheme.onPrimaryContainer,
            size: 24.w,
          ),
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'İşlem Geçmişi',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                widget.customer.name,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: _loadCustomerHistory,
          icon: Icon(Icons.refresh),
          tooltip: 'Yenile',
        ),
      ],
    );
  }

  Widget _buildContent(ThemeData theme) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16.h),
            Text(
              'İşlem geçmişi yükleniyor...',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48.w,
              color: theme.colorScheme.error,
            ),
            SizedBox(height: 16.h),
            Text(
              'Bir hata oluştu',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              _errorMessage!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.h),
            FilledButton.icon(
              onPressed: _loadCustomerHistory,
              icon: Icon(Icons.refresh),
              label: Text('Tekrar Dene'),
            ),
          ],
        ),
      );
    }

    if (_transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 48.w,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            SizedBox(height: 16.h),
            Text(
              'Henüz işlem geçmişi yok',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Bu müşteri için henüz satış kaydı bulunmuyor.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _transactions.length,
      itemBuilder: (context, index) {
        final transaction = _transactions[index];
        return _buildTransactionCard(transaction, theme);
      },
    );
  }

  Widget _buildTransactionCard(
    Map<String, dynamic> transaction,
    ThemeData theme,
  ) {
    final isPaid = transaction['isPaid'] == 1;
    final amount = (transaction['amount'] as num).toDouble();

    // Clean date formatting - single line display
    final displayDate = DateFormatter.formatDisplayDate(transaction['date']);
    final relativeTime = DateFormatter.getRelativeTime(transaction['date']);

    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color:
                        isPaid
                            ? Colors.green.withAlpha(25)
                            : Colors.orange.withAlpha(25),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(
                    isPaid ? Icons.check_circle : Icons.schedule,
                    color: isPaid ? Colors.green : Colors.orange,
                    size: 20.w,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction['productName'] ?? 'Ürün belirtilmedi',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      // Single line date display - no more column issues
                      Text(
                        '$displayDate ($relativeTime)',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${amount.toStringAsFixed(2)} ₺',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isPaid ? Colors.green : Colors.orange,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 2.h,
                      ),
                      decoration: BoxDecoration(
                        color: isPaid ? Colors.green : Colors.orange,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Text(
                        isPaid ? 'Ödendi' : 'Borç',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Notes section if available
            if (transaction['notes'] != null &&
                transaction['notes'].toString().isNotEmpty) ...[
              SizedBox(height: 12.h),
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withAlpha(
                    77,
                  ),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.note_outlined,
                      size: 16.w,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        transaction['notes'].toString(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCloseButton(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: () => Navigator.of(context).pop(),
        icon: Icon(Icons.close),
        label: Text('Kapat'),
        style: FilledButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 16.h),
        ),
      ),
    );
  }
}
