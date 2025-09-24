export interface CreateParticipationDto {
  userId: string;
  gameId: string;
}

export interface CreatePredictionDto {
  userId: string;
  gameId: string;
  week: number;
  matchId: string;
  selectedTeam: 'home' | 'visitor';
}

export interface ParticipationResponseDto {
  _id: string;
  userId: {
    _id: string;
    username: string;
    firstName: string;
    lastName: string;
  };
  gameId: {
    _id: string;
    name: string;
    currentWeek: number;
    totalWeeks: number;
  };
  predictions: PredictionResponseDto[];
  livesRemaining: number;
  totalPoints: number;
  isEliminated: boolean;
  eliminationWeek?: number;
  joinedAt: Date;
  lastActivityAt: Date;
  createdAt: Date;
  updatedAt: Date;
}

export interface PredictionResponseDto {
  week: number;
  matchId: string;
  selectedTeam: 'home' | 'visitor';
  isCorrect?: boolean;
  pointsEarned?: number;
  createdAt: Date;
}
