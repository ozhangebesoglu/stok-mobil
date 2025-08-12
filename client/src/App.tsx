import React from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { ThemeProvider, createTheme } from '@mui/material/styles';
import { CssBaseline } from '@mui/material';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { LocalizationProvider } from '@mui/x-date-pickers/LocalizationProvider';
import { AdapterDateFns } from '@mui/x-date-pickers/AdapterDateFns';
import { tr } from 'date-fns/locale';

import { AuthProvider, useAuth } from './context/AuthContext';
import LoginPage from './components/LoginPage';
import Layout from './components/Layout';
import Dashboard from './components/Dashboard';
import LoadingScreen from './components/LoadingScreen';

// React Query client
const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      retry: 1,
      refetchOnWindowFocus: false,
    },
  },
});

// Material-UI tema
const theme = createTheme({
  palette: {
    primary: {
      main: '#2196F3',
      light: '#64B5F6',
      dark: '#1976D2',
    },
    secondary: {
      main: '#FF5722',
      light: '#FF8A65',
      dark: '#D84315',
    },
    background: {
      default: '#f5f5f5',
      paper: '#ffffff',
    },
  },
  typography: {
    fontFamily: [
      '-apple-system',
      'BlinkMacSystemFont',
      '"Segoe UI"',
      'Roboto',
      '"Helvetica Neue"',
      'Arial',
      'sans-serif',
    ].join(','),
    h1: {
      fontWeight: 700,
    },
    h2: {
      fontWeight: 700,
    },
    h3: {
      fontWeight: 600,
    },
    h4: {
      fontWeight: 600,
    },
    h5: {
      fontWeight: 600,
    },
    h6: {
      fontWeight: 600,
    },
  },
  shape: {
    borderRadius: 12,
  },
  components: {
    MuiButton: {
      styleOverrides: {
        root: {
          borderRadius: 8,
          textTransform: 'none',
          fontWeight: 600,
        },
      },
    },
    MuiCard: {
      styleOverrides: {
        root: {
          borderRadius: 12,
          boxShadow: '0 2px 12px rgba(0,0,0,0.08)',
        },
      },
    },
    MuiPaper: {
      styleOverrides: {
        root: {
          borderRadius: 12,
        },
      },
    },
  },
});

// Protected Route bileşeni
function ProtectedRoute({ children }: { children: React.ReactNode }) {
  const { state } = useAuth();

  if (state.isLoading) {
    return <LoadingScreen />;
  }

  if (!state.isAuthenticated) {
    return <Navigate to="/login" replace />;
  }

  return <Layout>{children}</Layout>;
}

// Public Route bileşeni (giriş yapmış kullanıcıları yönlendir)
function PublicRoute({ children }: { children: React.ReactNode }) {
  const { state } = useAuth();

  if (state.isLoading) {
    return <LoadingScreen />;
  }

  if (state.isAuthenticated) {
    return <Navigate to="/dashboard" replace />;
  }

  return <>{children}</>;
}

// Ana App Routes
function AppRoutes() {
  return (
    <Routes>
      {/* Public Routes */}
      <Route
        path="/login"
        element={
          <PublicRoute>
            <LoginPage />
          </PublicRoute>
        }
      />

      {/* Protected Routes */}
      <Route
        path="/dashboard"
        element={
          <ProtectedRoute>
            <Dashboard />
          </ProtectedRoute>
        }
      />

      {/* Placeholder routes for other pages */}
      <Route
        path="/stok"
        element={
          <ProtectedRoute>
            <div>Stok Yönetimi Sayfası (Geliştiriliyor...)</div>
          </ProtectedRoute>
        }
      />
      
      <Route
        path="/satis"
        element={
          <ProtectedRoute>
            <div>Satış İşlemleri Sayfası (Geliştiriliyor...)</div>
          </ProtectedRoute>
        }
      />

      <Route
        path="/musteriler"
        element={
          <ProtectedRoute>
            <div>Müşteriler Sayfası (Geliştiriliyor...)</div>
          </ProtectedRoute>
        }
      />

      <Route
        path="/tedarikciler"
        element={
          <ProtectedRoute>
            <div>Tedarikçiler Sayfası (Geliştiriliyor...)</div>
          </ProtectedRoute>
        }
      />

      <Route
        path="/mali"
        element={
          <ProtectedRoute>
            <div>Mali İşlemler Sayfası (Geliştiriliyor...)</div>
          </ProtectedRoute>
        }
      />

      <Route
        path="/raporlar"
        element={
          <ProtectedRoute>
            <div>Raporlar Sayfası (Geliştiriliyor...)</div>
          </ProtectedRoute>
        }
      />

      <Route
        path="/ayarlar"
        element={
          <ProtectedRoute>
            <div>Ayarlar Sayfası (Geliştiriliyor...)</div>
          </ProtectedRoute>
        }
      />

      <Route
        path="/profil"
        element={
          <ProtectedRoute>
            <div>Profil Sayfası (Geliştiriliyor...)</div>
          </ProtectedRoute>
        }
      />

      {/* Ana yönlendirme */}
      <Route path="/" element={<Navigate to="/dashboard" replace />} />
      
      {/* 404 sayfası */}
      <Route path="*" element={<Navigate to="/dashboard" replace />} />
    </Routes>
  );
}

function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <ThemeProvider theme={theme}>
        <LocalizationProvider dateAdapter={AdapterDateFns} adapterLocale={tr}>
          <CssBaseline />
          <Router>
            <AuthProvider>
              <AppRoutes />
            </AuthProvider>
          </Router>
        </LocalizationProvider>
      </ThemeProvider>
    </QueryClientProvider>
  );
}

export default App;
