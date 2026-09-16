import express, { Application } from 'express';
import cors from 'cors';
import helmet from 'helmet';
import swaggerUi from 'swagger-ui-express';
import { env } from './config/env';
import { swaggerSpec } from './config/swagger';
import routes from './routes';
import { requestLogger } from './middlewares/logger.middleware';
import { errorHandler, notFoundHandler } from './middlewares/error.middleware';
import { sequelize } from './config/database';
import { seedInitialData } from './services/seed.service';

const app: Application = express();

// Security Middlewares
app.use(helmet({ crossOriginResourcePolicy: { policy: 'cross-origin' } }));
app.use(cors({
  origin: true,
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
}));

// Body Parsing & Logging
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(requestLogger);

// Lazy Database & Seed Auto-Initialization for Serverless / Cloud Functions
let isDbInitialized = false;
app.use(async (req, res, next) => {
  if (!isDbInitialized) {
    try {
      await sequelize.sync();
      await sequelize.query('ALTER TABLE platform_configs ADD COLUMN IF NOT EXISTS "razorpayKeyId" VARCHAR(255) DEFAULT \'rzp_live_89123849102934\';');
      await sequelize.query('ALTER TABLE platform_configs ADD COLUMN IF NOT EXISTS "razorpayKeySecret" VARCHAR(255) DEFAULT \'rzp_sec_99182391028349\';');
      await sequelize.query('ALTER TABLE platform_configs ADD COLUMN IF NOT EXISTS "razorpayWebhookSecret" VARCHAR(255) DEFAULT \'whsec_rzp_live_109283\';');
      await sequelize.query('ALTER TABLE platform_configs ADD COLUMN IF NOT EXISTS "stripePublishableKey" VARCHAR(255) DEFAULT \'pk_live_51M091823981023984\';');
      await sequelize.query('ALTER TABLE platform_configs ADD COLUMN IF NOT EXISTS "stripeSecretKey" VARCHAR(255) DEFAULT \'sk_live_51M091823981023984_sec_99182\';');
      await sequelize.query('ALTER TABLE platform_configs ADD COLUMN IF NOT EXISTS "stripeWebhookSecret" VARCHAR(255) DEFAULT \'whsec_stripe_live_991823\';');
      await seedInitialData();
      isDbInitialized = true;
    } catch (err) {
      console.warn('[Serverless DB Init Note] Column alter check:', err);
    }
  }
  next();
});

// Swagger API Documentation Endpoint
app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerSpec, {
  customSiteTitle: 'PropConnect API Documentation',
}));

// Main API Routes
app.use(env.API_PREFIX, routes);

// Root route redirect to Swagger UI
app.get('/', (req, res) => {
  res.send(`
    <html>
      <head><title>PropConnect API</title></head>
      <body style="font-family: Arial, sans-serif; display: flex; flex-direction: column; align-items: center; justify-content: center; height: 100vh; background-color: #0f172a; color: #f8fafc;">
        <h1>🚀 PropConnect Node.js Backend</h1>
        <p>API Base URL: <code>${env.API_PREFIX}</code></p>
        <a href="/api-docs" style="padding: 12px 24px; background-color: #2563eb; color: white; border-radius: 8px; text-decoration: none; font-weight: bold; margin-top: 16px;">Open Swagger API Docs</a>
      </body>
    </html>
  `);
});

// 404 & Error Middlewares
app.use(notFoundHandler);
app.use(errorHandler);

export default app;
