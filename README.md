# 🥩 Esnaf Defterim - Kasap Dükkanı Yönetim Sistemi

Modern ve profesyonel kasap dükkanı yönetim uygulaması. Stok takibi, satış yönetimi, müşteri ilişkileri ve finansal raporlama özellikleri ile tam kapsamlı bir çözüm.

## ✨ Özellikler

### 🔐 Kullanıcı Yönetimi
- Güvenli giriş sistemi (JWT)
- Rol tabanlı yetkilendirme (Admin/Kullanıcı)
- Şifre değiştirme

### 📦 Stok Yönetimi
- Ürün ekleme, düzenleme, silme
- Kategori bazlı organizasyon
- Ağırlık bazlı stok takibi
- Alış/satış fiyatı yönetimi
- Kar oranı hesaplama
- Stok hareket geçmişi

### 🛒 Satış Yönetimi
- Yeni satış oluşturma
- Müşteri seçimi
- Ürün seçimi ve miktar belirleme
- İndirim uygulama
- Fatura oluşturma

### 👥 Müşteri Yönetimi
- Müşteri kayıt sistemi
- Müşteri tipi (Bireysel/Kurumsal)
- İletişim bilgileri
- Satış geçmişi

### 🏢 Tedarikçi Yönetimi
- Tedarikçi kayıt sistemi
- İletişim bilgileri
- Vergi numarası takibi

### 💰 Finansal Yönetim
- Kasa işlemleri
- Ödeme takibi
- Borç/Alacak yönetimi
- Gider takibi

### 📊 Raporlama
- Dashboard ile genel bakış
- Satış raporları
- Stok raporları
- Finansal raporlar

## 🛠️ Teknolojiler

### Backend
- **Node.js** - Runtime environment
- **Express.js** - Web framework
- **MySQL** - Veritabanı
- **JWT** - Authentication
- **bcryptjs** - Şifre hashleme
- **Helmet** - Güvenlik
- **Morgan** - Logging

### Frontend
- **React** - UI framework
- **TypeScript** - Type safety
- **Material-UI** - UI components
- **React Router** - Navigation
- **Axios** - HTTP client
- **Date-fns** - Date manipulation

## 🚀 Kurulum

### Gereksinimler
- Node.js (v16 veya üzeri)
- MySQL (v8.0 veya üzeri)
- npm veya yarn

### 1. Projeyi Klonlayın
```bash
git clone <repository-url>
cd esnaf-defterim
```

### 2. Veritabanını Kurun
```bash
# MySQL'e bağlanın
mysql -u root -p

# Veritabanını oluşturun
CREATE DATABASE esnaf_defterim CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

# Veritabanını seçin
USE esnaf_defterim;

# Schema'yı çalıştırın
SOURCE database/schema.sql;
```

### 3. Backend Kurulumu
```bash
cd backend

# Bağımlılıkları yükleyin
npm install

# Environment dosyasını oluşturun
cp .env.example .env

# .env dosyasını düzenleyin
# Veritabanı bilgilerinizi girin
DB_HOST=localhost
DB_USER=root
DB_PASSWORD=your_password
DB_NAME=esnaf_defterim
JWT_SECRET=your_jwt_secret_key_here

# Backend'i başlatın
npm run dev
```

### 4. Frontend Kurulumu
```bash
cd frontend

# Bağımlılıkları yükleyin
npm install

# Frontend'i başlatın
npm start
```

## 🔧 Konfigürasyon

### Environment Değişkenleri

#### Backend (.env)
```env
# Database Configuration
DB_HOST=localhost
DB_USER=root
DB_PASSWORD=your_password
DB_NAME=esnaf_defterim
DB_PORT=3306

# JWT Configuration
JWT_SECRET=your_jwt_secret_key_here
JWT_EXPIRES_IN=24h

# Server Configuration
PORT=5000
NODE_ENV=development

# CORS Configuration
CORS_ORIGIN=http://localhost:3000
```

#### Frontend (.env)
```env
REACT_APP_API_URL=http://localhost:5000/api
```

## 📱 Kullanım

### Demo Giriş Bilgileri
- **Email:** admin@esnafdefterim.com
- **Şifre:** admin123

### Temel İşlemler

1. **Stok Ekleme**
   - Stok Yönetimi → Yeni Stok Ekle
   - Ürün bilgilerini girin
   - Kaydet

2. **Satış Yapma**
   - Satışlar → Yeni Satış
   - Müşteri seçin
   - Ürünleri ekleyin
   - Fiyatları belirleyin
   - Satışı tamamlayın

3. **Rapor Görüntüleme**
   - Dashboard'da genel istatistikleri görün
   - Detaylı raporlar için ilgili modülleri kullanın

## 📁 Proje Yapısı

```
esnaf-defterim/
├── backend/                 # Backend uygulaması
│   ├── config/             # Konfigürasyon dosyaları
│   ├── middleware/         # Middleware'ler
│   ├── routes/             # API route'ları
│   ├── server.js           # Ana server dosyası
│   └── package.json
├── frontend/               # Frontend uygulaması
│   ├── public/             # Statik dosyalar
│   ├── src/
│   │   ├── components/     # React bileşenleri
│   │   ├── contexts/       # Context'ler
│   │   ├── pages/          # Sayfa bileşenleri
│   │   ├── services/       # API servisleri
│   │   ├── types/          # TypeScript tipleri
│   │   └── App.tsx         # Ana uygulama
│   └── package.json
├── database/               # Veritabanı dosyaları
│   └── schema.sql          # Veritabanı şeması
└── README.md
```

## 🔒 Güvenlik

- JWT tabanlı authentication
- Şifre hashleme (bcrypt)
- CORS koruması
- Rate limiting
- Helmet güvenlik başlıkları
- SQL injection koruması

## 📊 Veritabanı Şeması

Sistem 13 ana tablo içerir:

1. **kullanicilar** - Kullanıcı bilgileri
2. **tedarikciler** - Tedarikçi bilgileri
3. **musteriler** - Müşteri bilgileri
4. **kategoriler** - Ürün kategorileri
5. **stoklar** - Stok bilgileri
6. **stok_hareketleri** - Stok hareket geçmişi
7. **satislar** - Satış kayıtları
8. **satis_detaylari** - Satış detayları
9. **odemeler** - Ödeme kayıtları
10. **borclar_alacaklar** - Borç/Alacak takibi
11. **giderler** - Gider kayıtları
12. **kasa** - Kasa işlemleri
13. **sistem_ayarlari** - Sistem ayarları

## 🚀 Deployment

### Production Build

#### Backend
```bash
cd backend
npm run build
npm start
```

#### Frontend
```bash
cd frontend
npm run build
```

### Docker (Yakında)
```bash
docker-compose up -d
```

## 🤝 Katkıda Bulunma

1. Fork yapın
2. Feature branch oluşturun (`git checkout -b feature/amazing-feature`)
3. Commit yapın (`git commit -m 'Add amazing feature'`)
4. Push yapın (`git push origin feature/amazing-feature`)
5. Pull Request oluşturun

## 📝 Lisans

Bu proje MIT lisansı altında lisanslanmıştır.

## 📞 İletişim

- **Email:** info@esnafdefterim.com
- **Website:** https://esnafdefterim.com

## 🙏 Teşekkürler

- Material-UI ekibine
- React ekibine
- Node.js topluluğuna

---

**Esnaf Defterim** - Modern kasap dükkanı yönetim sistemi 🥩
