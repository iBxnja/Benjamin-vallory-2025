import { Request, Response } from 'express';
import { UserService } from '../services/UserService';
import { generateToken } from '../middleware/auth';
import { CreateUserDto, LoginDto, UpdateUserDto } from '../types/dto/UserDto';

export class UserController {
  /**
   * Registrar nuevo usuario
   */
  static async register(req: Request, res: Response): Promise<void> {
    try {
      const userData: CreateUserDto = req.body;
      const user = await UserService.createUser(userData);
      
      const token = generateToken(user._id);
      
      res.status(201).json({
        success: true,
        message: 'User created successfully',
        data: {
          user: {
            _id: user._id,
            username: user.username,
            email: user.email,
            firstName: user.firstName,
            lastName: user.lastName,
            lives: user.lives,
            isActive: user.isActive,
            createdAt: user.createdAt,
            updatedAt: user.updatedAt
          },
          token
        }
      });
    } catch (error) {
      res.status(400).json({
        success: false,
        message: error instanceof Error ? error.message : 'Error creating user'
      });
    }
  }

  /**
   * Iniciar sesión
   */
  static async login(req: Request, res: Response): Promise<void> {
    try {
      const loginData: LoginDto = req.body;
      const user = await UserService.validateCredentials(loginData);
      
      if (!user) {
        res.status(401).json({
          success: false,
          message: 'Invalid credentials'
        });
        return;
      }

      const token = generateToken(user._id);
      
      res.json({
        success: true,
        message: 'Login successful',
        data: {
          user: {
            _id: user._id,
            username: user.username,
            email: user.email,
            firstName: user.firstName,
            lastName: user.lastName,
            lives: user.lives,
            isActive: user.isActive,
            createdAt: user.createdAt,
            updatedAt: user.updatedAt
          },
          token
        }
      });
    } catch (error) {
      res.status(400).json({
        success: false,
        message: error instanceof Error ? error.message : 'Error during login'
      });
    }
  }

  /**
   * Obtener perfil del usuario autenticado
   */
  static async getProfile(req: any, res: Response): Promise<void> {
    try {
      const user = await UserService.getUserById(req.user._id);
      
      if (!user) {
        res.status(404).json({
          success: false,
          message: 'User not found'
        });
        return;
      }

      console.log(`🔍 getProfile - Usuario: ${user.username}, vidas: ${user.lives}`);

      res.json({
        success: true,
        data: user  // Cambiar { user } por user directamente
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        message: error instanceof Error ? error.message : 'Error fetching profile'
      });
    }
  }

  /**
   * Actualizar perfil del usuario
   */
  static async updateProfile(req: any, res: Response): Promise<void> {
    try {
      const updateData: UpdateUserDto = req.body;
      const user = await UserService.updateUser(req.user._id, updateData);
      
      if (!user) {
        res.status(404).json({
          success: false,
          message: 'User not found'
        });
        return;
      }

      res.json({
        success: true,
        message: 'Profile updated successfully',
        data: { user }
      });
    } catch (error) {
      res.status(400).json({
        success: false,
        message: error instanceof Error ? error.message : 'Error updating profile'
      });
    }
  }

  /**
   * Obtener todos los usuarios (admin)
   */
  static async getAllUsers(req: Request, res: Response): Promise<void> {
    try {
      const users = await UserService.getAllUsers();
      
      res.json({
        success: true,
        data: { users }
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        message: error instanceof Error ? error.message : 'Error fetching users'
      });
    }
  }

  /**
   * Obtener usuario por ID
   */
  static async getUserById(req: Request, res: Response): Promise<void> {
    try {
      const { id } = req.params;
      const user = await UserService.getUserById(id);
      
      if (!user) {
        res.status(404).json({
          success: false,
          message: 'User not found'
        });
        return;
      }

      res.json({
        success: true,
        data: { user }
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        message: error instanceof Error ? error.message : 'Error fetching user'
      });
    }
  }

  /**
   * Eliminar usuario
   */
  static async deleteUser(req: any, res: Response): Promise<void> {
    try {
      const success = await UserService.deleteUser(req.user._id);
      
      if (!success) {
        res.status(404).json({
          success: false,
          message: 'User not found'
        });
        return;
      }

      res.json({
        success: true,
        message: 'User deleted successfully'
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        message: error instanceof Error ? error.message : 'Error deleting user'
      });
    }
  }

  /**
   * Obtener ranking global de usuarios
   */
  static async getUserRanking(req: Request, res: Response): Promise<void> {
    try {
      const ranking = await UserService.getUserRanking();
      res.json({ 
        success: true, 
        data: ranking 
      });
    } catch (error) {
      res.status(500).json({ 
        success: false, 
        message: error instanceof Error ? error.message : 'Error obteniendo el ranking' 
      });
    }
  }

}
