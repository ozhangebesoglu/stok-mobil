import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

void main() async {
  print('Veritabanı sıfırlama işlemi başlatılıyor...');

  try {
    // Veritabanı dosyasının yolunu al
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'kasap_stok.db');

    // Dosyanın var olup olmadığını kontrol et
    bool fileExists = await File(path).exists();

    if (fileExists) {
      // Varsa sil
      await File(path).delete();
      print('Veritabanı silindi: $path');
    } else {
      print('Veritabanı dosyası bulunamadı: $path');
    }

    print('Veritabanı sıfırlama işlemi tamamlandı.');
    print(
      'Uygulamayı yeniden başlatın, veritabanı otomatik olarak oluşturulacaktır.',
    );
  } catch (e) {
    print('Hata: $e');
  }

  // Windows için bekle
  print('Çıkmak için Enter tuşuna basın...');
  stdin.readLineSync();
}
