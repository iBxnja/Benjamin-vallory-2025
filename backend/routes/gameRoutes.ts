import express from 'express';
import { GameController } from '../controllers/GameController';
import { authenticateToken } from '../middleware/auth';
import { 
  validateGameCreation, 
  validateMatchResult 
} from '../middleware/validation';
import MatchAutomationService from '../services/MatchAutomationService';

const router = express.Router();

// Todas las rutas requieren autenticación
router.use(authenticateToken);

// CRUD de juegos
router.post('/', validateGameCreation, GameController.createGame);
router.get('/', GameController.getAllGames);
router.get('/:id', GameController.getGameById);
router.put('/:id', GameController.updateGame);
router.delete('/:id', GameController.deleteGame);

// Funcionalidades específicas
router.get('/:id/current-week', GameController.getCurrentWeekMatches);
router.get('/:id/status', GameController.checkGameStatus);
router.get('/:gameId/match/:matchId', GameController.getMatchById);

// Estado en tiempo real de partidos
router.get('/:gameId/match/:matchId/status', (req, res) => {
  try {
    const { gameId, matchId } = req.params;
    // TODO: Implementar lógica para obtener estado del partido
    res.json({
      success: true,
      data: {
        status: 'pending',
        timeRemaining: 300000, // 5 minutos en millisegundos
        canBet: true
      }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error getting match status'
    });
  }
});

export default router;
