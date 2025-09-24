import express from 'express';
import { GameController } from '../controllers/GameController';
import { ParticipationController } from '../controllers/ParticipationController';
import { authenticateToken } from '../middleware/auth';
import { validatePrediction } from '../middleware/validation';

const router = express.Router();

// Rutas públicas para compatibilidad con la prueba técnica
router.get('/', GameController.getAllGames);

// Rutas protegidas
router.use(authenticateToken);

// Unirse a un survivor (juego)
router.post('/join/:id', ParticipationController.joinGame);

// Hacer predicción
router.post('/pick', validatePrediction, ParticipationController.makePrediction);

export default router;