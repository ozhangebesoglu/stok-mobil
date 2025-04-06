import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/product.dart';
import '../models/customer.dart';
import '../models/sale.dart';
import '../providers/stock_provider.dart';
import '../providers/customer_provider.dart';
import '../providers/sales_provider.dart';
import '../widgets/custom_text_field.dart';
import '../main.dart'; // Ana sayfadaki istatistikleri güncellemek için

class SalesManagementPage extends StatefulWidget {
  @override
  _SalesManagementPageState createState() => _SalesManagementPageState();
}

class _SalesManagementPageState extends State<SalesManagementPage> {
  final _formKey = GlobalKey<FormState>();

  Product? _selectedProduct;
  Customer? _selectedCustomer;

  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  final _customerNameController =
      TextEditingController(); // Müşteri seçilmediğinde manuel giriş için

  bool _isPaid = true;
  List<Sale> _recentSales = [];
  String _searchQuery = '';
  bool _isQuickSale = false; // Hızlı satış modu (müşterisiz)

  @override
  void initState() {
    super.initState();
    _loadRecentSales();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _priceController.dispose();
    _customerNameController.dispose();
    super.dispose();
  }

  Future<void> _loadRecentSales() async {
    final salesProvider = Provider.of<SalesProvider>(context, listen: false);
    await salesProvider.loadSales();

    setState(() {
      _recentSales =
          salesProvider.sales.take(10).toList(); // Son 10 satışı göster
    });
  }

  void _showAddSaleDialog() {
    final products =
        Provider.of<StockProvider>(context, listen: false).products;
    final customers =
        Provider.of<CustomerProvider>(context, listen: false).customers;

    // Formları temizle
    _selectedProduct = null;
    _selectedCustomer = null;
    _customerNameController.clear();
    _quantityController.clear();
    _priceController.clear();
    _isPaid = true;
    _isQuickSale = false;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: Row(
                    children: [
                      Icon(Icons.point_of_sale, color: Colors.green),
                      SizedBox(width: 10),
                      Text('Yeni Satış Ekle'),
                    ],
                  ),
                  content: SingleChildScrollView(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Ürün Seçimi
                          Text(
                            'Ürün Seçimi',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          DropdownButtonFormField<Product>(
                            decoration: InputDecoration(
                              prefixIcon: Icon(Icons.shopping_bag),
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 16,
                              ),
                            ),
                            hint: Text('Ürün seçiniz'),
                            value: _selectedProduct,
                            isExpanded: true,
                            items:
                                products.map((product) {
                                  return DropdownMenuItem<Product>(
                                    value: product,
                                    child: Text(
                                      '${product.name} (${product.quantity} ${product.unit})',
                                    ),
                                  );
                                }).toList(),
                            validator:
                                (value) =>
                                    value == null
                                        ? 'Lütfen bir ürün seçin'
                                        : null,
                            onChanged: (Product? newValue) {
                              setState(() {
                                _selectedProduct = newValue;
                                if (_selectedProduct != null) {
                                  _priceController.text =
                                      _selectedProduct!.sellingPrice.toString();
                                }
                              });
                            },
                          ),
                          SizedBox(height: 16),

                          // Satış tipi seçimi
                          Row(
                            children: [
                              Text(
                                'Satış Tipi:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: RadioListTile<bool>(
                                        title: Text('Müşterili'),
                                        value: false,
                                        groupValue: _isQuickSale,
                                        onChanged: (value) {
                                          setState(() {
                                            _isQuickSale = value!;
                                          });
                                        },
                                        contentPadding: EdgeInsets.zero,
                                        dense: true,
                                      ),
                                    ),
                                    Expanded(
                                      child: RadioListTile<bool>(
                                        title: Text('Günlük Satış'),
                                        value: true,
                                        groupValue: _isQuickSale,
                                        onChanged: (value) {
                                          setState(() {
                                            _isQuickSale = value!;
                                            if (_isQuickSale) {
                                              _isPaid =
                                                  true; // Günlük satışlar her zaman ödenmiş olur
                                            }
                                          });
                                        },
                                        contentPadding: EdgeInsets.zero,
                                        dense: true,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          // Müşteri Seçimi (sadece müşterili satışta göster)
                          if (!_isQuickSale) ...[
                            SizedBox(height: 16),
                            Text(
                              'Müşteri Seçimi',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            DropdownButtonFormField<Customer>(
                              decoration: InputDecoration(
                                prefixIcon: Icon(Icons.person),
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 16,
                                ),
                              ),
                              hint: Text('Müşteri seçiniz'),
                              value: _selectedCustomer,
                              isExpanded: true,
                              items:
                                  customers.map((customer) {
                                    return DropdownMenuItem<Customer>(
                                      value: customer,
                                      child: Text(customer.name),
                                    );
                                  }).toList(),
                              validator:
                                  (value) =>
                                      _isQuickSale
                                          ? null
                                          : (value == null
                                              ? 'Lütfen bir müşteri seçin'
                                              : null),
                              onChanged: (Customer? newValue) {
                                setState(() {
                                  _selectedCustomer = newValue;
                                });
                              },
                            ),
                          ] else ...[
                            // Günlük satışlarda müşteri adı girişi (isteğe bağlı)
                            SizedBox(height: 16),
                            CustomTextField(
                              labelText: 'Müşteri Adı (Opsiyonel)',
                              controller: _customerNameController,
                              prefixIcon: Icons.person_outline,
                              isRequired: false,
                              hintText: 'Ör: Günlük Müşteri',
                            ),
                          ],

                          SizedBox(height: 16),

                          // Miktar ve Fiyat
                          Row(
                            children: [
                              Expanded(
                                child: CustomTextField(
                                  labelText: 'Miktar',
                                  controller: _quantityController,
                                  prefixIcon: Icons.scale,
                                  keyboardType: TextInputType.number,
                                  isRequired: true,
                                  onChanged: (value) {
                                    setState(() {
                                      // Toplam fiyatı otomatik güncelle
                                      if (value.isNotEmpty &&
                                          _selectedProduct != null) {
                                        double quantity =
                                            double.tryParse(value) ?? 0;
                                        double price =
                                            _selectedProduct!.sellingPrice;
                                        _priceController.text =
                                            (quantity * price).toString();
                                      }
                                    });
                                  },
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: CustomTextField(
                                  labelText: 'Fiyat (₺)',
                                  controller: _priceController,
                                  prefixIcon: Icons.attach_money,
                                  keyboardType: TextInputType.number,
                                  isRequired: true,
                                ),
                              ),
                            ],
                          ),

                          // Ödeme Durumu (sadece müşterili satışta göster)
                          if (!_isQuickSale) ...[
                            SizedBox(height: 12),
                            Row(
                              children: [
                                Text(
                                  'Ödeme Durumu:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: RadioListTile<bool>(
                                          title: Text('Ödendi'),
                                          value: true,
                                          groupValue: _isPaid,
                                          onChanged: (value) {
                                            setState(() {
                                              _isPaid = value!;
                                            });
                                          },
                                          contentPadding: EdgeInsets.zero,
                                          dense: true,
                                        ),
                                      ),
                                      Expanded(
                                        child: RadioListTile<bool>(
                                          title: Text('Borç'),
                                          value: false,
                                          groupValue: _isPaid,
                                          onChanged: (value) {
                                            setState(() {
                                              _isPaid = value!;
                                            });
                                          },
                                          contentPadding: EdgeInsets.zero,
                                          dense: true,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
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
                      onPressed: () => _addSale(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
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
          ),
    );
  }

  Future<void> _addSale(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      try {
        final stockProvider = Provider.of<StockProvider>(
          context,
          listen: false,
        );
        final salesProvider = Provider.of<SalesProvider>(
          context,
          listen: false,
        );
        final customerProvider = Provider.of<CustomerProvider>(
          context,
          listen: false,
        );

        // Form verilerini al
        final product = _selectedProduct!;
        final quantity = double.parse(_quantityController.text);
        final price = double.parse(_priceController.text);

        // Stok kontrolü
        if (quantity > product.quantity) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Yetersiz stok! Mevcut stok: ${product.quantity} ${product.unit}',
              ),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        // Satış kaydı oluştur
        final sale = Sale(
          customerId: _isQuickSale ? null : _selectedCustomer?.id,
          customerName:
              _isQuickSale
                  ? (_customerNameController.text.isNotEmpty
                      ? _customerNameController.text
                      : "Günlük Müşteri")
                  : _selectedCustomer!.name,
          amount: price,
          date: DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
          isPaid:
              _isQuickSale
                  ? true
                  : _isPaid, // Günlük satışlar her zaman ödenmiş olur
          productId: product.id,
          productName: product.name,
          quantity: quantity,
          unit: product.unit,
          unitPrice: price / quantity,
        );

        // Satışı kaydet
        await salesProvider.addSale(sale);

        // Stok miktarını güncelle
        await stockProvider.updateStock(product.id!, -quantity);

        // Eğer borç ise müşteri bakiyesini güncelle (sadece müşterili satışlarda)
        if (!_isQuickSale && !_isPaid && _selectedCustomer != null) {
          await customerProvider.updateBalance(_selectedCustomer!.id!, price);
        }

        Navigator.of(context).pop();

        // Son satışları güncelle
        _loadRecentSales();

        // Ana sayfadaki istatistikleri güncelle
        HomePage.updateStatistics(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Satış başarıyla kaydedildi'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Satış kaydedilirken hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Satış silme metodu
  Future<void> _deleteSale(Sale sale) async {
    try {
      final salesProvider = Provider.of<SalesProvider>(context, listen: false);
      final stockProvider = Provider.of<StockProvider>(context, listen: false);
      final customerProvider = Provider.of<CustomerProvider>(
        context,
        listen: false,
      );

      // Satışı veritabanından sil
      await salesProvider.deleteSale(sale.id!);

      // Stok miktarını geri ekle
      if (sale.productId != null) {
        await stockProvider.updateStock(sale.productId!, sale.quantity);
      }

      // Eğer borç ise müşteri bakiyesini düzelt
      if (!sale.isPaid && sale.customerId != null) {
        await customerProvider.updateBalance(sale.customerId!, -sale.amount);
      }

      // Ana sayfadaki istatistikleri güncelle
      HomePage.updateStatistics(context);

      // Son satışları güncelle
      _loadRecentSales();

      _showSuccessMessage('Satış başarıyla silindi');
    } catch (e) {
      _showErrorMessage('Satış silinirken hata oluştu: $e');
    }
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: EdgeInsets.all(8),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error, color: Colors.white),
            SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: EdgeInsets.all(8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allSales = Provider.of<SalesProvider>(context).sales;

    // Filtreleme - arama
    final filteredSales =
        _searchQuery.isEmpty
            ? allSales
            : allSales
                .where(
                  (sale) =>
                      sale.productName.toLowerCase().contains(
                        _searchQuery.toLowerCase(),
                      ) ||
                      sale.customerName.toLowerCase().contains(
                        _searchQuery.toLowerCase(),
                      ),
                )
                .toList();

    return Scaffold(
      backgroundColor: Color(0xFFD2B48C), // Tan rengi
      appBar: AppBar(
        title: Text('Satış Yönetimi'),
        backgroundColor: Color(0xFF8B0000), // Muted Tomato Red
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(CupertinoIcons.back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadRecentSales,
            tooltip: 'Yenile',
          ),
        ],
      ),
      body: Column(
        children: [
          // Arama çubuğu
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: CupertinoSearchTextField(
              placeholder: 'Ürün veya müşteri ara...',
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              padding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
            ),
          ),

          // Satış listesi
          Expanded(
            child:
                filteredSales.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            CupertinoIcons.cart,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Henüz satış kaydı yok',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      padding: EdgeInsets.all(8),
                      itemCount: filteredSales.length,
                      itemBuilder: (context, index) {
                        final sale = filteredSales[index];
                        final formattedDate = DateFormat(
                          'dd.MM.yyyy HH:mm',
                        ).format(
                          DateFormat('yyyy-MM-dd HH:mm:ss').parse(sale.date),
                        );

                        return Dismissible(
                          key: Key(sale.id.toString()),
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: EdgeInsets.only(right: 20.0),
                            color: Colors.red,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  CupertinoIcons.delete,
                                  color: Colors.white,
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Sil',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                          direction: DismissDirection.endToStart,
                          confirmDismiss: (direction) async {
                            return await showCupertinoDialog<bool>(
                              context: context,
                              builder:
                                  (context) => CupertinoAlertDialog(
                                    title: Text('Satışı Sil'),
                                    content: Text(
                                      '${sale.productName} ürününe ait bu satışı silmek istediğinize emin misiniz?',
                                    ),
                                    actions: [
                                      CupertinoDialogAction(
                                        child: Text('İptal'),
                                        onPressed:
                                            () => Navigator.pop(context, false),
                                      ),
                                      CupertinoDialogAction(
                                        child: Text('Sil'),
                                        isDestructiveAction: true,
                                        onPressed:
                                            () => Navigator.pop(context, true),
                                      ),
                                    ],
                                  ),
                            );
                          },
                          onDismissed: (direction) {
                            _deleteSale(sale);
                          },
                          child: Card(
                            elevation: 0,
                            margin: EdgeInsets.symmetric(vertical: 4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: Colors.grey.shade200,
                                width: 0.5,
                              ),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.green.shade100,
                                child: Icon(
                                  Icons.shopping_cart,
                                  color: Colors.green,
                                ),
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      sale.productName,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '${sale.amount.toStringAsFixed(2)} ₺',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Müşteri: ${sale.customerName}'),
                                  Text(
                                    'Miktar: ${sale.quantity.toStringAsFixed(2)} ${sale.unit}',
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(formattedDate),
                                      Chip(
                                        label: Text(
                                          sale.isPaid ? 'Ödendi' : 'Borç',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                          ),
                                        ),
                                        backgroundColor:
                                            sale.isPaid
                                                ? Colors.green
                                                : Colors.orange,
                                        padding: EdgeInsets.zero,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              isThreeLine: true,
                              trailing: Icon(
                                CupertinoIcons.chevron_right,
                                color: Colors.grey,
                                size: 16,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
      floatingActionButton: Container(
        width: 160,
        height: 50,
        decoration: BoxDecoration(
          color: Color(0xFF8B0000), // Muted Tomato Red
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _showAddSaleDialog,
            borderRadius: BorderRadius.circular(25),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.add, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Satış Ekle',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
