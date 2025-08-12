-- Esnaf Defterim - Kasap Dükkanı Veritabanı
-- Modern kasap dükkanı yönetim sistemi için veritabanı şeması

-- Veritabanı oluştur
CREATE DATABASE IF NOT EXISTS esnaf_defterim CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE esnaf_defterim;

-- 1. Kullanıcılar Tablosu
CREATE TABLE kullanicilar (
    kullanici_id INT PRIMARY KEY AUTO_INCREMENT,
    isim VARCHAR(100) NOT NULL,
    email VARCHAR(150) UNIQUE NOT NULL,
    telefon VARCHAR(20),
    sifre_hash VARCHAR(255) NOT NULL,
    rol ENUM('admin', 'kullanici', 'kasiyer') DEFAULT 'kullanici',
    aktif BOOLEAN DEFAULT TRUE,
    son_giris DATETIME NULL,
    olusturma_tarihi DATETIME DEFAULT CURRENT_TIMESTAMP,
    guncelleme_tarihi DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_email (email),
    INDEX idx_rol (rol)
);

-- 2. Tedarikçiler Tablosu
CREATE TABLE tedarikciler (
    tedarikci_id INT PRIMARY KEY AUTO_INCREMENT,
    isim VARCHAR(100) NOT NULL,
    telefon VARCHAR(20),
    email VARCHAR(150),
    adres TEXT,
    vergi_no VARCHAR(20),
    notlar TEXT,
    aktif BOOLEAN DEFAULT TRUE,
    olusturma_tarihi DATETIME DEFAULT CURRENT_TIMESTAMP,
    guncelleme_tarihi DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_isim (isim),
    INDEX idx_vergi_no (vergi_no)
);

-- 3. Müşteriler Tablosu
CREATE TABLE musteriler (
    musteri_id INT PRIMARY KEY AUTO_INCREMENT,
    isim VARCHAR(100) NOT NULL,
    telefon VARCHAR(20),
    email VARCHAR(150),
    adres TEXT,
    musteri_tipi ENUM('Bireysel', 'Kurumsal') DEFAULT 'Bireysel',
    vergi_no VARCHAR(20),
    kredi_limiti DECIMAL(10,2) DEFAULT 0,
    aktif BOOLEAN DEFAULT TRUE,
    olusturma_tarihi DATETIME DEFAULT CURRENT_TIMESTAMP,
    guncelleme_tarihi DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_isim (isim),
    INDEX idx_telefon (telefon),
    INDEX idx_musteri_tipi (musteri_tipi)
);

-- 4. Kategoriler Tablosu
CREATE TABLE kategoriler (
    kategori_id INT PRIMARY KEY AUTO_INCREMENT,
    kategori_adi VARCHAR(100) NOT NULL UNIQUE,
    aciklama TEXT,
    renk VARCHAR(7) DEFAULT '#3498db',
    aktif BOOLEAN DEFAULT TRUE,
    olusturma_tarihi DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_kategori_adi (kategori_adi)
);

-- 5. Stoklar Tablosu
CREATE TABLE stoklar (
    stok_id INT PRIMARY KEY AUTO_INCREMENT,
    urun_adi VARCHAR(100) NOT NULL,
    kategori_id INT,
    toplam_agirlik DECIMAL(8,3) NOT NULL,
    kalan_agirlik DECIMAL(8,3) NOT NULL,
    tedarikci_id INT,
    alis_fiyati DECIMAL(8,2),
    satis_fiyati DECIMAL(8,2),
    kar_orani DECIMAL(5,2) AS ((satis_fiyati - alis_fiyati) / alis_fiyati * 100),
    kesim_tarihi DATETIME,
    son_kullanma_tarihi DATETIME,
    minimum_stok DECIMAL(8,3) DEFAULT 0,
    aktif BOOLEAN DEFAULT TRUE,
    olusturma_tarihi DATETIME DEFAULT CURRENT_TIMESTAMP,
    guncelleme_tarihi DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (kategori_id) REFERENCES kategoriler(kategori_id) ON DELETE SET NULL,
    FOREIGN KEY (tedarikci_id) REFERENCES tedarikciler(tedarikci_id) ON DELETE SET NULL,
    INDEX idx_urun_adi (urun_adi),
    INDEX idx_kategori (kategori_id),
    INDEX idx_kalan_agirlik (kalan_agirlik),
    INDEX idx_son_kullanma (son_kullanma_tarihi)
);

-- 6. Stok Hareketleri Tablosu
CREATE TABLE stok_hareketleri (
    hareket_id INT PRIMARY KEY AUTO_INCREMENT,
    stok_id INT NOT NULL,
    kullanici_id INT,
    islem_turu ENUM('Giriş', 'Çıkış', 'Düzeltme', 'Fire') NOT NULL,
    miktar DECIMAL(8,3) NOT NULL,
    onceki_miktar DECIMAL(8,3),
    sonraki_miktar DECIMAL(8,3),
    islem_tarihi DATETIME DEFAULT CURRENT_TIMESTAMP,
    aciklama TEXT,
    satis_id INT NULL,
    FOREIGN KEY (stok_id) REFERENCES stoklar(stok_id) ON DELETE CASCADE,
    FOREIGN KEY (kullanici_id) REFERENCES kullanicilar(kullanici_id) ON DELETE SET NULL,
    INDEX idx_stok_id (stok_id),
    INDEX idx_islem_tarihi (islem_tarihi),
    INDEX idx_islem_turu (islem_turu)
);

-- 7. Satışlar Tablosu
CREATE TABLE satislar (
    satis_id INT PRIMARY KEY AUTO_INCREMENT,
    kullanici_id INT NOT NULL,
    musteri_id INT NULL,
    satis_turu ENUM('Perakende', 'Toptan', 'Online') DEFAULT 'Perakende',
    toplam_miktar DECIMAL(8,3) NOT NULL,
    ara_toplam DECIMAL(10,2) NOT NULL,
    indirim_orani DECIMAL(5,2) DEFAULT 0,
    indirim_tutari DECIMAL(10,2) DEFAULT 0,
    kdv_orani DECIMAL(5,2) DEFAULT 18,
    kdv_tutari DECIMAL(10,2) AS (ara_toplam * kdv_orani / 100),
    toplam_tutar DECIMAL(10,2) NOT NULL,
    odenen_tutar DECIMAL(10,2) DEFAULT 0,
    kalan_tutar DECIMAL(10,2) AS (toplam_tutar - odenen_tutar),
    durum ENUM('Taslak', 'Tamamlandı', 'İptal', 'İade') DEFAULT 'Tamamlandı',
    satis_tarihi DATETIME DEFAULT CURRENT_TIMESTAMP,
    olusturma_tarihi DATETIME DEFAULT CURRENT_TIMESTAMP,
    guncelleme_tarihi DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (kullanici_id) REFERENCES kullanicilar(kullanici_id),
    FOREIGN KEY (musteri_id) REFERENCES musteriler(musteri_id) ON DELETE SET NULL,
    INDEX idx_satis_tarihi (satis_tarihi),
    INDEX idx_durum (durum),
    INDEX idx_kullanici (kullanici_id),
    INDEX idx_musteri (musteri_id)
);

-- 8. Satış Detayları Tablosu
CREATE TABLE satis_detaylari (
    detay_id INT PRIMARY KEY AUTO_INCREMENT,
    satis_id INT NOT NULL,
    stok_id INT NOT NULL,
    urun_adi VARCHAR(100) NOT NULL,
    miktar DECIMAL(8,3) NOT NULL,
    birim_fiyat DECIMAL(8,2) NOT NULL,
    ara_toplam DECIMAL(10,2) AS (miktar * birim_fiyat),
    indirim_orani DECIMAL(5,2) DEFAULT 0,
    indirim_tutari DECIMAL(10,2) DEFAULT 0,
    toplam DECIMAL(10,2) AS (ara_toplam - indirim_tutari),
    FOREIGN KEY (satis_id) REFERENCES satislar(satis_id) ON DELETE CASCADE,
    FOREIGN KEY (stok_id) REFERENCES stoklar(stok_id),
    INDEX idx_satis_id (satis_id),
    INDEX idx_stok_id (stok_id)
);

-- 9. Ödemeler Tablosu
CREATE TABLE odemeler (
    odeme_id INT PRIMARY KEY AUTO_INCREMENT,
    satis_id INT,
    kullanici_id INT,
    odeme_turu ENUM('Nakit', 'Kredi Kartı', 'Banka Kartı', 'Havale', 'Çek', 'Veresiye') NOT NULL,
    tutar DECIMAL(10,2) NOT NULL,
    odeme_tarihi DATETIME DEFAULT CURRENT_TIMESTAMP,
    aciklama TEXT,
    durum ENUM('Beklemede', 'Onaylandı', 'İptal') DEFAULT 'Onaylandı',
    olusturma_tarihi DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (satis_id) REFERENCES satislar(satis_id) ON DELETE CASCADE,
    FOREIGN KEY (kullanici_id) REFERENCES kullanicilar(kullanici_id),
    INDEX idx_odeme_tarihi (odeme_tarihi),
    INDEX idx_odeme_turu (odeme_turu),
    INDEX idx_durum (durum)
);

-- 10. Borçlar Alacaklar Tablosu
CREATE TABLE borclar_alacaklar (
    borc_alacak_id INT PRIMARY KEY AUTO_INCREMENT,
    musteri_id INT NOT NULL,
    satis_id INT NULL,
    tutar DECIMAL(10,2) NOT NULL,
    kalan_tutar DECIMAL(10,2) NOT NULL,
    tur ENUM('Borç', 'Alacak') NOT NULL,
    durum ENUM('Açık', 'Kapalı', 'Kısmi') DEFAULT 'Açık',
    vade_tarihi DATE NULL,
    tarih DATETIME DEFAULT CURRENT_TIMESTAMP,
    aciklama TEXT,
    olusturma_tarihi DATETIME DEFAULT CURRENT_TIMESTAMP,
    guncelleme_tarihi DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (musteri_id) REFERENCES musteriler(musteri_id) ON DELETE CASCADE,
    FOREIGN KEY (satis_id) REFERENCES satislar(satis_id) ON DELETE SET NULL,
    INDEX idx_musteri_id (musteri_id),
    INDEX idx_durum (durum),
    INDEX idx_vade_tarihi (vade_tarihi)
);

-- 11. Giderler Tablosu
CREATE TABLE giderler (
    gider_id INT PRIMARY KEY AUTO_INCREMENT,
    kullanici_id INT,
    gider_kategori ENUM('Kira', 'Elektrik', 'Su', 'Doğalgaz', 'Personel', 'Temizlik', 'Nakliye', 'Vergi', 'Sigorta', 'Diğer') NOT NULL,
    gider_adi VARCHAR(100) NOT NULL,
    tutar DECIMAL(10,2) NOT NULL,
    tarih DATE DEFAULT (CURRENT_DATE),
    aciklama TEXT,
    fatura_no VARCHAR(50),
    tedarikci_id INT NULL,
    olusturma_tarihi DATETIME DEFAULT CURRENT_TIMESTAMP,
    guncelleme_tarihi DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (kullanici_id) REFERENCES kullanicilar(kullanici_id),
    FOREIGN KEY (tedarikci_id) REFERENCES tedarikciler(tedarikci_id) ON DELETE SET NULL,
    INDEX idx_tarih (tarih),
    INDEX idx_kategori (gider_kategori),
    INDEX idx_kullanici (kullanici_id)
);

-- 12. Kasa Tablosu
CREATE TABLE kasa (
    kasa_id INT PRIMARY KEY AUTO_INCREMENT,
    kullanici_id INT,
    islem_turu ENUM('Giriş', 'Çıkış') NOT NULL,
    kaynak ENUM('Satış', 'Gider', 'Borç Ödeme', 'Alacak Tahsil', 'Diğer') NOT NULL,
    referans_id INT NULL,
    tutar DECIMAL(10,2) NOT NULL,
    onceki_bakiye DECIMAL(10,2),
    sonraki_bakiye DECIMAL(10,2),
    tarih DATETIME DEFAULT CURRENT_TIMESTAMP,
    aciklama TEXT,
    olusturma_tarihi DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (kullanici_id) REFERENCES kullanicilar(kullanici_id),
    INDEX idx_tarih (tarih),
    INDEX idx_islem_turu (islem_turu),
    INDEX idx_kaynak (kaynak)
);

-- 13. Sistem Ayarları Tablosu
CREATE TABLE sistem_ayarlari (
    ayar_id INT PRIMARY KEY AUTO_INCREMENT,
    ayar_adi VARCHAR(100) NOT NULL UNIQUE,
    ayar_degeri TEXT,
    veri_tipi ENUM('string', 'number', 'boolean', 'json') DEFAULT 'string',
    aciklama TEXT,
    guncelleme_tarihi DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_ayar_adi (ayar_adi)
);

-- 14. Oturumlar Tablosu (Güvenlik için)
CREATE TABLE oturumlar (
    oturum_id INT PRIMARY KEY AUTO_INCREMENT,
    kullanici_id INT NOT NULL,
    token_hash VARCHAR(255) NOT NULL,
    ip_adresi VARCHAR(45),
    user_agent TEXT,
    olusturma_tarihi DATETIME DEFAULT CURRENT_TIMESTAMP,
    son_aktivite DATETIME DEFAULT CURRENT_TIMESTAMP,
    aktif BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (kullanici_id) REFERENCES kullanicilar(kullanici_id) ON DELETE CASCADE,
    INDEX idx_kullanici_id (kullanici_id),
    INDEX idx_token_hash (token_hash),
    INDEX idx_son_aktivite (son_aktivite)
);

-- Trigger'lar

-- Stok hareket trigger'ı
DELIMITER //
CREATE TRIGGER stok_hareket_after_insert 
AFTER INSERT ON stok_hareketleri
FOR EACH ROW
BEGIN
    IF NEW.islem_turu = 'Giriş' THEN
        UPDATE stoklar 
        SET kalan_agirlik = kalan_agirlik + NEW.miktar 
        WHERE stok_id = NEW.stok_id;
    ELSEIF NEW.islem_turu IN ('Çıkış', 'Fire') THEN
        UPDATE stoklar 
        SET kalan_agirlik = kalan_agirlik - NEW.miktar 
        WHERE stok_id = NEW.stok_id;
    ELSEIF NEW.islem_turu = 'Düzeltme' THEN
        UPDATE stoklar 
        SET kalan_agirlik = NEW.sonraki_miktar 
        WHERE stok_id = NEW.stok_id;
    END IF;
END//
DELIMITER ;

-- Kasa bakiye trigger'ı
DELIMITER //
CREATE TRIGGER kasa_bakiye_trigger 
BEFORE INSERT ON kasa
FOR EACH ROW
BEGIN
    DECLARE son_bakiye DECIMAL(10,2) DEFAULT 0;
    
    SELECT COALESCE(sonraki_bakiye, 0) INTO son_bakiye 
    FROM kasa 
    ORDER BY kasa_id DESC 
    LIMIT 1;
    
    SET NEW.onceki_bakiye = son_bakiye;
    
    IF NEW.islem_turu = 'Giriş' THEN
        SET NEW.sonraki_bakiye = son_bakiye + NEW.tutar;
    ELSE
        SET NEW.sonraki_bakiye = son_bakiye - NEW.tutar;
    END IF;
END//
DELIMITER ;

-- View'lar

-- Stok durumu view
CREATE VIEW stok_durumu AS
SELECT 
    s.stok_id,
    s.urun_adi,
    k.kategori_adi,
    s.kalan_agirlik,
    s.minimum_stok,
    CASE 
        WHEN s.kalan_agirlik <= s.minimum_stok THEN 'Kritik'
        WHEN s.kalan_agirlik <= s.minimum_stok * 2 THEN 'Düşük'
        ELSE 'Normal'
    END as stok_durumu,
    s.satis_fiyati,
    s.son_kullanma_tarihi,
    CASE 
        WHEN s.son_kullanma_tarihi <= CURDATE() THEN 'Süresi Geçmiş'
        WHEN s.son_kullanma_tarihi <= DATE_ADD(CURDATE(), INTERVAL 3 DAY) THEN 'Yakında Geçecek'
        ELSE 'Normal'
    END as tarih_durumu
FROM stoklar s
LEFT JOIN kategoriler k ON s.kategori_id = k.kategori_id
WHERE s.aktif = TRUE;

-- Günlük satış özeti view
CREATE VIEW gunluk_satis_ozeti AS
SELECT 
    DATE(satis_tarihi) as tarih,
    COUNT(*) as satis_sayisi,
    SUM(toplam_miktar) as toplam_miktar,
    SUM(toplam_tutar) as toplam_ciro,
    SUM(odenen_tutar) as tahsilat,
    SUM(kalan_tutar) as bekleyen_tahsilat,
    AVG(toplam_tutar) as ortalama_satis
FROM satislar 
WHERE durum = 'Tamamlandı'
GROUP BY DATE(satis_tarihi);

-- Müşteri borç durumu view
CREATE VIEW musteri_borc_durumu AS
SELECT 
    m.musteri_id,
    m.isim,
    m.telefon,
    COALESCE(SUM(CASE WHEN ba.tur = 'Borç' AND ba.durum != 'Kapalı' THEN ba.kalan_tutar ELSE 0 END), 0) as toplam_borc,
    COALESCE(SUM(CASE WHEN ba.tur = 'Alacak' AND ba.durum != 'Kapalı' THEN ba.kalan_tutar ELSE 0 END), 0) as toplam_alacak,
    m.kredi_limiti,
    COUNT(CASE WHEN ba.vade_tarihi < CURDATE() AND ba.durum != 'Kapalı' THEN 1 END) as geciken_borc_sayisi
FROM musteriler m
LEFT JOIN borclar_alacaklar ba ON m.musteri_id = ba.musteri_id
WHERE m.aktif = TRUE
GROUP BY m.musteri_id, m.isim, m.telefon, m.kredi_limiti;

-- Varsayılan veriler
INSERT INTO kategoriler (kategori_adi, aciklama, renk) VALUES 
('Dana', 'Dana eti ürünleri', '#e74c3c'),
('Tavuk', 'Tavuk eti ürünleri', '#f39c12'),
('Kuzu', 'Kuzu eti ürünleri', '#9b59b6'),
('Kıyma', 'Kıyma ürünleri', '#34495e'),
('Şarküteri', 'Şarküteri ürünleri', '#16a085'),
('Sakatat', 'Sakatat ürünleri', '#8e44ad'),
('Diğer', 'Diğer et ürünleri', '#95a5a6');

INSERT INTO sistem_ayarlari (ayar_adi, ayar_degeri, veri_tipi, aciklama) VALUES
('firma_adi', 'Esnaf Defterim', 'string', 'Firma adı'),
('telefon', '0555 123 45 67', 'string', 'İletişim telefonu'),
('adres', '', 'string', 'Firma adresi'),
('vergi_no', '', 'string', 'Vergi numarası'),
('kdv_orani', '18', 'number', 'Varsayılan KDV oranı'),
('para_birimi', 'TL', 'string', 'Para birimi'),
('minimum_stok_uyarisi', 'true', 'boolean', 'Minimum stok uyarısını etkinleştir'),
('son_kullanma_uyarisi', 'true', 'boolean', 'Son kullanma tarihi uyarısını etkinleştir'),
('veresiye_limiti', '1000', 'number', 'Varsayılan veresiye limiti'),
('fiş_yazıcısı', 'false', 'boolean', 'Fiş yazıcısını etkinleştir');

-- Admin kullanıcı (şifre: admin123)
-- Şifre hash'i bcrypt ile oluşturulmuş
INSERT INTO kullanicilar (isim, email, sifre_hash, rol) VALUES 
('Admin', 'admin@esnafdefterim.com', '$2a$10$/lfczrlaeE/.TTXrNAf1UuT04gcUuUCAqJ9077h1l0uRiSnVhTp1i', 'admin');

-- Demo müşteri
INSERT INTO musteriler (isim, telefon, musteri_tipi) VALUES 
('Nakit Müşteri', '', 'Bireysel'),
('Demo Müşteri', '0532 123 45 67', 'Bireysel');

-- Demo tedarikçi
INSERT INTO tedarikciler (isim, telefon, email) VALUES 
('Demo Et Tedarikçisi', '0212 123 45 67', 'demo@tedarikci.com');