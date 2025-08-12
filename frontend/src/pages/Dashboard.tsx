import React, { useState, useEffect } from 'react';
import {
  Box,
  Grid,
  Card,
  CardContent,
  Typography,
  CircularProgress,
  Alert,
} from '@mui/material';
import {
  Inventory,
  ShoppingCart,
  People,
  AccountBalance,
  TrendingUp,
  TrendingDown,
} from '@mui/icons-material';
import apiService from '../services/api';

interface DashboardStats {
  toplamStok: number;
  toplamSatis: number;
  toplamMusteri: number;
  kasaBakiye: number;
  gunlukSatis: number;
  haftalikSatis: number;
}

export const Dashboard: React.FC = () => {
  const [stats, setStats] = useState<DashboardStats | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    const fetchDashboardStats = async () => {
      try {
        // Mock data for now - in real app, you'd have a dashboard endpoint
        const mockStats: DashboardStats = {
          toplamStok: 1250,
          toplamSatis: 456,
          toplamMusteri: 89,
          kasaBakiye: 15420.50,
          gunlukSatis: 1250.75,
          haftalikSatis: 8750.25,
        };
        
        setStats(mockStats);
      } catch (err: any) {
        setError('Dashboard verileri yüklenirken hata oluştu');
      } finally {
        setLoading(false);
      }
    };

    fetchDashboardStats();
  }, []);

  if (loading) {
    return (
      <Box display="flex" justifyContent="center" alignItems="center" minHeight="400px">
        <CircularProgress />
      </Box>
    );
  }

  if (error) {
    return (
      <Alert severity="error" sx={{ mb: 2 }}>
        {error}
      </Alert>
    );
  }

  const statCards = [
    {
      title: 'Toplam Stok',
      value: `${stats?.toplamStok.toLocaleString()} kg`,
      icon: <Inventory sx={{ fontSize: 40, color: 'primary.main' }} />,
      color: 'primary.main',
    },
    {
      title: 'Toplam Satış',
      value: `${stats?.toplamSatis.toLocaleString()} adet`,
      icon: <ShoppingCart sx={{ fontSize: 40, color: 'success.main' }} />,
      color: 'success.main',
    },
    {
      title: 'Toplam Müşteri',
      value: stats?.toplamMusteri.toLocaleString(),
      icon: <People sx={{ fontSize: 40, color: 'info.main' }} />,
      color: 'info.main',
    },
    {
      title: 'Kasa Bakiyesi',
      value: `${stats?.kasaBakiye.toLocaleString('tr-TR', { style: 'currency', currency: 'TRY' })}`,
      icon: <AccountBalance sx={{ fontSize: 40, color: 'warning.main' }} />,
      color: 'warning.main',
    },
  ];

  const trendCards = [
    {
      title: 'Günlük Satış',
      value: `${stats?.gunlukSatis.toLocaleString('tr-TR', { style: 'currency', currency: 'TRY' })}`,
      icon: <TrendingUp sx={{ fontSize: 40, color: 'success.main' }} />,
      trend: '+12.5%',
      trendColor: 'success.main',
    },
    {
      title: 'Haftalık Satış',
      value: `${stats?.haftalikSatis.toLocaleString('tr-TR', { style: 'currency', currency: 'TRY' })}`,
      icon: <TrendingDown sx={{ fontSize: 40, color: 'error.main' }} />,
      trend: '-3.2%',
      trendColor: 'error.main',
    },
  ];

  return (
    <Box>
      <Typography variant="h4" gutterBottom sx={{ fontWeight: 'bold', mb: 4 }}>
        Dashboard
      </Typography>

      {/* Main Stats */}
      <Grid container spacing={3} sx={{ mb: 4 }}>
        {statCards.map((card, index) => (
          <Grid item xs={12} sm={6} md={3} key={index}>
            <Card sx={{ height: '100%' }}>
              <CardContent>
                <Box display="flex" alignItems="center" justifyContent="space-between">
                  <Box>
                    <Typography color="textSecondary" gutterBottom variant="h6">
                      {card.title}
                    </Typography>
                    <Typography variant="h4" component="div" sx={{ fontWeight: 'bold' }}>
                      {card.value}
                    </Typography>
                  </Box>
                  {card.icon}
                </Box>
              </CardContent>
            </Card>
          </Grid>
        ))}
      </Grid>

      {/* Trend Stats */}
      <Grid container spacing={3}>
        {trendCards.map((card, index) => (
          <Grid item xs={12} sm={6} key={index}>
            <Card sx={{ height: '100%' }}>
              <CardContent>
                <Box display="flex" alignItems="center" justifyContent="space-between">
                  <Box>
                    <Typography color="textSecondary" gutterBottom variant="h6">
                      {card.title}
                    </Typography>
                    <Typography variant="h4" component="div" sx={{ fontWeight: 'bold' }}>
                      {card.value}
                    </Typography>
                    <Typography 
                      variant="body2" 
                      sx={{ color: card.trendColor, fontWeight: 'bold' }}
                    >
                      {card.trend} geçen döneme göre
                    </Typography>
                  </Box>
                  {card.icon}
                </Box>
              </CardContent>
            </Card>
          </Grid>
        ))}
      </Grid>

      {/* Quick Actions */}
      <Box sx={{ mt: 4 }}>
        <Typography variant="h5" gutterBottom sx={{ fontWeight: 'bold', mb: 3 }}>
          Hızlı İşlemler
        </Typography>
        <Grid container spacing={2}>
          <Grid item xs={12} sm={6} md={3}>
            <Card sx={{ cursor: 'pointer', '&:hover': { boxShadow: 4 } }}>
              <CardContent sx={{ textAlign: 'center', py: 3 }}>
                <Inventory sx={{ fontSize: 60, color: 'primary.main', mb: 2 }} />
                <Typography variant="h6">Yeni Stok Ekle</Typography>
              </CardContent>
            </Card>
          </Grid>
          <Grid item xs={12} sm={6} md={3}>
            <Card sx={{ cursor: 'pointer', '&:hover': { boxShadow: 4 } }}>
              <CardContent sx={{ textAlign: 'center', py: 3 }}>
                <ShoppingCart sx={{ fontSize: 60, color: 'success.main', mb: 2 }} />
                <Typography variant="h6">Yeni Satış</Typography>
              </CardContent>
            </Card>
          </Grid>
          <Grid item xs={12} sm={6} md={3}>
            <Card sx={{ cursor: 'pointer', '&:hover': { boxShadow: 4 } }}>
              <CardContent sx={{ textAlign: 'center', py: 3 }}>
                <People sx={{ fontSize: 60, color: 'info.main', mb: 2 }} />
                <Typography variant="h6">Müşteri Ekle</Typography>
              </CardContent>
            </Card>
          </Grid>
          <Grid item xs={12} sm={6} md={3}>
            <Card sx={{ cursor: 'pointer', '&:hover': { boxShadow: 4 } }}>
              <CardContent sx={{ textAlign: 'center', py: 3 }}>
                <AccountBalance sx={{ fontSize: 60, color: 'warning.main', mb: 2 }} />
                <Typography variant="h6">Kasa İşlemi</Typography>
              </CardContent>
            </Card>
          </Grid>
        </Grid>
      </Box>
    </Box>
  );
};