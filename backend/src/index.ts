import { onRequest } from 'firebase-functions/v2/https';
import app from './app';

/**
 * Firebase Cloud Function wrapping Express API App
 */
export const api = onRequest({ region: 'us-central1', memory: '512MiB' }, app);
