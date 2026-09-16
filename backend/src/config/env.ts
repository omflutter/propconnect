import dotenv from 'dotenv';
import path from 'path';

// Load .env file from root of backend directory
dotenv.config({ path: path.resolve(__dirname, '../../.env') });
dotenv.config({ path: path.resolve(__dirname, '../.env') });
dotenv.config();

export const env = {
  PORT: process.env.APP_PORT ? parseInt(process.env.APP_PORT, 10) : process.env.PORT ? parseInt(process.env.PORT, 10) : 5001,
  NODE_ENV: process.env.NODE_ENV || 'production',
  API_PREFIX: process.env.API_PREFIX || '/api/v1',

  DB_DIALECT: (process.env.DB_DIALECT || 'postgres') as 'postgres',
  DB_HOST: process.env.DB_HOST || 'pg-4a3e0f2-robolaxian-0331.e.aivencloud.com',
  DB_PORT: process.env.DB_PORT ? parseInt(process.env.DB_PORT, 10) : 27067,
  DB_USER: process.env.DB_USER || 'avnadmin',
  DB_PASSWORD: process.env.DB_PASSWORD || '',
  DB_NAME: process.env.DB_NAME || 'defaultdb',
  DB_SSL: process.env.DB_SSL === 'true' || true,

  JWT_SECRET: process.env.JWT_SECRET || 'super_secret_propconnect_jwt_key_2026',
};
