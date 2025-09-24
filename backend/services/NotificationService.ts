import Notification, { INotification } from '../models/Notification';
import mongoose from 'mongoose';

export class NotificationService {
  /**
   * Crear una notificación de resultado de predicción
   */
  static async createPredictionResultNotification(
    userId: string,
    gameId: string,
    gameName: string,
    matchId: string,
    matchInfo: string,
    isCorrect: boolean,
    pointsGained?: number,
    livesLost?: number
  ): Promise<INotification> {
    const title = isCorrect ? '🎉 ¡Predicción Correcta!' : '😔 Predicción Incorrecta';
    
    let message = `En el partido ${matchInfo} de la liga ${gameName}`;
    
    if (isCorrect && pointsGained) {
      message += ` acertaste tu predicción. ¡Ganaste ${pointsGained} puntos!`;
    } else if (!isCorrect && livesLost) {
      message += ` tu predicción fue incorrecta. Perdiste ${livesLost} vida${livesLost > 1 ? 's' : ''}.`;
    }

    const notification = new Notification({
      userId: new mongoose.Types.ObjectId(userId),
      type: 'prediction_result',
      title,
      message,
      data: {
        gameId,
        gameName,
        matchId,
        matchInfo,
        pointsGained: pointsGained || 0,
        livesLost: livesLost || 0,
        isCorrect
      },
      isRead: false
    });

    return await notification.save();
  }

  /**
   * Crear notificación de resultado de partido
   */
  static async createMatchResultNotification(
    userId: string,
    gameId: string,
    gameName: string,
    matchId: string,
    matchInfo: string,
    result: string,
    homeTeam: string,
    visitorTeam: string
  ): Promise<INotification> {
    let winner = '';
    let resultIcon = '';
    
    switch (result) {
      case 'home':
        winner = homeTeam;
        resultIcon = '🏠';
        break;
      case 'visitor':
        winner = visitorTeam;
        resultIcon = '✈️';
        break;
      case 'draw':
        winner = 'Empate';
        resultIcon = '🤝';
        break;
      default:
        winner = 'Desconocido';
        resultIcon = '❓';
    }

    const title = `⚽ Resultado: ${homeTeam} vs ${visitorTeam}`;
    const message = `${resultIcon} ¡${winner}${result === 'draw' ? '' : ' ganó'}! El partido ${matchInfo} de la liga ${gameName} ha finalizado.`;

    const notification = new Notification({
      userId: new mongoose.Types.ObjectId(userId),
      type: 'game_update',
      title,
      message,
      data: {
        gameId,
        gameName,
        matchId,
        matchInfo,
        result,
        homeTeam,
        visitorTeam,
        winner
      },
      isRead: false
    });

    return await notification.save();
  }

  /**
   * Crear notificación de eliminación
   */
  static async createEliminationNotification(
    userId: string,
    gameId: string,
    gameName: string,
    week: number
  ): Promise<INotification> {
    const notification = new Notification({
      userId: new mongoose.Types.ObjectId(userId),
      type: 'elimination',
      title: '💀 Has sido eliminado',
      message: `Te quedaste sin vidas en la liga ${gameName} durante la semana ${week}. ¡Mejor suerte la próxima vez!`,
      data: {
        gameId,
        gameName
      },
      isRead: false
    });

    return await notification.save();
  }

  /**
   * Obtener notificaciones de un usuario
   */
  static async getUserNotifications(
    userId: string,
    limit: number = 20,
    offset: number = 0,
    unreadOnly: boolean = false
  ): Promise<INotification[]> {
    const query: any = { userId: new mongoose.Types.ObjectId(userId) };
    
    if (unreadOnly) {
      query.isRead = false;
    }

    return await Notification.find(query)
      .sort({ createdAt: -1 })
      .limit(limit)
      .skip(offset)
      .exec();
  }

  /**
   * Contar notificaciones no leídas
   */
  static async getUnreadCount(userId: string): Promise<number> {
    return await Notification.countDocuments({
      userId: new mongoose.Types.ObjectId(userId),
      isRead: false
    });
  }

  /**
   * Marcar notificación como leída
   */
  static async markAsRead(notificationId: string, userId: string): Promise<boolean> {
    const result = await Notification.updateOne(
      { 
        _id: new mongoose.Types.ObjectId(notificationId),
        userId: new mongoose.Types.ObjectId(userId)
      },
      { isRead: true, updatedAt: new Date() }
    );

    return result.modifiedCount > 0;
  }

  /**
   * Marcar todas las notificaciones como leídas
   */
  static async markAllAsRead(userId: string): Promise<number> {
    const result = await Notification.updateMany(
      { 
        userId: new mongoose.Types.ObjectId(userId),
        isRead: false
      },
      { isRead: true, updatedAt: new Date() }
    );

    return result.modifiedCount;
  }

  /**
   * Eliminar notificaciones antiguas (más de 30 días)
   */
  static async cleanupOldNotifications(): Promise<number> {
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

    const result = await Notification.deleteMany({
      createdAt: { $lt: thirtyDaysAgo }
    });

    return result.deletedCount;
  }
}
