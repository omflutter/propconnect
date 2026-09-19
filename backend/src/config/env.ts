import dotenv from 'dotenv';
import path from 'path';

// Load .env file from root of backend directory
dotenv.config({ path: path.resolve(__dirname, '../../.env') });
dotenv.config({ path: path.resolve(__dirname, '../.env') });
dotenv.config();

export const env = {
  PORT: process.env.PORT ? parseInt(process.env.PORT, 10) : (process.env.APP_PORT ? parseInt(process.env.APP_PORT, 10) : 5000),
  NODE_ENV: process.env.NODE_ENV || 'production',
  API_PREFIX: process.env.API_PREFIX || '/api/v1',

  DB_DIALECT: (process.env.DB_DIALECT || 'postgres') as 'postgres',
  DB_HOST: process.env.DB_HOST || '127.0.0.1',
  DB_PORT: process.env.DB_PORT ? parseInt(process.env.DB_PORT, 10) : 5432,
  DB_USER: process.env.DB_USER || 'propconnect_user',
  DB_PASSWORD: process.env.DB_PASSWORD || 'PropConnect2026!SecureDb',
  DB_NAME: process.env.DB_NAME || 'propconnect_db',
  DB_SSL: process.env.DB_SSL === 'true',

  JWT_SECRET: process.env.JWT_SECRET || 'super_secret_propconnect_jwt_key_2026',

  // Interakt WhatsApp Business API
  INTERAKT_API_KEY: process.env.INTERAKT_API_KEY || 'N2VnTGNPTnVfSjBWZG92YTFHcnpkR2RrLXRsemhtZ0tfcDVEaWlJQ0VjYzo=',
  INTERAKT_BUSINESS_ID: process.env.INTERAKT_BUSINESS_ID || '1433676617960236',
  INTERAKT_BASE_URL: process.env.INTERAKT_BASE_URL || 'https://api.interakt.ai/v1/public',
};
