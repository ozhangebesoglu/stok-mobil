import React, { createContext, useContext, useReducer, useEffect, ReactNode } from 'react';
import { authService } from '../services/api';

// Kullanıcı tipi
export interface User {
  kullanici_id: number;
  isim: string;
  email: string;
  telefon?: string;
  rol: 'admin' | 'kullanici' | 'kasiyer';
  son_giris?: string;
  olusturma_tarihi?: string;
}

// Auth state tipi
interface AuthState {
  user: User | null;
  token: string | null;
  isLoading: boolean;
  isAuthenticated: boolean;
}

// Action tipleri
type AuthAction =
  | { type: 'LOGIN_START' }
  | { type: 'LOGIN_SUCCESS'; payload: { user: User; token: string } }
  | { type: 'LOGIN_FAILURE' }
  | { type: 'LOGOUT' }
  | { type: 'SET_LOADING'; payload: boolean }
  | { type: 'UPDATE_USER'; payload: User };

// Initial state
const initialState: AuthState = {
  user: null,
  token: null,
  isLoading: true,
  isAuthenticated: false,
};

// Reducer
function authReducer(state: AuthState, action: AuthAction): AuthState {
  switch (action.type) {
    case 'LOGIN_START':
      return { ...state, isLoading: true };
    
    case 'LOGIN_SUCCESS':
      return {
        ...state,
        user: action.payload.user,
        token: action.payload.token,
        isLoading: false,
        isAuthenticated: true,
      };
    
    case 'LOGIN_FAILURE':
      return {
        ...state,
        user: null,
        token: null,
        isLoading: false,
        isAuthenticated: false,
      };
    
    case 'LOGOUT':
      return {
        ...state,
        user: null,
        token: null,
        isLoading: false,
        isAuthenticated: false,
      };
    
    case 'SET_LOADING':
      return { ...state, isLoading: action.payload };
    
    case 'UPDATE_USER':
      return { ...state, user: action.payload };
    
    default:
      return state;
  }
}

// Context tipi
interface AuthContextType {
  state: AuthState;
  login: (email: string, password: string) => Promise<boolean>;
  logout: () => void;
  updateUser: (user: User) => void;
}

// Context oluştur
const AuthContext = createContext<AuthContextType | undefined>(undefined);

// Provider props tipi
interface AuthProviderProps {
  children: ReactNode;
}

// Auth Provider
export function AuthProvider({ children }: AuthProviderProps) {
  const [state, dispatch] = useReducer(authReducer, initialState);

  // Sayfa yüklendiğinde token kontrolü
  useEffect(() => {
    const initAuth = async () => {
      try {
        const token = localStorage.getItem('authToken');
        const userStr = localStorage.getItem('user');

        if (token && userStr) {
          // Token geçerliliğini kontrol et
          const response = await authService.verifyToken();
          if (response.success && response.data?.user) {
            dispatch({
              type: 'LOGIN_SUCCESS',
              payload: {
                user: response.data.user,
                token,
              },
            });
          } else {
            // Token geçersiz
            localStorage.removeItem('authToken');
            localStorage.removeItem('user');
            dispatch({ type: 'LOGIN_FAILURE' });
          }
        } else {
          dispatch({ type: 'LOGIN_FAILURE' });
        }
      } catch (error) {
        console.error('Auth initialization error:', error);
        localStorage.removeItem('authToken');
        localStorage.removeItem('user');
        dispatch({ type: 'LOGIN_FAILURE' });
      }
    };

    initAuth();
  }, []);

  // Giriş yap
  const login = async (email: string, sifre: string): Promise<boolean> => {
    try {
      dispatch({ type: 'LOGIN_START' });

      const response = await authService.login(email, sifre);
      
      if (response.success && response.data) {
        const { user, token } = response.data;
        
        // Local storage'a kaydet
        localStorage.setItem('authToken', token);
        localStorage.setItem('user', JSON.stringify(user));

        dispatch({
          type: 'LOGIN_SUCCESS',
          payload: { user, token },
        });

        return true;
      } else {
        dispatch({ type: 'LOGIN_FAILURE' });
        return false;
      }
    } catch (error) {
      console.error('Login error:', error);
      dispatch({ type: 'LOGIN_FAILURE' });
      return false;
    }
  };

  // Çıkış yap
  const logout = () => {
    localStorage.removeItem('authToken');
    localStorage.removeItem('user');
    dispatch({ type: 'LOGOUT' });
  };

  // Kullanıcı bilgilerini güncelle
  const updateUser = (user: User) => {
    localStorage.setItem('user', JSON.stringify(user));
    dispatch({ type: 'UPDATE_USER', payload: user });
  };

  const value = {
    state,
    login,
    logout,
    updateUser,
  };

  return (
    <AuthContext.Provider value={value}>
      {children}
    </AuthContext.Provider>
  );
}

// Custom hook
export function useAuth() {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
}