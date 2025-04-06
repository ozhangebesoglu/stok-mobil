import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/sale.dart';
import '../providers/sales_provider.dart';
import '../services/database/database_helper.dart';
import '../main.dart';

class RestaurantManagement extends StatefulWidget {
  @override
  _RestaurantManagementState createState() => _RestaurantManagementState();
}

class _RestaurantManagementState extends State<RestaurantManagement> {
  final _restaurantController = TextEditingController();
  final _productController = TextEditingController();
  final _quantityController = TextEditingController();
  final _unitPriceController = TextEditingController();
  final _notesController = TextEditingController();
  final _totalAmountController = TextEditingController();
  String _selectedUnit = 'kg';
  List<Map<String, dynamic>> _restaurantSales = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadRestaurantSales();
  }

  @override
  void dispose() {
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
      print('Restoran satışları yüklenirken hata: $e');
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
    if (_restaurantController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lütfen restoran adı girin'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_totalAmountController.text.isEmpty ||
        double.parse(_totalAmountController.text) <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lütfen geçerli bir tutar girin'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Tarih formatı
      final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
      final now = DateTime.now();
      final formattedDate = dateFormat.format(now);

      // Veritabanına ekleme
      final db = await DatabaseHelper().database;
      final sale = {
        'restaurant': _restaurantController.text,
        'amount': double.parse(_totalAmountController.text),
        'date': formattedDate,
        'productName': _productController.text,
        'quantity':
            _quantityController.text.isNotEmpty
                ? double.parse(_quantityController.text)
                : null,
        'unit': _selectedUnit,
        'unitPrice':
            _unitPriceController.text.isNotEmpty
                ? double.parse(_unitPriceController.text)
                : null,
        'notes': _notesController.text,
      };

      await db.insert('restaurant_sales', sale);

      // SalesProvider'a da ekleyelim (istatistik için)
      final saleModel = Sale(
        customerName: 'Restoran: ${_restaurantController.text}',
        amount: double.parse(_totalAmountController.text),
        date: formattedDate,
        isPaid: true,
        productName:
            _productController.text.isEmpty
                ? 'Ürün belirtilmedi'
                : _productController.text,
        quantity:
            _quantityController.text.isEmpty
                ? 1
                : double.parse(_quantityController.text),
        unit: _selectedUnit,
        unitPrice:
            _unitPriceController.text.isEmpty
                ? 0
                : double.parse(_unitPriceController.text),
        notes: _notesController.text,
      );

      await Provider.of<SalesProvider>(
        context,
        listen: false,
      ).addSale(saleModel);

      // Ana sayfadaki istatistikleri güncelle
      HomePage.updateStatistics(context);

      // Form temizle
      _restaurantController.clear();
      _productController.clear();
      _quantityController.clear();
      _unitPriceController.clear();
      _notesController.clear();
      _totalAmountController.clear();

      // Listeyi yenile
      _loadRestaurantSales();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Restoran satışı eklendi'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Satış eklenirken hata: $e');

      try {
        // isPaid olmadan tekrar deneyelim
        final db = await DatabaseHelper().database;
        final sale = {
          'restaurant': _restaurantController.text,
          'amount': double.parse(_totalAmountController.text),
          'date': DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
          'productName': _productController.text,
          'quantity':
              _quantityController.text.isNotEmpty
                  ? double.parse(_quantityController.text)
                  : null,
          'unit': _selectedUnit,
          'unitPrice':
              _unitPriceController.text.isNotEmpty
                  ? double.parse(_unitPriceController.text)
                  : null,
          'notes': _notesController.text,
        };

        await db.insert('restaurant_sales', sale);

        // Listeyi yenile
        _loadRestaurantSales();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Restoran satışı eklendi (alternatif metod)'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e2) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e2'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // Restoran satışı sil
  Future<void> _deleteRestaurantSale(int id) async {
    try {
      final db = await DatabaseHelper().database;
      await db.delete('restaurant_sales', where: 'id = ?', whereArgs: [id]);

      // Listeyi yenile
      _loadRestaurantSales();

      // Ana sayfadaki istatistikleri güncelle
      HomePage.updateStatistics(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Satış silindi'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // Restoran ödeme alma dialogu
  void _showPaymentDialog(String restaurantName) {
    final _paymentController = TextEditingController();
    final _paymentNotesController = TextEditingController();
    bool _isDebt = false;

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
                        controller: _paymentController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Tutar',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.money),
                        ),
                      ),
                      SizedBox(height: 10),
                      TextField(
                        controller: _paymentNotesController,
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
                              groupValue: _isDebt,
                              onChanged: (value) {
                                setState(() {
                                  _isDebt = value!;
                                });
                              },
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<bool>(
                              title: Text('Borç Ekle'),
                              value: true,
                              groupValue: _isDebt,
                              onChanged: (value) {
                                setState(() {
                                  _isDebt = value!;
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
                          if (_paymentController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Lütfen tutar giriniz'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          final amount = double.parse(_paymentController.text);
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
                          final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
                          final now = DateTime.now();
                          final formattedDate = dateFormat.format(now);
                          final notes =
                              _paymentNotesController.text.isNotEmpty
                                  ? _paymentNotesController.text
                                  : (_isDebt ? 'Borç eklendi' : 'Ödeme alındı');

                          // Veritabanı işlemleri
                          final db = await DatabaseHelper().database;

                          try {
                            // Veritabanına kayıt
                            final sale = {
                              'restaurant': restaurantName,
                              'amount': amount,
                              'date': formattedDate,
                              'productName':
                                  _isDebt ? 'Borç Kaydı' : 'Ödeme Alındı',
                              'notes': notes,
                            };

                            await db.insert('restaurant_sales', sale);

                            // SalesProvider'a da ekleyelim (istatistik için)
                            final saleModel = Sale(
                              customerName: 'Restoran: $restaurantName',
                              amount: amount,
                              date: formattedDate,
                              isPaid: !_isDebt,
                              productName:
                                  _isDebt ? 'Borç Kaydı' : 'Ödeme Alındı',
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
                                  _isDebt ? 'Borç eklendi' : 'Ödeme alındı',
                                ),
                                backgroundColor:
                                    _isDebt ? Colors.orange : Colors.green,
                              ),
                            );
                          } catch (e) {
                            print('İlk deneme başarısız: $e');

                            // Alternatif yöntem - isPaid olmadan
                            final sale = {
                              'restaurant': restaurantName,
                              'amount': amount,
                              'date': formattedDate,
                              'productName':
                                  _isDebt ? 'Borç Kaydı' : 'Ödeme Alındı',
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
                                  _isDebt ? 'Borç eklendi' : 'Ödeme alındı',
                                ),
                                backgroundColor:
                                    _isDebt ? Colors.orange : Colors.green,
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
                      child: Text('Kaydet'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                    ),
                  ],
                ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Restoran Satışları'),
        backgroundColor: Colors.brown,
      ),
      body: Column(
        children: [
          // Form alanı
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.brown.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            margin: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Yeni Restoran Satışı',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                // Restoran adı
                TextField(
                  controller: _restaurantController,
                  decoration: InputDecoration(
                    labelText: 'Restoran İsmi*',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.restaurant),
                  ),
                ),
                SizedBox(height: 16),
                // Ürün adı ve miktar
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _productController,
                        decoration: InputDecoration(
                          labelText: 'Ürün Adı',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.shopping_bag),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: _quantityController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Miktar',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.scale),
                        ),
                        onChanged: (value) => _calculateTotalAmount(),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                // Birim ve birim fiyat
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Birim',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.straighten),
                        ),
                        value: _selectedUnit,
                        items:
                            ['kg', 'gr', 'adet', 'litre'].map((unit) {
                              return DropdownMenuItem(
                                value: unit,
                                child: Text(unit),
                              );
                            }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedUnit = value!;
                          });
                        },
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: _unitPriceController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Birim Fiyat',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.attach_money),
                        ),
                        onChanged: (value) => _calculateTotalAmount(),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                // Toplam tutar
                TextField(
                  controller: _totalAmountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Toplam Tutar (₺)*',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.money),
                  ),
                ),
                SizedBox(height: 16),
                // Notlar
                TextField(
                  controller: _notesController,
                  decoration: InputDecoration(
                    labelText: 'Notlar',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.note),
                  ),
                  maxLines: 2,
                ),
                SizedBox(height: 16),
                // Butonlar
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // Form temizle
                          _restaurantController.clear();
                          _productController.clear();
                          _quantityController.clear();
                          _unitPriceController.clear();
                          _notesController.clear();
                          _totalAmountController.clear();
                        },
                        icon: Icon(Icons.clear),
                        label: Text('Temizle'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey,
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _addRestaurantSale,
                        icon: Icon(Icons.add),
                        label: Text('Satış Ekle'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Satışlar listesi başlığı
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Restoran Satışları',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (_isLoading)
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),
          // Satışlar listesi
          Expanded(
            child:
                _isLoading
                    ? Center(child: CircularProgressIndicator())
                    : _restaurantSales.isEmpty
                    ? Center(child: Text('Henüz satış kaydı bulunmuyor'))
                    : ListView.builder(
                      itemCount: _restaurantSales.length,
                      padding: EdgeInsets.all(16),
                      itemBuilder: (context, index) {
                        final sale = _restaurantSales[index];
                        final date = DateFormat('dd.MM.yyyy HH:mm').format(
                          DateFormat('yyyy-MM-dd HH:mm:ss').parse(sale['date']),
                        );

                        final isPayment = sale['productName'] == 'Ödeme Alındı';
                        final isDebt = sale['productName'] == 'Borç Kaydı';

                        return Card(
                          margin: EdgeInsets.only(bottom: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                          child: InkWell(
                            onTap: () {
                              // İşlem seçenekleri
                              showModalBottomSheet(
                                context: context,
                                builder:
                                    (context) => Container(
                                      padding: EdgeInsets.all(16),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          ListTile(
                                            leading: Icon(Icons.payment),
                                            title: Text('Ödeme/Borç Ekle'),
                                            onTap: () {
                                              Navigator.of(context).pop();
                                              _showPaymentDialog(
                                                sale['restaurant'],
                                              );
                                            },
                                          ),
                                          ListTile(
                                            leading: Icon(Icons.delete),
                                            title: Text('Kaydı Sil'),
                                            onTap: () {
                                              Navigator.of(context).pop();
                                              _deleteRestaurantSale(sale['id']);
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                              );
                            },
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            backgroundColor:
                                                isPayment
                                                    ? Colors.green
                                                    : isDebt
                                                    ? Colors.orange
                                                    : Colors.brown,
                                            child: Icon(
                                              isPayment
                                                  ? Icons.payment
                                                  : isDebt
                                                  ? Icons.money_off
                                                  : Icons.restaurant,
                                              color: Colors.white,
                                            ),
                                          ),
                                          SizedBox(width: 12),
                                          Text(
                                            sale['restaurant'],
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        '${sale['amount'].toStringAsFixed(2)} ₺',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color:
                                              isDebt
                                                  ? Colors.red
                                                  : Colors.green,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8),
                                  Text(date),
                                  if (!isPayment &&
                                      !isDebt &&
                                      sale['productName'] != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Text(
                                        'Ürün: ${sale['productName']}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  if (!isPayment &&
                                      !isDebt &&
                                      sale['quantity'] != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: Text(
                                        'Miktar: ${sale['quantity']} ${sale['unit'] ?? ''}',
                                      ),
                                    ),
                                  if (sale['notes'] != null &&
                                      sale['notes'].toString().isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Text(
                                        'Not: ${sale['notes']}',
                                        style: TextStyle(
                                          fontStyle: FontStyle.italic,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ),
                                ],
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
}
