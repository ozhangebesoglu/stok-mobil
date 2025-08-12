const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { body, validationResult } = require('express-validator');
const { query, queryOne } = require('../config/database');
const { authenticateToken } = require('../middleware/auth');

const router = express.Router();

// Giriş yap
router.post('/login', [
  body('email').isEmail().withMessage('Geçerli bir email adresi girin'),
  body('sifre').isLength({ min: 1 }).withMessage('Şifre gerekli')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        message: 'Girdi hatası',
        errors: errors.array()
      });
    }

    const { email, sifre } = req.body;

    // Kullanıcıyı bul
    const user = await queryOne(
      'SELECT kullanici_id, isim, email, sifre_hash, rol, aktif FROM kullanicilar WHERE email = ?',
      [email]
    );

    if (!user) {
      return res.status(401).json({
        success: false,
        message: 'Email veya şifre hatalı'
      });
    }

    if (!user.aktif) {
      return res.status(401).json({
        success: false,
        message: 'Hesabınız deaktif edilmiş'
      });
    }

    // Şifre kontrolü
    const isValidPassword = await bcrypt.compare(sifre, user.sifre_hash);
    if (!isValidPassword) {
      return res.status(401).json({
        success: false,
        message: 'Email veya şifre hatalı'
      });
    }

    // JWT token oluştur
    const token = jwt.sign(
      { 
        kullanici_id: user.kullanici_id,
        email: user.email,
        rol: user.rol
      },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
    );

    // Son giriş tarihini güncelle
    await query(
      'UPDATE kullanicilar SET son_giris = CURRENT_TIMESTAMP WHERE kullanici_id = ?',
      [user.kullanici_id]
    );

    // Şifreyi response'dan çıkar
    delete user.sifre_hash;

    res.json({
      success: true,
      message: 'Giriş başarılı',
      data: {
        user,
        token
      }
    });

  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({
      success: false,
      message: 'Sunucu hatası'
    });
  }
});

// Kullanıcı profili
router.get('/profile', authenticateToken, async (req, res) => {
  try {
    const user = await queryOne(
      'SELECT kullanici_id, isim, email, telefon, rol, son_giris, olusturma_tarihi FROM kullanicilar WHERE kullanici_id = ?',
      [req.user.kullanici_id]
    );

    res.json({
      success: true,
      data: { user }
    });

  } catch (error) {
    console.error('Profile error:', error);
    res.status(500).json({
      success: false,
      message: 'Sunucu hatası'
    });
  }
});

// Şifre değiştir
router.put('/change-password', [
  authenticateToken,
  body('mevcutSifre').isLength({ min: 1 }).withMessage('Mevcut şifre gerekli'),
  body('yeniSifre').isLength({ min: 6 }).withMessage('Yeni şifre en az 6 karakter olmalı')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        message: 'Girdi hatası',
        errors: errors.array()
      });
    }

    const { mevcutSifre, yeniSifre } = req.body;

    // Mevcut şifreyi kontrol et
    const user = await queryOne(
      'SELECT sifre_hash FROM kullanicilar WHERE kullanici_id = ?',
      [req.user.kullanici_id]
    );

    const isValidPassword = await bcrypt.compare(mevcutSifre, user.sifre_hash);
    if (!isValidPassword) {
      return res.status(400).json({
        success: false,
        message: 'Mevcut şifre hatalı'
      });
    }

    // Yeni şifreyi hash'le
    const saltRounds = 10;
    const hashedPassword = await bcrypt.hash(yeniSifre, saltRounds);

    // Şifreyi güncelle
    await query(
      'UPDATE kullanicilar SET sifre_hash = ? WHERE kullanici_id = ?',
      [hashedPassword, req.user.kullanici_id]
    );

    res.json({
      success: true,
      message: 'Şifre başarıyla değiştirildi'
    });

  } catch (error) {
    console.error('Change password error:', error);
    res.status(500).json({
      success: false,
      message: 'Sunucu hatası'
    });
  }
});

// Token doğrula
router.post('/verify-token', authenticateToken, (req, res) => {
  res.json({
    success: true,
    message: 'Token geçerli',
    data: { user: req.user }
  });
});

module.exports = router;