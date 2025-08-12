-- Kasap Dükkanı Veritabanı Oluşturma Script

-- 1. Kullanıcılar Tablosu
CREATE TABLE IF NOT EXISTS kullanicilar (
    kullanici_id INT PRIMARY KEY AUTO_INCREMENT,
    isim VARCHAR(100) NOT NULL,
    email VARCHAR(150) UNIQUE NOT NULL,
    telefon VARCHAR(20),
    sifre_hash VARCHAR(255) NOT NULL,
    rol VARCHAR(50) DEFAULT 'kullanici',
    aktif BOOLEAN DEFAULT TRUE,
    olusturma_tarihi DATETIME DEFAULT CURRENT_TIMESTAMP,
    guncelleme_tarihi DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- 2. Tedarikçiler Tablosu
CREATE TABLE IF NOT EXISTS tedarikciler (
    tedarikci_id INT PRIMARY KEY AUTO_INCREMENT,
    isim VARCHAR(100) NOT NULL,
    telefon VARCHAR(20),
    email VARCHAR(150),
    adres TEXT,
    vergi_no VARCHAR(20),
    notlar TEXT,
    aktif BOOLEAN DEFAULT TRUE,
    olusturma_tarihi DATETIME DEFAULT CURRENT_TIMESTAMP,
    guncelleme_tarihi DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- 3. Müşteriler Tablosu
CREATE TABLE IF NOT EXISTS musteriler (
    musteri_id INT PRIMARY KEY AUTO_INCREMENT,
    isim VARCHAR(100) NOT NULL,
    telefon VARCHAR(20),
    email VARCHAR(150),
    adres TEXT,
    musteri_tipi VARCHAR(50) DEFAULT 'Bireysel',
    vergi_no VARCHAR(20),
    aktif BOOLEAN DEFAULT TRUE,
    olusturma_tarihi DATETIME DEFAULT CURRENT_TIMESTAMP,
    guncelleme_tarihi DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- 4. Kategoriler Tablosu
CREATE TABLE IF NOT EXISTS kategoriler (
    kategori_id INT PRIMARY KEY AUTO_INCREMENT,
    kategori_adi VARCHAR(100) NOT NULL,
    aciklama TEXT,
    aktif BOOLEAN DEFAULT TRUE,
    olusturma_tarihi DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- 5. Stoklar Tablosu
CREATE TABLE IF NOT EXISTS stoklar (
    stok_id INT PRIMARY KEY AUTO_INCREMENT,
    urun_adi VARCHAR(100) NOT NULL,
    kategori_id INT,
    toplam_agirlik FLOAT NOT NULL,
    kalan_agirlik FLOAT NOT NULL,
    tedarikci_id INT,
    alis_fiyati DECIMAL(8,2),
    satis_fiyati DECIMAL(8,2),
    kar_orani DECIMAL(5,2),
    kesim_tarihi DATETIME,
    son_kullanma_tarihi DATETIME,
    aktif BOOLEAN DEFAULT TRUE,
    olusturma_tarihi DATETIME DEFAULT CURRENT_TIMESTAMP,
    guncelleme_tarihi DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (kategori_id) REFERENCES kategoriler(kategori_id),
    FOREIGN KEY (tedarikci_id) REFERENCES tedarikciler(tedarikci_id)
);

-- 6. Stok Hareketleri Tablosu
CREATE TABLE IF NOT EXISTS stok_hareketleri (
    hareket_id INT PRIMARY KEY AUTO_INCREMENT,
    stok_id INT NOT NULL,
    kullanici_id INT,
    islem_turu VARCHAR(20) NOT NULL,
    miktar FLOAT NOT NULL,
    onceki_miktar FLOAT,
    sonraki_miktar FLOAT,
    islem_tarihi DATETIME DEFAULT CURRENT_TIMESTAMP,
    aciklama TEXT,
    satis_id INT,
    FOREIGN KEY (stok_id) REFERENCES stoklar(stok_id),
    FOREIGN KEY (kullanici_id) REFERENCES kullanicilar(kullanici_id)
);

-- 7. Satışlar Tablosu
CREATE TABLE IF NOT EXISTS satislar (
    satis_id INT PRIMARY KEY AUTO_INCREMENT,
    kullanici_id INT NOT NULL,
    musteri_id INT,
    satis_turu VARCHAR(50) DEFAULT 'Perakende',
    toplam_miktar FLOAT NOT NULL,
    ara_toplam DECIMAL(10,2) NOT NULL,
    indirim_orani DECIMAL(5,2) DEFAULT 0,
    indirim_tutari DECIMAL(10,2) DEFAULT 0,
    toplam_tutar DECIMAL(10,2) NOT NULL,
    odenen_tutar DECIMAL(10,2) DEFAULT 0,
    kalan_tutar DECIMAL(10,2) DEFAULT 0,
    durum VARCHAR(20) DEFAULT 'Tamamlandı',
    satis_tarihi DATETIME DEFAULT CURRENT_TIMESTAMP,
    olusturma_tarihi DATETIME DEFAULT CURRENT_TIMESTAMP,
    guncelleme_tarihi DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (kullanici_id) REFERENCES kullanicilar(kullanici_id),
    FOREIGN KEY (musteri_id) REFERENCES musteriler(musteri_id)
);

-- 8. Satış Detayları Tablosu
CREATE TABLE IF NOT EXISTS satis_detaylari (
    detay_id INT PRIMARY KEY AUTO_INCREMENT,
    satis_id INT NOT NULL,
    stok_id INT NOT NULL,
    urun_adi VARCHAR(100) NOT NULL,
    miktar FLOAT NOT NULL,
    birim_fiyat DECIMAL(8,2) NOT NULL,
    ara_toplam DECIMAL(10,2) NOT NULL,
    indirim_orani DECIMAL(5,2) DEFAULT 0,
    toplam DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (satis_id) REFERENCES satislar(satis_id),
    FOREIGN KEY (stok_id) REFERENCES stoklar(stok_id)
);

-- 9. Ödemeler Tablosu
CREATE TABLE IF NOT EXISTS odemeler (
    odeme_id INT PRIMARY KEY AUTO_INCREMENT,
    satis_id INT,
    kullanici_id INT,
    odeme_turu VARCHAR(30) NOT NULL,
    tutar DECIMAL(10,2) NOT NULL,
    odeme_tarihi DATETIME DEFAULT CURRENT_TIMESTAMP,
    aciklama TEXT,
    durum VARCHAR(20) DEFAULT 'Onaylandı',
    olusturma_tarihi DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (satis_id) REFERENCES satislar(satis_id),
    FOREIGN KEY (kullanici_id) REFERENCES kullanicilar(kullanici_id)
);

-- 10. Borçlar Alacaklar Tablosu
CREATE TABLE IF NOT EXISTS borclar_alacaklar (
    borc_alacak_id INT PRIMARY KEY AUTO_INCREMENT,
    musteri_id INT NOT NULL,
    satis_id INT,
    tutar DECIMAL(10,2) NOT NULL,
    kalan_tutar DECIMAL(10,2) NOT NULL,
    tur VARCHAR(10) NOT NULL,
    durum VARCHAR(20) DEFAULT 'Açık',
    vade_tarihi DATETIME,
    tarih DATETIME DEFAULT CURRENT_TIMESTAMP,
    aciklama TEXT,
    olusturma_tarihi DATETIME DEFAULT CURRENT_TIMESTAMP,
    guncelleme_tarihi DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (musteri_id) REFERENCES musteriler(musteri_id),
    FOREIGN KEY (satis_id) REFERENCES satislar(satis_id)
);

-- 11. Giderler Tablosu
CREATE TABLE IF NOT EXISTS giderler (
    gider_id INT PRIMARY KEY AUTO_INCREMENT,
    kullanici_id INT,
    gider_kategori VARCHAR(50) NOT NULL,
    gider_adi VARCHAR(100) NOT NULL,
    tutar DECIMAL(10,2) NOT NULL,
    tarih DATETIME DEFAULT CURRENT_TIMESTAMP,
    aciklama TEXT,
    fatura_no VARCHAR(50),
    tedarikci_id INT,
    olusturma_tarihi DATETIME DEFAULT CURRENT_TIMESTAMP,
    guncelleme_tarihi DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (kullanici_id) REFERENCES kullanicilar(kullanici_id),
    FOREIGN KEY (tedarikci_id) REFERENCES tedarikciler(tedarikci_id)
);

-- 12. Kasa Tablosu
CREATE TABLE IF NOT EXISTS kasa (
    kasa_id INT PRIMARY KEY AUTO_INCREMENT,
    kullanici_id INT,
    islem_turu VARCHAR(20) NOT NULL,
    kaynak VARCHAR(30) NOT NULL,
    referans_id INT,
    tutar DECIMAL(10,2) NOT NULL,
    onceki_bakiye DECIMAL(10,2),
    sonraki_bakiye DECIMAL(10,2),
    tarih DATETIME DEFAULT CURRENT_TIMESTAMP,
    aciklama TEXT,
    olusturma_tarihi DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (kullanici_id) REFERENCES kullanicilar(kullanici_id)
);

-- 13. Sistem Ayarları Tablosu
CREATE TABLE IF NOT EXISTS sistem_ayarlari (
    ayar_id INT PRIMARY KEY AUTO_INCREMENT,
    ayar_adi VARCHAR(100) NOT NULL UNIQUE,
    ayar_degeri TEXT,
    aciklama TEXT,
    guncelleme_tarihi DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- İndeksler
CREATE INDEX IF NOT EXISTS idx_satislar_tarihi ON satislar(satis_tarihi);
CREATE INDEX IF NOT EXISTS idx_odemeler_tarihi ON odemeler(odeme_tarihi);
CREATE INDEX IF NOT EXISTS idx_stok_hareketleri_tarihi ON stok_hareketleri(islem_tarihi);
CREATE INDEX IF NOT EXISTS idx_giderler_tarihi ON giderler(tarih);
CREATE INDEX IF NOT EXISTS idx_kasa_tarihi ON kasa(tarih);
CREATE INDEX IF NOT EXISTS idx_musteriler_telefon ON musteriler(telefon);
CREATE INDEX IF NOT EXISTS idx_stoklar_urun_adi ON stoklar(urun_adi);

-- Varsayılan Veriler
INSERT INTO kategoriler (kategori_adi, aciklama) VALUES 
('Dana', 'Dana eti ürünleri'),
('Tavuk', 'Tavuk eti ürünleri'),
('Kuzu', 'Kuzu eti ürünleri'),
('Kıyma', 'Kıyma ürünleri'),
('Şarküteri', 'Şarküteri ürünleri'),
('Diğer', 'Diğer et ürünleri');

INSERT INTO sistem_ayarlari (ayar_adi, ayar_degeri, aciklama) VALUES
('firma_adi', 'Kasap Dükkanım', 'Firma adı'),
('telefon', '0555 123 45 67', 'İletişim telefonu'),
('adres', '', 'Firma adresi'),
('vergi_no', '', 'Vergi numarası'),
('kdv_orani', '18', 'Varsayılan KDV oranı'),
('para_birimi', 'TL', 'Para birimi');