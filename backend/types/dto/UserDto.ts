export interface CreateUserDto {
  username: string;
  email: string;
  password: string;
  firstName: string;
  lastName: string;
}

export interface UpdateUserDto {
  firstName?: string;
  lastName?: string;
  email?: string;
  lives?: number;
}

export interface LoginDto {
  emailOrUsername: string;
  password: string;
}

export interface UserResponseDto {
  _id: string;
  username: string;
  email: string;
  firstName: string;
  lastName: string;
  lives: number;
  isActive: boolean;
  createdAt: Date;
  updatedAt: Date;
}

export interface AuthResponseDto {
  user: UserResponseDto;
  token: string;
}
