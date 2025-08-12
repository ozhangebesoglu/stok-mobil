const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const compression = require('compression');
const morgan = require('morgan');
const rateLimit = require('express-rate-limit');
require('dotenv').config();

const { testConnection } = require('./config/database');

const app = express();
const PORT = process.env.PORT || 5000;

// Rate limiting
const limiter = rateLimit({
  windowMs: 1 * 60 * 1000, // 1 dakika
  max: process.env.MAX_REQUESTS_PER_MINUTE || 100,
  message: {
    success: false,
    message: 'Çok fazla istek gönderildi, lütfen daha sonra tekrar deneyin'
  }
});

// Middleware
app.use(helmet());
app.use(compression());
app.use(morgan('combined'));
app.use(limiter);
app.use(cors({
  origin: process.env.CORS_ORIGIN || 'http://localhost:3000',
  credentials: true
}));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Routes
app.use('/api/auth', require('./routes/auth'));

// Ana route
app.get('/', (req, res) => {
  res.json({
    success: true,
    message: 'Esnaf Defterim API v1.0',
    timestamp: new Date().toISOString(),
    status: 'active'
  });
});

// Health check
app.get('/health', async (req, res) => {
  try {
    const dbStatus = await testConnection();
    res.json({
      success: true,
      status: 'healthy',
      database: dbStatus ? 'connected' : 'disconnected',
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    res.status(503).json({
      success: false,
      status: 'unhealthy',
      database: 'error',
      timestamp: new Date().toISOString()
    });
  }
});

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({
    success: false,
    message: 'API endpoint bulunamadı'
  });
});

// Global error handler
app.use((error, req, res, next) => {
  console.error('Global error:', error);
  res.status(500).json({
    success: false,
    message: 'Sunucu hatası',
    ...(process.env.NODE_ENV === 'development' && { error: error.message })
  });
});

// Server başlat
async function startServer() {
  try {
    // Veritabanı bağlantısını test et
    const dbConnected = await testConnection();
    if (!dbConnected) {
      console.error('❌ Veritabanı bağlantısı kurulamadı. Server başlatılamıyor.');
      process.exit(1);
    }

    app.listen(PORT, () => {
      console.log(`🚀 Server http://localhost:${PORT} adresinde çalışıyor`);
      console.log(`📱 Frontend: ${process.env.CORS_ORIGIN || 'http://localhost:3000'}`);
      console.log(`🔧 Environment: ${process.env.NODE_ENV || 'development'}`);
    });
  } catch (error) {
    console.error('❌ Server başlatma hatası:', error);
    process.exit(1);
  }
}

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('SIGTERM sinyali alındı, server kapatılıyor...');
  process.exit(0);
});

process.on('SIGINT', () => {
  console.log('SIGINT sinyali alındı, server kapatılıyor...');
  process.exit(0);
});

startServer();