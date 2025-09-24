import express from 'express';
import { NotificationController } from '../controllers/NotificationController';
import { authenticateToken } from '../middleware/auth';

const router = express.Router();

// Todas las rutas requieren autenticación
router.use(authenticateToken);

// Obtener notificaciones del usuario
router.get('/', NotificationController.getUserNotifications);

// Obtener contador de notificaciones no leídas
router.get('/unread-count', NotificationController.getUnreadCount);

// Marcar notificación específica como leída
router.put('/:notificationId/read', NotificationController.markAsRead);

// Marcar todas las notificaciones como leídas
router.put('/mark-all-read', NotificationController.markAllAsRead);

export default router;
