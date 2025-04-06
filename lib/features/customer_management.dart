import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/customer.dart';
import '../models/sale.dart';
import '../models/product.dart';
import '../providers/customer_provider.dart';
import '../providers/sales_provider.dart';
import '../providers/stock_provider.dart';
import '../widgets/custom_text_field.dart';
import '../services/database/database_helper.dart';
import '../main.dart'; // Ana sayfadaki istatistikleri güncellemek için

class CustomerManagementPage extends StatefulWidget {
  @override
  _CustomerManagementPageState createState() => _CustomerManagementPageState();
}

class _CustomerManagementPageState extends State<CustomerManagementPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _balanceController = TextEditingController();
  String _searchQuery = '';

  // Restoran satışları için
  final _restaurantController = TextEditingController();
  final _amountController = TextEditingController();
  final _quantityController = TextEditingController();
  final _unitController = TextEditingController();
  final _unitPriceController = TextEditingController();
  final _notesController = TextEditingController();
  List<Map<String, dynamic>> _restaurantSales = [];
  bool _isEditing = false;
  int? _editingId;

  // Stok ürünleri için
  List<Product> _products = [];
  Product? _selectedProduct;

  // Mevcut birim listesi
  final List<String> _units = ['kg', 'gr', 'adet', 'paket', 'kasa'];
  String _selectedUnit = 'kg';

  // Sekmeler için
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CustomerProvider>(context, listen: false).loadCustomers();
      Provider.of<StockProvider>(context, listen: false).loadProducts();
      _loadProducts();
      _loadRestaurantSales();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _balanceController.dispose();
    _restaurantController.dispose();
    _amountController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    _unitPriceController.dispose();
    _notesController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  // Stok ürünlerini yükle
  void _loadProducts() {
    final stockProvider = Provider.of<StockProvider>(context, listen: false);
    setState(() {
      _products = stockProvider.products;
    });
  }

  // Restoran satışlarını yükle
  Future<void> _loadRestaurantSales() async {
    try {
      final db = await DatabaseHelper().database;
      final results = await db.query('restaurant_sales', orderBy: 'date DESC');

      setState(() {
        _restaurantSales = results;
      });
    } catch (e) {
      print('Restoran satışları yüklenirken hata: $e');
    }
  }

  // Birim için dropdown oluşturma
  Widget _buildUnitDropdown() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(4),
      ),
      child: DropdownButtonFormField<String>(
        value: _units.contains(_selectedUnit) ? _selectedUnit : _units.first,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: 'Birim',
          contentPadding: EdgeInsets.zero,
          border: InputBorder.none,
        ),
        icon: Icon(Icons.arrow_drop_down),
        items:
            _units.map((String unit) {
              return DropdownMenuItem<String>(value: unit, child: Text(unit));
            }).toList(),
        onChanged: (String? newValue) {
          if (newValue != null) {
            setState(() {
              _selectedUnit = newValue;
            });
          }
        },
      ),
    );
  }

  // Ürün seçimi için dropdown oluşturma
  Widget _buildProductDropdown() {
    // Eğer stokta ürün yoksa
    if (_products.isEmpty) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 15),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Icon(Icons.shopping_bag, color: Colors.grey),
            SizedBox(width: 10),
            Text(
              'Stokta ürün bulunmuyor',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // Sadece stokta olan (miktarı > 0) ve ID'si null olmayan ürünleri filtrele
    final validProducts =
        _products.where((p) => p.id != null && p.quantity > 0).toList();

    if (validProducts.isEmpty) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 15),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Icon(Icons.shopping_bag, color: Colors.grey),
            SizedBox(width: 10),
            Text(
              'Stokta satılabilir ürün bulunmuyor',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // Seçilen ürün geçerli değilse veya stokta yoksa, seçimi sıfırla
    if (_selectedProduct == null ||
        !validProducts.any((p) => p.id == _selectedProduct!.id) ||
        _selectedProduct!.quantity <= 0) {
      _selectedProduct = null;
    }

    // Eğer seçili ürün yoksa dropdown değeri null olmalı
    final selectedProductId = _selectedProduct?.id;

    // Seçili ürün ID'sinin items listesinde var olduğunu kontrol et
    bool hasValidSelection =
        selectedProductId != null &&
        validProducts.any((p) => p.id == selectedProductId);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(4),
      ),
      child: DropdownButtonFormField<int>(
        value: hasValidSelection ? selectedProductId : null,
        hint: Text('Ürün Seçin*'),
        isExpanded: true,
        decoration: InputDecoration(
          contentPadding: EdgeInsets.zero,
          border: InputBorder.none,
          errorStyle: TextStyle(height: 0),
        ),
        icon: Icon(Icons.arrow_drop_down),
        items:
            validProducts.map((Product product) {
              return DropdownMenuItem<int>(
                value: product.id,
                child: Text(
                  '${product.name} (${product.quantity} ${product.unit})',
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
        onChanged: (int? productId) {
          if (productId != null) {
            final product = validProducts.firstWhere(
              (p) => p.id == productId,
              orElse: () => validProducts.first,
            );

            setState(() {
              _selectedProduct = product;
              _selectedUnit = product.unit;
              _unitPriceController.text = product.sellingPrice.toString();
              _updateTotalAmount();
            });
          } else {
            setState(() {
              _selectedProduct = null;
            });
          }
        },
      ),
    );
  }

  // Toplam tutarı güncelleme
  void _updateTotalAmount() {
    if (_selectedProduct != null &&
        _quantityController.text.isNotEmpty &&
        _unitPriceController.text.isNotEmpty) {
      final quantity = double.tryParse(_quantityController.text) ?? 0;
      final unitPrice =
          double.tryParse(_unitPriceController.text) ??
          _selectedProduct!.sellingPrice;

      setState(() {
        _amountController.text = (quantity * unitPrice).toStringAsFixed(2);
      });
    }
  }

  // Restoran satışı ekle
  Future<void> _addRestaurantSale() async {
    final restaurantName = _restaurantController.text.trim();
    final amountText = _amountController.text.trim();
    final amount = double.tryParse(amountText) ?? 0;
    final quantity = double.tryParse(_quantityController.text.trim()) ?? 0;
    final unitPrice = double.tryParse(_unitPriceController.text.trim()) ?? 0;

    if (restaurantName.isEmpty || amount <= 0) {
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Text('Hata'),
              content: Text('Geçerli bir restoran ismi ve tutar girin!'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Tamam'),
                ),
              ],
            ),
      );
      return;
    }

    if (_selectedProduct == null) {
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Text('Hata'),
              content: Text('Lütfen stoktan bir ürün seçin!'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Tamam'),
                ),
              ],
            ),
      );
      return;
    }

    try {
      final db = await DatabaseHelper().database;
      final stockProvider = Provider.of<StockProvider>(context, listen: false);

      // Satış kaydı
      final sale = {
        'restaurant': restaurantName,
        'amount': amount,
        'date': DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
        'productName': _selectedProduct!.name,
        'quantity': quantity,
        'unit': _selectedUnit,
        'unitPrice': unitPrice,
        'notes': _notesController.text.trim(),
      };

      if (_isEditing && _editingId != null) {
        // Mevcut kaydı güncelle
        await db.update(
          'restaurant_sales',
          sale,
          where: 'id = ?',
          whereArgs: [_editingId],
        );
      } else {
        // Yeni kayıt ekle
        await db.insert('restaurant_sales', sale);

        // Stok miktarını güncelle
        if (_selectedProduct!.id != null) {
          await stockProvider.updateStock(_selectedProduct!.id!, -quantity);
        }

        // Genel satış tablosuna da kaydet
        final saleRecord = Sale(
          customerName: 'Restoran: $restaurantName',
          amount: amount,
          date: DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
          isPaid: true,
          productName: _selectedProduct!.name,
          quantity: quantity > 0 ? quantity : 1,
          unit: _selectedUnit,
          unitPrice: unitPrice > 0 ? unitPrice : amount,
        );

        // Satışı kaydet
        await Provider.of<SalesProvider>(
          context,
          listen: false,
        ).addSale(saleRecord);
      }

      // Listeyi güncelle
      _loadRestaurantSales();
      _loadProducts(); // Stok listesini güncelle

      // Ana sayfadaki istatistikleri güncelle
      try {
        HomePage.updateStatistics(context);
      } catch (e) {
        print('İstatistikler güncellenirken hata: $e');
        // Ana sayfa istatistikleri güncellenemezse, kullanıcıya bildirmeye gerek yok
      }

      // Form temizle ve düzenleme modunu kapat
      _clearRestaurantSaleForm();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'Restoran satışı güncellendi'
                : 'Restoran satışı eklendi',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Satış eklenirken hata: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Düzenleme modunda form doldur
  void _editRestaurantSale(Map<String, dynamic> sale) {
    setState(() {
      _editingId = sale['id'];
      _restaurantController.text = sale['restaurant'] ?? '';
      _amountController.text = sale['amount']?.toString() ?? '';

      // Ürün adına göre seçili ürünü belirle
      final productName = sale['productName'] ?? '';
      _selectedProduct = null; // Önce seçimi temizle

      if (productName.isNotEmpty) {
        try {
          // Eğer bu isimde bir ürün stokta varsa seç
          final matchingProduct = _products.firstWhere(
            (p) => p.name == productName && p.id != null,
            orElse:
                () => Product(
                  name: productName,
                  quantity: 0,
                  unit: sale['unit'] ?? 'adet',
                  purchasePrice: 0, // Varsayılan alış fiyatı
                  sellingPrice:
                      double.tryParse(sale['unitPrice']?.toString() ?? '0') ??
                      0,
                  category: '', // Varsayılan kategori
                ),
          );

          // Stokta varsa ve geçerli bir ID'si varsa seç
          if (matchingProduct.id != null) {
            _selectedProduct = matchingProduct;
          }
        } catch (e) {
          print('Ürün belirlenirken hata: $e');
          _selectedProduct = null;
        }
      }

      _quantityController.text = sale['quantity']?.toString() ?? '';
      _selectedUnit = sale['unit'] ?? 'kg';

      // Eğer birim geçerli değilse varsayılan birime ayarla
      if (!_units.contains(_selectedUnit)) {
        _selectedUnit = _units.first;
      }

      _unitPriceController.text = sale['unitPrice']?.toString() ?? '';
      _notesController.text = sale['notes'] ?? '';
      _isEditing = true;
    });
  }

  // Form alanlarını temizle
  void _clearRestaurantSaleForm() {
    setState(() {
      _restaurantController.clear();
      _amountController.clear();
      _selectedProduct = null;
      _quantityController.clear();
      _unitPriceController.text = '';
      _notesController.clear();

      // Varsayılan birim
      _selectedUnit = _units.first;

      _isEditing = false;
      _editingId = null;
    });
  }

  // Restoran satışını sil
  Future<void> _deleteRestaurantSale(int id) async {
    try {
      final db = await DatabaseHelper().database;
      await db.delete('restaurant_sales', where: 'id = ?', whereArgs: [id]);
      _loadRestaurantSales();

      // Ana sayfadaki istatistikleri güncelle
      HomePage.updateStatistics(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Satış silindi'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Satış silinirken hata: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showAddCustomerDialog() {
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

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 10),
                Text('Müşteri başarıyla eklendi'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
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
  void _showCustomerHistory(Customer customer) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            insetPadding: EdgeInsets.all(16),
            child: Container(
              width: double.maxFinite,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppBar(
                    title: Text('İşlem Geçmişi: ${customer.name}'),
                    automaticallyImplyLeading: false,
                    actions: [
                      IconButton(
                        icon: Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  Expanded(
                    child: FutureBuilder<List<Map<String, dynamic>>>(
                      future: _loadCustomerHistory(customer.id!),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        }

                        if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              'İşlem geçmişi yüklenirken hata oluştu',
                              style: TextStyle(color: Colors.red),
                            ),
                          );
                        }

                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return Center(
                            child: Text(
                              'Bu müşteri için işlem geçmişi bulunamadı',
                            ),
                          );
                        }

                        final transactions = snapshot.data!;

                        return ListView.builder(
                          padding: EdgeInsets.all(16),
                          itemCount: transactions.length,
                          itemBuilder: (context, index) {
                            final transaction = transactions[index];
                            final date = DateFormat('dd.MM.yyyy HH:mm').format(
                              DateFormat(
                                'yyyy-MM-dd HH:mm:ss',
                              ).parse(transaction['date']),
                            );

                            final bool isPaid = transaction['isPaid'] == 1;
                            final double amount = transaction['amount'];
                            final String transactionType =
                                transaction['transactionType'];

                            return Card(
                              margin: EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: _getTransactionColor(
                                    transactionType,
                                    isPaid,
                                  ),
                                  child: Icon(
                                    _getTransactionIcon(
                                      transactionType,
                                      isPaid,
                                    ),
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                title: Text(
                                  _getTransactionTitle(transactionType, isPaid),
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (transaction['productName'] != null)
                                      Text(
                                        'Ürün: ${transaction['productName']}',
                                      ),
                                    if (transaction['quantity'] != null)
                                      Text(
                                        'Miktar: ${transaction['quantity']} ${transaction['unit'] ?? ''}',
                                      ),
                                    Text('Tarih: $date'),
                                  ],
                                ),
                                trailing: Text(
                                  '${amount.toStringAsFixed(2)} ₺',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isPaid ? Colors.green : Colors.red,
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  // Ödeme dialog
  void _showPaymentDialog(Customer customer) {
    final _paymentController = TextEditingController();
    final _notesController = TextEditingController();
    bool _isDebt = false;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => Dialog(
                  insetPadding: EdgeInsets.all(16),
                  child: Container(
                    width: double.maxFinite,
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.7,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppBar(
                          title: Text('Ödeme/Borç İşlemi: ${customer.name}'),
                          automaticallyImplyLeading: false,
                          actions: [
                            IconButton(
                              icon: Icon(Icons.close),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'Mevcut Borç: ${customer.balance.toStringAsFixed(2)} ₺',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color:
                                        customer.balance > 0
                                            ? Colors.red
                                            : Colors.green,
                                  ),
                                ),
                                SizedBox(height: 24),
                                TextField(
                                  controller: _paymentController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: 'Tutar',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.money),
                                  ),
                                ),
                                SizedBox(height: 16),
                                TextField(
                                  controller: _notesController,
                                  maxLines: 3,
                                  decoration: InputDecoration(
                                    labelText: 'Açıklama (Opsiyonel)',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.note),
                                  ),
                                ),
                                SizedBox(height: 24),
                                Text(
                                  'İşlem Türü:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 8),
                                RadioListTile<bool>(
                                  title: Text('Ödeme Al'),
                                  value: false,
                                  groupValue: _isDebt,
                                  activeColor: Colors.green,
                                  onChanged: (value) {
                                    setState(() {
                                      _isDebt = value!;
                                    });
                                  },
                                ),
                                RadioListTile<bool>(
                                  title: Text('Borç Ekle'),
                                  value: true,
                                  activeColor: Colors.orange,
                                  groupValue: _isDebt,
                                  onChanged: (value) {
                                    setState(() {
                                      _isDebt = value!;
                                    });
                                  },
                                ),
                                SizedBox(height: 24),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed:
                                            () => Navigator.of(context).pop(),
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(
                                            vertical: 12,
                                          ),
                                          child: Text('İptal'),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Expanded(
                                      flex: 2,
                                      child: ElevatedButton(
                                        onPressed: () async {
                                          try {
                                            if (_paymentController
                                                .text
                                                .isEmpty) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    'Lütfen tutar giriniz',
                                                  ),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                              return;
                                            }

                                            final amount = double.parse(
                                              _paymentController.text,
                                            );
                                            if (amount <= 0) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    'Tutar sıfırdan büyük olmalıdır',
                                                  ),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                              return;
                                            }

                                            final updateAmount =
                                                _isDebt ? amount : -amount;

                                            // Müşteri bakiyesini güncelle
                                            await Provider.of<CustomerProvider>(
                                              context,
                                              listen: false,
                                            ).updateBalance(
                                              customer.id!,
                                              updateAmount,
                                            );

                                            // Tarih formatı
                                            final dateFormat = DateFormat(
                                              'yyyy-MM-dd HH:mm:ss',
                                            );
                                            final now = DateTime.now();
                                            final formattedDate = dateFormat
                                                .format(now);
                                            final notes =
                                                _notesController.text.isNotEmpty
                                                    ? _notesController.text
                                                    : (_isDebt
                                                        ? 'Borç eklendi'
                                                        : 'Ödeme alındı');

                                            // Veritabanına kayıt
                                            final db =
                                                await DatabaseHelper().database;

                                            if (_isDebt) {
                                              // Borç ekleme
                                              final sale = {
                                                'restaurant':
                                                    'Restoran: ${customer.name}',
                                                'amount': amount,
                                                'date': formattedDate,
                                                'productName': 'Borç Kaydı',
                                                'notes': notes,
                                              };

                                              await db.insert(
                                                'restaurant_sales',
                                                sale,
                                              );

                                              // SalesProvider'a da ekleyelim (istatistik için)
                                              final saleModel = Sale(
                                                customerName:
                                                    'Restoran: ${customer.name}',
                                                amount: amount,
                                                date: formattedDate,
                                                isPaid: false,
                                                productName: 'Borç Kaydı',
                                                quantity: 1,
                                                unit: 'adet',
                                                unitPrice: amount,
                                                notes: notes,
                                                customerId: customer.id,
                                              );

                                              await Provider.of<SalesProvider>(
                                                context,
                                                listen: false,
                                              ).addSale(saleModel);
                                            } else {
                                              // Ödeme alma
                                              final sale = {
                                                'restaurant':
                                                    'Restoran: ${customer.name}',
                                                'amount': amount,
                                                'date': formattedDate,
                                                'productName': 'Ödeme Alındı',
                                                'notes': notes,
                                              };

                                              await db.insert(
                                                'restaurant_sales',
                                                sale,
                                              );

                                              // SalesProvider'a da ekleyelim (istatistik için)
                                              final saleModel = Sale(
                                                customerName:
                                                    'Restoran: ${customer.name}',
                                                amount: amount,
                                                date: formattedDate,
                                                isPaid: true,
                                                productName: 'Ödeme Alındı',
                                                quantity: 1,
                                                unit: 'adet',
                                                unitPrice: amount,
                                                notes: notes,
                                                customerId: customer.id,
                                              );

                                              await Provider.of<SalesProvider>(
                                                context,
                                                listen: false,
                                              ).addSale(saleModel);
                                            }

                                            // Ana sayfadaki istatistikleri güncelle
                                            try {
                                              HomePage.updateStatistics(
                                                context,
                                              );
                                            } catch (e) {
                                              print(
                                                'İstatistikler güncellenirken hata: $e',
                                              );
                                            }

                                            Navigator.of(context).pop();

                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  _isDebt
                                                      ? 'Borç eklendi'
                                                      : 'Ödeme alındı',
                                                ),
                                                backgroundColor:
                                                    _isDebt
                                                        ? Colors.orange
                                                        : Colors.green,
                                              ),
                                            );
                                          } catch (e) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text('Hata: $e'),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              _isDebt
                                                  ? Colors.orange
                                                  : Colors.green,
                                        ),
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(
                                            vertical: 12,
                                          ),
                                          child: Text(
                                            _isDebt ? 'Borç Ekle' : 'Ödeme Al',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
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

  // Müşteri işlem geçmişi yükle
  Future<List<Map<String, dynamic>>> _loadCustomerHistory(
    int customerId,
  ) async {
    try {
      final db = await DatabaseHelper().database;
      final List<Map<String, dynamic>> allTransactions = [];

      // Satışlar
      final List<Map<String, dynamic>> sales = await db.query(
        'sales',
        where: 'customerId = ?',
        whereArgs: [customerId],
      );

      // Ödemeler
      final List<Map<String, dynamic>> payments = await db.query(
        'sales',
        where: 'customerId = ? AND productName = ?',
        whereArgs: [customerId, 'Borç Ödemesi'],
      );

      // İşlem tipini ekle
      for (var sale in sales) {
        if (sale['productName'] == 'Borç Ödemesi') {
          sale['transactionType'] = 'payment';
        } else if (sale['isPaid'] == 1) {
          sale['transactionType'] = 'paid_sale';
        } else {
          sale['transactionType'] = 'sale';
        }
      }

      // Tüm işlemleri birleştir
      allTransactions.addAll(sales);

      // Tarihe göre sırala (en yeniden en eskiye)
      allTransactions.sort((a, b) {
        DateTime dateA = DateFormat('yyyy-MM-dd HH:mm:ss').parse(a['date']);
        DateTime dateB = DateFormat('yyyy-MM-dd HH:mm:ss').parse(b['date']);
        return dateB.compareTo(dateA); // Ters sıralama (en yeni en üstte)
      });

      return allTransactions;
    } catch (e) {
      print('Müşteri işlem geçmişi yüklenirken hata: $e');
      return [];
    }
  }

  // İşlem ikonunu belirle
  IconData _getTransactionIcon(String type, bool isPaid) {
    if (type == 'payment') {
      return Icons.payment;
    } else if (type == 'paid_sale') {
      return Icons.shopping_cart;
    } else {
      return Icons.add_shopping_cart;
    }
  }

  // İşlem rengini belirle
  Color _getTransactionColor(String type, bool isPaid) {
    if (type == 'payment') {
      return Colors.blue;
    } else if (type == 'paid_sale') {
      return Colors.green;
    } else {
      return Colors.orange;
    }
  }

  // İşlem başlığını belirle
  String _getTransactionTitle(String type, bool isPaid) {
    if (type == 'payment') {
      return 'Borç Ödemesi';
    } else if (type == 'paid_sale') {
      return 'Satış (Ödendi)';
    } else {
      return 'Satış (Borç)';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFD2B48C), // Tan rengi
      appBar: AppBar(
        title: Text('Müşteri ve Satış Yönetimi'),
        backgroundColor: Color(0xFF8B0000), // Muted Tomato Red
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(CupertinoIcons.back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Müşteri & Borç Takibi'),
            Tab(text: 'Restoran Satışları'),
          ],
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Müşteri ve Borç Takibi Sekmesi
          _buildCustomerTabContent(),

          // Restoran Satışları Sekmesi
          _buildRestaurantSalesTabContent(),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildFloatingActionButton() {
    // Aktif sekmeye göre FAB göster
    if (_tabController.index == 0) {
      return FloatingActionButton(
        onPressed: _showAddCustomerDialog,
        backgroundColor: Color(0xFF8B0000),
        child: Icon(Icons.person_add),
        tooltip: 'Müşteri Ekle',
      );
    } else {
      return Container(); // Restoran satışları tabında FAB gösterme
    }
  }

  // Müşteri Tab İçeriği
  Widget _buildCustomerTabContent() {
    return Column(
      children: [
        // Arama alanı
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: TextField(
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'Müşteri ara...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              filled: true,
              fillColor: Colors.grey.shade100,
              contentPadding: EdgeInsets.symmetric(vertical: 0),
            ),
          ),
        ),

        // Müşteri listesi
        Expanded(
          child: Consumer<CustomerProvider>(
            builder: (context, customerProvider, child) {
              final customers = customerProvider.customers;

              if (customers.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outlined, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Henüz müşteri eklenmemiş',
                        style: TextStyle(fontSize: 18, color: Colors.grey[700]),
                      ),
                      SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _showAddCustomerDialog,
                        icon: Icon(Icons.add),
                        label: Text('Müşteri Ekle'),
                      ),
                    ],
                  ),
                );
              }

              final filteredCustomers =
                  customers
                      .where(
                        (customer) => customer.name.toLowerCase().contains(
                          _searchQuery.toLowerCase(),
                        ),
                      )
                      .toList();

              if (filteredCustomers.isEmpty) {
                return Center(
                  child: Text('Aramanıza uygun müşteri bulunamadı'),
                );
              }

              return ListView.builder(
                itemCount: filteredCustomers.length,
                itemBuilder: (context, index) {
                  final customer = filteredCustomers[index];
                  return Card(
                    margin: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text(
                          customer.name.substring(0, 1).toUpperCase(),
                        ),
                        backgroundColor:
                            customer.balance > 0
                                ? Colors.red.shade200
                                : Colors.green.shade200,
                      ),
                      title: Text(customer.name),
                      subtitle: Row(
                        children: [
                          if (customer.phone.isNotEmpty) ...[
                            Icon(Icons.phone, size: 14),
                            SizedBox(width: 4),
                            Text(customer.phone),
                            SizedBox(width: 8),
                          ],
                          if (customer.balance > 0) ...[
                            Icon(Icons.account_balance, size: 14),
                            SizedBox(width: 4),
                            Text(
                              '${customer.balance.toStringAsFixed(2)} ₺',
                              style: TextStyle(color: Colors.red),
                            ),
                          ],
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.payment, size: 20),
                            onPressed: () => _showPaymentDialog(customer),
                            tooltip: 'Ödeme İşlemi',
                          ),
                          IconButton(
                            icon: Icon(Icons.history, size: 20),
                            onPressed: () => _showCustomerHistory(customer),
                            tooltip: 'İşlem Geçmişi',
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.delete,
                              size: 20,
                              color: Colors.red,
                            ),
                            onPressed:
                                () => _showDeleteCustomerDialog(customer),
                            tooltip: 'Müşteriyi Sil',
                          ),
                        ],
                      ),
                      onTap: () {
                        // Müşteri detay sayfası veya düzenleme
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // Restoran Satışları Tab İçeriği
  Widget _buildRestaurantSalesTabContent() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isEditing
                        ? 'Restoran Satışını Düzenle'
                        : 'Yeni Restoran Satışı',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 12),
                  TextField(
                    controller: _restaurantController,
                    decoration: InputDecoration(
                      labelText: 'Restoran İsmi*',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.restaurant),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 14,
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _buildProductDropdown()),
                      SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _quantityController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Miktar',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.scale),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 14,
                            ),
                          ),
                          onChanged: (value) {
                            _updateTotalAmount();
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _buildUnitDropdown()),
                      SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _unitPriceController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Birim Fiyat',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.attach_money),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 14,
                            ),
                          ),
                          onChanged: (value) {
                            _updateTotalAmount();
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Toplam Tutar (₺)*',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.attach_money),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 14,
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: _notesController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Notlar',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.note),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 14,
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _clearRestaurantSaleForm,
                          icon: Icon(Icons.clear),
                          label: Text('Temizle'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: _addRestaurantSale,
                          icon: Icon(_isEditing ? Icons.update : Icons.add),
                          label: Text(_isEditing ? 'Güncelle' : 'Satış Ekle'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                _isEditing ? Colors.orange : Color(0xFF8B0000),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Restoran Satışları',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                'Kaydırmak için sola sürükleyin',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Expanded(
            child:
                _restaurantSales.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.restaurant, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'Henüz restoran satışı eklenmemiş',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      itemCount: _restaurantSales.length,
                      itemBuilder: (context, index) {
                        final sale = _restaurantSales[index];
                        final date =
                            sale['date'] != null
                                ? DateFormat('dd.MM.yyyy').format(
                                  DateFormat(
                                    'yyyy-MM-dd HH:mm:ss',
                                  ).parse(sale['date']),
                                )
                                : '';

                        return Dismissible(
                          key: ValueKey(sale['id']),
                          background: Container(
                            color: Colors.red,
                            alignment: Alignment.centerRight,
                            padding: EdgeInsets.only(right: 16),
                            child: Icon(Icons.delete, color: Colors.white),
                          ),
                          direction: DismissDirection.endToStart,
                          confirmDismiss: (direction) async {
                            return await showDialog(
                              context: context,
                              builder:
                                  (context) => AlertDialog(
                                    title: Text('Satışı Sil'),
                                    content: Text(
                                      'Bu satışı silmek istediğinize emin misiniz?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed:
                                            () => Navigator.of(
                                              context,
                                            ).pop(false),
                                        child: Text('İptal'),
                                      ),
                                      TextButton(
                                        onPressed:
                                            () =>
                                                Navigator.of(context).pop(true),
                                        child: Text('Sil'),
                                        style: TextButton.styleFrom(
                                          foregroundColor: Colors.red,
                                        ),
                                      ),
                                    ],
                                  ),
                            );
                          },
                          onDismissed: (direction) {
                            _deleteRestaurantSale(sale['id']);
                          },
                          child: Card(
                            margin: EdgeInsets.only(bottom: 8),
                            child: InkWell(
                              onTap: () => _showRestaurantOptions(sale),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Row(
                                            children: [
                                              CircleAvatar(
                                                backgroundColor: Color(
                                                  0xFF8B0000,
                                                ),
                                                child: Icon(
                                                  Icons.restaurant,
                                                  color: Colors.white,
                                                  size: 20,
                                                ),
                                              ),
                                              SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      sale['restaurant'],
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                    SizedBox(height: 4),
                                                    Text(
                                                      date,
                                                      style: TextStyle(
                                                        color: Colors.grey,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          '${sale['amount'].toStringAsFixed(2)} ₺',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: Colors.green,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (sale['productName'] != null &&
                                        sale['productName']
                                            .toString()
                                            .isNotEmpty) ...[
                                      SizedBox(height: 8),
                                      Divider(),
                                      SizedBox(height: 8),
                                      Wrap(
                                        spacing: 8,
                                        children: [
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.shopping_bag,
                                                size: 14,
                                                color: Colors.grey,
                                              ),
                                              SizedBox(width: 4),
                                              Flexible(
                                                child: Text(
                                                  '${sale['productName']}',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (sale['quantity'] != null)
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.scale,
                                                  size: 14,
                                                  color: Colors.grey,
                                                ),
                                                SizedBox(width: 4),
                                                Text(
                                                  '${sale['quantity']} ${sale['unit'] ?? 'adet'}',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ],
                                            ),
                                        ],
                                      ),
                                    ],
                                    if (sale['notes'] != null &&
                                        sale['notes']
                                            .toString()
                                            .isNotEmpty) ...[
                                      SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.note,
                                            size: 14,
                                            color: Colors.grey,
                                          ),
                                          SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              '${sale['notes']}',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontStyle: FontStyle.italic,
                                                color: Colors.grey[700],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
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

                    Navigator.of(context).pop();

                    // Ana sayfadaki istatistikleri güncelle
                    HomePage.updateStatistics(context);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.white),
                            SizedBox(width: 10),
                            Text('Müşteri başarıyla silindi'),
                          ],
                        ),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  } catch (e) {
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
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: Text('Sil'),
              ),
            ],
          ),
    );
  }

  // Restoran satışını ödeme veya işlem geçmişi görüntüleme
  void _showRestaurantOptions(Map<String, dynamic> restaurant) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            insetPadding: EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Container(
              width: double.maxFinite,
              constraints: BoxConstraints(maxHeight: 240),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppBar(
                    title: Text('${restaurant['restaurant']} İşlemleri'),
                    automaticallyImplyLeading: false,
                    actions: [
                      IconButton(
                        icon: Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        InkWell(
                          onTap: () {
                            Navigator.of(context).pop();
                            _editRestaurantSale(restaurant);
                          },
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: Colors.orange.shade100,
                                  child: Icon(Icons.edit, color: Colors.orange),
                                ),
                                SizedBox(width: 16),
                                Text(
                                  'Düzenle',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Divider(),
                        InkWell(
                          onTap: () {
                            Navigator.of(context).pop();
                            _deleteRestaurantSale(restaurant['id']);
                          },
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: Colors.red.shade100,
                                  child: Icon(Icons.delete, color: Colors.red),
                                ),
                                SizedBox(width: 16),
                                Text(
                                  'Sil',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
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
