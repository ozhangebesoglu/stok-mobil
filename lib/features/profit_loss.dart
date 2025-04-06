import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../providers/sales_provider.dart';
import '../widgets/custom_text_field.dart';
import '../services/database/database_helper.dart';

class ProfitLossPage extends StatefulWidget {
  @override
  _ProfitLossPageState createState() => _ProfitLossPageState();
}

class _ProfitLossPageState extends State<ProfitLossPage> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _categoryController = TextEditingController();

  List<Expense> _expenses = [];
  List<Map<String, dynamic>> _incomes = [];
  double _totalIncome = 0;
  double _totalExpense = 0;
  String _selectedPeriod = 'Bu Ay'; // "Bu Gün", "Bu Hafta", "Bu Ay", "Tümü"

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await _loadExpenses();
    await _loadIncomes();
    await _calculateIncome();
    _calculateProfit();
  }

  Future<void> _loadExpenses() async {
    final db = await DatabaseHelper().database;

    // Tarihe göre filtreleme
    String? dateFilter;
    DateTime now = DateTime.now();

    if (_selectedPeriod == 'Bu Gün') {
      String today = DateFormat('yyyy-MM-dd').format(now);
      dateFilter = "date LIKE '$today%'";
    } else if (_selectedPeriod == 'Bu Hafta') {
      DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      String startDate = DateFormat('yyyy-MM-dd').format(startOfWeek);
      dateFilter = "date >= '$startDate'";
    } else if (_selectedPeriod == 'Bu Ay') {
      String currentMonth = DateFormat('yyyy-MM').format(now);
      dateFilter = "date LIKE '$currentMonth%'";
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'expenses',
      where: dateFilter,
      orderBy: 'date DESC',
    );

    setState(() {
      _expenses = List.generate(maps.length, (i) {
        return Expense.fromMap(maps[i]);
      });

      _totalExpense = _expenses.fold(0, (sum, expense) => sum + expense.amount);
    });
  }

  Future<void> _loadIncomes() async {
    final db = await DatabaseHelper().database;

    // Tarihe göre filtreleme
    String? dateFilter;
    DateTime now = DateTime.now();

    if (_selectedPeriod == 'Bu Gün') {
      String today = DateFormat('yyyy-MM-dd').format(now);
      dateFilter = "date LIKE '$today%'";
    } else if (_selectedPeriod == 'Bu Hafta') {
      DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      String startDate = DateFormat('yyyy-MM-dd').format(startOfWeek);
      dateFilter = "date >= '$startDate'";
    } else if (_selectedPeriod == 'Bu Ay') {
      String currentMonth = DateFormat('yyyy-MM').format(now);
      dateFilter = "date LIKE '$currentMonth%'";
    }

    // Manuel eklenen gelirler
    final List<Map<String, dynamic>> manualIncomes = await db.query(
      'manual_incomes',
      where: dateFilter,
      orderBy: 'date DESC',
    );

    // Borç ödemeleri (ödeme alınan satışlar)
    final List<Map<String, dynamic>> debtPayments = await db.query(
      'sales',
      where:
          dateFilter != null
              ? "$dateFilter AND productName = 'Borç Ödemesi' AND isPaid = 1"
              : "productName = 'Borç Ödemesi' AND isPaid = 1",
      orderBy: 'date DESC',
    );

    // Borç ödemelerini manuel gelirler gibi formatlayalım
    for (var payment in debtPayments) {
      final Map<String, dynamic> incomeFormat = {
        'id': payment['id'],
        'description': 'Müşteri Ödemesi: ${payment['customerName']}',
        'amount': payment['amount'],
        'date': payment['date'],
        'category': 'Müşteri Ödemesi',
        'sourceType': 'payment', // Kaynak tipini belirtelim
        'sourceId': payment['id'],
      };
      manualIncomes.add(incomeFormat);
    }

    // Restoran satışları
    final List<Map<String, dynamic>> restaurantSales = await db.query(
      'restaurant_sales',
      where: dateFilter,
      orderBy: 'date DESC',
    );

    // Restoran satışlarını aynı formata çevirelim
    for (var sale in restaurantSales) {
      final Map<String, dynamic> incomeFormat = {
        'id': sale['id'],
        'description': 'Restoran Satışı: ${sale['restaurant']}',
        'amount': sale['amount'],
        'date': sale['date'],
        'category': 'Restoran Satışı',
        'sourceType': 'restaurant', // Kaynak tipini belirtelim
        'sourceId': sale['id'],
      };
      manualIncomes.add(incomeFormat);
    }

    // Tarihe göre sıralayalım (en yeniden en eskiye)
    manualIncomes.sort((a, b) {
      DateTime dateA = DateFormat(
        'yyyy-MM-dd HH:mm:ss',
      ).parse(a['date'].toString());
      DateTime dateB = DateFormat(
        'yyyy-MM-dd HH:mm:ss',
      ).parse(b['date'].toString());
      return dateB.compareTo(dateA);
    });

    setState(() {
      _incomes = manualIncomes;
    });
  }

  Future<void> _calculateIncome() async {
    try {
      final db = await DatabaseHelper().database;
      double totalIncome = 0.0;

      // Tarihe göre filtreleme
      String? dateFilter;
      DateTime now = DateTime.now();

      if (_selectedPeriod == 'Bu Gün') {
        String today = DateFormat('yyyy-MM-dd').format(now);
        dateFilter = "date LIKE '$today%'";
      } else if (_selectedPeriod == 'Bu Hafta') {
        DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        String startDate = DateFormat('yyyy-MM-dd').format(startOfWeek);
        dateFilter = "date >= '$startDate'";
      } else if (_selectedPeriod == 'Bu Ay') {
        String currentMonth = DateFormat('yyyy-MM').format(now);
        dateFilter = "date LIKE '$currentMonth%'";
      }

      // 1. Satışlardan gelen gelirler (ödemesi alınanlar)
      final salesQuery =
          dateFilter != null
              ? "SELECT SUM(amount) as total FROM sales WHERE $dateFilter AND isPaid = 1"
              : "SELECT SUM(amount) as total FROM sales WHERE isPaid = 1";

      final salesResult = await db.rawQuery(salesQuery);
      final salesTotal =
          salesResult.isNotEmpty && salesResult.first['total'] != null
              ? _parseToDouble(salesResult.first['total'])
              : 0.0;

      // 2. Manuel eklenen gelirler
      final manualQuery =
          dateFilter != null
              ? "SELECT SUM(amount) as total FROM manual_incomes WHERE $dateFilter"
              : "SELECT SUM(amount) as total FROM manual_incomes";

      final manualResult = await db.rawQuery(manualQuery);
      final manualTotal =
          manualResult.isNotEmpty && manualResult.first['total'] != null
              ? _parseToDouble(manualResult.first['total'])
              : 0.0;

      // 3. Restoran satışları
      final restaurantQuery =
          dateFilter != null
              ? "SELECT SUM(amount) as total FROM restaurant_sales WHERE $dateFilter"
              : "SELECT SUM(amount) as total FROM restaurant_sales";

      final restaurantResult = await db.rawQuery(restaurantQuery);
      final restaurantTotal =
          restaurantResult.isNotEmpty && restaurantResult.first['total'] != null
              ? _parseToDouble(restaurantResult.first['total'])
              : 0.0;

      // Toplam gelir
      totalIncome = salesTotal + manualTotal + restaurantTotal;

      // Hata ayıklama için logger ekleyelim
      print('Kâr-Zarar Hesabı Detayları:');
      print('Seçili Dönem: $_selectedPeriod');
      print('Satışlardan Gelen Gelir: $salesTotal');
      print('Manuel Gelirler: $manualTotal');
      print('Restoran Satışları: $restaurantTotal');
      print('Toplam Gelir: $totalIncome');

      setState(() {
        _totalIncome = totalIncome;
      });
    } catch (e) {
      print('Gelir hesaplanırken hata: $e');
      setState(() {
        _totalIncome = 0;
      });
    }
  }

  // SQLite değerini double'a çevirme yardımcı metodu
  double _parseToDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  void _calculateProfit() {
    setState(() {
      // Kâr-zarar hesabı otomatik olarak yapılır
    });
  }

  void _showAddExpenseDialog({Expense? expense}) {
    final bool isEditing = expense != null;

    // Form değerlerini ayarla
    _descriptionController.text = isEditing ? expense.description : '';
    _amountController.text = isEditing ? expense.amount.toString() : '';
    _categoryController.text = isEditing ? expense.category : 'Genel';

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.add_shopping_cart, color: Colors.red),
                SizedBox(width: 10),
                Text(isEditing ? 'Gider Düzenle' : 'Yeni Gider Ekle'),
              ],
            ),
            content: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomTextField(
                    labelText: 'Açıklama',
                    controller: _descriptionController,
                    prefixIcon: Icons.description,
                    isRequired: true,
                  ),
                  CustomTextField(
                    labelText: 'Tutar',
                    controller: _amountController,
                    prefixIcon: Icons.money,
                    keyboardType: TextInputType.number,
                    isRequired: true,
                  ),
                  CustomTextField(
                    labelText: 'Kategori',
                    controller: _categoryController,
                    prefixIcon: Icons.category,
                  ),
                ],
              ),
            ),
            actions: [
              if (isEditing)
                TextButton(
                  onPressed: () async {
                    await _deleteExpense(expense);
                    Navigator.of(context).pop();
                  },
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: Text('Sil'),
                ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('İptal'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (isEditing) {
                    _updateExpense(expense);
                  } else {
                    _addExpense();
                  }
                },
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

  void _showAddIncomeDialog() {
    // Form değerlerini temizle
    _descriptionController.text = '';
    _amountController.text = '';
    _categoryController.text = 'Genel';

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.trending_up, color: Colors.green),
                SizedBox(width: 10),
                Text('Yeni Gelir Ekle'),
              ],
            ),
            content: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomTextField(
                    labelText: 'Açıklama',
                    controller: _descriptionController,
                    prefixIcon: Icons.description,
                    isRequired: true,
                  ),
                  CustomTextField(
                    labelText: 'Tutar',
                    controller: _amountController,
                    prefixIcon: Icons.money,
                    keyboardType: TextInputType.number,
                    isRequired: true,
                  ),
                  CustomTextField(
                    labelText: 'Kategori',
                    controller: _categoryController,
                    prefixIcon: Icons.category,
                  ),
                ],
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
                onPressed: _addIncome,
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

  Future<void> _addExpense() async {
    if (_formKey.currentState!.validate()) {
      try {
        final expense = Expense(
          description: _descriptionController.text,
          amount: double.parse(_amountController.text),
          date: DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
          category: _categoryController.text,
        );

        final db = await DatabaseHelper().database;
        await db.insert('expenses', expense.toMap());

        Navigator.of(context).pop();

        // Verileri yeniden yükle
        _loadData();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gider başarıyla eklendi'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gider eklenirken hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateExpense(Expense expense) async {
    if (_formKey.currentState!.validate()) {
      try {
        final updatedExpense = Expense(
          id: expense.id,
          description: _descriptionController.text,
          amount: double.parse(_amountController.text),
          date: expense.date, // Tarihi değiştirmiyoruz
          category: _categoryController.text,
        );

        final db = await DatabaseHelper().database;
        await db.update(
          'expenses',
          updatedExpense.toMap(),
          where: 'id = ?',
          whereArgs: [expense.id],
        );

        Navigator.of(context).pop();

        // Verileri yeniden yükle
        _loadData();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gider başarıyla güncellendi'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gider güncellenirken hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteExpense(Expense expense) async {
    try {
      final db = await DatabaseHelper().database;
      await db.delete('expenses', where: 'id = ?', whereArgs: [expense.id]);

      // Verileri yeniden yükle
      _loadData();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gider başarıyla silindi'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gider silinirken hata oluştu: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _addIncome() async {
    if (_formKey.currentState!.validate()) {
      try {
        final income = {
          'description': _descriptionController.text,
          'amount': double.parse(_amountController.text),
          'date': DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
          'category': _categoryController.text,
        };

        final db = await DatabaseHelper().database;
        await db.insert('manual_incomes', income);

        Navigator.of(context).pop();

        // Verileri yeniden yükle
        _loadData();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gelir başarıyla eklendi'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gelir eklenirken hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteIncome(int id) async {
    try {
      final db = await DatabaseHelper().database;
      await db.delete('manual_incomes', where: 'id = ?', whereArgs: [id]);

      // Verileri yeniden yükle
      _loadData();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gelir başarıyla silindi'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gelir silinirken hata oluştu: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showEditIncomeDialog(Map<String, dynamic> income) {
    // Form değerlerini doldur
    _descriptionController.text = income['description'] ?? '';
    _amountController.text = income['amount'].toString();
    _categoryController.text = income['category'] ?? 'Genel';

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.edit, color: Colors.blue),
                SizedBox(width: 10),
                Text('Geliri Düzenle'),
              ],
            ),
            content: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomTextField(
                    labelText: 'Açıklama',
                    controller: _descriptionController,
                    prefixIcon: Icons.description,
                    isRequired: true,
                  ),
                  CustomTextField(
                    labelText: 'Tutar',
                    controller: _amountController,
                    prefixIcon: Icons.money,
                    keyboardType: TextInputType.number,
                    isRequired: true,
                  ),
                  CustomTextField(
                    labelText: 'Kategori',
                    controller: _categoryController,
                    prefixIcon: Icons.category,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => _deleteIncome(income['id']),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: Text('Sil'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('İptal'),
              ),
              ElevatedButton(
                onPressed: () => _updateIncome(income['id']),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.save, size: 16),
                    SizedBox(width: 8),
                    Text('Güncelle'),
                  ],
                ),
              ),
            ],
          ),
    );
  }

  Future<void> _updateIncome(int id) async {
    if (_formKey.currentState!.validate()) {
      try {
        final income = {
          'description': _descriptionController.text,
          'amount': double.parse(_amountController.text),
          'category': _categoryController.text,
        };

        final db = await DatabaseHelper().database;
        await db.update(
          'manual_incomes',
          income,
          where: 'id = ?',
          whereArgs: [id],
        );

        Navigator.of(context).pop();

        // Verileri yeniden yükle
        _loadData();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gelir başarıyla güncellendi'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gelir güncellenirken hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Kâr veya zarar hesapla
    final profit = _totalIncome - _totalExpense;
    final isProfitable = profit >= 0;

    return Scaffold(
      backgroundColor: Color(0xFFD2B48C), // Tan rengi
      appBar: AppBar(
        title: Text('Kâr-Zarar Hesabı'),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                _selectedPeriod = value;
                _loadData();
              });
            },
            itemBuilder:
                (context) => [
                  PopupMenuItem(value: 'Bu Gün', child: Text('Bu Gün')),
                  PopupMenuItem(value: 'Bu Hafta', child: Text('Bu Hafta')),
                  PopupMenuItem(value: 'Bu Ay', child: Text('Bu Ay')),
                  PopupMenuItem(value: 'Tümü', child: Text('Tümü')),
                ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Özet Kartları
              Text(
                '$_selectedPeriod Özeti',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      title: 'Gelir',
                      amount: _totalIncome,
                      icon: Icons.arrow_upward,
                      color: Colors.green,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryCard(
                      title: 'Gider',
                      amount: _totalExpense,
                      icon: Icons.arrow_downward,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              _buildSummaryCard(
                title: isProfitable ? 'Kâr' : 'Zarar',
                amount: profit.abs(),
                icon: isProfitable ? Icons.trending_up : Icons.trending_down,
                color: isProfitable ? Colors.green : Colors.red,
                fullWidth: true,
              ),

              SizedBox(height: 24),

              // İşlem Butonları
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _showAddIncomeDialog,
                      icon: Icon(Icons.add),
                      label: Text('Gelir Ekle'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _showAddExpenseDialog,
                      icon: Icon(Icons.add),
                      label: Text('Gider Ekle'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 24),

              // Gelirler ve Giderler Bölümü
              Row(
                children: [
                  // Gelirler Bölümü
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Gelirler',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        if (_incomes.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.trending_up,
                                    size: 32,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Henüz gelir kaydı yok',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ListView.builder(
                              physics: NeverScrollableScrollPhysics(),
                              shrinkWrap: true,
                              itemCount: _incomes.length,
                              itemBuilder: (context, index) {
                                final income = _incomes[index];
                                final date = DateFormat('dd.MM.yyyy').format(
                                  DateFormat(
                                    'yyyy-MM-dd HH:mm:ss',
                                  ).parse(income['date']),
                                );

                                return Dismissible(
                                  key: Key(income['id'].toString()),
                                  background: Container(
                                    color: Colors.red,
                                    alignment: Alignment.centerRight,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    child: Icon(
                                      Icons.delete,
                                      color: Colors.white,
                                    ),
                                  ),
                                  direction: DismissDirection.endToStart,
                                  confirmDismiss: (direction) async {
                                    return await showDialog<bool>(
                                      context: context,
                                      builder:
                                          (context) => AlertDialog(
                                            title: Text('Geliri Sil'),
                                            content: Text(
                                              'Bu gelir kaydını silmek istediğinize emin misiniz?',
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
                                                    () => Navigator.of(
                                                      context,
                                                    ).pop(true),
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
                                    _deleteIncome(income['id']);
                                  },
                                  child: Card(
                                    margin: EdgeInsets.only(bottom: 8),
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: Colors.green,
                                        child: Icon(
                                          Icons.attach_money,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                      title: Text(
                                        income['description'],
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      subtitle: Text(
                                        date,
                                        style: TextStyle(fontSize: 12),
                                      ),
                                      trailing: Text(
                                        '${income['amount'].toStringAsFixed(2)} ₺',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                      onTap:
                                          () => _showEditIncomeDialog(income),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Giderler Bölümü
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Giderler',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        if (_expenses.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.trending_down,
                                    size: 32,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Henüz gider kaydı yok',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: ListView.builder(
                              physics: NeverScrollableScrollPhysics(),
                              shrinkWrap: true,
                              itemCount: _expenses.length,
                              itemBuilder: (context, index) {
                                final expense = _expenses[index];
                                final date = DateFormat('dd.MM.yyyy').format(
                                  DateFormat(
                                    'yyyy-MM-dd HH:mm:ss',
                                  ).parse(expense.date),
                                );

                                return Card(
                                  margin: EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: _getCategoryColor(
                                        expense.category,
                                      ),
                                      child: Icon(
                                        _getCategoryIcon(expense.category),
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                    title: Text(
                                      expense.description,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    subtitle: Text(
                                      date,
                                      style: TextStyle(fontSize: 12),
                                    ),
                                    trailing: Text(
                                      '${expense.amount.toStringAsFixed(2)} ₺',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red,
                                      ),
                                    ),
                                    onTap:
                                        () => _showAddExpenseDialog(
                                          expense: expense,
                                        ),
                                  ),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required double amount,
    required IconData icon,
    required Color color,
    bool fullWidth = false,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: fullWidth ? double.infinity : null,
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              '${amount.toStringAsFixed(2)} ₺',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'kira':
        return Colors.purple;
      case 'elektrik':
        return Colors.orange;
      case 'su':
        return Colors.blue;
      case 'doğalgaz':
        return Colors.deepOrange;
      case 'personel':
        return Colors.teal;
      case 'vergi':
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'kira':
        return Icons.home;
      case 'elektrik':
        return Icons.electric_bolt;
      case 'su':
        return Icons.water_drop;
      case 'doğalgaz':
        return Icons.local_fire_department;
      case 'personel':
        return Icons.people;
      case 'vergi':
        return Icons.receipt;
      default:
        return Icons.shopping_bag;
    }
  }
}
