import axios, { AxiosResponse } from 'axios';

const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://localhost:5000/api';

// Axios instance oluştur
const api = axios.create({
  baseURL: API_BASE_URL,
  timeout: 10000,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Request interceptor - token ekle
api.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('authToken');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => {
    return Promise.reject(error);
  }
);

// Response interceptor - hata yönetimi
api.interceptors.response.use(
  (response: AxiosResponse) => {
    return response;
  },
  (error) => {
    if (error.response?.status === 401) {
      // Token geçersiz, kullanıcıyı çıkış yaptır
      localStorage.removeItem('authToken');
      localStorage.removeItem('user');
      window.location.href = '/login';
    }
    return Promise.reject(error);
  }
);

// API Response tipi
export interface ApiResponse<T = any> {
  success: boolean;
  message: string;
  data?: T;
  errors?: any[];
}

// Auth servis fonksiyonları
export const authService = {
  login: async (email: string, sifre: string): Promise<ApiResponse> => {
    const response = await api.post('/auth/login', { email, sifre });
    return response.data;
  },

  getProfile: async (): Promise<ApiResponse> => {
    const response = await api.get('/auth/profile');
    return response.data;
  },

  changePassword: async (mevcutSifre: string, yeniSifre: string): Promise<ApiResponse> => {
    const response = await api.put('/auth/change-password', { mevcutSifre, yeniSifre });
    return response.data;
  },

  verifyToken: async (): Promise<ApiResponse> => {
    const response = await api.post('/auth/verify-token');
    return response.data;
  },
};

// Genel API fonksiyonları
export const apiService = {
  get: async <T>(endpoint: string): Promise<ApiResponse<T>> => {
    const response = await api.get(endpoint);
    return response.data;
  },

  post: async <T>(endpoint: string, data: any): Promise<ApiResponse<T>> => {
    const response = await api.post(endpoint, data);
    return response.data;
  },

  put: async <T>(endpoint: string, data: any): Promise<ApiResponse<T>> => {
    const response = await api.put(endpoint, data);
    return response.data;
  },

  delete: async <T>(endpoint: string): Promise<ApiResponse<T>> => {
    const response = await api.delete(endpoint);
    return response.data;
  },
};

export default api;