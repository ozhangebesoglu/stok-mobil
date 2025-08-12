export interface User {
  kullanici_id: number;
  isim: string;
  email: string;
  telefon?: string;
  rol: string;
  aktif: boolean;
}

export interface Stok {
  stok_id: number;
  urun_adi: string;
  kategori_id?: number;
  kategori_adi?: string;
  toplam_agirlik: number;
  kalan_agirlik: number;
  tedarikci_id?: number;
  tedarikci_adi?: string;
  alis_fiyati?: number;
  satis_fiyati?: number;
  kar_orani?: number;
  kesim_tarihi?: string;
  son_kullanma_tarihi?: string;
  aktif: boolean;
  olusturma_tarihi: string;
  guncelleme_tarihi: string;
}

export interface Kategori {
  kategori_id: number;
  kategori_adi: string;
  aciklama?: string;
  aktif: boolean;
  olusturma_tarihi: string;
}

export interface Tedarikci {
  tedarikci_id: number;
  isim: string;
  telefon?: string;
  email?: string;
  adres?: string;
  vergi_no?: string;
  notlar?: string;
  aktif: boolean;
  olusturma_tarihi: string;
  guncelleme_tarihi: string;
}

export interface Musteri {
  musteri_id: number;
  isim: string;
  telefon?: string;
  email?: string;
  adres?: string;
  musteri_tipi: string;
  vergi_no?: string;
  aktif: boolean;
  olusturma_tarihi: string;
  guncelleme_tarihi: string;
}

export interface StokHareketi {
  hareket_id: number;
  stok_id: number;
  kullanici_id?: number;
  kullanici_adi?: string;
  islem_turu: string;
  miktar: number;
  onceki_miktar?: number;
  sonraki_miktar?: number;
  islem_tarihi: string;
  aciklama?: string;
  satis_id?: number;
}

export interface Satis {
  satis_id: number;
  kullanici_id: number;
  musteri_id?: number;
  satis_turu: string;
  toplam_miktar: number;
  ara_toplam: number;
  indirim_orani: number;
  indirim_tutari: number;
  toplam_tutar: number;
  odenen_tutar: number;
  kalan_tutar: number;
  durum: string;
  satis_tarihi: string;
  olusturma_tarihi: string;
  guncelleme_tarihi: string;
}

export interface SatisDetay {
  detay_id: number;
  satis_id: number;
  stok_id: number;
  urun_adi: string;
  miktar: number;
  birim_fiyat: number;
  ara_toplam: number;
  indirim_orani: number;
  toplam: number;
}

export interface Odeme {
  odeme_id: number;
  satis_id?: number;
  kullanici_id?: number;
  odeme_turu: string;
  tutar: number;
  odeme_tarihi: string;
  aciklama?: string;
  durum: string;
  olusturma_tarihi: string;
}

export interface BorcAlacak {
  borc_alacak_id: number;
  musteri_id: number;
  satis_id?: number;
  tutar: number;
  kalan_tutar: number;
  tur: string;
  durum: string;
  vade_tarihi?: string;
  tarih: string;
  aciklama?: string;
  olusturma_tarihi: string;
  guncelleme_tarihi: string;
}

export interface Gider {
  gider_id: number;
  kullanici_id?: number;
  gider_kategori: string;
  gider_adi: string;
  tutar: number;
  tarih: string;
  aciklama?: string;
  fatura_no?: string;
  tedarikci_id?: number;
  olusturma_tarihi: string;
  guncelleme_tarihi: string;
}

export interface Kasa {
  kasa_id: number;
  kullanici_id?: number;
  islem_turu: string;
  kaynak: string;
  referans_id?: number;
  tutar: number;
  onceki_bakiye?: number;
  sonraki_bakiye?: number;
  tarih: string;
  aciklama?: string;
  olusturma_tarihi: string;
}

export interface SistemAyar {
  ayar_id: number;
  ayar_adi: string;
  ayar_degeri?: string;
  aciklama?: string;
  guncelleme_tarihi: string;
}

export interface ApiResponse<T> {
  success: boolean;
  message: string;
  data?: T;
}

export interface PaginatedResponse<T> {
  success: boolean;
  data: {
    [key: string]: T[];
    pagination: {
      page: number;
      limit: number;
      total: number;
      pages: number;
    };
  };
}

export interface LoginRequest {
  email: string;
  sifre: string;
}

export interface LoginResponse {
  token: string;
  user: User;
}

export interface StokFormData {
  urun_adi: string;
  kategori_id?: number;
  toplam_agirlik: number;
  kalan_agirlik: number;
  tedarikci_id?: number;
  alis_fiyati?: number;
  satis_fiyati?: number;
  kesim_tarihi?: string;
  son_kullanma_tarihi?: string;
}