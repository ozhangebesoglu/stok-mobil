const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { pool } = require('../config/database');
const { authenticateToken } = require('../middleware/auth');

const router = express.Router();

// Login
router.post('/login', async (req, res) => {
  try {
    const { email, sifre } = req.body;

    if (!email || !sifre) {
      return res.status(400).json({
        success: false,
        message: 'Email ve şifre gereklidir'
      });
    }

    const [users] = await pool.execute(
      'SELECT * FROM kullanicilar WHERE email = ? AND aktif = 1',
      [email]
    );

    if (users.length === 0) {
      return res.status(401).json({
        success: false,
        message: 'Geçersiz email veya şifre'
      });
    }

    const user = users[0];
    const isValidPassword = await bcrypt.compare(sifre, user.sifre_hash);

    if (!isValidPassword) {
      return res.status(401).json({
        success: false,
        message: 'Geçersiz email veya şifre'
      });
    }

    const token = jwt.sign(
      { userId: user.kullanici_id, email: user.email },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRES_IN }
    );

    res.json({
      success: true,
      message: 'Giriş başarılı',
      data: {
        token,
        user: {
          kullanici_id: user.kullanici_id,
          isim: user.isim,
          email: user.email,
          rol: user.rol
        }
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

// Register (Admin only)
router.post('/register', authenticateToken, async (req, res) => {
  try {
    const { isim, email, telefon, sifre, rol = 'kullanici' } = req.body;

    if (!isim || !email || !sifre) {
      return res.status(400).json({
        success: false,
        message: 'İsim, email ve şifre gereklidir'
      });
    }

    // Check if user already exists
    const [existingUsers] = await pool.execute(
      'SELECT kullanici_id FROM kullanicilar WHERE email = ?',
      [email]
    );

    if (existingUsers.length > 0) {
      return res.status(400).json({
        success: false,
        message: 'Bu email adresi zaten kullanılıyor'
      });
    }

    // Hash password
    const saltRounds = 12;
    const hashedPassword = await bcrypt.hash(sifre, saltRounds);

    // Insert new user
    const [result] = await pool.execute(
      'INSERT INTO kullanicilar (isim, email, telefon, sifre_hash, rol) VALUES (?, ?, ?, ?, ?)',
      [isim, email, telefon, hashedPassword, rol]
    );

    res.status(201).json({
      success: true,
      message: 'Kullanıcı başarıyla oluşturuldu',
      data: {
        kullanici_id: result.insertId,
        isim,
        email,
        rol
      }
    });
  } catch (error) {
    console.error('Register error:', error);
    res.status(500).json({
      success: false,
      message: 'Sunucu hatası'
    });
  }
});

// Get current user
router.get('/me', authenticateToken, async (req, res) => {
  try {
    res.json({
      success: true,
      data: {
        user: req.user
      }
    });
  } catch (error) {
    console.error('Get user error:', error);
    res.status(500).json({
      success: false,
      message: 'Sunucu hatası'
    });
  }
});

// Change password
router.put('/change-password', authenticateToken, async (req, res) => {
  try {
    const { currentPassword, newPassword } = req.body;

    if (!currentPassword || !newPassword) {
      return res.status(400).json({
        success: false,
        message: 'Mevcut şifre ve yeni şifre gereklidir'
      });
    }

    // Get current user with password
    const [users] = await pool.execute(
      'SELECT sifre_hash FROM kullanicilar WHERE kullanici_id = ?',
      [req.user.kullanici_id]
    );

    if (users.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Kullanıcı bulunamadı'
      });
    }

    // Verify current password
    const isValidPassword = await bcrypt.compare(currentPassword, users[0].sifre_hash);

    if (!isValidPassword) {
      return res.status(400).json({
        success: false,
        message: 'Mevcut şifre yanlış'
      });
    }

    // Hash new password
    const saltRounds = 12;
    const hashedNewPassword = await bcrypt.hash(newPassword, saltRounds);

    // Update password
    await pool.execute(
      'UPDATE kullanicilar SET sifre_hash = ? WHERE kullanici_id = ?',
      [hashedNewPassword, req.user.kullanici_id]
    );

    res.json({
      success: true,
      message: 'Şifre başarıyla güncellendi'
    });
  } catch (error) {
    console.error('Change password error:', error);
    res.status(500).json({
      success: false,
      message: 'Sunucu hatası'
    });
  }
});

module.exports = router;