import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../widgets/custom_text_field.dart';
import '../services/database/database_helper.dart';
import '../core/utils/logger.dart';

class ProfitLossPage extends StatefulWidget {
  const ProfitLossPage({super.key});

  @override
  State<ProfitLossPage> createState() => _ProfitLossPageState();
}

class _ProfitLossPageState extends State<ProfitLossPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _categoryController = TextEditingController();

  List<Expense> _expenses = [];
  List<Map<String, dynamic>> _incomes = [];
  double _totalIncome = 0;
  double _totalExpense = 0;
  String _selectedPeriod = 'Bu Ay';
  final bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
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

    // Tüm gelir kaynaklarını toplayacağımız ana liste
    List<Map<String, dynamic>> allIncomes = [];

    try {
      // Manuel eklenen gelirler
      final List<Map<String, dynamic>> manualIncomes = await db.query(
        'manual_incomes',
        where: dateFilter,
        orderBy: 'date DESC',
      );

      // Manuel gelirleri ana listeye ekle
      allIncomes.addAll(
        manualIncomes
            .map(
              (income) => {
                'id': income['id'],
                'description': income['description'],
                'amount': income['amount'],
                'date': income['date'],
                'category': income['category'],
                'sourceType': 'manual',
                'sourceId': income['id'],
              },
            )
            .toList(),
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

      // Borç ödemelerini ana listeye ekle
      allIncomes.addAll(
        debtPayments
            .map(
              (payment) => {
                'id': payment['id'],
                'description': 'Müşteri Ödemesi: ${payment['customerName']}',
                'amount': payment['amount'],
                'date': payment['date'],
                'category': 'Müşteri Ödemesi',
                'sourceType': 'payment',
                'sourceId': payment['id'],
              },
            )
            .toList(),
      );

      // Restoran satışları
      final List<Map<String, dynamic>> restaurantSales = await db.query(
        'restaurant_sales',
        where: dateFilter,
        orderBy: 'date DESC',
      );

      // Restoran satışlarını ana listeye ekle
      allIncomes.addAll(
        restaurantSales
            .map(
              (sale) => {
                'id': sale['id'],
                'description': 'Restoran Satışı: ${sale['restaurant']}',
                'amount': sale['amount'],
                'date': sale['date'],
                'category': 'Restoran Satışı',
                'sourceType': 'restaurant',
                'sourceId': sale['id'],
              },
            )
            .toList(),
      );

      // Normal satışlar
      final List<Map<String, dynamic>> normalSales = await db.query(
        'sales',
        where:
            dateFilter != null
                ? "$dateFilter AND productName != 'Borç Ödemesi' AND isPaid = 1"
                : "productName != 'Borç Ödemesi' AND isPaid = 1",
        orderBy: 'date DESC',
      );

      // Normal satışları ana listeye ekle
      allIncomes.addAll(
        normalSales
            .map(
              (sale) => {
                'id': sale['id'],
                'description':
                    'Müşteri Satışı: ${sale['customerName']} - ${sale['productName']}',
                'amount': sale['amount'],
                'date': sale['date'],
                'category': 'Müşteri Satışı',
                'sourceType': 'sale',
                'sourceId': sale['id'],
              },
            )
            .toList(),
      );

      // Tarihe göre sıralayalım (en yeniden en eskiye)
      allIncomes.sort((a, b) {
        DateTime dateA = DateFormat(
          'yyyy-MM-dd HH:mm:ss',
        ).parse(a['date'].toString());
        DateTime dateB = DateFormat(
          'yyyy-MM-dd HH:mm:ss',
        ).parse(b['date'].toString());
        return dateB.compareTo(dateA);
      });

      setState(() {
        _incomes = allIncomes;
      });
    } catch (e) {
      Logger.error('Müşteri işlem geçmişi yüklenirken hata', e);
      setState(() {
        _incomes = [];
      });
    }
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
      Logger.debug('Kâr-Zarar Hesabı Detayları:');
      Logger.debug('Seçili Dönem: $_selectedPeriod');
      Logger.debug('Satışlardan Gelen Gelir: $salesTotal');
      Logger.debug('Manuel Gelirler: $manualTotal');
      Logger.debug('Restoran Satışları: $restaurantTotal');
      Logger.debug('Toplam Gelir: $totalIncome');

      setState(() {
        _totalIncome = totalIncome;
      });
    } catch (e) {
      Logger.error('Gelir hesaplanırken hata', e);
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
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gider eklenirken hata oluştu: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
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
            backgroundColor: Theme.of(context).colorScheme.error,
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
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gelir eklenirken hata oluştu: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
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
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gelir silinirken hata oluştu: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
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
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gelir güncellenirken hata oluştu: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final profit = _totalIncome - _totalExpense;
    final isProfitable = profit >= 0;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Kâr-Zarar Analizi',
          style: theme.textTheme.titleLarge?.copyWith(
            color: colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        actions: [
          Container(
            margin: EdgeInsets.only(right: 16.w),
            child: DropdownButton<String>(
              value: _selectedPeriod,
              icon: Icon(CupertinoIcons.calendar, color: colorScheme.onPrimary),
              underline: SizedBox.shrink(),
              dropdownColor: colorScheme.surface,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
              items:
                  ['Bu Gün', 'Bu Hafta', 'Bu Ay', 'Tümü']
                      .map(
                        (period) => DropdownMenuItem(
                          value: period,
                          child: Text(period),
                        ),
                      )
                      .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedPeriod = value;
                  });
                  _loadData();
                }
              },
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: colorScheme.onPrimary,
          labelColor: colorScheme.onPrimary,
          unselectedLabelColor: colorScheme.onPrimary.withAlpha(179),
          tabs: [
            Tab(icon: Icon(CupertinoIcons.chart_pie_fill), text: 'Özet'),
            Tab(
              icon: Icon(CupertinoIcons.arrow_up_circle_fill),
              text: 'Gelirler',
            ),
            Tab(
              icon: Icon(CupertinoIcons.arrow_down_circle_fill),
              text: 'Giderler',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSummaryTab(colorScheme, theme, profit, isProfitable),
          _buildIncomesTab(colorScheme, theme),
          _buildExpensesTab(colorScheme, theme),
        ],
      ),
    );
  }

  Widget _buildSummaryTab(
    ColorScheme colorScheme,
    ThemeData theme,
    double profit,
    bool isProfitable,
  ) {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Period Header
            Container(
              width: double.infinity,
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
              child: Column(
                children: [
                  Icon(
                    CupertinoIcons.calendar_today,
                    color: colorScheme.primary,
                    size: 32.w,
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    '$_selectedPeriod Özeti',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: colorScheme.onPrimaryContainer.withAlpha(179),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    DateFormat('dd MMMM yyyy', 'tr_TR').format(DateTime.now()),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onPrimaryContainer.withAlpha(179),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 24.h),

            // Income & Expense Cards
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    colorScheme: colorScheme,
                    theme: theme,
                    title: 'Gelir',
                    amount: _totalIncome,
                    icon: CupertinoIcons.arrow_up_circle_fill,
                    color: Colors.green,
                    isPositive: true,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: _buildMetricCard(
                    colorScheme: colorScheme,
                    theme: theme,
                    title: 'Gider',
                    amount: _totalExpense,
                    icon: CupertinoIcons.arrow_down_circle_fill,
                    color: Colors.red,
                    isPositive: false,
                  ),
                ),
              ],
            ),

            SizedBox(height: 16.h),

            // Profit/Loss Card
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors:
                      isProfitable
                          ? [Colors.green.shade400, Colors.green.shade600]
                          : [Colors.red.shade400, Colors.red.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20.r),
                boxShadow: [
                  BoxShadow(
                    color: (isProfitable ? Colors.green : Colors.red).withAlpha(
                      77,
                    ),
                    blurRadius: 15,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(
                    isProfitable
                        ? CupertinoIcons.chart_bar_alt_fill
                        : CupertinoIcons.exclamationmark_triangle_fill,
                    color: Colors.white,
                    size: 40.w,
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    isProfitable ? 'Kâr' : 'Zarar',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    '${profit.abs().toStringAsFixed(2)} ₺',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    isProfitable
                        ? 'Tebrikler! Kâr elde ediyorsunuz'
                        : 'Dikkat! Zarar durumundasınız',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withAlpha(230),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            SizedBox(height: 32.h),

            // Quick Actions
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    onPressed: () {
                      _showAddIncomeDialog();
                    },
                    label: 'Gelir Ekle',
                    icon: CupertinoIcons.add_circled_solid,
                    color: Colors.green,
                    theme: theme,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: _buildActionButton(
                    onPressed: () {
                      _showAddExpenseDialog();
                    },
                    label: 'Gider Ekle',
                    icon: CupertinoIcons.minus_circled,
                    color: Colors.red,
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

  Widget _buildMetricCard({
    required ColorScheme colorScheme,
    required ThemeData theme,
    required String title,
    required double amount,
    required IconData icon,
    required Color color,
    required bool isPositive,
  }) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: color.withAlpha(51), width: 1),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withAlpha(13),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(icon, color: color, size: 24.w),
          ),
          SizedBox(height: 12.h),
          Text(
            title,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withAlpha(179),
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            '${amount.toStringAsFixed(2)} ₺',
            style: theme.textTheme.titleLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required VoidCallback onPressed,
    required String label,
    required IconData icon,
    required Color color,
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
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: color.withAlpha(77),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          padding: EdgeInsets.symmetric(horizontal: 24.w),
        ),
      ),
    );
  }

  Widget _buildIncomesTab(ColorScheme colorScheme, ThemeData theme) {
    return RefreshIndicator(
      onRefresh: _loadData,
      child:
          _isLoading
              ? Center(
                child: CircularProgressIndicator(color: colorScheme.primary),
              )
              : _incomes.isEmpty
              ? _buildEmptyState(
                colorScheme: colorScheme,
                theme: theme,
                icon: CupertinoIcons.arrow_up_circle,
                title: 'Henüz gelir kaydı yok',
                subtitle: 'İlk gelirinizi eklemek için butona tıklayın',
                actionLabel: 'Gelir Ekle',
                onAction: () => _showAddIncomeDialog(),
              )
              : ListView.builder(
                padding: EdgeInsets.all(16.w),
                itemCount: _incomes.length,
                itemBuilder: (context, index) {
                  final income = _incomes[index];
                  return _buildIncomeCard(income, colorScheme, theme);
                },
              ),
    );
  }

  Widget _buildExpensesTab(ColorScheme colorScheme, ThemeData theme) {
    return RefreshIndicator(
      onRefresh: _loadData,
      child:
          _isLoading
              ? Center(
                child: CircularProgressIndicator(color: colorScheme.primary),
              )
              : _expenses.isEmpty
              ? _buildEmptyState(
                colorScheme: colorScheme,
                theme: theme,
                icon: CupertinoIcons.arrow_down_circle,
                title: 'Henüz gider kaydı yok',
                subtitle: 'İlk giderinizi eklemek için butona tıklayın',
                actionLabel: 'Gider Ekle',
                onAction: () => _showAddExpenseDialog(),
              )
              : ListView.builder(
                padding: EdgeInsets.all(16.w),
                itemCount: _expenses.length,
                itemBuilder: (context, index) {
                  final expense = _expenses[index];
                  return _buildExpenseCard(expense, colorScheme, theme);
                },
              ),
    );
  }

  Widget _buildEmptyState({
    required ColorScheme colorScheme,
    required ThemeData theme,
    required IconData icon,
    required String title,
    required String subtitle,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
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
                icon,
                size: 64.w,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8.h),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withAlpha(128),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32.h),
            FilledButton.icon(
              onPressed: onAction,
              icon: Icon(CupertinoIcons.add),
              label: Text(actionLabel),
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIncomeCard(
    Map<String, dynamic> income,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    final date = DateFormat(
      'dd.MM.yyyy',
    ).format(DateFormat('yyyy-MM-dd HH:mm:ss').parse(income['date']));

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      child: Card(
        elevation: 2,
        shadowColor: colorScheme.shadow.withAlpha(25),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: InkWell(
          onTap: () => _showEditIncomeDialog(income),
          borderRadius: BorderRadius.circular(16.r),
          child: Container(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: Colors.green.withAlpha(25),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    CupertinoIcons.arrow_up_circle_fill,
                    color: Colors.green,
                    size: 24.w,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        income['description'] ?? 'Gelir',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        income['category'] ?? 'Genel',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withAlpha(128),
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        date,
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
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    '+${(income['amount'] as num).toStringAsFixed(2)} ₺',
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

  Widget _buildExpenseCard(
    Expense expense,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    final date = DateFormat(
      'dd.MM.yyyy',
    ).format(DateFormat('yyyy-MM-dd HH:mm:ss').parse(expense.date));

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      child: Card(
        elevation: 2,
        shadowColor: colorScheme.shadow.withAlpha(25),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: InkWell(
          onTap: () => _showAddExpenseDialog(expense: expense),
          borderRadius: BorderRadius.circular(16.r),
          child: Container(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: Colors.red.withAlpha(25),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    CupertinoIcons.arrow_down_circle_fill,
                    color: Colors.red,
                    size: 24.w,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        expense.description,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        expense.category,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withAlpha(128),
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        date,
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
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    '-${expense.amount.toStringAsFixed(2)} ₺',
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
}
