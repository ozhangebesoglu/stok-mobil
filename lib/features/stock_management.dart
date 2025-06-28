import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/product.dart';
import '../models/expense.dart';
import '../providers/stock_provider.dart';
import '../widgets/custom_text_field.dart';
import '../services/database/database_helper.dart';
import '../core/utils/logger.dart';

class StockManagementPage extends StatefulWidget {
  const StockManagementPage({super.key});

  @override
  State<StockManagementPage> createState() => _StockManagementPageState();
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
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await Provider.of<StockProvider>(context, listen: false).loadProducts();
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
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;

        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
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
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.close,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    Divider(color: colorScheme.outline.withAlpha(51)),
                    SizedBox(height: 16),
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
                    SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _addProduct,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 1,
                        ),
                        child: Text(
                          'Kaydet',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
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
        if (kDebugMode) {
          Logger.debug('Form validation passed, starting product addition...');
        }

        final quantity = double.parse(_quantityController.text);
        final purchasePrice = double.parse(_purchasePriceController.text);

        final product = Product(
          name: _nameController.text.trim(),
          category: _categoryController.text.trim(),
          quantity: quantity,
          unit: _unitController.text.trim(),
          purchasePrice: purchasePrice,
          sellingPrice: double.parse(_sellingPriceController.text),
        );

        if (kDebugMode) {
          Logger.debug('Product created: ${product.toString()}');
          Logger.debug('Product isValid: ${product.isValid}');
        }

        // Ürünü ekle ve sonucu kontrol et
        final stockProvider = Provider.of<StockProvider>(
          context,
          listen: false,
        );
        final success = await stockProvider.addProduct(product);

        if (kDebugMode) {
          Logger.debug('AddProduct result: $success');
          Logger.debug('Provider error: ${stockProvider.errorMessage}');
          Logger.debug(
            'Products count after add: ${stockProvider.products.length}',
          );
        }

        if (success) {
          // Stok alış maliyetini gider olarak ekle
          final totalCost = quantity * purchasePrice;
          await _addStockPurchaseExpense(product.name, totalCost);

          // Form temizle
          _nameController.clear();
          _categoryController.clear();
          _quantityController.clear();
          _unitController.clear();
          _purchasePriceController.clear();
          _sellingPriceController.clear();

          // Kategorileri güncelle
          _loadCategories();

          // Modal'ı kapat
          Navigator.of(context).pop();

          // Başarı mesajı göster
          _showSuccessMessage(
            'Ürün başarıyla eklendi ve alış maliyeti gider olarak kaydedildi',
          );

          // Provider'ı yeniden yükle (state refresh)
          await stockProvider.loadProducts();

          if (kDebugMode) {
            Logger.debug(
              'Products reloaded, count: ${stockProvider.products.length}',
            );
          }
        } else {
          // Hata mesajını provider'dan al
          final errorMessage = stockProvider.errorMessage;
          _showErrorMessage(
            errorMessage ?? 'Ürün eklenirken bilinmeyen hata oluştu',
          );
        }
      } catch (e) {
        _showErrorMessage('Ürün eklenirken hata oluştu: $e');
        if (kDebugMode) {
          Logger.error('_addProduct error', e);
        }
      }
    } else {
      if (kDebugMode) {
        Logger.debug('Form validation failed');
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
        backgroundColor: Theme.of(context).colorScheme.primary,
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
        backgroundColor: Theme.of(context).colorScheme.error,
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
      Logger.error('Gider kaydedilirken hata oluştu', e);
    }
  }

  void _showStockUpdateDialog(Product product) {
    final updateQuantityController = TextEditingController();
    final purchasePriceController = TextEditingController();
    final sellingPriceController = TextEditingController();
    final nameController = TextEditingController();
    final categoryController = TextEditingController();
    final unitController = TextEditingController();

    // Mevcut değerleri doldur
    purchasePriceController.text = product.purchasePrice.toString();
    sellingPriceController.text = product.sellingPrice.toString();
    nameController.text = product.name;
    categoryController.text = product.category;
    unitController.text = product.unit;

    bool isAddition = true;
    bool isEditMode = false; // Düzenleme modu kontrolü

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;

        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          isEditMode
                              ? '${product.name} - Ürün Düzenle'
                              : '${product.name} - Stok Güncelleme',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              isEditMode ? Icons.inventory : Icons.edit,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            onPressed: () {
                              setState(() {
                                isEditMode = !isEditMode;
                              });
                            },
                            tooltip:
                                isEditMode ? 'Stok Modu' : 'Düzenleme Modu',
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.close,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Divider(color: colorScheme.outline.withAlpha(51)),
                  SizedBox(height: 16),

                  if (!isEditMode) ...[
                    // Stok güncelleme modu
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withAlpha(
                          77,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: colorScheme.outline.withAlpha(51),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Mevcut Stok:',
                                style: TextStyle(fontWeight: FontWeight.bold),
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
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Alış Fiyatı:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '${product.purchasePrice.toStringAsFixed(2)} ₺',
                                style: TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Satış Fiyatı:',
                                style: TextStyle(fontWeight: FontWeight.bold),
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
                      groupValue: isAddition,
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
                          isAddition = value!;
                        });
                      },
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: updateQuantityController,
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
                    if (isAddition) ...[
                      TextField(
                        controller: purchasePriceController,
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
                  ] else ...[
                    // Ürün düzenleme modu
                    Text(
                      'Ürün Bilgilerini Düzenle',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Ürün Adı',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: Icon(Icons.shopping_bag),
                      ),
                    ),
                    SizedBox(height: 12),
                    TextField(
                      controller: categoryController,
                      decoration: InputDecoration(
                        labelText: 'Kategori',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: Icon(Icons.category),
                      ),
                    ),
                    SizedBox(height: 12),
                    TextField(
                      controller: unitController,
                      decoration: InputDecoration(
                        labelText: 'Birim',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: Icon(Icons.straighten),
                      ),
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: purchasePriceController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Alış Fiyatı (₺)',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: Icon(Icons.attach_money),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: sellingPriceController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Satış Fiyatı (₺)',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: Icon(Icons.monetization_on),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                  ],

                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            try {
                              if (isEditMode) {
                                // Ürün bilgilerini güncelle
                                final updatedProduct = Product(
                                  id: product.id,
                                  name: nameController.text.trim(),
                                  category: categoryController.text.trim(),
                                  quantity: product.quantity,
                                  unit: unitController.text.trim(),
                                  purchasePrice: double.parse(
                                    purchasePriceController.text,
                                  ),
                                  sellingPrice: double.parse(
                                    sellingPriceController.text,
                                  ),
                                );

                                await Provider.of<StockProvider>(
                                  context,
                                  listen: false,
                                ).updateProduct(updatedProduct);

                                Navigator.pop(context);
                                _showSuccessMessage(
                                  'Ürün bilgileri başarıyla güncellendi',
                                );
                                _loadCategories(); // Kategorileri yenile
                              } else {
                                // Stok güncelle
                                final amount = double.parse(
                                  updateQuantityController.text,
                                );
                                final updateAmount =
                                    isAddition ? amount : -amount;

                                await Provider.of<StockProvider>(
                                  context,
                                  listen: false,
                                ).updateStock(
                                  productId: product.id!,
                                  newQuantity: updateAmount,
                                );

                                // Eğer stok ekleme yapıldıysa, bunu bir gider olarak kaydet
                                if (isAddition) {
                                  final purchasePrice = double.parse(
                                    purchasePriceController.text,
                                  );
                                  final totalCost = amount * purchasePrice;
                                  await _addStockPurchaseExpense(
                                    product.name,
                                    totalCost,
                                  );
                                }

                                Navigator.pop(context);
                                _showSuccessMessage(
                                  isAddition
                                      ? 'Stok başarıyla eklendi'
                                      : 'Stok başarıyla çıkarıldı',
                                );
                              }
                            } catch (e) {
                              _showErrorMessage('Hata: $e');
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                isEditMode
                                    ? Colors.blue
                                    : (isAddition
                                        ? Colors.green
                                        : Colors.orange),
                            padding: EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            isEditMode
                                ? 'Bilgileri Güncelle'
                                : (isAddition ? 'Stok Ekle' : 'Stok Çıkar'),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
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
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Stok Yönetimi',
          style: theme.textTheme.titleLarge?.copyWith(
            color: colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        leading: IconButton(
          icon: Icon(CupertinoIcons.back, color: colorScheme.onPrimary),
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
              vertical: 12.0,
            ),
            color: colorScheme.surface,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withAlpha(77),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: colorScheme.outline.withAlpha(51),
                    ),
                  ),
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Ürün ara...',
                      prefixIcon: Icon(
                        Icons.search,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                      hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                    style: TextStyle(color: colorScheme.onSurface),
                  ),
                ),
                SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      Text(
                        'Kategori: ',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      SizedBox(width: 8),
                      ...List.generate(_categories.length, (index) {
                        final category = _categories[index];
                        final isSelected = _selectedCategory == category;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: FilterChip(
                            label: Text(category),
                            selected: isSelected,
                            selectedColor: colorScheme.primaryContainer,
                            backgroundColor: colorScheme.surfaceContainerHighest
                                .withAlpha(77),
                            labelStyle: TextStyle(
                              color:
                                  isSelected
                                      ? colorScheme.onPrimaryContainer
                                      : colorScheme.onSurfaceVariant,
                              fontSize: 13,
                              fontWeight:
                                  isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                            ),
                            side: BorderSide(
                              color:
                                  isSelected
                                      ? colorScheme.primary
                                      : colorScheme.outline.withAlpha(77),
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
                          color: colorScheme.onSurfaceVariant,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Henüz ürün eklenmemiş',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _showAddProductDialog,
                          icon: Icon(Icons.add),
                          label: Text('Ürün Ekle'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                          ),
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
                          color: colorScheme.onSurfaceVariant,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Arama kriterine uygun ürün bulunamadı.',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        SizedBox(height: 16),
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _searchQuery = '';
                              _selectedCategory = 'Tümü';
                            });
                          },
                          icon: Icon(Icons.clear_all),
                          label: Text('Filtreleri Temizle'),
                          style: TextButton.styleFrom(
                            foregroundColor: colorScheme.primary,
                          ),
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
                                    isDestructiveAction: true,
                                    onPressed:
                                        () => Navigator.pop(context, true),
                                    child: Text('Sil'),
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
                        elevation: 1,
                        color: colorScheme.surface,
                        surfaceTintColor: colorScheme.surfaceTint,
                        margin: EdgeInsets.symmetric(vertical: 4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color:
                                isLowStock
                                    ? colorScheme.error.withAlpha(128)
                                    : colorScheme.outline.withAlpha(51),
                            width: isLowStock ? 1.5 : 0.5,
                          ),
                        ),
                        child: InkWell(
                          onTap: () => _showStockUpdateDialog(product),
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: _getCategoryColor(
                                      product.category,
                                    ).withAlpha(25),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      product.name
                                          .substring(0, 1)
                                          .toUpperCase(),
                                      style: theme.textTheme.titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: _getCategoryColor(
                                              product.category,
                                            ),
                                          ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product.name,
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              color: colorScheme.onSurface,
                                            ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        product.category,
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                              color:
                                                  colorScheme.onSurfaceVariant,
                                            ),
                                      ),
                                      SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: colorScheme
                                                  .primaryContainer
                                                  .withAlpha(77),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  CupertinoIcons.cube_box,
                                                  size: 12,
                                                  color: colorScheme.primary,
                                                ),
                                                SizedBox(width: 4),
                                                Text(
                                                  '${product.quantity} ${product.unit}',
                                                  style: theme
                                                      .textTheme
                                                      .bodySmall
                                                      ?.copyWith(
                                                        color:
                                                            colorScheme
                                                                .onPrimaryContainer,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            '${product.sellingPrice.toStringAsFixed(2)} ₺',
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                                  color: colorScheme.primary,
                                                  fontWeight: FontWeight.w600,
                                                ),
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
                                      color: colorScheme.errorContainer,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          CupertinoIcons
                                              .exclamationmark_triangle,
                                          size: 12,
                                          color: colorScheme.onErrorContainer,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'Az Stok',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color:
                                                    colorScheme
                                                        .onErrorContainer,
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                SizedBox(width: 8),
                                Icon(
                                  CupertinoIcons.chevron_right,
                                  color: colorScheme.onSurfaceVariant,
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddProductDialog,
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 3,
        icon: Icon(CupertinoIcons.add),
        label: Text(
          'Ürün Ekle',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
    );
  }
}
