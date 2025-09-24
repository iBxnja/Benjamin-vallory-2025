import mongoose, { Document, Schema } from 'mongoose';

export interface IPrediction {
  week: number;
  matchId: string;
  selectedTeam: 'home' | 'visitor' | 'draw';
  isCorrect?: boolean;
  pointsEarned?: number;
  createdAt: Date;
}

export interface IParticipation extends Document {
  userId: mongoose.Types.ObjectId;
  gameId: mongoose.Types.ObjectId;
  predictions: IPrediction[];
  livesRemaining: number;
  totalPoints: number;
  isEliminated: boolean;
  eliminationWeek?: number;
  joinedAt: Date;
  lastActivityAt: Date;
  createdAt: Date;
  updatedAt: Date;
}

const PredictionSchema = new Schema({
  week: { type: Number, required: true, min: 1 },
  matchId: { type: String, required: true },
  selectedTeam: { 
    type: String, 
    required: true, 
    enum: ['home', 'visitor', 'draw'] 
  },
  isCorrect: { type: Boolean },
  pointsEarned: { type: Number, default: 0 },
  createdAt: { type: Date, default: Date.now }
});

const ParticipationSchema: Schema = new mongoose.Schema({
  userId: { 
    type: Schema.Types.ObjectId, 
    ref: 'User', 
    required: true 
  },
  gameId: { 
    type: Schema.Types.ObjectId, 
    ref: 'Game', 
    required: true 
  },
  predictions: [PredictionSchema],
  livesRemaining: { 
    type: Number, 
    required: true, 
    min: 0 
  },
  totalPoints: { 
    type: Number, 
    default: 0,
    min: 0
  },
  isEliminated: { 
    type: Boolean, 
    default: false 
  },
  eliminationWeek: { 
    type: Number 
  },
  joinedAt: { 
    type: Date, 
    default: Date.now 
  },
  lastActivityAt: { 
    type: Date, 
    default: Date.now 
  }
}, {
  timestamps: true
});

// Indexes for better performance
ParticipationSchema.index({ userId: 1, gameId: 1 }, { unique: true });
ParticipationSchema.index({ gameId: 1, isEliminated: 1 });
ParticipationSchema.index({ userId: 1, isEliminated: 1 });

export default mongoose.model<IParticipation>('Participation', ParticipationSchema);
