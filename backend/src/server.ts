import app from './app';
import { env } from './config/env';
import { initDatabase } from './config/database';
import { seedInitialData } from './services/seed.service';

const startServer = async () => {
  console.log('[Server] Starting PropConnect Backend Application...');
  
  // Initialize Database Connection
  const dbConnected = await initDatabase();
  if (dbConnected) {
    await seedInitialData();
  }

  const server = app.listen(env.PORT, () => {
    console.log(`=======================================================`);
    console.log(` 🚀 PropConnect Backend Server is running!`);
    console.log(` 📍 Environment: ${env.NODE_ENV}`);
    console.log(` 🌐 Server URL:  http://localhost:${env.PORT}`);
    console.log(` 📚 API Docs:    http://localhost:${env.PORT}/api-docs`);
    console.log(` 💚 Health Check: http://localhost:${env.PORT}${env.API_PREFIX}/health`);
    console.log(`=======================================================`);
  });

  server.on('error', (err: any) => {
    if (err.code === 'EADDRINUSE') {
      console.error(`\n❌ [Server Error] Port ${env.PORT} is already in use by another process.`);
      console.error(`👉 Please kill the process using port ${env.PORT} or close the previous terminal session.\n`);
      process.exit(1);
    }
  });

  process.on('unhandledRejection', (err: any) => {
    console.error('[Unhandled Rejection]', err);
  });

  process.on('uncaughtException', (err: any) => {
    console.error('[Uncaught Exception]', err);
  });
};

startServer();
