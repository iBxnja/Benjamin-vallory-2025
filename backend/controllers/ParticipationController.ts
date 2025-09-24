import { Request, Response } from 'express';
import { ParticipationService } from '../services/ParticipationService';
import { authenticateToken, AuthRequest } from '../middleware/auth';
import { validatePrediction } from '../middleware/validation';
import { CreateParticipationDto, CreatePredictionDto } from '../types/dto/ParticipationDto';

export class ParticipationController {
  /**
   * Unirse a un juego
   */
  static async joinGame(req: AuthRequest, res: Response): Promise<void> {
    try {
      const { gameId } = req.params;
      const participationData: CreateParticipationDto = {
        userId: req.user?._id || req.body.userId,
        gameId
      };
      
      const participation = await ParticipationService.joinGame(participationData);
      
      // Verificar si es una participación existente o nueva
      const isNewParticipation = participation.createdAt.getTime() === participation.updatedAt.getTime();
      
      res.status(200).json({
        success: true,
        message: isNewParticipation ? 'Successfully joined the game' : 'Already participating in this game',
        data: { participation }
      });
    } catch (error) {
      res.status(400).json({
        success: false,
        message: error instanceof Error ? error.message : 'Error joining game'
      });
    }
  }

  /**
   * Obtener participación por ID
   */
  static async getParticipationById(req: Request, res: Response): Promise<void> {
    try {
      const { id } = req.params;
      const participation = await ParticipationService.getParticipationById(id);
      
      if (!participation) {
        res.status(404).json({
          success: false,
          message: 'Participation not found'
        });
        return;
      }

      res.json({
        success: true,
        data: { participation }
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        message: error instanceof Error ? error.message : 'Error fetching participation'
      });
    }
  }

  /**
   * Obtener participaciones del usuario autenticado
   */
  static async getUserParticipations(req: AuthRequest, res: Response): Promise<void> {
    try {
      const userId = req.user?._id || '';
      console.log(`🔍 getUserParticipations - Usuario ID: ${userId}`);
      
      const participations = await ParticipationService.getUserParticipations(userId);
      // console.log(`🔍 Participaciones encontradas: ${participations.length}`);
      
      // for (const p of participations) {
      //   console.log(`🔍 Participación: vidas=${p.livesRemaining}, eliminado=${p.isEliminated}, juego=${p.gameId}`);
      // }
      
      res.json({
        success: true,
        data: { participations }
      });
    } catch (error) {
      console.error('❌ Error en getUserParticipations:', error);
      res.status(500).json({
        success: false,
        message: error instanceof Error ? error.message : 'Error fetching user participations'
      });
    }
  }

  /**
   * Obtener participaciones de un juego
   */
  static async getGameParticipations(req: Request, res: Response): Promise<void> {
    try {
      const { gameId } = req.params;
      const participations = await ParticipationService.getGameParticipations(gameId);
      
      res.json({
        success: true,
        data: { participations }
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        message: error instanceof Error ? error.message : 'Error fetching game participations'
      });
    }
  }

  /**
   * Hacer una predicción
   */
  static async makePrediction(req: AuthRequest, res: Response): Promise<void> {
    try {
      const userId = req.user?._id || req.body.userId;
      const { gameId, week, matchId, selectedTeam } = req.body;
      
      console.log(`🎯 Predicción recibida:`, {
        userId,
        gameId, 
        week,
        matchId,
        selectedTeam
      });
      
      const predictionData: CreatePredictionDto = {
        userId,
        gameId,
        week,
        matchId,
        selectedTeam
      };
      
      const participation = await ParticipationService.makePrediction(predictionData);
      
      if (!participation) {
        console.log(`❌ Participación no encontrada para usuario ${userId}`);
        res.status(404).json({
          success: false,
          message: 'Participation not found'
        });
        return;
      }

      console.log(`✅ Predicción creada exitosamente para usuario ${userId}`);

      res.json({
        success: true,
        message: 'Prediction made successfully',
        data: { participation }
      });
    } catch (error) {
      console.error(`❌ Error en predicción:`, error instanceof Error ? error.message : error);
      res.status(400).json({
        success: false,
        message: error instanceof Error ? error.message : 'Error making prediction'
      });
    }
  }

  /**
   * Evaluar predicciones de una semana
   */
  static async evaluateWeekPredictions(req: Request, res: Response): Promise<void> {
    try {
      const { gameId, week } = req.params;
      await ParticipationService.evaluateWeekPredictions(gameId, parseInt(week));
      
      res.json({
        success: true,
        message: 'Week predictions evaluated successfully'
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        message: error instanceof Error ? error.message : 'Error evaluating predictions'
      });
    }
  }

  /**
   * Obtener líderes del juego
   */
  static async getGameLeaders(req: Request, res: Response): Promise<void> {
    try {
      const { gameId } = req.params;
      const { limit = 10 } = req.query;
      
      const leaders = await ParticipationService.getGameLeaders(
        gameId, 
        parseInt(limit as string)
      );
      
      res.json({
        success: true,
        data: { leaders }
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        message: error instanceof Error ? error.message : 'Error fetching game leaders'
      });
    }
  }

  /**
   * Obtener estadísticas de predicciones para un partido
   */
  static async getMatchPredictionStats(req: Request, res: Response): Promise<void> {
    try {
      const { gameId, matchId } = req.params;
      
      const stats = await ParticipationService.getMatchPredictionStats(gameId, matchId);
      
      res.json({
        success: true,
        data: { stats }
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        message: error instanceof Error ? error.message : 'Error fetching match prediction stats'
      });
    }
  }

  /**
   * Abandonar juego
   */
  static async leaveGame(req: AuthRequest, res: Response): Promise<void> {
    try {
      const { gameId } = req.params;
      const userId = req.user?._id || req.body.userId;
      
      const success = await ParticipationService.leaveGame(userId || '', gameId);
      
      if (!success) {
        res.status(404).json({
          success: false,
          message: 'Participation not found'
        });
        return;
      }

      res.json({
        success: true,
        message: 'Successfully left the game'
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        message: error instanceof Error ? error.message : 'Error leaving game'
      });
    }
  }
}