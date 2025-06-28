# Teknik İçerik (Tech Context)

## Teknoloji Yığını
*   **Çerçeve (Framework)**: Flutter
*   **Programlama Dili**: Dart (`sdk: ^3.7.2`)
*   **Veritabanı**: SQLite (yerel depolama için `sqflite` ve `sqflite_common_ffi` paketleri ile)
*   **Durum Yönetimi (State Management)**: `provider`
*   **Kullanıcı Arayüzü (UI)**: Material Design
*   **Raporlama ve Yazdırma**: `pdf` ve `printing`
*   **Grafik ve Görselleştirme**: `fl_chart`
*   **Uluslararasılaştırma (i18n)**: `intl` (tarih/para birimi formatlama)
*   **Yerel Depolama (Basit Veriler)**: `shared_preferences`

## Geliştirme Ortamı
*   **Flutter SDK**: `^3.7.2` versiyonu
*   **IDE**: Visual Studio Code veya Android Studio gibi standart Flutter geliştirme ortamları.
*   **Kod Analizi**: `flutter_lints` paketi ile iyi kodlama pratikleri teşvik edilmektedir.

## Dağıtım Süreci
*   Uygulama, Flutter'ın desteklediği Android, iOS, Windows, Linux, macOS ve Web gibi platformlar için derlenebilir.
*   `sqflite_common_ffi` paketinin varlığı, projenin özellikle **Windows masaüstü platformu** için de hedeflendiğini ve test edildiğini göstermektedir.

## Performans Değerlendirmeleri
*   Tek kullanıcılı bir masaüstü uygulaması için yerel SQLite veritabanı kullanımı, genellikle yüksek performanslı ve verimli bir çözümdür.
*   Büyük veri kümeleriyle çalışırken (örneğin, binlerce satış kaydı üzerinde rapor oluşturma), `fl_chart` ile grafik çizdirme ve `pdf` ile rapor oluşturma işlemlerinin performansı göz önünde bulundurulmalıdır.

## Teknik Borç
*   `db_repair_tool.dart` ve `reset_database.dart` gibi yardımcı betiklerin varlığı, geçmişte veritabanı şema güncellemeleri veya veri bütünlüğü sorunları yaşanmış olabileceğine işaret etmektedir. Bu durum, gelecekte veritabanı yönetiminde dikkatli olunmasını gerektiren bir teknik borç olabilir.
*   `customer_management.dart` (76KB) ve `stock_management.dart` (41KB) gibi bazı özellik dosyalarının boyutları oldukça büyüktür. Bu dosyaların zamanla bakımını ve okunabilirliğini zorlaştırabilir. Bu "God files" (Tanrı dosyaları), gelecekte daha küçük ve yönetilebilir bileşenlere (widget'lar, servisler) ayrıştırılarak yeniden yapılandırılabilir (refactoring).

## Kütüphane Detayları (Context7 Analizi)

Projede kullanılan bazı anahtar kütüphaneler hakkında daha fazla bilgi edinmek için `context7` aracı kullanılmıştır.

### `provider`
`context7` aracılığıyla yapılan analizde, projenin durum yönetimi için kullandığı `provider` (/rrousselgit/provider) paketinin dokümantasyonuna başarıyla ulaşılmıştır. Öne çıkan bazı noktalar şunlardır:
*   **Basit Kullanım**: `context.watch<T>()`, `context.read<T>()` ve `context.select<T, R>()` gibi `BuildContext` eklentileri ile provider'lara erişim oldukça basittir.
*   **Performans Optimizasyonu**: `Selector` widget'ı veya `context.select` metodu, sadece dinlenmesi gereken belirli bir değere abone olarak gereksiz widget yeniden inşa edilmelerini (rebuild) önler. Bu, büyük uygulamalarda performansı artırmak için kritik bir özelliktir.
*   **Temiz Kod Yapısı**: `MultiProvider`, iç içe geçmiş `Provider` yapılarını önleyerek kodun daha okunabilir ve yönetilebilir olmasını sağlar.
*   **Esneklik**: `ChangeNotifierProvider`, `FutureProvider`, `StreamProvider` ve `ProxyProvider` gibi çeşitli provider türleri ile farklı senaryolara yönelik esnek çözümler sunar. `ProxyProvider`, bir provider'ın başka bir provider'a bağımlı olduğu durumlar için oldukça kullanışlıdır.

### `sqflite`
`sqflite` paketi için `context7` aracı ile yapılan aramalarda, Flutter projesinde kullanılan `sqflite` paketine özgü doğrudan ve net bir dokümantasyon bulunamamıştır. Araç, genel "sqlite" aramalarıyla ilgili birçok sonuç döndürmüş ancak projenin ihtiyacına yönelik spesifik bilgiye ulaşılamamıştır. Bu nedenle, bu kütüphane hakkındaki bilgiler `pub.dev` üzerindeki resmi dokümantasyonuna dayanmaktadır. 