import express from 'express';
import { UserController } from '../controllers/UserController';
import { authenticateToken } from '../middleware/auth';
import { 
  validateUserRegistration, 
  validateUserLogin 
} from '../middleware/validation';

const router = express.Router();

// Rutas públicas
router.post('/register', validateUserRegistration, UserController.register);
router.post('/login', validateUserLogin, UserController.login);

// Rutas protegidas
router.get('/profile', authenticateToken, UserController.getProfile);
router.get('/me', authenticateToken, UserController.getProfile); // Alias para /profile
router.put('/profile', authenticateToken, UserController.updateProfile);
router.delete('/profile', authenticateToken, UserController.deleteUser);

// Rutas de administración
router.get('/', authenticateToken, UserController.getAllUsers);
router.get('/:id', authenticateToken, UserController.getUserById);
router.get('/ranking/global', authenticateToken, UserController.getUserRanking);

export default router;
