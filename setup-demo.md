# Esnaf Defterim - Demo Kurulum

Bu dosya, **Esnaf Defterim** kasap dükkanı yönetim sistemini hızlıca test etmek için gerekli adımları içerir.

## Hızlı Demo Kurulumu

### 1. Veritabanı Kurulumu (MySQL gerekli)

MySQL veritabanınızda aşağıdaki komutu çalıştırın:

```bash
mysql -u root -p < database.sql
```

Veya MySQL komut satırında:

```sql
source database.sql
```

### 2. Backend Başlatma

```bash
cd server
npm install
npm run dev
```

Backend `http://localhost:5000` adresinde çalışacak.

### 3. Frontend Başlatma

Yeni bir terminal açın:

```bash
cd client
npm start
```

Frontend `http://localhost:3000` adresinde çalışacak.

### 4. Demo Giriş

Tarayıcınızda `http://localhost:3000` adresine gidin.

**Demo Giriş Bilgileri:**
- Email: `admin@esnafdefterim.com`
- Şifre: `admin123`

## Özellikler

✅ **Tamamlanan Modüller:**
- Kullanıcı kimlik doğrulama (JWT)
- Modern responsive dashboard
- Istatistik kartları ve grafikler
- Yan menü navigasyonu
- Güvenli API yapısı

🚧 **Geliştirme Aşamasındaki Modüller:**
- Stok yönetimi
- Satış işlemleri
- Müşteri yönetimi
- Mali işlemler
- Raporlama

## Teknik Detaylar

- **Frontend**: React 18 + TypeScript + Material-UI
- **Backend**: Node.js + Express + MySQL
- **Güvenlik**: JWT, bcrypt, rate limiting
- **Responsive**: Mobil ve tablet uyumlu

## Test Verileri

Veritabanı aşağıdaki demo verilerle gelir:

- 1 Admin kullanıcı
- 7 Ürün kategorisi (Dana, Tavuk, Kuzu, vs.)
- 2 Demo müşteri
- 1 Demo tedarikçi
- Sistem ayarları

## Sorun Giderme

### MySQL Bağlantı Hatası
`server/.env` dosyasındaki veritabanı bilgilerini kontrol edin:

```env
DB_HOST=localhost
DB_PORT=3306
DB_USER=root
DB_PASSWORD=your_password
DB_NAME=esnaf_defterim
```

### Port Çakışması
Eğer 3000 veya 5000 portları kullanımdaysa:

- Backend için `server/.env` dosyasında `PORT=5001`
- Frontend için `client/.env` dosyasında `REACT_APP_API_URL=http://localhost:5001/api`

### Dependencies Hatası
```bash
# Root dizinde
npm run install-all

# Veya manuel
cd server && npm install
cd ../client && npm install
```

---

🎉 **Demo hazır!** Sistemi test etmeye başlayabilirsiniz.