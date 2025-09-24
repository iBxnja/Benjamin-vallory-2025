import express from 'express';
import mongoose from 'mongoose';
import cors from 'cors';
import dotenv from 'dotenv';
import helmet from 'helmet';

// Importar rutas
import survivorRoutes from './routes/survivorRoutes';
import userRoutes from './routes/userRoutes';
import gameRoutes from './routes/gameRoutes';
import participationRoutes from './routes/participationRoutes';
import bannerRoutes from './routes/bannerRoutes';
import notificationRoutes from './routes/notificationRoutes';

// Importar seeds
import seedSurvivors from './seeds/seedData';
import MatchAutomationService from './services/MatchAutomationService';

dotenv.config();

const app = express();

// Middlewares de seguridad
app.use(helmet());
app.use(cors({
  origin: process.env.FRONTEND_URL || 'http://localhost:3000',
  credentials: true
}));

// Middlewares de parsing
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// Middleware de logging
app.use((req, res, next) => {
  console.log(`${new Date().toISOString()} - ${req.method} ${req.path}`);
  next();
});

// Conexión a MongoDB
mongoose.connect(process.env.MONGO_URI || 'mongodb://localhost:27017/survivor')
  .then(() => {
    console.log('✅ Connected to MongoDB');

  })
  .catch((error) => {
    console.error('❌ MongoDB connection error:', error);
  });

// Rutas de la API
app.use('/api/survivor', survivorRoutes);
app.use('/api/users', userRoutes);
app.use('/api/games', gameRoutes);
app.use('/api/participations', participationRoutes);
app.use('/api/banners', bannerRoutes);
app.use('/api/notifications', notificationRoutes);

// Ruta de salud
app.get('/api/health', (req, res) => {
  res.json({
    success: true,
    message: 'Server is running',
    timestamp: new Date().toISOString()
  });
});

// Middleware de manejo de errores
app.use((err: any, req: express.Request, res: express.Response, next: express.NextFunction) => {
  console.error('Error:', err);
  res.status(500).json({
    success: false,
    message: 'Internal server error'
  });
});

// Middleware para rutas no encontradas
app.use('*', (req, res) => {
  res.status(404).json({
    success: false,
    message: 'Route not found'
  });
});

const PORT = process.env.PORT || 4300;
app.listen(PORT, async () => {
  console.log(`🚀 Server running on port ${PORT}`);
  console.log(`📱 Health check: http://localhost:${PORT}/api/health`);
  
  // Ejecutar seeding después de iniciar el servidor
  await seedSurvivors();
  
  // Inicializar sistema de automatización de partidos
  const automationService = MatchAutomationService.getInstance();
  await automationService.initialize();
});