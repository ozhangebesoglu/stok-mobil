import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/product.dart';
import '../models/expense.dart';
import '../providers/stock_provider.dart';
import '../widgets/custom_text_field.dart';
import '../services/database/database_helper.dart';

class StockManagementPage extends StatefulWidget {
  @override
  _StockManagementPageState createState() => _StockManagementPageState();
}

class _StockManagementPageState extends State<StockManagementPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _quantityController = TextEditingController();
  final _unitController = TextEditingController();
  final _purchasePriceController = TextEditingController();
  final _sellingPriceController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'Tümü';
  List<String> _categories = ['Tümü'];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  void _loadCategories() {
    final products =
        Provider.of<StockProvider>(context, listen: false).products;
    final categories = products.map((p) => p.category).toSet().toList();
      setState(() {
      _categories = ['Tümü', ...categories];
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    _purchasePriceController.dispose();
    _sellingPriceController.dispose();
    super.dispose();
  }

  void _showAddProductDialog() {
    // Form değerlerini temizle
    _nameController.clear();
    _categoryController.clear();
    _quantityController.clear();
    _unitController.text = 'kg'; // Varsayılan değer
    _purchasePriceController.clear();
    _sellingPriceController.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Yeni Ürün Ekle',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    Divider(),
                    SizedBox(height: 8),
                    CustomTextField(
                      labelText: 'Ürün Adı',
                      controller: _nameController,
                      prefixIcon: Icons.shopping_bag,
                      isRequired: true,
                    ),
                    CustomTextField(
                      labelText: 'Kategori',
                      controller: _categoryController,
                      prefixIcon: Icons.category,
                      isRequired: true,
                      hintText: 'Örn: Dana, Kuzu, Tavuk',
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            labelText: 'Miktar',
                            controller: _quantityController,
                            prefixIcon: Icons.scale,
                            keyboardType: TextInputType.number,
                            isRequired: true,
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: CustomTextField(
                            labelText: 'Birim',
                            controller: _unitController,
                            prefixIcon: Icons.straighten,
                            isRequired: true,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            labelText: 'Alış Fiyatı (₺)',
                            controller: _purchasePriceController,
                            prefixIcon: Icons.money,
                            keyboardType: TextInputType.number,
                            isRequired: true,
                            onChanged: (value) {
                              // Satış fiyatını hesapla (örn: %20 kar)
                              if (value.isNotEmpty) {
                                try {
                                  double purchasePrice = double.parse(value);
                                  double sellingPrice =
                                      purchasePrice * 1.2; // %20 kar
                                  _sellingPriceController.text = sellingPrice
                                      .toStringAsFixed(2);
                                } catch (_) {}
                              }
                            },
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: CustomTextField(
                            labelText: 'Satış Fiyatı (₺)',
                            controller: _sellingPriceController,
                            prefixIcon: Icons.monetization_on,
                            keyboardType: TextInputType.number,
                            isRequired: true,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _addProduct,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Kaydet',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _addProduct() async {
    if (_formKey.currentState!.validate()) {
      try {
        final quantity = double.parse(_quantityController.text);
        final purchasePrice = double.parse(_purchasePriceController.text);

        final product = Product(
          name: _nameController.text,
          category: _categoryController.text,
          quantity: quantity,
          unit: _unitController.text,
          purchasePrice: purchasePrice,
          sellingPrice: double.parse(_sellingPriceController.text),
        );

        // Ürünü ekle
        await Provider.of<StockProvider>(
          context,
          listen: false,
        ).addProduct(product);

        // Stok alış maliyetini gider olarak ekle
        final totalCost = quantity * purchasePrice;
        await _addStockPurchaseExpense(product.name, totalCost);

        _nameController.clear();
        _categoryController.clear();
        _quantityController.clear();
        _unitController.clear();
        _purchasePriceController.clear();
        _sellingPriceController.clear();

        // Kategorileri güncelle
        _loadCategories();

        Navigator.of(context).pop();

        _showSuccessMessage(
          'Ürün başarıyla eklendi ve alış maliyeti gider olarak kaydedildi',
        );
      } catch (e) {
        _showErrorMessage('Ürün eklenirken hata oluştu: $e');
      }
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

  Future<void> _addStockPurchaseExpense(
    String productName,
    double amount,
  ) async {
    try {
      final expense = Expense(
        description: '$productName stok alımı',
        amount: amount,
        date: DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
        category: 'Stok Alım',
      );

      final db = await DatabaseHelper().database;
      await db.insert('expenses', expense.toMap());
    } catch (e) {
      print('Gider kaydedilirken hata oluştu: $e');
    }
  }

  void _deleteProduct(Product product) {
    showCupertinoDialog(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
            title: Text('Ürünü Sil'),
            content: Text(
              '${product.name} ürününü silmek istediğinize emin misiniz? Bu işlem geri alınamaz.',
            ),
            actions: [
              CupertinoDialogAction(
                child: Text('İptal'),
                onPressed: () => Navigator.pop(context),
              ),
              CupertinoDialogAction(
                child: Text('Sil'),
                isDestructiveAction: true,
                onPressed: () async {
                  try {
                    await Provider.of<StockProvider>(
                      context,
                      listen: false,
                    ).deleteProduct(product.id!);
                    Navigator.pop(context);
                    _showSuccessMessage(
                      '${product.name} ürünü başarıyla silindi',
                    );
                    // Kategorileri güncelle
                    _loadCategories();
                  } catch (e) {
                    Navigator.pop(context);
                    _showErrorMessage('Ürün silinirken hata oluştu: $e');
                  }
                },
              ),
            ],
          ),
    );
  }

  void _showStockUpdateDialog(Product product) {
    final _updateQuantityController = TextEditingController();
    final _purchasePriceController = TextEditingController();
    _purchasePriceController.text = product.purchasePrice.toString();
    bool _isAddition = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder:
              (context, setState) => Container(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${product.name} - Stok Güncelleme',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.close),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                        Divider(),
                        SizedBox(height: 8),
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Mevcut Stok:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${product.quantity} ${product.unit}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Alış Fiyatı:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${product.purchasePrice.toStringAsFixed(2)} ₺',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Satış Fiyatı:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${product.sellingPrice.toStringAsFixed(2)} ₺',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 16),
                        CupertinoSlidingSegmentedControl<bool>(
                          groupValue: _isAddition,
                          children: {
                            true: Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: 10,
                                horizontal: 20,
                              ),
                              child: Text(
                                'Stok Ekle',
                                style: TextStyle(fontSize: 14),
                              ),
                            ),
                            false: Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: 10,
                                horizontal: 20,
                              ),
                              child: Text(
                                'Stok Çıkar',
                                style: TextStyle(fontSize: 14),
                              ),
                            ),
                          },
                          onValueChanged: (value) {
    setState(() {
                              _isAddition = value!;
                            });
                          },
                        ),
                        SizedBox(height: 16),
                        TextField(
                          controller: _updateQuantityController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Miktar',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: Icon(Icons.trending_up),
                          ),
                        ),
                        SizedBox(height: 8),
                        if (_isAddition) ...[
                          TextField(
                            controller: _purchasePriceController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Alış Fiyatı (₺)',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: Icon(Icons.attach_money),
                            ),
                          ),
                          SizedBox(height: 8),
                        ],
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () async {
                                  try {
                                    final amount = double.parse(
                                      _updateQuantityController.text,
                                    );
                                    final updateAmount =
                                        _isAddition ? amount : -amount;

                                    await Provider.of<StockProvider>(
                                      context,
                                      listen: false,
                                    ).updateStock(product.id!, updateAmount);

                                    // Eğer stok ekleme yapıldıysa, bunu bir gider olarak kaydet
                                    if (_isAddition) {
                                      final purchasePrice = double.parse(
                                        _purchasePriceController.text,
                                      );
                                      final totalCost = amount * purchasePrice;
                                      await _addStockPurchaseExpense(
                                        product.name,
                                        totalCost,
                                      );
                                    }

                                    Navigator.of(context).pop();

                                    _showSuccessMessage(
                                      _isAddition
                                          ? 'Stok eklendi ve alış gideri kaydedildi'
                                          : 'Stok çıkarıldı',
                                    );
                                  } catch (e) {
                                    _showErrorMessage('Hata: $e');
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  padding: EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  'Güncelle',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _deleteProduct(product);
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  side: BorderSide(color: Colors.red),
                                  padding: EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  'Ürünü Sil',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
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
              ),
        );
      },
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'dana':
        return Colors.red;
      case 'kuzu':
        return Colors.green;
      case 'tavuk':
        return Colors.orange;
      case 'hindi':
        return Colors.purple;
      case 'balık':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final products = Provider.of<StockProvider>(context).products;

    // Ürünleri filtrele
    final filteredProducts =
        products.where((product) {
          // Kategori filtreleme
          if (_selectedCategory != 'Tümü' &&
              product.category != _selectedCategory) {
            return false;
          }

          // Arama sorgusuna göre filtreleme
          if (_searchQuery.isNotEmpty) {
            return product.name.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ||
                product.category.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                );
          }

          return true;
        }).toList();

    return Scaffold(
      backgroundColor: Color(0xFFD2B48C), // Tan rengi
      appBar: AppBar(
        title: Text('Stok Yönetimi'),
        backgroundColor: Color(0xFF8B0000), // Muted Tomato Red
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(CupertinoIcons.back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Arama ve Filtreleme
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            color: Colors.white,
            child: Column(
              children: [
                CupertinoSearchTextField(
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  placeholder: 'Ürün ara...',
                  padding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                ),
                SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      Text(
                        'Kategori: ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      SizedBox(width: 8),
                      ...List.generate(_categories.length, (index) {
                        final category = _categories[index];
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Text(category),
                            selected: _selectedCategory == category,
                            selectedColor: Colors.blue.shade100,
                            labelStyle: TextStyle(
                              color:
                                  _selectedCategory == category
                                      ? Colors.blue.shade800
                                      : Colors.black,
                              fontSize: 13,
                            ),
                            onSelected: (selected) {
                              setState(() {
                                _selectedCategory = category;
                              });
                            },
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Ürün listesi
          Expanded(
            child: Consumer<StockProvider>(
              builder: (context, stockProvider, child) {
                final products = stockProvider.products;

                if (products.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          CupertinoIcons.cube_box,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Henüz ürün eklenmemiş',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[700],
                          ),
                        ),
                        SizedBox(height: 16),
                        CupertinoButton.filled(
                          onPressed: _showAddProductDialog,
                          child: Text('Ürün Ekle'),
                        ),
                      ],
                    ),
                  );
                }

                if (filteredProducts.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          CupertinoIcons.search,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text('Arama kriterine uygun ürün bulunamadı.'),
                        SizedBox(height: 16),
                        CupertinoButton(
                          onPressed: () {
                            setState(() {
                              _searchQuery = '';
                              _selectedCategory = 'Tümü';
                            });
                          },
                          child: Text('Filtreleri Temizle'),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: filteredProducts.length,
                  padding: EdgeInsets.all(8),
              itemBuilder: (context, index) {
                    final product = filteredProducts[index];
                    final isLowStock =
                        product.quantity < 5; // Örnek düşük stok kontrolü

                    return Dismissible(
                      key: Key(product.id.toString()),
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: EdgeInsets.only(right: 20.0),
                        color: Colors.red,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(CupertinoIcons.delete, color: Colors.white),
                            SizedBox(height: 4),
                            Text('Sil', style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                      direction: DismissDirection.endToStart,
                      confirmDismiss: (direction) async {
                        return await showCupertinoDialog<bool>(
                          context: context,
                          builder:
                              (context) => CupertinoAlertDialog(
                                title: Text('Ürünü Sil'),
                                content: Text(
                                  '${product.name} ürününü silmek istediğinize emin misiniz?',
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
                      onDismissed: (direction) async {
                        try {
                          await Provider.of<StockProvider>(
                            context,
                            listen: false,
                          ).deleteProduct(product.id!);
                          _showSuccessMessage(
                            '${product.name} ürünü başarıyla silindi',
                          );
                          // Kategorileri güncelle
                          _loadCategories();
                        } catch (e) {
                          _showErrorMessage('Ürün silinirken hata oluştu: $e');
                        }
                      },
                      child: Card(
                        elevation: 0,
                        margin: EdgeInsets.symmetric(vertical: 4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color:
                                isLowStock
                                    ? Colors.red.shade300
                                    : Colors.grey.shade200,
                            width: isLowStock ? 1 : 0.5,
                          ),
                        ),
                        child: InkWell(
                          onTap: () => _showStockUpdateDialog(product),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                CircleAvatar(
                                  backgroundColor: _getCategoryColor(
                                    product.category,
                                  ).withOpacity(0.2),
                                  foregroundColor: _getCategoryColor(
                                    product.category,
                                  ),
                                  child: Text(
                                    product.name.substring(0, 1).toUpperCase(),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: _getCategoryColor(
                                        product.category,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product.name,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        product.category,
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 13,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(
                                            CupertinoIcons.cube_box,
                                            size: 14,
                                            color: Colors.blue,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            '${product.quantity} ${product.unit}',
                                            style: TextStyle(fontSize: 13),
                                          ),
                                          SizedBox(width: 12),
                                          Icon(
                                            CupertinoIcons.money_dollar,
                                            size: 14,
                                            color: Colors.green,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            '${product.sellingPrice.toStringAsFixed(2)} ₺',
                                            style: TextStyle(fontSize: 13),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                if (isLowStock)
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          CupertinoIcons
                                              .exclamationmark_triangle,
                                          size: 14,
                                          color: Colors.red,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'Az Stok',
                                          style: TextStyle(
                                            color: Colors.red,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                SizedBox(width: 4),
                                Icon(
                                  CupertinoIcons.chevron_right,
                                  color: Colors.grey,
                                  size: 16,
                                ),
                              ],
                            ),
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
      floatingActionButton: Container(
        width: 160,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.blue,
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
            onTap: _showAddProductDialog,
            borderRadius: BorderRadius.circular(25),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.add, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Ürün Ekle',
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
