import React, { useState, useEffect } from 'react';
import {
  Box,
  Button,
  TextField,
  Typography,
  Card,
  CardContent,
  Grid,
  IconButton,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Alert,
  CircularProgress,
  Chip,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Paper,
  TablePagination,
} from '@mui/material';
import {
  Add,
  Edit,
  Delete,
  Search,
  Visibility,
} from '@mui/icons-material';
import { Stok, StokFormData } from '../types';
import apiService from '../services/api';
import { format } from 'date-fns';
import { tr } from 'date-fns/locale';

export const Stoklar: React.FC = () => {
  const [stoklar, setStoklar] = useState<Stok[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [searchTerm, setSearchTerm] = useState('');
  const [page, setPage] = useState(0);
  const [rowsPerPage, setRowsPerPage] = useState(10);
  const [total, setTotal] = useState(0);
  const [dialogOpen, setDialogOpen] = useState(false);
  const [editingStok, setEditingStok] = useState<Stok | null>(null);
  const [formData, setFormData] = useState<StokFormData>({
    urun_adi: '',
    kategori_id: undefined,
    toplam_agirlik: 0,
    kalan_agirlik: 0,
    tedarikci_id: undefined,
    alis_fiyati: undefined,
    satis_fiyati: undefined,
    kesim_tarihi: '',
    son_kullanma_tarihi: '',
  });

  useEffect(() => {
    fetchStoklar();
  }, [page, rowsPerPage, searchTerm]);

  const fetchStoklar = async () => {
    try {
      setLoading(true);
      const response = await apiService.getStoklar(page + 1, rowsPerPage, searchTerm);
      if (response.success && response.data) {
        setStoklar(response.data.stoklar);
        setTotal(response.data.pagination.total);
      }
    } catch (err: any) {
      setError('Stoklar yüklenirken hata oluştu');
    } finally {
      setLoading(false);
    }
  };

  const handleOpenDialog = (stok?: Stok) => {
    if (stok) {
      setEditingStok(stok);
      setFormData({
        urun_adi: stok.urun_adi,
        kategori_id: stok.kategori_id,
        toplam_agirlik: stok.toplam_agirlik,
        kalan_agirlik: stok.kalan_agirlik,
        tedarikci_id: stok.tedarikci_id,
        alis_fiyati: stok.alis_fiyati,
        satis_fiyati: stok.satis_fiyati,
        kesim_tarihi: stok.kesim_tarihi ? format(new Date(stok.kesim_tarihi), 'yyyy-MM-dd') : '',
        son_kullanma_tarihi: stok.son_kullanma_tarihi ? format(new Date(stok.son_kullanma_tarihi), 'yyyy-MM-dd') : '',
      });
    } else {
      setEditingStok(null);
      setFormData({
        urun_adi: '',
        kategori_id: undefined,
        toplam_agirlik: 0,
        kalan_agirlik: 0,
        tedarikci_id: undefined,
        alis_fiyati: undefined,
        satis_fiyati: undefined,
        kesim_tarihi: '',
        son_kullanma_tarihi: '',
      });
    }
    setDialogOpen(true);
  };

  const handleCloseDialog = () => {
    setDialogOpen(false);
    setEditingStok(null);
  };

  const handleSubmit = async () => {
    try {
      if (editingStok) {
        await apiService.updateStok(editingStok.stok_id, formData);
      } else {
        await apiService.createStok(formData);
      }
      handleCloseDialog();
      fetchStoklar();
    } catch (err: any) {
      setError(err.response?.data?.message || 'İşlem başarısız');
    }
  };

  const handleDelete = async (stokId: number) => {
    if (window.confirm('Bu stoku silmek istediğinizden emin misiniz?')) {
      try {
        await apiService.deleteStok(stokId);
        fetchStoklar();
      } catch (err: any) {
        setError('Silme işlemi başarısız');
      }
    }
  };

  const handleChangePage = (event: unknown, newPage: number) => {
    setPage(newPage);
  };

  const handleChangeRowsPerPage = (event: React.ChangeEvent<HTMLInputElement>) => {
    setRowsPerPage(parseInt(event.target.value, 10));
    setPage(0);
  };

  if (loading && stoklar.length === 0) {
    return (
      <Box display="flex" justifyContent="center" alignItems="center" minHeight="400px">
        <CircularProgress />
      </Box>
    );
  }

  return (
    <Box>
      <Box display="flex" justifyContent="space-between" alignItems="center" mb={3}>
        <Typography variant="h4" sx={{ fontWeight: 'bold' }}>
          Stok Yönetimi
        </Typography>
        <Button
          variant="contained"
          startIcon={<Add />}
          onClick={() => handleOpenDialog()}
        >
          Yeni Stok Ekle
        </Button>
      </Box>

      {error && (
        <Alert severity="error" sx={{ mb: 2 }}>
          {error}
        </Alert>
      )}

      {/* Search Bar */}
      <Card sx={{ mb: 3 }}>
        <CardContent>
          <TextField
            fullWidth
            variant="outlined"
            placeholder="Stok ara..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            InputProps={{
              startAdornment: <Search sx={{ mr: 1, color: 'text.secondary' }} />,
            }}
          />
        </CardContent>
      </Card>

      {/* Stok Table */}
      <Card>
        <TableContainer>
          <Table>
            <TableHead>
              <TableRow>
                <TableCell>Ürün Adı</TableCell>
                <TableCell>Kategori</TableCell>
                <TableCell align="right">Toplam Ağırlık</TableCell>
                <TableCell align="right">Kalan Ağırlık</TableCell>
                <TableCell align="right">Alış Fiyatı</TableCell>
                <TableCell align="right">Satış Fiyatı</TableCell>
                <TableCell align="right">Kar Oranı</TableCell>
                <TableCell>Durum</TableCell>
                <TableCell align="center">İşlemler</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {stoklar.map((stok) => (
                <TableRow key={stok.stok_id}>
                  <TableCell>{stok.urun_adi}</TableCell>
                  <TableCell>{stok.kategori_adi || '-'}</TableCell>
                  <TableCell align="right">{stok.toplam_agirlik} kg</TableCell>
                  <TableCell align="right">{stok.kalan_agirlik} kg</TableCell>
                  <TableCell align="right">
                    {stok.alis_fiyati ? `${stok.alis_fiyati} ₺` : '-'}
                  </TableCell>
                  <TableCell align="right">
                    {stok.satis_fiyati ? `${stok.satis_fiyati} ₺` : '-'}
                  </TableCell>
                  <TableCell align="right">
                    {stok.kar_orani ? (
                      <Chip
                        label={`%${stok.kar_orani.toFixed(1)}`}
                        color={stok.kar_orani > 0 ? 'success' : 'error'}
                        size="small"
                      />
                    ) : (
                      '-'
                    )}
                  </TableCell>
                  <TableCell>
                    <Chip
                      label={stok.aktif ? 'Aktif' : 'Pasif'}
                      color={stok.aktif ? 'success' : 'default'}
                      size="small"
                    />
                  </TableCell>
                  <TableCell align="center">
                    <IconButton size="small" onClick={() => handleOpenDialog(stok)}>
                      <Edit />
                    </IconButton>
                    <IconButton size="small" onClick={() => handleDelete(stok.stok_id)}>
                      <Delete />
                    </IconButton>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </TableContainer>
        <TablePagination
          rowsPerPageOptions={[5, 10, 25]}
          component="div"
          count={total}
          rowsPerPage={rowsPerPage}
          page={page}
          onPageChange={handleChangePage}
          onRowsPerPageChange={handleChangeRowsPerPage}
          labelRowsPerPage="Sayfa başına satır:"
          labelDisplayedRows={({ from, to, count }) =>
            `${from}-${to} / ${count !== -1 ? count : `${to}'den fazla`}`
          }
        />
      </Card>

      {/* Add/Edit Dialog */}
      <Dialog open={dialogOpen} onClose={handleCloseDialog} maxWidth="md" fullWidth>
        <DialogTitle>
          {editingStok ? 'Stok Düzenle' : 'Yeni Stok Ekle'}
        </DialogTitle>
        <DialogContent>
          <Grid container spacing={2} sx={{ mt: 1 }}>
            <Grid item xs={12} sm={6}>
              <TextField
                fullWidth
                label="Ürün Adı"
                value={formData.urun_adi}
                onChange={(e) => setFormData({ ...formData, urun_adi: e.target.value })}
                required
              />
            </Grid>
            <Grid item xs={12} sm={6}>
              <FormControl fullWidth>
                <InputLabel>Kategori</InputLabel>
                <Select
                  value={formData.kategori_id || ''}
                  onChange={(e) => setFormData({ ...formData, kategori_id: e.target.value as number })}
                  label="Kategori"
                >
                  <MenuItem value={1}>Dana</MenuItem>
                  <MenuItem value={2}>Tavuk</MenuItem>
                  <MenuItem value={3}>Kuzu</MenuItem>
                  <MenuItem value={4}>Kıyma</MenuItem>
                  <MenuItem value={5}>Şarküteri</MenuItem>
                  <MenuItem value={6}>Diğer</MenuItem>
                </Select>
              </FormControl>
            </Grid>
            <Grid item xs={12} sm={6}>
              <TextField
                fullWidth
                label="Toplam Ağırlık (kg)"
                type="number"
                value={formData.toplam_agirlik}
                onChange={(e) => setFormData({ ...formData, toplam_agirlik: parseFloat(e.target.value) || 0 })}
                required
              />
            </Grid>
            <Grid item xs={12} sm={6}>
              <TextField
                fullWidth
                label="Kalan Ağırlık (kg)"
                type="number"
                value={formData.kalan_agirlik}
                onChange={(e) => setFormData({ ...formData, kalan_agirlik: parseFloat(e.target.value) || 0 })}
                required
              />
            </Grid>
            <Grid item xs={12} sm={6}>
              <TextField
                fullWidth
                label="Alış Fiyatı (₺)"
                type="number"
                value={formData.alis_fiyati || ''}
                onChange={(e) => setFormData({ ...formData, alis_fiyati: parseFloat(e.target.value) || undefined })}
              />
            </Grid>
            <Grid item xs={12} sm={6}>
              <TextField
                fullWidth
                label="Satış Fiyatı (₺)"
                type="number"
                value={formData.satis_fiyati || ''}
                onChange={(e) => setFormData({ ...formData, satis_fiyati: parseFloat(e.target.value) || undefined })}
              />
            </Grid>
            <Grid item xs={12} sm={6}>
              <TextField
                fullWidth
                label="Kesim Tarihi"
                type="date"
                value={formData.kesim_tarihi}
                onChange={(e) => setFormData({ ...formData, kesim_tarihi: e.target.value })}
                InputLabelProps={{ shrink: true }}
              />
            </Grid>
            <Grid item xs={12} sm={6}>
              <TextField
                fullWidth
                label="Son Kullanma Tarihi"
                type="date"
                value={formData.son_kullanma_tarihi}
                onChange={(e) => setFormData({ ...formData, son_kullanma_tarihi: e.target.value })}
                InputLabelProps={{ shrink: true }}
              />
            </Grid>
          </Grid>
        </DialogContent>
        <DialogActions>
          <Button onClick={handleCloseDialog}>İptal</Button>
          <Button onClick={handleSubmit} variant="contained">
            {editingStok ? 'Güncelle' : 'Ekle'}
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};