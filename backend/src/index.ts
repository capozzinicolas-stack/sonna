import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import cookieParser from 'cookie-parser';
import { env } from './config/env';
import { errorHandler } from './middleware/errorHandler';
import authRoutes from './modules/auth/routes';

const app = express();

// Middleware
app.use(helmet());
app.use(cors({
  origin: [env.FRONTEND_URL, /\.vercel\.app$/],
  credentials: true,
}));
app.use(morgan('dev'));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));
app.use(cookieParser());

// Health check
app.get('/api/health', (_req, res) => {
  res.status(200).json({ status: 'ok', timestamp: new Date().toISOString() });
});

// API routes
app.use('/api/v1/auth', authRoutes);

// Error handler (must be last)
app.use(errorHandler);

// Start server (only when not running on Vercel)
if (!process.env.VERCEL) {
  app.listen(env.PORT, () => {
    console.log(`🚀 SONNA Backend running on port ${env.PORT}`);
    console.log(`📍 Health check: http://localhost:${env.PORT}/api/health`);
  });
}

export default app;
