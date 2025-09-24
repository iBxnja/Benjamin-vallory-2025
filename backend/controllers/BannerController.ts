import { Request, Response } from 'express';
import { BannerService } from '../services/BannerService';

export class BannerController {
  /**
   * Obtener todos los banners activos
   */
  static async getActiveBanners(req: Request, res: Response): Promise<void> {
    try {
      const banners = await BannerService.getActiveBanners();
      
      res.json({
        success: true,
        data: { banners }
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        message: error instanceof Error ? error.message : 'Error fetching banners'
      });
    }
  }

  /**
   * Obtener banner por ID
   */
  static async getBannerById(req: Request, res: Response): Promise<void> {
    try {
      const { id } = req.params;
      const banner = await BannerService.getBannerById(id);
      
      if (!banner) {
        res.status(404).json({
          success: false,
          message: 'Banner not found'
        });
        return;
      }

      res.json({
        success: true,
        data: { banner }
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        message: error instanceof Error ? error.message : 'Error fetching banner'
      });
    }
  }

  /**
   * Crear nuevo banner
   */
  static async createBanner(req: Request, res: Response): Promise<void> {
    try {
      const banner = await BannerService.createBanner(req.body);
      
      res.status(201).json({
        success: true,
        message: 'Banner created successfully',
        data: { banner }
      });
    } catch (error) {
      res.status(400).json({
        success: false,
        message: error instanceof Error ? error.message : 'Error creating banner'
      });
    }
  }

  /**
   * Actualizar banner
   */
  static async updateBanner(req: Request, res: Response): Promise<void> {
    try {
      const { id } = req.params;
      const banner = await BannerService.updateBanner(id, req.body);
      
      if (!banner) {
        res.status(404).json({
          success: false,
          message: 'Banner not found'
        });
        return;
      }

      res.json({
        success: true,
        message: 'Banner updated successfully',
        data: { banner }
      });
    } catch (error) {
      res.status(400).json({
        success: false,
        message: error instanceof Error ? error.message : 'Error updating banner'
      });
    }
  }

  /**
   * Eliminar banner
   */
  static async deleteBanner(req: Request, res: Response): Promise<void> {
    try {
      const { id } = req.params;
      const success = await BannerService.deleteBanner(id);
      
      if (!success) {
        res.status(404).json({
          success: false,
          message: 'Banner not found'
        });
        return;
      }

      res.json({
        success: true,
        message: 'Banner deleted successfully'
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        message: error instanceof Error ? error.message : 'Error deleting banner'
      });
    }
  }
}
