import { Request, Response } from 'express';
import { NotificationService } from '../services/NotificationService';

export class NotificationController {
  /**
   * Obtener notificaciones del usuario
   */
  static async getUserNotifications(req: any, res: Response): Promise<void> {
    try {
      const userId = req.user._id;
      const limit = parseInt(req.query.limit as string) || 20;
      const offset = parseInt(req.query.offset as string) || 0;
      const unreadOnly = req.query.unreadOnly === 'true';

      const notifications = await NotificationService.getUserNotifications(
        userId,
        limit,
        offset,
        unreadOnly
      );

      res.json({
        success: true,
        data: {
          notifications,
          count: notifications.length
        }
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        message: error instanceof Error ? error.message : 'Error obteniendo notificaciones'
      });
    }
  }

  /**
   * Obtener contador de notificaciones no leídas
   */
  static async getUnreadCount(req: any, res: Response): Promise<void> {
    try {
      const userId = req.user._id;
      const count = await NotificationService.getUnreadCount(userId);

      res.json({
        success: true,
        data: { unreadCount: count }
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        message: error instanceof Error ? error.message : 'Error obteniendo contador'
      });
    }
  }

  /**
   * Marcar notificación como leída
   */
  static async markAsRead(req: any, res: Response): Promise<void> {
    try {
      const userId = req.user._id;
      const { notificationId } = req.params;

      const success = await NotificationService.markAsRead(notificationId, userId);

      if (success) {
        res.json({
          success: true,
          message: 'Notificación marcada como leída'
        });
      } else {
        res.status(404).json({
          success: false,
          message: 'Notificación no encontrada'
        });
      }
    } catch (error) {
      res.status(500).json({
        success: false,
        message: error instanceof Error ? error.message : 'Error marcando notificación'
      });
    }
  }

  /**
   * Marcar todas las notificaciones como leídas
   */
  static async markAllAsRead(req: any, res: Response): Promise<void> {
    try {
      const userId = req.user._id;
      const count = await NotificationService.markAllAsRead(userId);

      res.json({
        success: true,
        data: { markedCount: count },
        message: `${count} notificaciones marcadas como leídas`
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        message: error instanceof Error ? error.message : 'Error marcando notificaciones'
      });
    }
  }
}
