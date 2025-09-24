import Participation, { IParticipation } from '../models/Participation';
import User from '../models/User';
import Game from '../models/Game';
import { CreateParticipationDto, CreatePredictionDto } from '../types/dto/ParticipationDto';

export class ParticipationService {
  /**
   * Unirse a un juego
   */
  static async joinGame(participationData: CreateParticipationDto): Promise<IParticipation> {
    try {
      // Verificar que el usuario existe
      const user = await User.findById(participationData.userId);
      if (!user) {
        throw new Error('User not found');
      }

      // Verificar que el juego existe y está activo
      const game = await Game.findById(participationData.gameId);
      if (!game) {
        throw new Error('Game not found');
      }
      if (!game.isActive) {
        throw new Error('Game is not active');
      }

      // Verificar si el usuario ya está participando
      const existingParticipation = await Participation.findOne({
        userId: participationData.userId,
        gameId: participationData.gameId
      });

      if (existingParticipation) {
        // Si ya está participando, devolver la participación existente
        return existingParticipation;
      }

      // Usar las vidas del usuario, no las máximas del juego
      const userLives = user.lives || game.maxLives;
      console.log(`🎯 Usuario ${user.username}: vidas del perfil=${user.lives}, vidas asignadas=${userLives}, maxLives del juego=${game.maxLives}`);
      
      const participation = new Participation({
        ...participationData,
        livesRemaining: userLives,
        totalPoints: 0
      });

      await participation.save();
      return participation;
    } catch (error) {
      throw new Error(`Error joining game: ${error}`);
    }
  }

  /**
   * Obtener participación por ID
   */
  static async getParticipationById(participationId: string): Promise<IParticipation | null> {
    try {
      return await Participation.findById(participationId)
        .populate('userId', 'username firstName lastName')
        .populate('gameId', 'name currentWeek totalWeeks competition');
    } catch (error) {
      throw new Error(`Error fetching participation: ${error}`);
    }
  }

  /**
   * Obtener participaciones de un usuario
   */
  static async getUserParticipations(userId: string): Promise<IParticipation[]> {
    try {
      return await Participation.find({ userId })
        .populate('gameId', 'name currentWeek totalWeeks isActive competition')
        .sort({ joinedAt: -1 });
    } catch (error) {
      throw new Error(`Error fetching user participations: ${error}`);
    }
  }

  /**
   * Obtener participaciones de un juego
   */
  static async getGameParticipations(gameId: string): Promise<IParticipation[]> {
    try {
      return await Participation.find({ gameId })
        .populate('userId', 'username firstName lastName')
        .populate('gameId', 'name currentWeek totalWeeks competition')
        .sort({ totalPoints: -1, joinedAt: 1 });
    } catch (error) {
      throw new Error(`Error fetching game participations: ${error}`);
    }
  }

  /**
   * Hacer una predicción
   */
  static async makePrediction(predictionData: CreatePredictionDto): Promise<IParticipation | null> {
    try {
      const participation = await Participation.findOne({
        userId: predictionData.userId,
        gameId: predictionData.gameId
      });

      if (!participation) {
        throw new Error('Participation not found');
      }

      // VALIDAR SI EL USUARIO TIENE VIDAS RESTANTES
      if (participation.isEliminated) {
        throw new Error('No puedes hacer predicciones porque has sido eliminado del juego');
      }

      if (participation.livesRemaining <= 0) {
        throw new Error('No puedes hacer predicciones porque no tienes vidas restantes');
      }

      console.log(`🎯 Usuario ${participation.userId} haciendo predicción - Vidas restantes: ${participation.livesRemaining}`);

      // Verificar que no haya ya una predicción para esta semana y partido
      const existingPrediction = participation.predictions.find(
        p => p.week === predictionData.week && p.matchId === predictionData.matchId
      );

      if (existingPrediction) {
        throw new Error('Prediction already exists for this match');
      }

      // Agregar la nueva predicción
      participation.predictions.push({
        week: predictionData.week,
        matchId: predictionData.matchId,
        selectedTeam: predictionData.selectedTeam,
        createdAt: new Date()
      });

      participation.lastActivityAt = new Date();
      await participation.save();

      return participation;
    } catch (error) {
      throw new Error(`Error making prediction: ${error}`);
    }
  }

  /**
   * Evaluar predicciones de una semana
   * NOTA: Este método está deshabilitado porque MatchAutomationService ya procesa las predicciones
   * cuando terminan los partidos, evitando procesamiento duplicado.
   */
  static async evaluateWeekPredictions(gameId: string, week: number): Promise<void> {
    console.log(`⚠️ evaluateWeekPredictions deshabilitado - MatchAutomationService ya procesa las predicciones`);
    return; // Deshabilitado para evitar procesamiento duplicado
  }

  /**
   * Evaluar una predicción individual
   */
  private static evaluatePrediction(selectedTeam: string, actualWinner: string): boolean {
    if (actualWinner === 'draw') {
      // Si hay empate, solo es correcto si apostó por empate
      return selectedTeam === 'draw';
    }
    return selectedTeam === actualWinner;
  }

  /**
   * Obtener líderes del juego
   */
  static async getGameLeaders(gameId: string, limit: number = 10): Promise<IParticipation[]> {
    try {
      return await Participation.find({ 
        gameId, 
        isEliminated: false 
      })
        .populate('userId', 'username firstName lastName')
        .sort({ totalPoints: -1, livesRemaining: -1 })
        .limit(limit);
    } catch (error) {
      throw new Error(`Error fetching game leaders: ${error}`);
    }
  }

  /**
   * Obtener estadísticas de predicciones para un partido
   */
  static async getMatchPredictionStats(gameId: string, matchId: string): Promise<{
    homeVotes: number;
    visitorVotes: number;
    homePercentage: number;
    visitorPercentage: number;
    totalVotes: number;
  }> {
    try {
      const participations = await Participation.find({ gameId });
      
      let homeVotes = 0;
      let visitorVotes = 0;
      
      for (const participation of participations) {
        const prediction = participation.predictions.find(
          p => p.matchId === matchId
        );
        
        if (prediction) {
          if (prediction.selectedTeam === 'home') {
            homeVotes++;
          } else if (prediction.selectedTeam === 'visitor') {
            visitorVotes++;
          }
        }
      }
      
      const totalVotes = homeVotes + visitorVotes;
      const homePercentage = totalVotes > 0 ? Math.round((homeVotes / totalVotes) * 100) : 50;
      const visitorPercentage = totalVotes > 0 ? Math.round((visitorVotes / totalVotes) * 100) : 50;
      
      return {
        homeVotes,
        visitorVotes,
        homePercentage,
        visitorPercentage,
        totalVotes
      };
    } catch (error) {
      throw new Error(`Error fetching match prediction stats: ${error}`);
    }
  }

  /**
   * Eliminar participación
   */
  static async leaveGame(userId: string, gameId: string): Promise<boolean> {
    try {
      const result = await Participation.findOneAndDelete({
        userId,
        gameId
      });
      
      return !!result;
    } catch (error) {
      throw new Error(`Error leaving game: ${error}`);
    }
  }
}
