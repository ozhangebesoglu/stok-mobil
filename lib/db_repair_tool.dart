import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'services/database/database_helper.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(DbRepairApp());
}

class DbRepairApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Veritabanı Tamir Aracı',
      theme: ThemeData(
        primarySwatch: Colors.red,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: DbRepairScreen(),
    );
  }
}

class DbRepairScreen extends StatefulWidget {
  @override
  _DbRepairScreenState createState() => _DbRepairScreenState();
}

class _DbRepairScreenState extends State<DbRepairScreen> {
  String _dbPath = '';
  bool _isLoading = false;
  bool _isSuccess = false;
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    _getDbPath();
  }

  Future<void> _getDbPath() async {
    setState(() {
      _isLoading = true;
    });

    try {
      Directory documentsDirectory = await getApplicationDocumentsDirectory();
      String path = join(documentsDirectory.path, 'kasap_stok.db');
      setState(() {
        _dbPath = path;
        _statusMessage = 'Veritabanı konumu tespit edildi.';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Hata: Veritabanı konumu bulunamadı: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _resetDatabase() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Veritabanı sıfırlanıyor...';
    });

    try {
      File dbFile = File(_dbPath);
      if (await dbFile.exists()) {
        await dbFile.delete();
        setState(() {
          _statusMessage =
              'Veritabanı başarıyla silindi. Yenisi oluşturulacak.';
        });
      } else {
        setState(() {
          _statusMessage = 'Veritabanı dosyası bulunamadı. Yeni oluşturulacak.';
        });
      }

      // Yeni veritabanı oluştur
      final db = await DatabaseHelper().database;
      await db.close();

      setState(() {
        _isSuccess = true;
        _statusMessage =
            'Veritabanı başarıyla sıfırlandı ve yeniden oluşturuldu.';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Hata: Veritabanı sıfırlanamadı: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _checkTables() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Tablolar kontrol ediliyor...';
    });

    try {
      final db = await DatabaseHelper().database;

      // Check tables
      final List<Map<String, dynamic>> tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table'",
      );

      String tableNames = tables.map((t) => t['name'].toString()).join(', ');

      // Kontrol etmek istediğimiz sütunları içeren tablo adları
      final tableColumns = {
        'sales': ['notes', 'isPaid'],
        'restaurant_sales': ['notes', 'isPaid'],
      };

      String columnsReport = '';

      // Her tablonun sütunlarını kontrol et
      for (String tableName in tableColumns.keys) {
        final List<Map<String, dynamic>> columns = await db.rawQuery(
          "PRAGMA table_info($tableName)",
        );

        final Set<String> columnNames =
            columns.map((c) => c['name'].toString()).toSet();
        final List<String> missingColumns = [];

        for (String expectedColumn in tableColumns[tableName]!) {
          if (!columnNames.contains(expectedColumn)) {
            missingColumns.add(expectedColumn);
          }
        }

        if (missingColumns.isNotEmpty) {
          columnsReport +=
              '\n$tableName tablosunda eksik sütunlar: ${missingColumns.join(', ')}';
        } else {
          columnsReport += '\n$tableName tablosunda tüm sütunlar mevcut.';
        }
      }

      setState(() {
        _statusMessage = 'Tablolar: $tableNames\n$columnsReport';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Hata: Tablolar kontrol edilemedi: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Veritabanı Tamir Aracı')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Veritabanı Konumu:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(_dbPath.isEmpty ? 'Yükleniyor...' : _dbPath),
            SizedBox(height: 20),
            Text(
              'Durum:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:
                    _isSuccess ? Colors.green.shade100 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _isSuccess ? Colors.green : Colors.grey,
                ),
              ),
              child: Text(_statusMessage),
            ),
            SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _resetDatabase,
                    icon: Icon(Icons.refresh),
                    label: Text('Veritabanını Sıfırla'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _checkTables,
                    icon: Icon(Icons.table_chart),
                    label: Text('Tabloları Kontrol Et'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            if (_isLoading)
              Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 8),
                    Text('İşlem yapılıyor...'),
                  ],
                ),
              ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 20),
                    Text(
                      'Yardım:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '1. "Veritabanını Sıfırla" butonu mevcut veritabanını silip yeniden oluşturur. Bu işlem tüm verileri siler!',
                      style: TextStyle(fontSize: 14),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '2. "Tabloları Kontrol Et" butonu mevcut tabloları ve sütunları kontrol eder.',
                      style: TextStyle(fontSize: 14),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '3. Veritabanı sıfırlandığında tüm verileriniz silinir, yedek almanız önerilir.',
                      style: TextStyle(fontSize: 14, color: Colors.red),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
