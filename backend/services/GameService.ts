import Game, { IGame } from '../models/Game';
import { CreateGameDto, UpdateGameDto } from '../types/dto/GameDto';

export class GameService {
  /**
   * Crear un nuevo juego
   */
  static async createGame(gameData: CreateGameDto): Promise<IGame> {
    try {
      const game = new Game(gameData);
      await game.save();
      return game;
    } catch (error) {
      throw new Error(`Error creating game: ${error}`);
    }
  }

  /**
   * Obtener juego por ID
   */
  static async getGameById(gameId: string): Promise<IGame | null> {
    try {
      return await Game.findById(gameId);
    } catch (error) {
      throw new Error(`Error fetching game: ${error}`);
    }
  }

  /**
   * Obtener todos los juegos activos
   */
  static async getActiveGames(): Promise<IGame[]> {
    try {
      const games = await Game.find({ isActive: true }).sort({ createdAt: -1 });
      
      // Agregar conteo de participantes para cada juego
      const gamesWithParticipants = await Promise.all(
        games.map(async (game) => {
          const Participation = require('../models/Participation').default;
          const participantCount = await Participation.countDocuments({ gameId: game._id });
          
          return {
            ...game.toObject(),
            participantCount,
            maxParticipants: 20 // Capacidad máxima por defecto
          };
        })
      );
      
      return gamesWithParticipants as any;
    } catch (error) {
      throw new Error(`Error fetching active games: ${error}`);
    }
  }

  /**
   * Obtener todos los juegos
   */
  static async getAllGames(): Promise<IGame[]> {
    try {
      const games = await Game.find().sort({ createdAt: -1 });
      
      // Agregar conteo de participantes para cada juego
      const gamesWithParticipants = await Promise.all(
        games.map(async (game) => {
          const Participation = require('../models/Participation').default;
          const participantCount = await Participation.countDocuments({ gameId: game._id });
          
          return {
            ...game.toObject(),
            participantCount,
            maxParticipants: 20 // Capacidad máxima por defecto
          };
        })
      );
      
      return gamesWithParticipants as any;
    } catch (error) {
      throw new Error(`Error fetching all games: ${error}`);
    }
  }

  /**
   * Actualizar juego
   */
  static async updateGame(gameId: string, gameData: UpdateGameDto): Promise<IGame | null> {
    try {
      const game = await Game.findByIdAndUpdate(
        gameId,
        { ...gameData, updatedAt: new Date() },
        { new: true, runValidators: true }
      );
      
      return game;
    } catch (error) {
      throw new Error(`Error updating game: ${error}`);
    }
  }

  /**
   * Eliminar juego (soft delete)
   */
  static async deleteGame(gameId: string): Promise<boolean> {
    try {
      const result = await Game.findByIdAndUpdate(
        gameId,
        { isActive: false, updatedAt: new Date() },
        { new: true }
      );
      
      return !!result;
    } catch (error) {
      throw new Error(`Error deleting game: ${error}`);
    }
  }

  /**
   * Avanzar a la siguiente semana del juego
   */
  static async advanceToNextWeek(gameId: string): Promise<IGame | null> {
    try {
      const game = await Game.findById(gameId);
      if (!game) return null;

      if (game.currentWeek < game.totalWeeks) {
        game.currentWeek += 1;
        await game.save();
      }

      return game;
    } catch (error) {
      throw new Error(`Error advancing to next week: ${error}`);
    }
  }

  /**
   * Finalizar un partido
   */
  static async finishMatch(gameId: string, matchId: string, result: {
    homeScore: number;
    visitorScore: number;
  }): Promise<IGame | null> {
    try {
      const game = await Game.findById(gameId);
      if (!game) return null;

      const match = game.competition.find(m => m.matchId === matchId);
      if (!match) return null;

      match.isFinished = true;
      match.status = 'finished';
      match.result = {
        homeScore: result.homeScore,
        visitorScore: result.visitorScore,
        winner: result.homeScore > result.visitorScore ? 'home' : 
                result.visitorScore > result.homeScore ? 'visitor' : 'draw'
      };

      await game.save();
      return game;
    } catch (error) {
      throw new Error(`Error finishing match: ${error}`);
    }
  }

  /**
   * Obtener partidos de la semana actual
   */
  static async getCurrentWeekMatches(gameId: string): Promise<any[]> {
    try {
      const game = await Game.findById(gameId);
      if (!game) return [];

      // Por simplicidad, asumimos que cada semana tiene 3 partidos
      const matchesPerWeek = 3;
      const startIndex = (game.currentWeek - 1) * matchesPerWeek;
      const endIndex = startIndex + matchesPerWeek;

      return game.competition.slice(startIndex, endIndex);
    } catch (error) {
      throw new Error(`Error fetching current week matches: ${error}`);
    }
  }

  /**
   * Verificar si un juego está activo
   */
  static async isGameActive(gameId: string): Promise<boolean> {
    try {
      const game = await Game.findById(gameId);
      return game ? game.isActive : false;
    } catch (error) {
      throw new Error(`Error checking game status: ${error}`);
    }
  }

  /**
   * Obtener un partido específico por ID
   */
  static async getMatchById(gameId: string, matchId: string): Promise<any | null> {
    try {
      const game = await Game.findById(gameId);
      if (!game) return null;

      const match = game.competition.find(m => m.matchId === matchId);
      if (!match) return null;

      // Corregir inconsistencias en datos existentes
      if (match.isFinished && match.result) {
        const { homeScore, visitorScore, winner } = match.result;
        
        // Determinar el ganador correcto basado en el marcador
        let correctWinner: 'home' | 'visitor' | 'draw';
        if (homeScore > visitorScore) {
          correctWinner = 'home';
        } else if (visitorScore > homeScore) {
          correctWinner = 'visitor';
        } else {
          correctWinner = 'draw';
        }

        // Si hay inconsistencia, corregirla
        if (winner !== correctWinner) {
          console.log(`🔧 Corrigiendo inconsistencia en partido ${matchId}: marcador ${homeScore}-${visitorScore}, winner incorrecto: ${winner} -> ${correctWinner}`);
          
          match.result.winner = correctWinner;
          await game.save();
          
          console.log(`✅ Inconsistencia corregida para partido ${matchId}`);
        }
      }

      return match;
    } catch (error) {
      throw new Error(`Error fetching match: ${error}`);
    }
  }
}
