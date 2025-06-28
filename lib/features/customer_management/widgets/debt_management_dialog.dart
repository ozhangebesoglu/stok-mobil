import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../../models/customer.dart';
import '../../../services/database/database_helper.dart';
import '../../../core/utils/date_formatter.dart';

enum DebtManagementState { loading, loaded, error }

class DebtManagementDialog extends StatefulWidget {
  final Customer customer;
  final VoidCallback? onDebtUpdated;

  const DebtManagementDialog({
    super.key,
    required this.customer,
    this.onDebtUpdated,
  });

  @override
  State<DebtManagementDialog> createState() => _DebtManagementDialogState();
}

class _DebtManagementDialogState extends State<DebtManagementDialog> {
  // State management
  DebtManagementState _state = DebtManagementState.loading;
  String? _errorMessage;

  // Data
  List<Map<String, dynamic>> _unpaidSales = [];
  double _totalDebt = 0.0;
  double _selectedDebtAmount = 0.0;

  // Form controllers
  final _paymentAmountController = TextEditingController();
  final _notesController = TextEditingController();

  // Selected items for bulk operations
  final Set<int> _selectedSaleIds = {};
  bool _isSelectMode = false;

  @override
  void initState() {
    super.initState();
    _loadCustomerDebts();
  }

  @override
  void dispose() {
    _paymentAmountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomerDebts() async {
    try {
      setState(() {
        _state = DebtManagementState.loading;
        _errorMessage = null;
      });

      final db = await DatabaseHelper().database;

      // Get unpaid sales for this customer
      final unpaidSales = await db.query(
        'sales',
        where: 'customerId = ? AND isPaid = 0',
        whereArgs: [widget.customer.id],
        orderBy: 'date DESC',
      );

      double totalDebt = 0.0;
      for (final sale in unpaidSales) {
        totalDebt += (sale['amount'] as num).toDouble();
      }

      setState(() {
        _unpaidSales = unpaidSales;
        _totalDebt = totalDebt;
        _state = DebtManagementState.loaded;
      });
    } catch (e) {
      setState(() {
        _state = DebtManagementState.error;
        _errorMessage = 'Borç bilgileri yüklenirken hata: $e';
      });
    }
  }

  void _toggleSelectMode() {
    setState(() {
      _isSelectMode = !_isSelectMode;
      if (!_isSelectMode) {
        _selectedSaleIds.clear();
        _selectedDebtAmount = 0.0;
      }
    });
  }

  void _toggleSaleSelection(int saleId, double amount) {
    setState(() {
      if (_selectedSaleIds.contains(saleId)) {
        _selectedSaleIds.remove(saleId);
        _selectedDebtAmount -= amount;
      } else {
        _selectedSaleIds.add(saleId);
        _selectedDebtAmount += amount;
      }
    });
  }

  void _selectAllDebts() {
    setState(() {
      if (_selectedSaleIds.length == _unpaidSales.length) {
        // Deselect all
        _selectedSaleIds.clear();
        _selectedDebtAmount = 0.0;
      } else {
        // Select all
        _selectedSaleIds.clear();
        _selectedDebtAmount = 0.0;
        for (final sale in _unpaidSales) {
          _selectedSaleIds.add(sale['id'] as int);
          _selectedDebtAmount += (sale['amount'] as num).toDouble();
        }
      }
    });
  }

  Future<void> _processPayment(double paymentAmount, String notes) async {
    try {
      final db = await DatabaseHelper().database;

      if (_selectedSaleIds.isEmpty) {
        throw Exception('Ödeme yapılacak borç seçilmedi');
      }

      await db.transaction((txn) async {
        // Mark selected sales as paid
        for (final saleId in _selectedSaleIds) {
          await txn.update(
            'sales',
            {'isPaid': 1},
            where: 'id = ?',
            whereArgs: [saleId],
          );
        }

        // Add payment record
        await txn.insert('customer_payments', {
          'customerId': widget.customer.id,
          'amount': paymentAmount,
          'date': DateFormatter.nowForDatabase(),
          'notes': notes,
          'saleIds': _selectedSaleIds.join(','),
        });

        // Update customer balance
        await txn.update(
          'customers',
          {'balance': widget.customer.balance - paymentAmount},
          where: 'id = ?',
          whereArgs: [widget.customer.id],
        );
      });

      // Success feedback
      _showSuccessSnackBar('Ödeme başarıyla kaydedildi');

      // Refresh data
      await _loadCustomerDebts();

      // Reset selection
      setState(() {
        _isSelectMode = false;
        _selectedSaleIds.clear();
        _selectedDebtAmount = 0.0;
        _paymentAmountController.clear();
        _notesController.clear();
      });

      // Notify parent
      widget.onDebtUpdated?.call();
    } catch (e) {
      _showErrorSnackBar('Ödeme işlenirken hata: $e');
    }
  }

  Future<void> _deleteIndividualDebt(int saleId, double amount) async {
    try {
      final db = await DatabaseHelper().database;

      await db.transaction((txn) async {
        // Delete the sale
        await txn.delete('sales', where: 'id = ?', whereArgs: [saleId]);

        // Update customer balance
        await txn.update(
          'customers',
          {'balance': widget.customer.balance - amount},
          where: 'id = ?',
          whereArgs: [widget.customer.id],
        );
      });

      _showSuccessSnackBar('Borç kaydı silindi');
      await _loadCustomerDebts();
      widget.onDebtUpdated?.call();
    } catch (e) {
      _showErrorSnackBar('Borç silinirken hata: $e');
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.95,
        height: MediaQuery.of(context).size.height * 0.85,
        padding: EdgeInsets.all(24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(theme),
            SizedBox(height: 24.h),
            if (_state == DebtManagementState.loaded && _unpaidSales.isNotEmpty)
              _buildDebtSummary(theme),
            SizedBox(height: 16.h),
            Expanded(child: _buildContent(theme)),
            if (_state == DebtManagementState.loaded &&
                _unpaidSales.isNotEmpty) ...[
              SizedBox(height: 16.h),
              _buildActionButtons(theme),
            ],
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
            color: theme.colorScheme.errorContainer,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Icon(
            Icons.account_balance_wallet,
            color: theme.colorScheme.onErrorContainer,
            size: 24.w,
          ),
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Borç Yönetimi',
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
        if (_unpaidSales.isNotEmpty) ...[
          IconButton(
            onPressed: _toggleSelectMode,
            icon: Icon(_isSelectMode ? Icons.close : Icons.checklist),
            tooltip: _isSelectMode ? 'Seçimi İptal Et' : 'Çoklu Seçim',
          ),
          IconButton(
            onPressed: _loadCustomerDebts,
            icon: Icon(Icons.refresh),
            tooltip: 'Yenile',
          ),
        ],
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(Icons.close),
          tooltip: 'Kapat',
        ),
      ],
    );
  }

  Widget _buildDebtSummary(ThemeData theme) {
    final formatter = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Toplam Borç',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    formatter.format(_totalDebt),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ),
            if (_isSelectMode && _selectedDebtAmount > 0) ...[
              Container(
                width: 1.w,
                height: 40.h,
                color: theme.colorScheme.outline,
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Seçilen Tutar',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      formatter.format(_selectedDebtAmount),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
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

  Widget _buildContent(ThemeData theme) {
    switch (_state) {
      case DebtManagementState.loading:
        return _buildLoadingState(theme);
      case DebtManagementState.error:
        return _buildErrorState(theme);
      case DebtManagementState.loaded:
        return _buildLoadedState(theme);
    }
  }

  Widget _buildLoadingState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16.h),
          Text(
            'Borç bilgileri yükleniyor...',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48.w, color: theme.colorScheme.error),
          SizedBox(height: 16.h),
          Text(
            'Bir hata oluştu',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            _errorMessage ?? 'Bilinmeyen hata',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16.h),
          FilledButton.icon(
            onPressed: _loadCustomerDebts,
            icon: Icon(Icons.refresh),
            label: Text('Tekrar Dene'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadedState(ThemeData theme) {
    if (_unpaidSales.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 48.w, color: Colors.green),
            SizedBox(height: 16.h),
            Text(
              'Borç Yok!',
              style: theme.textTheme.titleLarge?.copyWith(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Bu müşterinin ödenmemiş borcu bulunmuyor.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        if (_isSelectMode) _buildSelectAllButton(theme),
        Expanded(
          child: ListView.builder(
            itemCount: _unpaidSales.length,
            itemBuilder: (context, index) {
              final sale = _unpaidSales[index];
              return _buildDebtCard(sale, theme);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSelectAllButton(ThemeData theme) {
    final allSelected = _selectedSaleIds.length == _unpaidSales.length;

    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: OutlinedButton.icon(
        onPressed: _selectAllDebts,
        icon: Icon(allSelected ? Icons.deselect : Icons.select_all),
        label: Text(allSelected ? 'Tümünü Kaldır' : 'Tümünü Seç'),
        style: OutlinedButton.styleFrom(
          minimumSize: Size(double.infinity, 40.h),
        ),
      ),
    );
  }

  Widget _buildDebtCard(Map<String, dynamic> sale, ThemeData theme) {
    final saleId = sale['id'] as int;
    final amount = (sale['amount'] as num).toDouble();
    final isSelected = _selectedSaleIds.contains(saleId);
    final displayDate = DateFormatter.formatDisplayDate(sale['date']);

    return Card(
      margin: EdgeInsets.only(bottom: 8.h),
      child: InkWell(
        onTap:
            _isSelectMode ? () => _toggleSaleSelection(saleId, amount) : null,
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.r),
            border:
                _isSelectMode && isSelected
                    ? Border.all(color: theme.colorScheme.primary, width: 2.w)
                    : null,
          ),
          child: Row(
            children: [
              if (_isSelectMode) ...[
                Checkbox(
                  value: isSelected,
                  onChanged: (value) => _toggleSaleSelection(saleId, amount),
                ),
                SizedBox(width: 12.w),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sale['productName'] ?? 'Ürün belirtilmedi',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      displayDate,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (sale['notes'] != null &&
                        sale['notes'].toString().isNotEmpty) ...[
                      SizedBox(height: 4.h),
                      Text(
                        sale['notes'].toString(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
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
                      color: Colors.red,
                    ),
                  ),
                  if (!_isSelectMode) ...[
                    SizedBox(height: 8.h),
                    IconButton(
                      onPressed: () => _showDeleteConfirmation(saleId, amount),
                      icon: Icon(Icons.delete_outline),
                      iconSize: 20.w,
                      color: Colors.red,
                      tooltip: 'Borcu Sil',
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    return Column(
      children: [
        if (_isSelectMode && _selectedSaleIds.isNotEmpty) ...[
          _buildPaymentForm(theme),
          SizedBox(height: 16.h),
        ],
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(Icons.close),
                label: Text('Kapat'),
              ),
            ),
            if (_isSelectMode && _selectedSaleIds.isNotEmpty) ...[
              SizedBox(width: 16.w),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _processSelectedPayment,
                  icon: Icon(Icons.payment),
                  label: Text('Ödeme Al'),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildPaymentForm(ThemeData theme) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ödeme Bilgileri',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _paymentAmountController,
                    decoration: InputDecoration(
                      labelText: 'Ödeme Tutarı',
                      prefixIcon: Icon(Icons.attach_money),
                      suffixText: '₺',
                      border: OutlineInputBorder(),
                      hintText: _selectedDebtAmount.toStringAsFixed(2),
                    ),
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                ),
                SizedBox(width: 16.w),
                FilledButton.tonal(
                  onPressed: () {
                    _paymentAmountController.text = _selectedDebtAmount
                        .toStringAsFixed(2);
                  },
                  child: Text('Tam Ödeme'),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            TextFormField(
              controller: _notesController,
              decoration: InputDecoration(
                labelText: 'Notlar (Opsiyonel)',
                prefixIcon: Icon(Icons.note),
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  void _processSelectedPayment() {
    final paymentText = _paymentAmountController.text.trim();
    if (paymentText.isEmpty) {
      _showErrorSnackBar('Ödeme tutarı girin');
      return;
    }

    final paymentAmount = double.tryParse(paymentText);
    if (paymentAmount == null || paymentAmount <= 0) {
      _showErrorSnackBar('Geçerli bir ödeme tutarı girin');
      return;
    }

    if (paymentAmount > _selectedDebtAmount) {
      _showErrorSnackBar('Ödeme tutarı seçilen borç tutarından fazla olamaz');
      return;
    }

    _processPayment(paymentAmount, _notesController.text.trim());
  }

  void _showDeleteConfirmation(int saleId, double amount) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Borcu Sil'),
            content: Text(
              'Bu borç kaydını silmek istediğinize emin misiniz?\n\n'
              'Tutar: ${amount.toStringAsFixed(2)} ₺\n\n'
              'Bu işlem geri alınamaz.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('İptal'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  _deleteIndividualDebt(saleId, amount);
                },
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                child: Text('Sil'),
              ),
            ],
          ),
    );
  }
}
