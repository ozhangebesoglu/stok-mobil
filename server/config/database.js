const mysql = require('mysql2/promise');
require('dotenv').config();

// Veritabanı bağlantı havuzu oluştur
const pool = mysql.createPool({
  host: process.env.DB_HOST || 'localhost',
  port: process.env.DB_PORT || 3306,
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || '',
  database: process.env.DB_NAME || 'esnaf_defterim',
  charset: 'utf8mb4',
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,
  acquireTimeout: 60000,
  timeout: 60000,
  reconnect: true
});

// Bağlantı testi
async function testConnection() {
  try {
    const connection = await pool.getConnection();
    console.log('✅ Veritabanı bağlantısı başarılı');
    connection.release();
    return true;
  } catch (error) {
    console.error('❌ Veritabanı bağlantı hatası:', error.message);
    return false;
  }
}

// Veritabanı sorgu helper fonksiyonu
async function query(sql, params = []) {
  try {
    const [rows] = await pool.execute(sql, params);
    return rows;
  } catch (error) {
    console.error('Veritabanı sorgu hatası:', error.message);
    throw error;
  }
}

// Tek satır getir
async function queryOne(sql, params = []) {
  const rows = await query(sql, params);
  return rows[0] || null;
}

module.exports = {
  pool,
  query,
  queryOne,
  testConnection
};