import { Request, Response } from 'express';
import { GameService } from '../services/GameService';
import { CreateGameDto, UpdateGameDto, MatchResultDto } from '../types/dto/GameDto';

export class GameController {
  /**
   * Crear nuevo juego
   */
  static async createGame(req: Request, res: Response): Promise<void> {
    try {
      const gameData: CreateGameDto = req.body;
      const game = await GameService.createGame(gameData);
      
      res.status(201).json({
        success: true,
        message: 'Game created successfully',
        data: { game }
      });
    } catch (error) {
      res.status(400).json({
        success: false,
        message: error instanceof Error ? error.message : 'Error creating game'
      });
    }
  }

  /**
   * Obtener todos los juegos
   */
  static async getAllGames(req: Request, res: Response): Promise<void> {
    try {
      const { active } = req.query;
      
      let games;
      if (active === 'true') {
        games = await GameService.getActiveGames();
      } else {
        games = await GameService.getAllGames();
      }
      
      res.json({
        success: true,
        data: { games }
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        message: error instanceof Error ? error.message : 'Error fetching games'
      });
    }
  }

  /**
   * Obtener juego por ID
   */
  static async getGameById(req: Request, res: Response): Promise<void> {
    try {
      const { id } = req.params;
      const game = await GameService.getGameById(id);
      
      if (!game) {
        res.status(404).json({
          success: false,
          message: 'Game not found'
        });
        return;
      }

      res.json({
        success: true,
        data: { game }
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        message: error instanceof Error ? error.message : 'Error fetching game'
      });
    }
  }

  /**
   * Actualizar juego
   */
  static async updateGame(req: Request, res: Response): Promise<void> {
    try {
      const { id } = req.params;
      const updateData: UpdateGameDto = req.body;
      const game = await GameService.updateGame(id, updateData);
      
      if (!game) {
        res.status(404).json({
          success: false,
          message: 'Game not found'
        });
        return;
      }

      res.json({
        success: true,
        message: 'Game updated successfully',
        data: { game }
      });
    } catch (error) {
      res.status(400).json({
        success: false,
        message: error instanceof Error ? error.message : 'Error updating game'
      });
    }
  }

  /**
   * Eliminar juego
   */
  static async deleteGame(req: Request, res: Response): Promise<void> {
    try {
      const { id } = req.params;
      const success = await GameService.deleteGame(id);
      
      if (!success) {
        res.status(404).json({
          success: false,
          message: 'Game not found'
        });
        return;
      }

      res.json({
        success: true,
        message: 'Game deleted successfully'
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        message: error instanceof Error ? error.message : 'Error deleting game'
      });
    }
  }

  /**
   * Avanzar a la siguiente semana
   */
  static async advanceWeek(req: Request, res: Response): Promise<void> {
    try {
      const { id } = req.params;
      const game = await GameService.advanceToNextWeek(id);
      
      if (!game) {
        res.status(404).json({
          success: false,
          message: 'Game not found'
        });
        return;
      }

      res.json({
        success: true,
        message: 'Week advanced successfully',
        data: { game }
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        message: error instanceof Error ? error.message : 'Error advancing week'
      });
    }
  }

  /**
   * Finalizar partido
   */
  static async finishMatch(req: Request, res: Response): Promise<void> {
    try {
      const { gameId, matchId } = req.params;
      const result: MatchResultDto = req.body;
      
      const game = await GameService.finishMatch(gameId, matchId, result);
      
      if (!game) {
        res.status(404).json({
          success: false,
          message: 'Game or match not found'
        });
        return;
      }

      res.json({
        success: true,
        message: 'Match finished successfully',
        data: { game }
      });
    } catch (error) {
      res.status(400).json({
        success: false,
        message: error instanceof Error ? error.message : 'Error finishing match'
      });
    }
  }

  /**
   * Obtener partidos de la semana actual
   */
  static async getCurrentWeekMatches(req: Request, res: Response): Promise<void> {
    try {
      const { id } = req.params;
      const matches = await GameService.getCurrentWeekMatches(id);
      
      res.json({
        success: true,
        data: { matches }
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        message: error instanceof Error ? error.message : 'Error fetching current week matches'
      });
    }
  }

  /**
   * Verificar si un juego está activo
   */
  static async checkGameStatus(req: Request, res: Response): Promise<void> {
    try {
      const { id } = req.params;
      const isActive = await GameService.isGameActive(id);
      
      res.json({
        success: true,
        data: { isActive }
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        message: error instanceof Error ? error.message : 'Error checking game status'
      });
    }
  }

  /**
   * Obtener un partido específico por ID
   */
  static async getMatchById(req: Request, res: Response): Promise<void> {
    try {
      const { gameId, matchId } = req.params;
      const match = await GameService.getMatchById(gameId, matchId);
      
      if (!match) {
        res.status(404).json({
          success: false,
          message: 'Match not found'
        });
        return;
      }

      res.json({
        success: true,
        data: { match }
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        message: error instanceof Error ? error.message : 'Error fetching match'
      });
    }
  }
}
