import axios, { AxiosInstance, AxiosResponse } from 'axios';
import { 
  ApiResponse, 
  LoginRequest, 
  LoginResponse, 
  User, 
  Stok, 
  StokFormData,
  PaginatedResponse 
} from '../types';

const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://localhost:5000/api';

class ApiService {
  private api: AxiosInstance;

  constructor() {
    this.api = axios.create({
      baseURL: API_BASE_URL,
      headers: {
        'Content-Type': 'application/json',
      },
    });

    // Request interceptor to add auth token
    this.api.interceptors.request.use(
      (config) => {
        const token = localStorage.getItem('token');
        if (token) {
          config.headers.Authorization = `Bearer ${token}`;
        }
        return config;
      },
      (error) => {
        return Promise.reject(error);
      }
    );

    // Response interceptor to handle errors
    this.api.interceptors.response.use(
      (response) => response,
      (error) => {
        if (error.response?.status === 401) {
          localStorage.removeItem('token');
          localStorage.removeItem('user');
          window.location.href = '/login';
        }
        return Promise.reject(error);
      }
    );
  }

  // Auth endpoints
  async login(credentials: LoginRequest): Promise<ApiResponse<LoginResponse>> {
    const response: AxiosResponse<ApiResponse<LoginResponse>> = await this.api.post('/auth/login', credentials);
    return response.data;
  }

  async getCurrentUser(): Promise<ApiResponse<{ user: User }>> {
    const response: AxiosResponse<ApiResponse<{ user: User }>> = await this.api.get('/auth/me');
    return response.data;
  }

  async changePassword(currentPassword: string, newPassword: string): Promise<ApiResponse<void>> {
    const response: AxiosResponse<ApiResponse<void>> = await this.api.put('/auth/change-password', {
      currentPassword,
      newPassword
    });
    return response.data;
  }

  // Stok endpoints
  async getStoklar(page: number = 1, limit: number = 10, search?: string): Promise<PaginatedResponse<Stok>> {
    const params = new URLSearchParams({
      page: page.toString(),
      limit: limit.toString(),
    });
    
    if (search) {
      params.append('search', search);
    }

    const response: AxiosResponse<PaginatedResponse<Stok>> = await this.api.get(`/stoklar?${params}`);
    return response.data;
  }

  async getStok(id: number): Promise<ApiResponse<Stok>> {
    const response: AxiosResponse<ApiResponse<Stok>> = await this.api.get(`/stoklar/${id}`);
    return response.data;
  }

  async createStok(stokData: StokFormData): Promise<ApiResponse<{ stok_id: number }>> {
    const response: AxiosResponse<ApiResponse<{ stok_id: number }>> = await this.api.post('/stoklar', stokData);
    return response.data;
  }

  async updateStok(id: number, stokData: StokFormData): Promise<ApiResponse<void>> {
    const response: AxiosResponse<ApiResponse<void>> = await this.api.put(`/stoklar/${id}`, stokData);
    return response.data;
  }

  async deleteStok(id: number): Promise<ApiResponse<void>> {
    const response: AxiosResponse<ApiResponse<void>> = await this.api.delete(`/stoklar/${id}`);
    return response.data;
  }

  async getStokHareketler(id: number, page: number = 1, limit: number = 10): Promise<PaginatedResponse<any>> {
    const params = new URLSearchParams({
      page: page.toString(),
      limit: limit.toString(),
    });

    const response: AxiosResponse<PaginatedResponse<any>> = await this.api.get(`/stoklar/${id}/hareketler?${params}`);
    return response.data;
  }
}

export const apiService = new ApiService();
export default apiService;