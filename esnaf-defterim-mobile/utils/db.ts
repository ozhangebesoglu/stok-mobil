import * as SQLite from 'expo-sqlite';

export const db = SQLite.openDatabaseSync('esnaf_defterim.db');

export function runMigrations() {
  db.execSync(`
    PRAGMA journal_mode = WAL;

    CREATE TABLE IF NOT EXISTS users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      isim TEXT NOT NULL,
      email TEXT NOT NULL UNIQUE,
      telefon TEXT,
      sifre_hash TEXT NOT NULL,
      rol TEXT DEFAULT 'kullanici',
      aktif INTEGER DEFAULT 1,
      created_at TEXT DEFAULT (datetime('now')),
      updated_at TEXT DEFAULT (datetime('now'))
    );

    CREATE TABLE IF NOT EXISTS kategoriler (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      kategori_adi TEXT NOT NULL UNIQUE,
      aciklama TEXT,
      aktif INTEGER DEFAULT 1,
      created_at TEXT DEFAULT (datetime('now'))
    );

    CREATE TABLE IF NOT EXISTS stoklar (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      urun_adi TEXT NOT NULL,
      kategori_id INTEGER,
      toplam_agirlik REAL NOT NULL,
      kalan_agirlik REAL NOT NULL,
      alis_fiyati REAL,
      satis_fiyati REAL,
      kar_orani REAL,
      aktif INTEGER DEFAULT 1,
      created_at TEXT DEFAULT (datetime('now')),
      updated_at TEXT DEFAULT (datetime('now')),
      FOREIGN KEY (kategori_id) REFERENCES kategoriler(id)
    );

    CREATE INDEX IF NOT EXISTS idx_stoklar_urun_adi ON stoklar(urun_adi);

    INSERT OR IGNORE INTO kategoriler (kategori_adi, aciklama) VALUES
      ('Dana', 'Dana eti ürünleri'),
      ('Tavuk', 'Tavuk eti ürünleri'),
      ('Kuzu', 'Kuzu eti ürünleri'),
      ('Kıyma', 'Kıyma ürünleri'),
      ('Şarküteri', 'Şarküteri ürünleri'),
      ('Diğer', 'Diğer et ürünleri');
  `);
}