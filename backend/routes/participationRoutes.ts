import express from 'express';
import { ParticipationController } from '../controllers/ParticipationController';
import { authenticateToken } from '../middleware/auth';
import { validatePrediction } from '../middleware/validation';

const router = express.Router();

// Todas las rutas requieren autenticación
router.use(authenticateToken);

// Participaciones
router.post('/join/:gameId', ParticipationController.joinGame);
router.get('/user', ParticipationController.getUserParticipations);
router.get('/game/:gameId', ParticipationController.getGameParticipations);
router.get('/:id', ParticipationController.getParticipationById);
router.delete('/leave/:gameId', ParticipationController.leaveGame);

// Predicciones
router.post('/predict', validatePrediction, ParticipationController.makePrediction);

// Administración
router.post('/evaluate/:gameId/:week', ParticipationController.evaluateWeekPredictions);
router.get('/leaders/:gameId', ParticipationController.getGameLeaders);
router.get('/stats/:gameId/:matchId', ParticipationController.getMatchPredictionStats);

export default router;
