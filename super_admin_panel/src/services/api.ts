const getApiBaseUrl = () => {
  if (import.meta.env.VITE_API_BASE_URL) {
    return import.meta.env.VITE_API_BASE_URL;
  }
  if (typeof window !== 'undefined') {
    if (/^(\d{1,3}\.){3}\d{1,3}$/.test(window.location.hostname)) {
      return `${window.location.protocol}//${window.location.hostname}:5000/api/v1`;
    }
    if (window.location.hostname !== 'localhost' && window.location.hostname !== '127.0.0.1') {
      return '/api/v1'; // Relative path for Firebase Hosting or reverse proxies
    }
  }
  return 'http://localhost:5000/api/v1';
};

const API_BASE_URL = getApiBaseUrl();

export interface ApiResponse<T = any> {
  success: boolean;
  message: string;
  data?: T;
  error?: any;
  statusCode?: number;
}

export async function apiFetch<T = any>(
  endpoint: string,
  options: RequestInit = {}
): Promise<ApiResponse<T>> {
  const token = localStorage.getItem('token');

  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
    ...(options.headers as Record<string, string>),
  };

  if (token) {
    headers['Authorization'] = `Bearer ${token}`;
  }

  const fullUrl = `${API_BASE_URL}${endpoint}`;

  try {
    const response = await fetch(fullUrl, {
      ...options,
      headers,
    });

    const statusCode = response.status;
    let data: any = {};
    const rawText = await response.text();

    try {
      data = rawText ? JSON.parse(rawText) : {};
    } catch (parseErr) {
      console.error(`[API Parse Error] ${options.method || 'GET'} ${fullUrl} -> Status ${statusCode}:`, rawText);
      const detailedMessage = `HTTP ${statusCode} ${response.statusText}: Server returned non-JSON response (${rawText.substring(0, 120)}...)`;
      return {
        success: false,
        statusCode,
        message: detailedMessage,
        error: rawText,
      };
    }

    if (!response.ok) {
      const detailedMessage = data.message || data.error || `HTTP ${statusCode} ${response.statusText}`;
      console.error(`[API Error Response] ${options.method || 'GET'} ${fullUrl} -> Status ${statusCode}:`, data);
      return {
        success: false,
        statusCode,
        message: `[HTTP ${statusCode}] ${detailedMessage}`,
        error: data.error || data,
      };
    }

    return {
      success: true,
      statusCode,
      message: data.message || 'Success',
      data: data.data !== undefined ? data.data : data,
    };
  } catch (err: any) {
    const networkMessage = `Network Error (${err.message || 'Failed to connect'}). Check internet connection or CORS settings for ${fullUrl}`;
    console.error(`[API Network Exception] ${options.method || 'GET'} ${fullUrl}:`, err);
    return {
      success: false,
      statusCode: 0,
      message: networkMessage,
      error: err,
    };
  }
}
