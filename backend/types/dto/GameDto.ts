import { IMatch } from '../../models/Game';

export interface CreateGameDto {
  name: string;
  competition: IMatch[];
  startDate: Date;
  endDate?: Date;
  maxLives: number;
  totalWeeks: number;
}

export interface UpdateGameDto {
  name?: string;
  isActive?: boolean;
  currentWeek?: number;
  endDate?: Date;
}

export interface GameResponseDto {
  _id: string;
  name: string;
  competition: IMatch[];
  startDate: Date;
  endDate?: Date;
  maxLives: number;
  isActive: boolean;
  currentWeek: number;
  totalWeeks: number;
  createdAt: Date;
  updatedAt: Date;
}

export interface MatchResultDto {
  homeScore: number;
  visitorScore: number;
}
