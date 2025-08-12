import React from 'react';
import { Box, CircularProgress, Typography } from '@mui/material';
import { Store } from '@mui/icons-material';

export default function LoadingScreen() {
  return (
    <Box
      sx={{
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        justifyContent: 'center',
        minHeight: '100vh',
        background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
        color: 'white',
      }}
    >
      <Store sx={{ fontSize: 80, mb: 3, opacity: 0.9 }} />
      <Typography variant="h4" component="h1" fontWeight="bold" gutterBottom>
        Esnaf Defterim
      </Typography>
      <Typography variant="h6" sx={{ opacity: 0.8, mb: 4 }}>
        Yükleniyor...
      </Typography>
      <CircularProgress color="inherit" size={50} />
    </Box>
  );
}