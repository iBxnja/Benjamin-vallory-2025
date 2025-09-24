import mongoose, { Document, Schema } from 'mongoose';

export interface INotification extends Document {
  userId: mongoose.Types.ObjectId;
  type: 'prediction_result' | 'game_update' | 'elimination' | 'achievement';
  title: string;
  message: string;
  data?: {
    gameId?: string;
    gameName?: string;
    matchId?: string;
    matchInfo?: string;
    pointsGained?: number;
    livesLost?: number;
    isCorrect?: boolean;
  };
  isRead: boolean;
  createdAt: Date;
  updatedAt: Date;
}

const NotificationSchema: Schema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    index: true
  },
  type: {
    type: String,
    enum: ['prediction_result', 'game_update', 'elimination', 'achievement'],
    required: true
  },
  title: {
    type: String,
    required: true,
    trim: true,
    maxlength: 100
  },
  message: {
    type: String,
    required: true,
    trim: true,
    maxlength: 500
  },
  data: {
    gameId: { type: String },
    gameName: { type: String },
    matchId: { type: String },
    matchInfo: { type: String },
    pointsGained: { type: Number },
    livesLost: { type: Number },
    isCorrect: { type: Boolean }
  },
  isRead: {
    type: Boolean,
    default: false,
    index: true
  }
}, {
  timestamps: true
});

// Índice compuesto para consultas eficientes
NotificationSchema.index({ userId: 1, isRead: 1, createdAt: -1 });

export default mongoose.model<INotification>('Notification', NotificationSchema);
