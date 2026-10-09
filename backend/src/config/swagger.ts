import swaggerJSDoc from 'swagger-jsdoc';
import { env } from './env';

const options: swaggerJSDoc.Options = {
  definition: {
    openapi: '3.0.0',
    info: {
      title: 'PropConnect API Documentation',
      version: '1.0.0',
      description: 'RESTful API documentation for PropConnect Real Estate Platform',
      contact: {
        name: 'PropConnect Developer Team',
      },
    },
    servers: [
      {
        url: `${env.API_PREFIX}`,
        description: 'Current Environment API Server',
      },
      {
        url: `http://72.61.229.6:5000${env.API_PREFIX}`,
        description: 'Production VPS Server (72.61.229.6:5000)',
      },
      {
        url: `http://localhost:${env.PORT}${env.API_PREFIX}`,
        description: 'Local Development Server',
      },
    ],
    components: {
      securitySchemes: {
        bearerAuth: {
          type: 'http',
          scheme: 'bearer',
          bearerFormat: 'JWT',
          description: 'Enter JWT Bearer Token',
        },
      },
      schemas: {
        StandardResponse: {
          type: 'object',
          properties: {
            success: { type: 'boolean', example: true },
            message: { type: 'string', example: 'Operation completed successfully' },
            data: { type: 'object', nullable: true },
          },
        },
        ErrorResponse: {
          type: 'object',
          properties: {
            success: { type: 'boolean', example: false },
            message: { type: 'string', example: 'Error details message' },
            error: { type: 'object', nullable: true },
          },
        },
      },
    },
  },
  apis: ['./src/routes/*.ts', './dist/routes/*.js'],
};

export const swaggerSpec = swaggerJSDoc(options);
