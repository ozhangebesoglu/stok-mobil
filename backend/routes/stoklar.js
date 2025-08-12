const express = require('express');
const { pool } = require('../config/database');
const { authenticateToken } = require('../middleware/auth');

const router = express.Router();

// Get all stoklar with pagination
router.get('/', authenticateToken, async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 10;
    const offset = (page - 1) * limit;
    const search = req.query.search || '';

    let query = `
      SELECT s.*, k.kategori_adi, t.isim as tedarikci_adi
      FROM stoklar s
      LEFT JOIN kategoriler k ON s.kategori_id = k.kategori_id
      LEFT JOIN tedarikciler t ON s.tedarikci_id = t.tedarikci_id
      WHERE s.aktif = 1
    `;
    let countQuery = 'SELECT COUNT(*) as total FROM stoklar WHERE aktif = 1';
    let params = [];
    let countParams = [];

    if (search) {
      query += ' AND s.urun_adi LIKE ?';
      countQuery += ' AND urun_adi LIKE ?';
      params.push(`%${search}%`);
      countParams.push(`%${search}%`);
    }

    query += ' ORDER BY s.olusturma_tarihi DESC LIMIT ? OFFSET ?';
    params.push(limit, offset);

    const [stoklar] = await pool.execute(query, params);
    const [countResult] = await pool.execute(countQuery, countParams);
    const total = countResult[0].total;

    res.json({
      success: true,
      data: {
        stoklar,
        pagination: {
          page,
          limit,
          total,
          pages: Math.ceil(total / limit)
        }
      }
    });
  } catch (error) {
    console.error('Get stoklar error:', error);
    res.status(500).json({
      success: false,
      message: 'Sunucu hatası'
    });
  }
});

// Get single stok
router.get('/:id', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;

    const [stoklar] = await pool.execute(
      `SELECT s.*, k.kategori_adi, t.isim as tedarikci_adi
       FROM stoklar s
       LEFT JOIN kategoriler k ON s.kategori_id = k.kategori_id
       LEFT JOIN tedarikciler t ON s.tedarikci_id = t.tedarikci_id
       WHERE s.stok_id = ? AND s.aktif = 1`,
      [id]
    );

    if (stoklar.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Stok bulunamadı'
      });
    }

    res.json({
      success: true,
      data: stoklar[0]
    });
  } catch (error) {
    console.error('Get stok error:', error);
    res.status(500).json({
      success: false,
      message: 'Sunucu hatası'
    });
  }
});

// Create new stok
router.post('/', authenticateToken, async (req, res) => {
  try {
    const {
      urun_adi,
      kategori_id,
      toplam_agirlik,
      kalan_agirlik,
      tedarikci_id,
      alis_fiyati,
      satis_fiyati,
      kesim_tarihi,
      son_kullanma_tarihi
    } = req.body;

    if (!urun_adi || !toplam_agirlik || !kalan_agirlik) {
      return res.status(400).json({
        success: false,
        message: 'Ürün adı, toplam ağırlık ve kalan ağırlık gereklidir'
      });
    }

    // Calculate kar orani
    let kar_orani = 0;
    if (alis_fiyati && satis_fiyati && alis_fiyati > 0) {
      kar_orani = ((satis_fiyati - alis_fiyati) / alis_fiyati) * 100;
    }

    const [result] = await pool.execute(
      `INSERT INTO stoklar (
        urun_adi, kategori_id, toplam_agirlik, kalan_agirlik, tedarikci_id,
        alis_fiyati, satis_fiyati, kar_orani, kesim_tarihi, son_kullanma_tarihi
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        urun_adi, kategori_id, toplam_agirlik, kalan_agirlik, tedarikci_id,
        alis_fiyati, satis_fiyati, kar_orani, kesim_tarihi, son_kullanma_tarihi
      ]
    );

    // Log stok movement
    await pool.execute(
      `INSERT INTO stok_hareketleri (
        stok_id, kullanici_id, islem_turu, miktar, onceki_miktar, sonraki_miktar, aciklama
      ) VALUES (?, ?, ?, ?, ?, ?, ?)`,
      [
        result.insertId, req.user.kullanici_id, 'Giriş', toplam_agirlik,
        0, toplam_agirlik, 'Yeni stok girişi'
      ]
    );

    res.status(201).json({
      success: true,
      message: 'Stok başarıyla oluşturuldu',
      data: {
        stok_id: result.insertId
      }
    });
  } catch (error) {
    console.error('Create stok error:', error);
    res.status(500).json({
      success: false,
      message: 'Sunucu hatası'
    });
  }
});

// Update stok
router.put('/:id', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;
    const {
      urun_adi,
      kategori_id,
      toplam_agirlik,
      kalan_agirlik,
      tedarikci_id,
      alis_fiyati,
      satis_fiyati,
      kesim_tarihi,
      son_kullanma_tarihi
    } = req.body;

    // Get current stok
    const [currentStok] = await pool.execute(
      'SELECT * FROM stoklar WHERE stok_id = ? AND aktif = 1',
      [id]
    );

    if (currentStok.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Stok bulunamadı'
      });
    }

    const oldStok = currentStok[0];

    // Calculate kar orani
    let kar_orani = 0;
    if (alis_fiyati && satis_fiyati && alis_fiyati > 0) {
      kar_orani = ((satis_fiyati - alis_fiyati) / alis_fiyati) * 100;
    }

    // Update stok
    await pool.execute(
      `UPDATE stoklar SET
        urun_adi = ?, kategori_id = ?, toplam_agirlik = ?, kalan_agirlik = ?,
        tedarikci_id = ?, alis_fiyati = ?, satis_fiyati = ?, kar_orani = ?,
        kesim_tarihi = ?, son_kullanma_tarihi = ?
       WHERE stok_id = ?`,
      [
        urun_adi, kategori_id, toplam_agirlik, kalan_agirlik,
        tedarikci_id, alis_fiyati, satis_fiyati, kar_orani,
        kesim_tarihi, son_kullanma_tarihi, id
      ]
    );

    // Log stok movement if ağırlık changed
    if (kalan_agirlik !== oldStok.kalan_agirlik) {
      const miktar = kalan_agirlik - oldStok.kalan_agirlik;
      const islem_turu = miktar > 0 ? 'Giriş' : 'Çıkış';
      
      await pool.execute(
        `INSERT INTO stok_hareketleri (
          stok_id, kullanici_id, islem_turu, miktar, onceki_miktar, sonraki_miktar, aciklama
        ) VALUES (?, ?, ?, ?, ?, ?, ?)`,
        [
          id, req.user.kullanici_id, islem_turu, Math.abs(miktar),
          oldStok.kalan_agirlik, kalan_agirlik, 'Stok güncelleme'
        ]
      );
    }

    res.json({
      success: true,
      message: 'Stok başarıyla güncellendi'
    });
  } catch (error) {
    console.error('Update stok error:', error);
    res.status(500).json({
      success: false,
      message: 'Sunucu hatası'
    });
  }
});

// Delete stok (soft delete)
router.delete('/:id', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;

    const [result] = await pool.execute(
      'UPDATE stoklar SET aktif = 0 WHERE stok_id = ?',
      [id]
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({
        success: false,
        message: 'Stok bulunamadı'
      });
    }

    res.json({
      success: true,
      message: 'Stok başarıyla silindi'
    });
  } catch (error) {
    console.error('Delete stok error:', error);
    res.status(500).json({
      success: false,
      message: 'Sunucu hatası'
    });
  }
});

// Get stok movements
router.get('/:id/hareketler', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 10;
    const offset = (page - 1) * limit;

    const [hareketler] = await pool.execute(
      `SELECT sh.*, k.isim as kullanici_adi
       FROM stok_hareketleri sh
       LEFT JOIN kullanicilar k ON sh.kullanici_id = k.kullanici_id
       WHERE sh.stok_id = ?
       ORDER BY sh.islem_tarihi DESC
       LIMIT ? OFFSET ?`,
      [id, limit, offset]
    );

    const [countResult] = await pool.execute(
      'SELECT COUNT(*) as total FROM stok_hareketleri WHERE stok_id = ?',
      [id]
    );

    res.json({
      success: true,
      data: {
        hareketler,
        pagination: {
          page,
          limit,
          total: countResult[0].total,
          pages: Math.ceil(countResult[0].total / limit)
        }
      }
    });
  } catch (error) {
    console.error('Get stok movements error:', error);
    res.status(500).json({
      success: false,
      message: 'Sunucu hatası'
    });
  }
});

module.exports = router;