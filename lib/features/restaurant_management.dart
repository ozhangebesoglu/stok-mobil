import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../services/database/database_helper.dart';
import '../models/sale.dart';
import '../providers/sales_provider.dart';
import '../main.dart';
import '../core/utils/date_formatter.dart';
import '../core/utils/logger.dart';

class RestaurantManagement extends StatefulWidget {
  const RestaurantManagement({super.key});

  @override
  State<RestaurantManagement> createState() => _RestaurantManagementState();
}

class _RestaurantManagementState extends State<RestaurantManagement>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Form controllers
  final _restaurantController = TextEditingController();
  final _productController = TextEditingController();
  final _quantityController = TextEditingController();
  final _unitPriceController = TextEditingController();
  final _notesController = TextEditingController();
  final _totalAmountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // State variables
  String _selectedUnit = 'kg';
  List<Map<String, dynamic>> _restaurantSales = [];
  bool _isLoading = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadRestaurantSales();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _restaurantController.dispose();
    _productController.dispose();
    _quantityController.dispose();
    _unitPriceController.dispose();
    _notesController.dispose();
    _totalAmountController.dispose();
    super.dispose();
  }

  Future<void> _loadRestaurantSales() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final db = await DatabaseHelper().database;
      final List<Map<String, dynamic>> results = await db.query(
        'restaurant_sales',
        orderBy: 'date DESC',
      );

      setState(() {
        _restaurantSales = results;
        _isLoading = false;
      });
    } catch (e) {
      Logger.error('Restoran satışları yüklenirken hata', e);
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Toplam tutar hesaplama
  void _calculateTotalAmount() {
    if (_quantityController.text.isNotEmpty &&
        _unitPriceController.text.isNotEmpty) {
      try {
        double quantity = double.parse(_quantityController.text);
        double unitPrice = double.parse(_unitPriceController.text);
        double totalAmount = quantity * unitPrice;
        _totalAmountController.text = totalAmount.toStringAsFixed(2);
      } catch (e) {
        _totalAmountController.text = '';
      }
    } else {
      _totalAmountController.text = '';
    }
  }

  // Restoran satışı ekle
  Future<void> _addRestaurantSale() async {
    // Form validation
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Additional validation
    if (_restaurantController.text.trim().isEmpty) {
      _showErrorSnackBar('Lütfen restoran adı girin');
      return;
    }

    if (_totalAmountController.text.trim().isEmpty) {
      _showErrorSnackBar('Lütfen toplam tutar girin');
      return;
    }

    double? totalAmount;
    try {
      totalAmount = double.parse(_totalAmountController.text.trim());
      if (totalAmount <= 0) {
        _showErrorSnackBar('Tutar sıfırdan büyük olmalıdır');
        return;
      }
    } catch (e) {
      _showErrorSnackBar('Geçerli bir tutar girin');
      return;
    }

    // Set loading state
    setState(() {
      _isSubmitting = true;
    });

    try {
      // Tarih formatı - DateFormatter kullanarak
      final formattedDate = DateFormatter.formatForDatabase(DateTime.now());

      // Veritabanına ekleme
      final db = await DatabaseHelper().database;
      final sale = {
        'restaurant': _restaurantController.text.trim(),
        'amount': totalAmount,
        'date': formattedDate,
        'productName':
            _productController.text.trim().isEmpty
                ? 'Ürün belirtilmedi'
                : _productController.text.trim(),
        'quantity':
            _quantityController.text.trim().isNotEmpty
                ? double.parse(_quantityController.text.trim())
                : null,
        'unit': _selectedUnit,
        'unitPrice':
            _unitPriceController.text.trim().isNotEmpty
                ? double.parse(_unitPriceController.text.trim())
                : null,
        'notes': _notesController.text.trim(),
      };

      await db.insert('restaurant_sales', sale);

      // SalesProvider'a da ekleyelim (istatistik için)
      final saleModel = Sale(
        customerName: 'Restoran: ${_restaurantController.text.trim()}',
        amount: totalAmount,
        date: formattedDate,
        isPaid: true,
        productName:
            _productController.text.trim().isEmpty
                ? 'Ürün belirtilmedi'
                : _productController.text.trim(),
        quantity:
            _quantityController.text.trim().isEmpty
                ? 1
                : double.parse(_quantityController.text.trim()),
        unit: _selectedUnit,
        unitPrice:
            _unitPriceController.text.trim().isEmpty
                ? 0
                : double.parse(_unitPriceController.text.trim()),
        notes: _notesController.text.trim(),
      );

      await Provider.of<SalesProvider>(
        context,
        listen: false,
      ).addSale(saleModel);

      // Clear form
      _clearForm();

      // Reload data
      await _loadRestaurantSales();

      // Switch to records tab to see the new entry
      _tabController.animateTo(1);

      // Success feedback
      _showSuccessSnackBar('Restoran satışı başarıyla eklendi');
    } catch (e) {
      Logger.error('Satış eklenirken hata', e);
      _showErrorSnackBar('Satış eklenirken bir hata oluştu: ${e.toString()}');
    } finally {
      // Reset loading state
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              CupertinoIcons.exclamationmark_triangle_fill,
              color: Colors.white,
            ),
            SizedBox(width: 8.w),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16.w),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(CupertinoIcons.checkmark_circle_fill, color: Colors.white),
            SizedBox(width: 8.w),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16.w),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
    );
  }

  // Restoran satışı sil
  Future<void> _deleteRestaurantSale(int id) async {
    try {
      final db = await DatabaseHelper().database;
      await db.delete('restaurant_sales', where: 'id = ?', whereArgs: [id]);

      // Listeyi yenile
      _loadRestaurantSales();

      // Success feedback - stay on same page instead of going home
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Satış başarıyla silindi'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // Restoran ödeme alma dialogu
  void _showPaymentDialog(String restaurantName) {
    final paymentController = TextEditingController();
    final paymentNotesController = TextEditingController();
    bool isDebt = false;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: Text('Ödeme/Borç Ekle: $restaurantName'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: paymentController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Tutar',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.money),
                        ),
                      ),
                      SizedBox(height: 10),
                      TextField(
                        controller: paymentNotesController,
                        decoration: InputDecoration(
                          labelText: 'Açıklama (Opsiyonel)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.note),
                        ),
                      ),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<bool>(
                              title: Text('Ödeme Al'),
                              value: false,
                              groupValue: isDebt,
                              onChanged: (value) {
                                setState(() {
                                  isDebt = value!;
                                });
                              },
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<bool>(
                              title: Text('Borç Ekle'),
                              value: true,
                              groupValue: isDebt,
                              onChanged: (value) {
                                setState(() {
                                  isDebt = value!;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('İptal'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        try {
                          if (paymentController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Lütfen tutar giriniz'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          final amount = double.parse(paymentController.text);
                          if (amount <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Tutar sıfırdan büyük olmalıdır'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          // Tarih formatı
                          final formattedDate = DateFormatter.formatForDatabase(
                            DateTime.now(),
                          );
                          final notes =
                              paymentNotesController.text.isNotEmpty
                                  ? paymentNotesController.text
                                  : (isDebt ? 'Borç eklendi' : 'Ödeme alındı');

                          // Veritabanı işlemleri
                          final db = await DatabaseHelper().database;

                          try {
                            // Veritabanına kayıt
                            final sale = {
                              'restaurant': restaurantName,
                              'amount': amount,
                              'date': formattedDate,
                              'productName':
                                  isDebt ? 'Borç Kaydı' : 'Ödeme Alındı',
                              'notes': notes,
                            };

                            await db.insert('restaurant_sales', sale);

                            // SalesProvider'a da ekleyelim (istatistik için)
                            final saleModel = Sale(
                              customerName: 'Restoran: $restaurantName',
                              amount: amount,
                              date: formattedDate,
                              isPaid: !isDebt,
                              productName:
                                  isDebt ? 'Borç Kaydı' : 'Ödeme Alındı',
                              quantity: 1,
                              unit: 'adet',
                              unitPrice: amount,
                              notes: notes,
                            );

                            await Provider.of<SalesProvider>(
                              context,
                              listen: false,
                            ).addSale(saleModel);

                            // Listeyi yenile
                            _loadRestaurantSales();

                            // Ana sayfadaki istatistikleri güncelle
                            HomePage.updateStatistics(context);

                            Navigator.of(context).pop();

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  isDebt ? 'Borç eklendi' : 'Ödeme alındı',
                                ),
                                backgroundColor:
                                    isDebt ? Colors.orange : Colors.green,
                              ),
                            );
                          } catch (e) {
                            Logger.error('İlk deneme başarısız', e);

                            // Alternatif yöntem - isPaid olmadan
                            final sale = {
                              'restaurant': restaurantName,
                              'amount': amount,
                              'date': formattedDate,
                              'productName':
                                  isDebt ? 'Borç Kaydı' : 'Ödeme Alındı',
                              'notes': notes,
                            };

                            await db.insert('restaurant_sales', sale);

                            // Listeyi yenile
                            _loadRestaurantSales();

                            // Ana sayfadaki istatistikleri güncelle
                            HomePage.updateStatistics(context);

                            Navigator.of(context).pop();

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  isDebt ? 'Borç eklendi' : 'Ödeme alındı',
                                ),
                                backgroundColor:
                                    isDebt ? Colors.orange : Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Hata: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      child: Text('Kaydet'),
                    ),
                  ],
                ),
          ),
    );
  }

  void _showRestaurantSaleOptions(Map<String, dynamic> sale) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder:
          (context) => Container(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Satış İşlemleri',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),

                // Sale details
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Restoran: ${sale['restaurant']}'),
                      Text('Ürün: ${sale['productName'] ?? 'Belirtilmedi'}'),
                      Text('Tutar: ${sale['amount']} ₺'),
                      Text(
                        'Tarih: ${DateFormatter.formatDisplayDate(sale['date'])}',
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 16),

                // Action buttons
                ListTile(
                  leading: Icon(Icons.payment, color: Colors.green),
                  title: Text('Ödeme/Borç Ekle'),
                  onTap: () {
                    Navigator.pop(context);
                    _showPaymentDialog(sale['restaurant']);
                  },
                ),

                ListTile(
                  leading: Icon(Icons.delete, color: Colors.red),
                  title: Text('Satışı Sil'),
                  onTap: () {
                    Navigator.pop(context);
                    _showDeleteConfirmation(sale);
                  },
                ),

                SizedBox(height: 8),
              ],
            ),
          ),
    );
  }

  void _showDeleteConfirmation(Map<String, dynamic> sale) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Satışı Sil'),
            content: Text(
              'Bu satış kaydını silmek istediğinize emin misiniz?\n\n'
              'Restoran: ${sale['restaurant']}\n'
              'Tutar: ${sale['amount']} ₺\n\n'
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
                  _deleteRestaurantSale(sale['id']);
                },
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                child: Text('Sil'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Restoran Satışları',
          style: theme.textTheme.titleLarge?.copyWith(
            color: colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: colorScheme.onPrimary,
          labelColor: colorScheme.onPrimary,
          unselectedLabelColor: colorScheme.onPrimary.withAlpha(179),
          tabs: [
            Tab(icon: Icon(CupertinoIcons.add_circled), text: 'Yeni Satış'),
            Tab(
              icon: Icon(CupertinoIcons.list_bullet),
              text: 'Satış Kayıtları',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildNewSaleTab(colorScheme, theme),
          _buildSalesRecordsTab(colorScheme, theme),
        ],
      ),
    );
  }

  Widget _buildNewSaleTab(ColorScheme colorScheme, ThemeData theme) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Modern header card
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primaryContainer.withAlpha(179),
                    colorScheme.primaryContainer.withAlpha(179),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withAlpha(25),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(
                      CupertinoIcons.add_circled,
                      color: colorScheme.onPrimary,
                      size: 24.w,
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Yeni Restoran Satışı',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: colorScheme.onPrimaryContainer.withAlpha(
                              179,
                            ),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          'Restoran satış bilgilerini girin',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onPrimaryContainer.withAlpha(
                              179,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 24.h),

            // Restaurant name field
            _buildFormField(
              controller: _restaurantController,
              label: 'Restoran İsmi',
              hint: 'Restoran adını girin',
              icon: CupertinoIcons.building_2_fill,
              isRequired: true,
              colorScheme: colorScheme,
              theme: theme,
            ),

            SizedBox(height: 16.h),

            // Product name field
            _buildFormField(
              controller: _productController,
              label: 'Ürün Adı',
              hint: 'Satılan ürünü girin',
              icon: CupertinoIcons.bag_fill,
              colorScheme: colorScheme,
              theme: theme,
            ),

            SizedBox(height: 16.h),

            // Quantity and unit row
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _buildFormField(
                    controller: _quantityController,
                    label: 'Miktar',
                    hint: '0',
                    icon: CupertinoIcons.number,
                    keyboardType: TextInputType.number,
                    onChanged: (value) => _calculateTotalAmount(),
                    colorScheme: colorScheme,
                    theme: theme,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(child: _buildUnitDropdown(colorScheme, theme)),
              ],
            ),

            SizedBox(height: 16.h),

            // Unit price field
            _buildFormField(
              controller: _unitPriceController,
              label: 'Birim Fiyat',
              hint: '0.00',
              icon: CupertinoIcons.money_dollar_circle_fill,
              keyboardType: TextInputType.number,
              onChanged: (value) => _calculateTotalAmount(),
              colorScheme: colorScheme,
              theme: theme,
            ),

            SizedBox(height: 16.h),

            // Total amount field (calculated)
            _buildFormField(
              controller: _totalAmountController,
              label: 'Toplam Tutar (₺)',
              hint: '0.00',
              icon: CupertinoIcons.money_dollar,
              keyboardType: TextInputType.number,
              isRequired: true,
              colorScheme: colorScheme,
              theme: theme,
              readOnly: false, // Allow manual edit
            ),

            SizedBox(height: 16.h),

            // Notes field
            _buildFormField(
              controller: _notesController,
              label: 'Notlar',
              hint: 'Ek bilgiler (opsiyonel)',
              icon: CupertinoIcons.doc_text_fill,
              maxLines: 3,
              colorScheme: colorScheme,
              theme: theme,
            ),

            SizedBox(height: 32.h),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    onPressed: _clearForm,
                    label: 'Temizle',
                    icon: CupertinoIcons.clear_circled,
                    color: colorScheme.outline,
                    textColor: colorScheme.onSurface,
                    theme: theme,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  flex: 2,
                  child: _buildActionButton(
                    onPressed: _isSubmitting ? null : _addRestaurantSale,
                    label: _isSubmitting ? 'Ekleniyor...' : 'Satış Ekle',
                    icon:
                        _isSubmitting
                            ? CupertinoIcons.clock
                            : CupertinoIcons.add_circled_solid,
                    color: colorScheme.primary,
                    textColor: colorScheme.onPrimary,
                    theme: theme,
                  ),
                ),
              ],
            ),

            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesRecordsTab(ColorScheme colorScheme, ThemeData theme) {
    return RefreshIndicator(
      onRefresh: _loadRestaurantSales,
      child:
          _isLoading
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: colorScheme.primary),
                    SizedBox(height: 16.h),
                    Text(
                      'Satış kayıtları yükleniyor...',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withAlpha(179),
                      ),
                    ),
                  ],
                ),
              )
              : _restaurantSales.isEmpty
              ? _buildEmptyState(colorScheme, theme)
              : Column(
                children: [
                  // Header with stats
                  Container(
                    padding: EdgeInsets.all(16.w),
                    margin: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.secondaryContainer.withAlpha(179),
                          colorScheme.secondaryContainer.withAlpha(179),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16.r),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.shadow.withAlpha(25),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(
                            color: colorScheme.secondary,
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Icon(
                            CupertinoIcons.chart_bar_fill,
                            color: colorScheme.onSecondary,
                            size: 24.w,
                          ),
                        ),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Toplam ${_restaurantSales.length} Kayıt',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: colorScheme.onSecondaryContainer
                                      .withAlpha(179),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                _getTotalSalesAmount(),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSecondaryContainer
                                      .withAlpha(179),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Sales list
                  Expanded(
                    child: ListView.builder(
                      itemCount: _restaurantSales.length,
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      itemBuilder: (context, index) {
                        final sale = _restaurantSales[index];
                        return _buildSaleCard(sale, colorScheme, theme);
                      },
                    ),
                  ),
                ],
              ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(32.w),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withAlpha(77),
              shape: BoxShape.circle,
            ),
            child: Icon(
              CupertinoIcons.doc_text,
              size: 64.w,
              color: colorScheme.onSurfaceVariant.withAlpha(179),
            ),
          ),
          SizedBox(height: 24.h),
          Text(
            'Henüz satış kaydı yok',
            style: theme.textTheme.titleLarge?.copyWith(
              color: colorScheme.onSurface.withAlpha(179),
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'İlk satışınızı kaydetmek için\n"Yeni Satış" sekmesini kullanın',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withAlpha(128),
            ),
          ),
          SizedBox(height: 32.h),
          FilledButton.icon(
            onPressed: () => _tabController.animateTo(0),
            icon: Icon(CupertinoIcons.add),
            label: Text('Yeni Satış Ekle'),
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaleCard(
    Map<String, dynamic> sale,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    final displayDate = DateFormatter.formatDisplayDate(sale['date']);
    final isPayment = sale['productName'] == 'Ödeme Alındı';
    final isDebt = sale['productName'] == 'Borç Kaydı';

    Color cardColor =
        isPayment
            ? Colors.green
            : isDebt
            ? Colors.red
            : colorScheme.primary;
    IconData cardIcon =
        isPayment
            ? CupertinoIcons.money_dollar_circle_fill
            : isDebt
            ? CupertinoIcons.exclamationmark_triangle_fill
            : CupertinoIcons.bag_fill;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      child: Card(
        elevation: 2,
        shadowColor: colorScheme.shadow.withAlpha(25),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: InkWell(
          onTap: () => _showRestaurantSaleOptions(sale),
          borderRadius: BorderRadius.circular(16.r),
          child: Container(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: cardColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(cardIcon, color: cardColor, size: 24.w),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sale['restaurant'] ?? 'Bilinmeyen Restoran',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface.withAlpha(179),
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        sale['productName'] ?? 'Ürün belirtilmedi',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withAlpha(128),
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        displayDate,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withAlpha(128),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 8.h,
                  ),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    '${(sale['amount'] as num).toStringAsFixed(2)} ₺',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getTotalSalesAmount() {
    if (_restaurantSales.isEmpty) return 'Toplam: 0.00 ₺';

    double total = _restaurantSales
        .map((sale) => (sale['amount'] as num).toDouble())
        .reduce((a, b) => a + b);

    return 'Toplam: ${total.toStringAsFixed(2)} ₺';
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required ColorScheme colorScheme,
    required ThemeData theme,
    bool isRequired = false,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool readOnly = false,
    Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
            children:
                isRequired
                    ? [
                      TextSpan(
                        text: ' *',
                        style: TextStyle(color: colorScheme.error),
                      ),
                    ]
                    : null,
          ),
        ),
        SizedBox(height: 8.h),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          readOnly: readOnly,
          onChanged: onChanged,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurface,
          ),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: colorScheme.primary),
            filled: true,
            fillColor: colorScheme.surfaceContainerHighest.withAlpha(30),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(
                color: colorScheme.outline.withAlpha(30),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: colorScheme.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: colorScheme.error, width: 1),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 16.h,
            ),
          ),
          validator:
              isRequired
                  ? (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '$label zorunludur';
                    }
                    return null;
                  }
                  : null,
        ),
      ],
    );
  }

  Widget _buildUnitDropdown(ColorScheme colorScheme, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Birim',
          style: theme.textTheme.labelLarge?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withAlpha(30),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: colorScheme.outline.withAlpha(30),
              width: 1,
            ),
          ),
          child: DropdownButtonFormField<String>(
            value: _selectedUnit,
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.straighten, color: colorScheme.primary),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 16.h,
              ),
            ),
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurface,
            ),
            dropdownColor: colorScheme.surface,
            borderRadius: BorderRadius.circular(12.r),
            items:
                ['kg', 'gr', 'adet', 'litre'].map((unit) {
                  return DropdownMenuItem(value: unit, child: Text(unit));
                }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedUnit = value!;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required VoidCallback? onPressed,
    required String label,
    required IconData icon,
    required Color color,
    required Color textColor,
    required ThemeData theme,
  }) {
    return SizedBox(
      height: 56.h,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20.w),
        label: Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          elevation: 2,
          shadowColor: color.withAlpha(30),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          padding: EdgeInsets.symmetric(horizontal: 24.w),
        ),
      ),
    );
  }

  void _clearForm() {
    _restaurantController.clear();
    _productController.clear();
    _quantityController.clear();
    _unitPriceController.clear();
    _notesController.clear();
    _totalAmountController.clear();
    setState(() {
      _selectedUnit = 'kg';
    });
  }
}
