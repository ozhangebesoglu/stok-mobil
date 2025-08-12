import React, { useState } from 'react';
import {
  Box,
  Card,
  CardContent,
  TextField,
  Button,
  Typography,
  Alert,
  InputAdornment,
  IconButton,
  Paper,
  Container,
  CircularProgress,
} from '@mui/material';
import { Visibility, VisibilityOff, Email, Lock, Store } from '@mui/icons-material';
import { useForm, Controller } from 'react-hook-form';
import { yupResolver } from '@hookform/resolvers/yup';
import * as yup from 'yup';
import { useAuth } from '../context/AuthContext';
import { useNavigate } from 'react-router-dom';

// Form şeması
const schema = yup.object({
  email: yup
    .string()
    .email('Geçerli bir email adresi girin')
    .required('Email adresi gerekli'),
  sifre: yup
    .string()
    .min(1, 'Şifre gerekli')
    .required('Şifre gerekli'),
});

interface LoginFormData {
  email: string;
  sifre: string;
}

export default function LoginPage() {
  const [showPassword, setShowPassword] = useState(false);
  const [error, setError] = useState('');
  const { login, state } = useAuth();
  const navigate = useNavigate();

  const {
    control,
    handleSubmit,
    formState: { errors, isSubmitting },
  } = useForm<LoginFormData>({
    resolver: yupResolver(schema),
    defaultValues: {
      email: '',
      sifre: '',
    },
  });

  const onSubmit = async (data: LoginFormData) => {
    try {
      setError('');
      const success = await login(data.email, data.sifre);
      
      if (success) {
        navigate('/dashboard');
      } else {
        setError('Email veya şifre hatalı');
      }
    } catch (err: any) {
      setError(err.response?.data?.message || 'Giriş yapılırken bir hata oluştu');
    }
  };

  const handleTogglePasswordVisibility = () => {
    setShowPassword(!showPassword);
  };

  return (
    <Box
      sx={{
        minHeight: '100vh',
        background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        padding: 2,
      }}
    >
      <Container maxWidth="sm">
        <Paper
          elevation={24}
          sx={{
            borderRadius: 4,
            overflow: 'hidden',
            background: 'rgba(255, 255, 255, 0.95)',
            backdropFilter: 'blur(10px)',
          }}
        >
          <Box
            sx={{
              background: 'linear-gradient(45deg, #2196F3 30%, #21CBF3 90%)',
              color: 'white',
              textAlign: 'center',
              py: 4,
            }}
          >
            <Store sx={{ fontSize: 60, mb: 2 }} />
            <Typography variant="h3" component="h1" fontWeight="bold">
              Esnaf Defterim
            </Typography>
            <Typography variant="h6" sx={{ opacity: 0.9, mt: 1 }}>
              Kasap Dükkanı Yönetim Sistemi
            </Typography>
          </Box>

          <CardContent sx={{ p: 4 }}>
            <Typography
              variant="h5"
              component="h2"
              textAlign="center"
              gutterBottom
              sx={{ mb: 3, fontWeight: 600, color: 'text.primary' }}
            >
              Giriş Yap
            </Typography>

            {error && (
              <Alert severity="error" sx={{ mb: 3 }}>
                {error}
              </Alert>
            )}

            <Box component="form" onSubmit={handleSubmit(onSubmit)} noValidate>
              <Controller
                name="email"
                control={control}
                render={({ field }) => (
                  <TextField
                    {...field}
                    fullWidth
                    label="Email Adresi"
                    type="email"
                    margin="normal"
                    variant="outlined"
                    error={!!errors.email}
                    helperText={errors.email?.message}
                    InputProps={{
                      startAdornment: (
                        <InputAdornment position="start">
                          <Email color="action" />
                        </InputAdornment>
                      ),
                    }}
                    sx={{ mb: 2 }}
                  />
                )}
              />

              <Controller
                name="sifre"
                control={control}
                render={({ field }) => (
                  <TextField
                    {...field}
                    fullWidth
                    label="Şifre"
                    type={showPassword ? 'text' : 'password'}
                    margin="normal"
                    variant="outlined"
                    error={!!errors.sifre}
                    helperText={errors.sifre?.message}
                    InputProps={{
                      startAdornment: (
                        <InputAdornment position="start">
                          <Lock color="action" />
                        </InputAdornment>
                      ),
                      endAdornment: (
                        <InputAdornment position="end">
                          <IconButton
                            onClick={handleTogglePasswordVisibility}
                            edge="end"
                            aria-label="toggle password visibility"
                          >
                            {showPassword ? <VisibilityOff /> : <Visibility />}
                          </IconButton>
                        </InputAdornment>
                      ),
                    }}
                    sx={{ mb: 3 }}
                  />
                )}
              />

              <Button
                type="submit"
                fullWidth
                variant="contained"
                size="large"
                disabled={isSubmitting || state.isLoading}
                sx={{
                  py: 1.5,
                  fontSize: '1.1rem',
                  fontWeight: 'bold',
                  background: 'linear-gradient(45deg, #2196F3 30%, #21CBF3 90%)',
                  '&:hover': {
                    background: 'linear-gradient(45deg, #1976D2 30%, #0288D1 90%)',
                  },
                  borderRadius: 2,
                }}
              >
                {isSubmitting || state.isLoading ? (
                  <CircularProgress size={24} color="inherit" />
                ) : (
                  'Giriş Yap'
                )}
              </Button>
            </Box>

            <Box textAlign="center" mt={3}>
              <Typography variant="body2" color="text.secondary">
                Demo Giriş: admin@esnafdefterim.com / admin123
              </Typography>
            </Box>
          </CardContent>
        </Paper>
      </Container>
    </Box>
  );
}