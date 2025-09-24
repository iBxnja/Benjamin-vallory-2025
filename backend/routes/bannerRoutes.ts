import express from 'express';
import { BannerController } from '../controllers/BannerController';
import { authenticateToken } from '../middleware/auth';

const router = express.Router();

// Rutas públicas
router.get('/', BannerController.getActiveBanners);
router.get('/:id', BannerController.getBannerById);

// Rutas protegidas (solo para administradores)
router.use(authenticateToken);
router.post('/', BannerController.createBanner);
router.put('/:id', BannerController.updateBanner);
router.delete('/:id', BannerController.deleteBanner);

export default router;
