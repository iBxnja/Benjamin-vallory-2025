import Banner, { IBanner } from '../models/Banner';

export class BannerService {
  /**
   * Obtener todos los banners activos
   */
  static async getActiveBanners(): Promise<IBanner[]> {
    try {
      return await Banner.find({ isActive: true }).sort({ order: 1, createdAt: -1 });
    } catch (error) {
      throw new Error(`Error fetching active banners: ${error}`);
    }
  }

  /**
   * Obtener banner por ID
   */
  static async getBannerById(bannerId: string): Promise<IBanner | null> {
    try {
      return await Banner.findById(bannerId);
    } catch (error) {
      throw new Error(`Error fetching banner: ${error}`);
    }
  }

  /**
   * Crear nuevo banner
   */
  static async createBanner(bannerData: {
    title: string;
    description: string;
    order?: number;
  }): Promise<IBanner> {
    try {
      const banner = new Banner(bannerData);
      await banner.save();
      return banner;
    } catch (error) {
      throw new Error(`Error creating banner: ${error}`);
    }
  }

  /**
   * Actualizar banner
   */
  static async updateBanner(bannerId: string, bannerData: {
    title?: string;
    description?: string;
    isActive?: boolean;
    order?: number;
  }): Promise<IBanner | null> {
    try {
      const banner = await Banner.findByIdAndUpdate(
        bannerId,
        { ...bannerData, updatedAt: new Date() },
        { new: true, runValidators: true }
      );
      
      return banner;
    } catch (error) {
      throw new Error(`Error updating banner: ${error}`);
    }
  }

  /**
   * Eliminar banner
   */
  static async deleteBanner(bannerId: string): Promise<boolean> {
    try {
      const result = await Banner.findByIdAndDelete(bannerId);
      return !!result;
    } catch (error) {
      throw new Error(`Error deleting banner: ${error}`);
    }
  }
}
