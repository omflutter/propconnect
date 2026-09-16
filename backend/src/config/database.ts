import { Sequelize } from 'sequelize';
import { env } from './env';

export const sequelize = new Sequelize(
  env.DB_NAME,
  env.DB_USER,
  env.DB_PASSWORD,
  {
    host: env.DB_HOST,
    port: env.DB_PORT,
    dialect: 'postgres',
    logging: false,
    dialectOptions: {
      ssl: env.DB_SSL
        ? {
            require: true,
            rejectUnauthorized: false,
          }
        : false,
    },
    pool: {
      max: 15,
      min: 0,
      acquire: 30000,
      idle: 10000,
    },
  }
);

/**
 * Authenticates connection and auto-synchronizes tables on startup.
 */
export const initDatabase = async (): Promise<boolean> => {
  try {
    await sequelize.authenticate();
    console.log('[Database] Aiven PostgreSQL connection established successfully.');
    await sequelize.sync({ alter: true });
    console.log('[Database] Sequelize models synchronized with Cloud Database.');
    return true;
  } catch (error: any) {
    console.error('[Database Error] Aiven PostgreSQL connection failed:', error.message || error);
    return false;
  }
};
