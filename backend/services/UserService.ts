import User, { IUser } from '../models/User';
import { CreateUserDto, UpdateUserDto, LoginDto } from '../types/dto/UserDto';

export class UserService {
  /**
   * Crear un nuevo usuario
   */
  static async createUser(userData: CreateUserDto): Promise<IUser> {
    try {
      const user = new User(userData);
      await user.save();
      return user as IUser;
    } catch (error) {
      throw new Error(`Error creating user: ${error}`);
    }
  }

  /**
   * Obtener usuario por ID
   */
  static async getUserById(userId: string): Promise<IUser | null> {
    try {
      const user = await User.findById(userId).select('-password');
      return user as IUser | null;
    } catch (error) {
      throw new Error(`Error fetching user: ${error}`);
    }
  }

  /**
   * Obtener usuario por email
   */
  static async getUserByEmail(email: string): Promise<IUser | null> {
    try {
      const user = await User.findOne({ email }).select('+password');
      return user as IUser | null;
    } catch (error) {
      throw new Error(`Error fetching user by email: ${error}`);
    }
  }

  /**
   * Obtener usuario por username
   */
  static async getUserByUsername(username: string): Promise<IUser | null> {
    try {
      const user = await User.findOne({ username }).select('+password');
      return user as IUser | null;
    } catch (error) {
      throw new Error(`Error fetching user by username: ${error}`);
    }
  }

  /**
   * Actualizar usuario
   */
  static async updateUser(userId: string, userData: UpdateUserDto): Promise<IUser | null> {
    try {
      const user = await User.findByIdAndUpdate(
        userId,
        { ...userData, updatedAt: new Date() },
        { new: true, runValidators: true }
      ).select('-password');
      
      return user as IUser | null;
    } catch (error) {
      throw new Error(`Error updating user: ${error}`);
    }
  }

  /**
   * Eliminar usuario (soft delete)
   */
  static async deleteUser(userId: string): Promise<boolean> {
    try {
      const result = await User.findByIdAndUpdate(
        userId,
        { isActive: false, updatedAt: new Date() },
        { new: true }
      );
      
      return !!result;
    } catch (error) {
      throw new Error(`Error deleting user: ${error}`);
    }
  }

  /**
   * Verificar credenciales de login
   */
  static async validateCredentials(loginData: LoginDto): Promise<IUser | null> {
    try {
      const user = await User.findOne({
        $or: [
          { email: loginData.emailOrUsername },
          { username: loginData.emailOrUsername }
        ]
      }).select('+password');

      if (!user || !user.isActive) {
        return null;
      }

      const isPasswordValid = await user.comparePassword(loginData.password);
      return isPasswordValid ? (user as IUser) : null;
    } catch (error) {
      throw new Error(`Error validating credentials: ${error}`);
    }
  }

  /**
   * Obtener todos los usuarios activos
   */
  static async getAllUsers(): Promise<IUser[]> {
    try {
      const users = await User.find({ isActive: true }).select('-password');
      return users as IUser[];
    } catch (error) {
      throw new Error(`Error fetching all users: ${error}`);
    }
  }

  /**
   * Actualizar vidas del usuario
   */
  static async updateUserLives(userId: string, lives: number): Promise<IUser | null> {
    try {
      const user = await User.findByIdAndUpdate(
        userId,
        { lives, updatedAt: new Date() },
        { new: true }
      ).select('-password');
      
      return user as IUser | null;
    } catch (error) {
      throw new Error(`Error updating user lives: ${error}`);
    }
  }

  /**
   * Obtener ranking global de usuarios basado en sus participaciones
   */
  static async getUserRanking(): Promise<any[]> {
    try {
      // Importar aquí para evitar dependencias circulares
      const Participation = require('../models/Participation').default;
      
      // Agregación para calcular estadísticas por usuario
      const ranking = await Participation.aggregate([
        {
          $group: {
            _id: '$userId',
            totalPoints: { $sum: '$totalPoints' },
            totalGames: { $sum: 1 },
            minLives: { $min: '$livesRemaining' },
            isEliminated: { $max: '$isEliminated' }, // Si alguna participación está eliminada
            maxWeekSurvived: { $max: '$currentWeek' }
          }
        },
        {
          $lookup: {
            from: 'users',
            localField: '_id',
            foreignField: '_id',
            as: 'userInfo'
          }
        },
        {
          $unwind: '$userInfo'
        },
        {
          $addFields: {
            currentLives: {
              $cond: {
                if: '$isEliminated',
                then: 0,
                else: '$minLives'
              }
            }
          }
        },
        {
          $project: {
            _id: 0,
            userId: '$_id',
            username: '$userInfo.username',
            firstName: '$userInfo.firstName',
            lastName: '$userInfo.lastName',
            fullName: {
              $concat: ['$userInfo.firstName', ' ', '$userInfo.lastName']
            },
            totalPoints: 1,
            totalGames: 1,
            currentLives: 1,
            isEliminated: 1,
            maxWeekSurvived: 1,
            createdAt: '$userInfo.createdAt'
          }
        },
        {
          $sort: {
            currentLives: -1,       // Primero por vidas (descendente)
            totalPoints: -1,        // Luego por puntos (descendente)
            maxWeekSurvived: -1,    // Luego por semanas sobrevividas
            createdAt: 1            // Finalmente por antigüedad (ascendente)
          }
        }
      ]);

      // Si no hay participaciones, devolver lista vacía
      if (ranking.length === 0) {
        return [];
      }

      // Agregar posición en el ranking
      return ranking.map((user: any, index: number) => ({
        ...user,
        position: index + 1
      }));

    } catch (error) {
      throw new Error(`Error getting user ranking: ${error}`);
    }
  }
}