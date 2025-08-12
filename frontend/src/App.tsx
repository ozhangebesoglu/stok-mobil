import React from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { ThemeProvider, createTheme } from '@mui/material/styles';
import { CssBaseline } from '@mui/material';
import { AuthProvider, useAuth } from './contexts/AuthContext';
import { AppLayout } from './components/Layout/AppLayout';
import { Login } from './pages/Login';
import { Dashboard } from './pages/Dashboard';
import { Stoklar } from './pages/Stoklar';

// Create theme
const theme = createTheme({
  palette: {
    primary: {
      main: '#1976d2',
    },
    secondary: {
      main: '#dc004e',
    },
  },
  typography: {
    fontFamily: '"Roboto", "Helvetica", "Arial", sans-serif',
  },
  components: {
    MuiButton: {
      styleOverrides: {
        root: {
          textTransform: 'none',
        },
      },
    },
  },
});

// Protected Route Component
const ProtectedRoute: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const { isAuthenticated, loading } = useAuth();

  if (loading) {
    return <div>Loading...</div>;
  }

  return isAuthenticated ? <>{children}</> : <Navigate to="/login" />;
};

// App Routes Component
const AppRoutes: React.FC = () => {
  const { isAuthenticated } = useAuth();

  return (
    <Routes>
      <Route path="/login" element={isAuthenticated ? <Navigate to="/dashboard" /> : <Login />} />
      <Route
        path="/dashboard"
        element={
          <ProtectedRoute>
            <AppLayout>
              <Dashboard />
            </AppLayout>
          </ProtectedRoute>
        }
      />
      <Route
        path="/stoklar"
        element={
          <ProtectedRoute>
            <AppLayout>
              <Stoklar />
            </AppLayout>
          </ProtectedRoute>
        }
      />
      <Route
        path="/satislar"
        element={
          <ProtectedRoute>
            <AppLayout>
              <div>Satışlar Sayfası (Yakında)</div>
            </AppLayout>
          </ProtectedRoute>
        }
      />
      <Route
        path="/musteriler"
        element={
          <ProtectedRoute>
            <AppLayout>
              <div>Müşteriler Sayfası (Yakında)</div>
            </AppLayout>
          </ProtectedRoute>
        }
      />
      <Route
        path="/tedarikciler"
        element={
          <ProtectedRoute>
            <AppLayout>
              <div>Tedarikçiler Sayfası (Yakında)</div>
            </AppLayout>
          </ProtectedRoute>
        }
      />
      <Route
        path="/faturalar"
        element={
          <ProtectedRoute>
            <AppLayout>
              <div>Faturalar Sayfası (Yakında)</div>
            </AppLayout>
          </ProtectedRoute>
        }
      />
      <Route
        path="/kasa"
        element={
          <ProtectedRoute>
            <AppLayout>
              <div>Kasa Sayfası (Yakında)</div>
            </AppLayout>
          </ProtectedRoute>
        }
      />
      <Route
        path="/ayarlar"
        element={
          <ProtectedRoute>
            <AppLayout>
              <div>Ayarlar Sayfası (Yakında)</div>
            </AppLayout>
          </ProtectedRoute>
        }
      />
      <Route
        path="/profil"
        element={
          <ProtectedRoute>
            <AppLayout>
              <div>Profil Sayfası (Yakında)</div>
            </AppLayout>
          </ProtectedRoute>
        }
      />
      <Route path="/" element={<Navigate to="/dashboard" />} />
    </Routes>
  );
};

function App() {
  return (
    <ThemeProvider theme={theme}>
      <CssBaseline />
      <AuthProvider>
        <Router>
          <AppRoutes />
        </Router>
      </AuthProvider>
    </ThemeProvider>
  );
}

export default App;