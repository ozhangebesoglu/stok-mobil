import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/database/database_helper.dart';
import '../models/expense.dart';
import '../main.dart';

class ReportingPage extends StatefulWidget {
  @override
  _ReportingPageState createState() => _ReportingPageState();
}

class _ReportingPageState extends State<ReportingPage> {
  // Satış verileri
  List<Map<String, dynamic>> _monthlySales = [];
  List<Map<String, dynamic>> _categorySales = [];

  // En iyi 3 müşteri
  List<Map<String, dynamic>> _topCustomers = [];

  // Yükleniyor durumu
  bool _isLoading = true;

  // Seçilen dönem
  String _selectedPeriod = 'Aylık'; // "Günlük", "Haftalık", "Aylık", "Yıllık"

  @override
  void initState() {
    super.initState();
    _loadReportData();
  }

  Future<void> _loadReportData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final db = await DatabaseHelper().database;

      String timeQuery = '';
      String timeGroupBy = '';
      String timeFormat = '';

      // Döneme göre SQL sorgusu ayarla
      switch (_selectedPeriod) {
        case 'Günlük':
          timeFormat = '%Y-%m-%d';
          timeGroupBy = 'day';
          break;
        case 'Haftalık':
          timeFormat = '%Y-%W'; // Yıl-hafta formatı
          timeGroupBy = 'week';
          break;
        case 'Aylık':
          timeFormat = '%Y-%m';
          timeGroupBy = 'month';
          break;
        case 'Yıllık':
          timeFormat = '%Y';
          timeGroupBy = 'year';
          break;
      }

      // Zamana göre satış verileri
      final List<Map<String, dynamic>> timeSalesData = await db.rawQuery('''
        SELECT 
          strftime('$timeFormat', date) as $timeGroupBy,
          SUM(amount) as total
        FROM sales
        GROUP BY $timeGroupBy
        ORDER BY $timeGroupBy DESC
        LIMIT 6
      ''');

      // Kategoriye göre satış verileri
      final List<Map<String, dynamic>> productCategorySales = await db.rawQuery(
        '''
        SELECT 
          'Satış' as category,
          SUM(amount) as total
        FROM sales
        UNION ALL
        SELECT 
          'Gider' as category,
          SUM(amount) as total
        FROM expenses
        ORDER BY total DESC
        LIMIT 3
      ''',
      );

      // Kategorilere göre satış dağılımı
      List<Map<String, dynamic>> categorySales = [];
      if (productCategorySales.isNotEmpty) {
        categorySales = productCategorySales;
      } else {
        // Gider kategorilerine göre dağılım
        final List<Map<String, dynamic>> expenseCategories = await db.rawQuery(
          '''
          SELECT 
            category,
            SUM(amount) as total
          FROM expenses
          GROUP BY category
          ORDER BY total DESC
          LIMIT 3
        ''',
        );

        if (expenseCategories.isNotEmpty) {
          categorySales = expenseCategories;
        }
      }

      // En iyi müşteriler
      final List<Map<String, dynamic>> topCustomers = await db.rawQuery('''
        SELECT 
          customerId,
          customerName,
          SUM(amount) as total
        FROM sales
        GROUP BY customerId
        ORDER BY total DESC
        LIMIT 3
      ''');

      setState(() {
        _monthlySales = timeSalesData;
        _categorySales = categorySales;
        _topCustomers = topCustomers;
        _isLoading = false;
      });
    } catch (e) {
      print('Raporlama verileri yüklenirken hata: $e');
      setState(() {
        _isLoading = false;
        _monthlySales = [];
        _categorySales = [];
        _topCustomers = [];
      });
    }
  }

  String _formatTimeLabel(String timeStr) {
    try {
      if (_selectedPeriod == 'Günlük') {
        final date = DateTime.parse(timeStr);
        return DateFormat('dd.MM.yyyy', 'tr_TR').format(date);
      } else if (_selectedPeriod == 'Haftalık') {
        // Hafta formatı: "2023-01" (yıl-hafta)
        final parts = timeStr.split('-');
        if (parts.length == 2) {
          return '${parts[0]} ${parts[1]}. Hafta';
        }
        return timeStr;
      } else if (_selectedPeriod == 'Aylık') {
        final date = DateTime.parse('${timeStr}-01');
        return DateFormat('MMMM yyyy', 'tr_TR').format(date);
      } else if (_selectedPeriod == 'Yıllık') {
        return timeStr;
      }
      return timeStr;
    } catch (e) {
      return timeStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFD2B48C), // Tan rengi
      appBar: AppBar(
        title: Text('Raporlama'),
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
            onPressed: _loadReportData,
            tooltip: 'Verileri Yenile',
          ),
        ],
      ),
      body: Column(
        children: [
          // Dönem seçici
          Container(
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Dönem: ',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 8),
                DropdownButton<String>(
                  value: _selectedPeriod,
                  icon: Icon(Icons.arrow_drop_down),
                  elevation: 16,
                  style: TextStyle(
                    color: Color(0xFF654321), // Deep Brown
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  underline: Container(
                    height: 2,
                    color: Color(0xFF8B0000), // Muted Tomato Red
                  ),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedPeriod = newValue;
                      });
                      _loadReportData();
                    }
                  },
                  items:
                      <String>[
                        'Günlük',
                        'Haftalık',
                        'Aylık',
                        'Yıllık',
                      ].map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                ),
              ],
            ),
          ),

          // İçerik bölümü
          Expanded(
            child:
                _isLoading
                    ? Center(child: CircularProgressIndicator())
                    : Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Satış Raporu
                            Text(
                              '$_selectedPeriod Satış Raporu',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 20),
                            if (_monthlySales.isEmpty)
                              _buildEmptyState(
                                'Seçilen dönemde satış verisi bulunamadı',
                              )
                            else
                              Container(
                                height: 300,
                                child: BarChart(
                                  BarChartData(
                                    barGroups: _getBarchartGroups(),
                                    titlesData: FlTitlesData(
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          getTitlesWidget: (
                                            double value,
                                            TitleMeta meta,
                                          ) {
                                            if (value.toInt() < 0 ||
                                                value.toInt() >=
                                                    _monthlySales.length) {
                                              return Text('');
                                            }

                                            // Zaman etiketini formatla
                                            String timeLabel = '';
                                            switch (_selectedPeriod) {
                                              case 'Günlük':
                                                timeLabel =
                                                    _monthlySales[value
                                                            .toInt()]['day']
                                                        ?.toString() ??
                                                    '';
                                                break;
                                              case 'Haftalık':
                                                timeLabel =
                                                    _monthlySales[value
                                                            .toInt()]['week']
                                                        ?.toString() ??
                                                    '';
                                                break;
                                              case 'Aylık':
                                                timeLabel =
                                                    _monthlySales[value
                                                            .toInt()]['month']
                                                        ?.toString() ??
                                                    '';
                                                break;
                                              case 'Yıllık':
                                                timeLabel =
                                                    _monthlySales[value
                                                            .toInt()]['year']
                                                        ?.toString() ??
                                                    '';
                                                break;
                                            }

                                            if (timeLabel.contains('-')) {
                                              final parts = timeLabel.split(
                                                '-',
                                              );
                                              if (parts.length == 2) {
                                                // Aylık "yıl-ay" formatı için
                                                if (_selectedPeriod ==
                                                    'Aylık') {
                                                  timeLabel =
                                                      '${parts[1]}/${parts[0].substring(2)}';
                                                }
                                                // Haftalık format için
                                                else if (_selectedPeriod ==
                                                    'Haftalık') {
                                                  timeLabel = 'H${parts[1]}';
                                                }
                                              }
                                            }

                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                top: 8.0,
                                              ),
                                              child: Text(
                                                timeLabel,
                                                style: TextStyle(fontSize: 12),
                                              ),
                                            );
                                          },
                                          reservedSize: 30,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            SizedBox(height: 40),

                            // Gelir Dağılımı
                            Text(
                              'Gelir Dağılımı',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 20),
                            if (_categorySales.isEmpty)
                              _buildEmptyState('Kategori verisi bulunamadı')
                            else
                              Container(
                                height: 300,
                                child: PieChart(
                                  PieChartData(
                                    sections: _getPieChartSections(),
                                    centerSpaceRadius: 40,
                                    sectionsSpace: 2,
                                  ),
                                ),
                              ),

                            SizedBox(height: 40),

                            // En İyi Müşteriler
                            Text(
                              'En İyi Müşteriler',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 20),
                            if (_topCustomers.isEmpty)
                              _buildEmptyState('Müşteri verisi bulunamadı')
                            else
                              ...List.generate(_topCustomers.length, (index) {
                                final customer = _topCustomers[index];
                                return Card(
                                  margin: EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: Colors.blue,
                                      child: Text('${index + 1}'),
                                    ),
                                    title: Text(customer['customerName']),
                                    trailing: Text(
                                      '${customer['total'].toStringAsFixed(2)} ₺',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                );
                              }),
                          ],
                        ),
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, color: Colors.grey, size: 48),
            SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(color: Colors.grey[700], fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  List<BarChartGroupData> _getBarchartGroups() {
    return List.generate(_monthlySales.length, (index) {
      final data = _monthlySales[index];
      final periodKey =
          _selectedPeriod == 'Günlük'
              ? 'day'
              : _selectedPeriod == 'Haftalık'
              ? 'week'
              : _selectedPeriod == 'Aylık'
              ? 'month'
              : 'year';

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: (data['total'] ?? 0).toDouble(),
            color: _getBarColor(index),
            width: 20,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(5),
              topRight: Radius.circular(5),
            ),
          ),
        ],
      );
    });
  }

  Color _getBarColor(int index) {
    List<Color> colors = [
      Color(0xFF8B0000), // Muted Tomato Red
      Color(0xFFAA2704), // Muted Rust Red
      Color(0xFF654321), // Deep Brown
      Color(0xFF013220), // Dark Green
      Color(0xFF9D9885), // Dusty Olive Green
      Color(0xFF778EA8), // Wash-Out Denim Blue
    ];
    return colors[index % colors.length];
  }

  List<PieChartSectionData> _getPieChartSections() {
    return List.generate(_categorySales.length, (index) {
      final data = _categorySales[index];
      final totalValue = (data['total'] ?? 0).toDouble();
      return PieChartSectionData(
        value: totalValue,
        color: _getPieColor(index),
        title: '${data['category']}\n${totalValue.toStringAsFixed(0)}₺',
        radius: 100,
        titleStyle: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      );
    });
  }

  Color _getPieColor(int index) {
    List<Color> colors = [
      Color(0xFF8B0000), // Muted Tomato Red
      Color(0xFF013220), // Dark Green
      Color(0xFF654321), // Deep Brown
      Color(0xFFAA2704), // Muted Rust Red
      Color(0xFF9D9885), // Dusty Olive Green
    ];
    return colors[index % colors.length];
  }
}
