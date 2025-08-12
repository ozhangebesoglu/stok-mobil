import React from 'react';
import {
  Box,
  Grid,
  Paper,
  Typography,
  Card,
  CardContent,
  LinearProgress,
  Chip,
  Avatar,
  List,
  ListItem,
  ListItemText,
  ListItemAvatar,
  IconButton,
} from '@mui/material';
import {
  TrendingUp,
  TrendingDown,
  Inventory,
  ShoppingCart,
  People,
  AttachMoney,
  Warning,
  Schedule,
  MoreVert,
} from '@mui/icons-material';
import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  PieChart,
  Pie,
  Cell,
  LineChart,
  Line,
} from 'recharts';

// Demo data
const statsData = [
  {
    title: 'Günlük Satış',
    value: '₺2,847',
    change: '+12.5%',
    trend: 'up',
    icon: <ShoppingCart />,
    color: '#4CAF50',
  },
  {
    title: 'Toplam Stok',
    value: '387 kg',
    change: '-5.2%',
    trend: 'down',
    icon: <Inventory />,
    color: '#2196F3',
  },
  {
    title: 'Aktif Müşteri',
    value: '143',
    change: '+8.1%',
    trend: 'up',
    icon: <People />,
    color: '#FF9800',
  },
  {
    title: 'Aylık Ciro',
    value: '₺89,432',
    change: '+18.7%',
    trend: 'up',
    icon: <AttachMoney />,
    color: '#9C27B0',
  },
];

const salesData = [
  { name: 'Pzt', satis: 2400, gider: 400 },
  { name: 'Sal', satis: 1398, gider: 300 },
  { name: 'Çar', satis: 9800, gider: 500 },
  { name: 'Per', satis: 3908, gider: 800 },
  { name: 'Cum', satis: 4800, gider: 600 },
  { name: 'Cmt', satis: 3800, gider: 700 },
  { name: 'Paz', satis: 4300, gider: 900 },
];

const categoryData = [
  { name: 'Dana', value: 45, color: '#e74c3c' },
  { name: 'Tavuk', value: 25, color: '#f39c12' },
  { name: 'Kuzu', value: 15, color: '#9b59b6' },
  { name: 'Kıyma', value: 10, color: '#34495e' },
  { name: 'Diğer', value: 5, color: '#95a5a6' },
];

const recentSales = [
  { id: 1, musteri: 'Ahmet Yılmaz', tutar: 250, zaman: '2 saat önce', urun: 'Dana Bonfile' },
  { id: 2, musteri: 'Nakit Müşteri', tutar: 180, zaman: '3 saat önce', urun: 'Tavuk But' },
  { id: 3, musteri: 'Fatma Demir', tutar: 320, zaman: '4 saat önce', urun: 'Kuzu Pirzola' },
  { id: 4, musteri: 'Mehmet Özkan', tutar: 150, zaman: '5 saat önce', urun: 'Kıyma' },
];

const lowStockItems = [
  { name: 'Dana Bonfile', miktar: 2.5, minimum: 5, renk: '#e74c3c' },
  { name: 'Tavuk Göğüs', miktar: 1.8, minimum: 3, renk: '#f39c12' },
  { name: 'Kuzu Pirzola', miktar: 0.5, minimum: 2, renk: '#9b59b6' },
];

export default function Dashboard() {
  return (
    <Box>
      {/* Başlık */}
      <Box mb={3}>
        <Typography variant="h4" component="h1" fontWeight="bold" gutterBottom>
          Ana Sayfa
        </Typography>
        <Typography variant="body1" color="text.secondary">
          Hoş geldiniz! İşletmenizin güncel durumunu buradan takip edebilirsiniz.
        </Typography>
      </Box>

      {/* İstatistik Kartları */}
      <Grid container spacing={3} mb={3}>
        {statsData.map((stat, index) => (
          <Grid item xs={12} sm={6} md={3} key={index}>
            <Card
              sx={{
                height: '100%',
                background: `linear-gradient(135deg, ${stat.color}15 0%, ${stat.color}25 100%)`,
                border: `1px solid ${stat.color}30`,
              }}
            >
              <CardContent>
                <Box display="flex" alignItems="center" justifyContent="space-between">
                  <Box>
                    <Typography color="text.secondary" gutterBottom variant="body2">
                      {stat.title}
                    </Typography>
                    <Typography variant="h5" component="div" fontWeight="bold">
                      {stat.value}
                    </Typography>
                    <Box display="flex" alignItems="center" mt={1}>
                      {stat.trend === 'up' ? (
                        <TrendingUp sx={{ color: 'success.main', fontSize: 16, mr: 0.5 }} />
                      ) : (
                        <TrendingDown sx={{ color: 'error.main', fontSize: 16, mr: 0.5 }} />
                      )}
                      <Typography
                        variant="body2"
                        color={stat.trend === 'up' ? 'success.main' : 'error.main'}
                      >
                        {stat.change}
                      </Typography>
                    </Box>
                  </Box>
                  <Avatar
                    sx={{
                      backgroundColor: stat.color,
                      width: 48,
                      height: 48,
                    }}
                  >
                    {stat.icon}
                  </Avatar>
                </Box>
              </CardContent>
            </Card>
          </Grid>
        ))}
      </Grid>

      <Grid container spacing={3}>
        {/* Satış Grafiği */}
        <Grid item xs={12} lg={8}>
          <Paper sx={{ p: 3, height: 400 }}>
            <Typography variant="h6" gutterBottom>
              Haftalık Satış Performansı
            </Typography>
            <ResponsiveContainer width="100%" height="90%">
              <BarChart data={salesData}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="name" />
                <YAxis />
                <Tooltip 
                  formatter={(value, name) => [
                    `₺${value}`, 
                    name === 'satis' ? 'Satış' : 'Gider'
                  ]}
                />
                <Bar dataKey="satis" fill="#4CAF50" name="satis" />
                <Bar dataKey="gider" fill="#f44336" name="gider" />
              </BarChart>
            </ResponsiveContainer>
          </Paper>
        </Grid>

        {/* Kategori Dağılımı */}
        <Grid item xs={12} lg={4}>
          <Paper sx={{ p: 3, height: 400 }}>
            <Typography variant="h6" gutterBottom>
              Satış Kategori Dağılımı
            </Typography>
            <ResponsiveContainer width="100%" height="70%">
              <PieChart>
                <Pie
                  data={categoryData}
                  cx="50%"
                  cy="50%"
                  outerRadius={80}
                  fill="#8884d8"
                  dataKey="value"
                  label={({ name, percent }) => `${name} %${(percent * 100).toFixed(0)}`}
                >
                  {categoryData.map((entry, index) => (
                    <Cell key={`cell-${index}`} fill={entry.color} />
                  ))}
                </Pie>
                <Tooltip />
              </PieChart>
            </ResponsiveContainer>
          </Paper>
        </Grid>

        {/* Son Satışlar */}
        <Grid item xs={12} lg={6}>
          <Paper sx={{ p: 3 }}>
            <Box display="flex" justifyContent="space-between" alignItems="center" mb={2}>
              <Typography variant="h6">
                Son Satışlar
              </Typography>
              <IconButton size="small">
                <MoreVert />
              </IconButton>
            </Box>
            <List>
              {recentSales.map((sale) => (
                <ListItem key={sale.id} divider>
                  <ListItemAvatar>
                    <Avatar sx={{ bgcolor: 'primary.main' }}>
                      <ShoppingCart />
                    </Avatar>
                  </ListItemAvatar>
                  <ListItemText
                    primary={
                      <Box display="flex" justifyContent="space-between" alignItems="center">
                        <Typography variant="subtitle2">
                          {sale.musteri}
                        </Typography>
                        <Typography variant="subtitle2" color="primary">
                          ₺{sale.tutar}
                        </Typography>
                      </Box>
                    }
                    secondary={
                      <Box display="flex" justifyContent="space-between" alignItems="center">
                        <Typography variant="body2" color="text.secondary">
                          {sale.urun}
                        </Typography>
                        <Typography variant="body2" color="text.secondary">
                          {sale.zaman}
                        </Typography>
                      </Box>
                    }
                  />
                </ListItem>
              ))}
            </List>
          </Paper>
        </Grid>

        {/* Düşük Stok Uyarıları */}
        <Grid item xs={12} lg={6}>
          <Paper sx={{ p: 3 }}>
            <Box display="flex" alignItems="center" mb={2}>
              <Warning sx={{ color: 'warning.main', mr: 1 }} />
              <Typography variant="h6">
                Düşük Stok Uyarıları
              </Typography>
            </Box>
            
            {lowStockItems.map((item, index) => (
              <Box key={index} mb={2}>
                <Box display="flex" justifyContent="space-between" alignItems="center" mb={1}>
                  <Typography variant="subtitle2">
                    {item.name}
                  </Typography>
                  <Chip
                    label="Kritik"
                    size="small"
                    color="error"
                    variant="outlined"
                  />
                </Box>
                <Box display="flex" alignItems="center" gap={1}>
                  <LinearProgress
                    variant="determinate"
                    value={(item.miktar / item.minimum) * 100}
                    sx={{
                      flexGrow: 1,
                      height: 8,
                      borderRadius: 4,
                      '& .MuiLinearProgress-bar': {
                        backgroundColor: item.renk,
                      },
                    }}
                  />
                  <Typography variant="body2" color="text.secondary">
                    {item.miktar} / {item.minimum} kg
                  </Typography>
                </Box>
              </Box>
            ))}

            <Box textAlign="center" mt={2}>
              <Typography variant="body2" color="text.secondary">
                Toplam {lowStockItems.length} ürün kritik seviyede
              </Typography>
            </Box>
          </Paper>
        </Grid>
      </Grid>
    </Box>
  );
}