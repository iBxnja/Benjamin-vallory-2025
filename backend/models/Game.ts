import mongoose, { Document, Schema } from 'mongoose';

export interface ITeam {
  name: string;
  flag: string;
}

export interface IMatch {
  matchId: string;
  home: ITeam;
  visitor: ITeam;
  date: Date;
  week: number; // Jornada a la que pertenece este partido
  result?: {
    homeScore: number;
    visitorScore: number;
    winner: 'home' | 'visitor' | 'draw';
  };
  isFinished: boolean;
  status: 'pending' | 'in_progress' | 'finished';
  bettingDeadline: Date;
  predictionsProcessed?: boolean;
}

export interface IWeek {
  weekNumber: number;
  name: string; // "Jornada 1", "Jornada 2", etc.
  startDate: Date;
  endDate: Date;
  matches: IMatch[];
  isActive: boolean;
  isCompleted: boolean;
}

export interface IGame extends Document {
  name: string;
  weeks: IWeek[]; // Nuevo: Array de jornadas
  competition: IMatch[]; // Mantener para compatibilidad, pero se llenará desde weeks
  startDate: Date;
  endDate?: Date;
  maxLives: number;
  isActive: boolean;
  currentWeek: number;
  totalWeeks: number;
  maxParticipants: number;
  participantCount: number;
  createdAt: Date;
  updatedAt: Date;
}

const TeamSchema = new Schema({
  name: { type: String, required: true, trim: true },
  flag: { type: String, required: true, trim: true }
});

const MatchSchema = new Schema({
  matchId: { type: String, required: true },
  home: { type: TeamSchema, required: true },
  visitor: { type: TeamSchema, required: true },
  date: { type: Date, required: true },
  week: { type: Number, required: true, min: 1 }, // Jornada
  result: {
    homeScore: { type: Number, min: 0 },
    visitorScore: { type: Number, min: 0 },
    winner: { type: String, enum: ['home', 'visitor', 'draw'] }
  },
  isFinished: { type: Boolean, default: false },
  status: { 
    type: String, 
    enum: ['pending', 'in_progress', 'finished'], 
    default: 'pending' 
  },
  bettingDeadline: { type: Date, required: true },
  predictionsProcessed: { type: Boolean, default: false }
});

const WeekSchema = new Schema({
  weekNumber: { type: Number, required: true, min: 1 },
  name: { type: String, required: true, trim: true },
  startDate: { type: Date, required: true },
  endDate: { type: Date, required: true },
  matches: [MatchSchema],
  isActive: { type: Boolean, default: false },
  isCompleted: { type: Boolean, default: false }
});

const GameSchema: Schema = new mongoose.Schema({
  name: { 
    type: String, 
    required: true, 
    trim: true,
    maxlength: 100
  },
  weeks: [WeekSchema], // Nuevo: Array de jornadas
  competition: [MatchSchema], // Mantener para compatibilidad
  startDate: { 
    type: Date, 
    required: true 
  },
  endDate: { 
    type: Date 
  },
  maxLives: { 
    type: Number, 
    default: 3,
    min: 1,
    max: 10
  },
  isActive: { 
    type: Boolean, 
    default: true 
  },
  currentWeek: { 
    type: Number, 
    default: 1,
    min: 1
  },
  totalWeeks: { 
    type: Number, 
    required: true,
    min: 1
  },
  maxParticipants: { 
    type: Number, 
    required: true, 
    min: 1, 
    default: 20 
  },
  participantCount: { 
    type: Number, 
    default: 0 
  }
}, {
  timestamps: true
});

export default mongoose.model<IGame>('Game', GameSchema);
