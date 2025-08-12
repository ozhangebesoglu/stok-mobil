# Esnaf Defterim - Kasap Dükkanı Yönetim Sistemi

Modern ve profesyonel kasap dükkanı yönetim sistemi. Stok takibi, satış işlemleri, müşteri yönetimi, mali işlemler ve raporlama modüllerini içerir.

## Özellikler

### 🏪 Ana Özellikler
- **Dashboard**: Güncel istatistikler ve grafiklerle işletme durumu
- **Stok Yönetimi**: Et ürünleri stok takibi, minimum stok uyarıları
- **Satış İşlemleri**: POS sistemi, fiş yazdırma, ödeme takibi
- **Müşteri Yönetimi**: Müşteri bilgileri, borç-alacak takibi
- **Tedarikçi Yönetimi**: Tedarikçi bilgileri ve sipariş takibi
- **Mali İşlemler**: Gelir-gider takibi, kasa yönetimi
- **Raporlama**: Detaylı satış ve mali raporlar

### 🔧 Teknik Özellikler
- **Frontend**: React 18, TypeScript, Material-UI
- **Backend**: Node.js, Express.js
- **Veritabanı**: MySQL
- **Kimlik Doğrulama**: JWT
- **Responsive**: Mobil ve tablet uyumlu
- **Güvenlik**: Rate limiting, input validation, CORS

## Kurulum

### Gereksinimler
- Node.js 16+
- MySQL 8.0+
- npm veya yarn

### 1. Projeyi Klonlayın
\`\`\`bash
git clone <repo-url>
cd esnaf-defterim
\`\`\`

### 2. Bağımlılıkları Yükleyin
\`\`\`bash
# Tüm bağımlılıkları yükle
npm run install-all

# Veya manuel olarak
npm install
cd server && npm install
cd ../client && npm install
\`\`\`

### 3. Veritabanını Kurun
\`\`\`bash
# MySQL'de veritabanını oluşturun
mysql -u root -p < database.sql
\`\`\`

### 4. Environment Variables
\`\`\`bash
# Server için
cp server/.env.example server/.env
# Veritabanı bilgilerini güncelleyin

# Client için (varsayılan değerler kullanılabilir)
# client/.env dosyası zaten hazır
\`\`\`

### 5. Uygulamayı Başlatın
\`\`\`bash
# Development mode (hem frontend hem backend)
npm run dev

# Veya ayrı ayrı
npm run server  # Backend: http://localhost:5000
npm run client  # Frontend: http://localhost:3000
\`\`\`

## Demo Giriş Bilgileri

- **Email**: admin@esnafdefterim.com
- **Şifre**: admin123

## Proje Yapısı

\`\`\`
esnaf-defterim/
├── client/                 # React frontend
│   ├── src/
│   │   ├── components/     # React bileşenleri
│   │   ├── context/        # React context'ler
│   │   ├── services/       # API servisleri
│   │   └── ...
│   └── package.json
├── server/                 # Node.js backend
│   ├── config/            # Veritabanı konfigürasyonu
│   ├── middleware/        # Express middleware'ler
│   ├── routes/            # API rotaları
│   └── index.js           # Ana server dosyası
├── database.sql           # Veritabanı şeması
└── README.md
\`\`\`

## API Endpoints

### Kimlik Doğrulama
- \`POST /api/auth/login\` - Giriş yap
- \`GET /api/auth/profile\` - Kullanıcı profili
- \`PUT /api/auth/change-password\` - Şifre değiştir
- \`POST /api/auth/verify-token\` - Token doğrula

### Gelecek Modüller
- \`/api/stok\` - Stok işlemleri
- \`/api/satis\` - Satış işlemleri
- \`/api/musteriler\` - Müşteri işlemleri
- \`/api/tedarikciler\` - Tedarikçi işlemleri
- \`/api/mali\` - Mali işlemler
- \`/api/raporlar\` - Raporlama

## Veritabanı Şeması

Sistem aşağıdaki ana tablolardan oluşur:

- **kullanicilar**: Sistem kullanıcıları
- **musteriler**: Müşteri bilgileri
- **tedarikciler**: Tedarikçi bilgileri
- **kategoriler**: Ürün kategorileri
- **stoklar**: Stok bilgileri
- **satislar**: Satış kayıtları
- **odemeler**: Ödeme kayıtları
- **borclar_alacaklar**: Borç-alacak takibi
- **giderler**: Gider kayıtları
- **kasa**: Kasa hareketleri

## Güvenlik

- JWT tabanlı kimlik doğrulama
- Bcrypt ile şifre hash'leme
- Rate limiting (dakikada 100 istek)
- Input validation
- CORS koruması
- SQL injection koruması

## Geliştirme

### Backend Geliştirme
\`\`\`bash
cd server
npm run dev  # nodemon ile otomatik restart
\`\`\`

### Frontend Geliştirme
\`\`\`bash
cd client
npm start    # Hot reload ile geliştirme
\`\`\`

### Production Build
\`\`\`bash
npm run build  # Client production build'i
\`\`\`

## Katkıda Bulunma

1. Fork yapın
2. Feature branch oluşturun (\`git checkout -b feature/amazing-feature\`)
3. Commit yapın (\`git commit -m 'Add amazing feature'\`)
4. Push yapın (\`git push origin feature/amazing-feature\`)
5. Pull Request açın

## Lisans

Bu proje MIT lisansı altında lisanslanmıştır.

## Destek

Herhangi bir sorun veya öneriniz için issue açabilirsiniz.

---

**Esnaf Defterim** - Modern kasap dükkanı yönetim sistemi
