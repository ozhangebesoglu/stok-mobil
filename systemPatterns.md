# Sistem Desenleri (System Patterns)

## Sistem Mimarisi
*   Uygulama, her bir ana özelliğin `lib/features` klasörü altında kendi dosyası içinde bulunduğu **özellik-bazlı (feature-based)** bir mimari yaklaşımını benimsemektedir.
*   Genel olarak, UI (Arayüz), State Management (Durum Yönetimi), Business Logic (İş Mantığı) ve Data Persistence (Veri Saklama) katmanlarından oluşan **katmanlı bir mimari** kullanmaktadır.
    *   **UI Katmanı**: `lib/features` altındaki dosyalar.
    *   **Durum Yönetimi**: `lib/providers` klasörü.
    *   **Servisler/İş Mantığı**: `lib/services` klasörü.
    *   **Veri Katmanı**: `lib/models` klasörü ve SQLite veritabanı.

## Bileşenler
*   **UI (Arayüz) Katmanı**: Flutter widget'larından oluşur ve özellik bazında organize edilmiştir.
*   **Durum Yönetimi Katmanı**: `provider` paketi kullanılarak uygulama durumu yönetilir. `ChangeNotifier` ve `Provider` sınıfları bu katmanın temelini oluşturur.
*   **Servis Katmanı**: `lib/services` dizininde veritabanı işlemleri, PDF oluşturma ve yazdırma gibi servisler bulunur.
*   **Veri Katmanı**: `lib/models` dizinindeki veri modelleri ve kalıcı depolama için SQLite veritabanından oluşur.

## Kullanılan Tasarım Desenleri
*   **Provider Pattern**: Flutter'da durum yönetimi için yaygın olarak kullanılan bir desendir.
*   **Repository/Service Pattern**: Veri erişim mantığını UI kodundan soyutlamak için kullanılır. Servis katmanı bu deseni uygular.
*   **MVVM (Model-View-ViewModel) Benzeri Yaklaşım**: `provider` kullanımı, UI (View) ile iş mantığının (ViewModel) ayrılmasını teşvik eder, bu da MVVM mimarisine benzer bir yapı oluşturur.

## Entegrasyon Noktaları
*   Uygulama büyük ölçüde kendi kendine yeterlidir. Ana entegrasyon noktaları, dosya sistemi (`path_provider` aracılığıyla veritabanı yolunu bulma) ve yazdırma servisi (`printing` paketi) üzerinden işletim sistemi ile kurulan etkileşimlerdir.

## Veri Akışı
1.  Kullanıcı arayüzdeki bir widget ile etkileşime girer (örn: bir butona tıklar).
2.  Bu etkileşim, ilgili `provider` içerisindeki bir metodu tetikler.
3.  `Provider`, iş mantığını yürütmek için ilgili servisi (örn: `DatabaseService`) çağırır.
4.  Servis, veritabanı üzerinde gerekli işlemleri (okuma, yazma, güncelleme) gerçekleştirir.
5.  İşlem sonucu elde edilen veri veya durum, katmanlar boyunca yukarıya, `provider`'a geri döner.
6.  `Provider`, `notifyListeners()` metodunu çağırarak durumun değiştiğini bildirir.
7.  Bu bildirimi dinleyen UI widget'ları kendilerini yeni veriyle günceller. 