const jwt = require('jsonwebtoken');
const { queryOne } = require('../config/database');

// JWT token doğrulama middleware
const authenticateToken = async (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1]; // Bearer TOKEN

  if (!token) {
    return res.status(401).json({ 
      success: false, 
      message: 'Erişim token\'ı gerekli' 
    });
  }

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    
    // Kullanıcının hala aktif olup olmadığını kontrol et
    const user = await queryOne(
      'SELECT kullanici_id, isim, email, rol, aktif FROM kullanicilar WHERE kullanici_id = ?',
      [decoded.kullanici_id]
    );

    if (!user || !user.aktif) {
      return res.status(401).json({ 
        success: false, 
        message: 'Geçersiz veya deaktif kullanıcı' 
      });
    }

    req.user = user;
    next();
  } catch (error) {
    return res.status(403).json({ 
      success: false, 
      message: 'Geçersiz token' 
    });
  }
};

// Admin yetki kontrolü
const requireAdmin = (req, res, next) => {
  if (req.user.rol !== 'admin') {
    return res.status(403).json({ 
      success: false, 
      message: 'Bu işlem için admin yetkisi gerekli' 
    });
  }
  next();
};

// Kasiyer veya admin yetki kontrolü
const requireCashierOrAdmin = (req, res, next) => {
  if (!['admin', 'kasiyer'].includes(req.user.rol)) {
    return res.status(403).json({ 
      success: false, 
      message: 'Bu işlem için kasiyer veya admin yetkisi gerekli' 
    });
  }
  next();
};

module.exports = {
  authenticateToken,
  requireAdmin,
  requireCashierOrAdmin
};