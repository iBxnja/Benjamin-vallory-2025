import Game from '../models/Game';
import Participation from '../models/Participation';
import { NotificationService } from './NotificationService';
import cron from 'node-cron';

class MatchAutomationService {
  private static instance: MatchAutomationService;
  private scheduledJobs: Map<string, any> = new Map();

  public static getInstance(): MatchAutomationService {
    if (!MatchAutomationService.instance) {
      MatchAutomationService.instance = new MatchAutomationService();
    }
    return MatchAutomationService.instance;
  }

  // Inicializar el sistema de automatización
  public async initialize() {
    console.log('🤖 Inicializando sistema de automatización de partidos...');
    
    // Sincronizar partidos desactualizados al iniciar
    await this.syncAllMatches();
    
    // Migrar vidas de usuarios existentes
    await this.migrateUserLives();
    
    // Verificar partidos cada 10 segundos para mayor precisión
    cron.schedule('*/10 * * * * *', async () => {
      await this.checkMatches();
    });

    // Log de estado de todos los partidos cada 1 minuto
    cron.schedule('0 * * * * *', async () => {
      await this.logMatchStatus();
    });

    console.log('✅ Sistema de automatización iniciado');
  }

  // Migrar vidas de usuarios existentes - FORZAR ACTUALIZACIÓN
  private async migrateUserLives() {
    try {
      console.log('🔄 FORZANDO migración de vidas de usuarios existentes...');
      
      // Importar User aquí para evitar dependencias circulares
      const User = require('../models/User').default;
      const Participation = require('../models/Participation').default;
      
      // Buscar específicamente el usuario Messi para debug
      const messi = await User.findOne({ username: 'messi10' });
      if (messi) {
        console.log(`👤 MESSI ENCONTRADO: vidas en perfil = ${messi.lives}`);
        
        const messiParticipations = await Participation.find({ userId: messi._id });
        console.log(`📊 Participaciones de Messi: ${messiParticipations.length}`);
        
        for (const participation of messiParticipations) {
          console.log(`🔄 Participación ${participation._id}: vidas actuales=${participation.livesRemaining}, vidas del usuario=${messi.lives}`);
          
          // FORZAR la actualización sin condiciones
          participation.livesRemaining = messi.lives;
          
          // Ajustar eliminación según las nuevas vidas
          if (messi.lives <= 0) {
            participation.isEliminated = true;
            participation.eliminationWeek = 1;
          } else {
            participation.isEliminated = false;
            participation.eliminationWeek = undefined;
          }
          
          await participation.save();
          console.log(`✅ MESSI ACTUALIZADO: participación ${participation._id} ahora tiene ${participation.livesRemaining} vidas`);
        }
      } else {
        console.log('❌ Usuario Messi NO encontrado');
      }
      
      // Procesar todos los demás usuarios
      const users = await User.find({});
      let migratedCount = 0;

      for (const user of users) {
        console.log(`👤 Procesando usuario: ${user.username} (vidas en perfil: ${user.lives})`);
        const participations = await Participation.find({ userId: user._id });
        
        for (const participation of participations) {
          const oldLives = participation.livesRemaining;
          const userLives = user.lives || 3;
          
          // SIEMPRE actualizar si es diferente
          if (oldLives !== userLives) {
            participation.livesRemaining = userLives;
            
            // Ajustar estado de eliminación
            if (userLives <= 0) {
              participation.isEliminated = true;
              participation.eliminationWeek = 1;
            } else if (userLives > 0 && participation.isEliminated) {
              participation.isEliminated = false;
              participation.eliminationWeek = undefined;
            }
            
            await participation.save();
            console.log(`✅ Usuario ${user.username}: ${oldLives} → ${userLives} vidas`);
            migratedCount++;
          } else {
            console.log(`⚪ Usuario ${user.username}: ya tiene ${userLives} vidas correctas`);
          }
        }
      }
      
      console.log(`🎉 Migración completada: ${migratedCount} participaciones actualizadas`);
    } catch (error) {
      console.error('❌ Error en migración de vidas:', error);
    }
  }

  // Sincronizar todos los partidos desactualizados
  private async syncAllMatches() {
    try {
      console.log('🔄 Sincronizando partidos desactualizados...');
      const games = await Game.find({ isActive: true });
      const now = new Date();
      let syncedCount = 0;

      for (const game of games) {
        let gameUpdated = false;

        for (const match of game.competition) {
          const matchDate = new Date(match.date);
          const timeDiff = matchDate.getTime() - now.getTime();
          const minutesDiff = Math.floor(timeDiff / (1000 * 60));

          // Si el partido debería haber terminado hace más de 3 minutos pero no está finalizado
          if (minutesDiff <= -3 && !match.isFinished) {
            console.log(`🔄 Sincronizando partido ${match.matchId} (debería haber terminado hace ${Math.abs(minutesDiff)} minutos)`);
            await this.finishMatch(game._id.toString(), match.matchId);
            gameUpdated = true;
            syncedCount++;
          }
          // Si el partido debería estar en curso pero está pendiente
          else if (minutesDiff <= 0 && match.status === 'pending') {
            console.log(`🔄 Sincronizando partido ${match.matchId} (debería estar en curso)`);
            match.status = 'in_progress';
            gameUpdated = true;
            syncedCount++;
          }
        }

        if (gameUpdated) {
          await game.save();
        }
      }

      console.log(`✅ Sincronización completada: ${syncedCount} partidos actualizados`);
    } catch (error) {
      console.error('❌ Error sincronizando partidos:', error);
    }
  }

  // Verificar todos los partidos y actualizar estados
  private async checkMatches() {
    try {
      const games = await Game.find({ isActive: true });
      const now = new Date();

      for (const game of games) {
        let gameUpdated = false;

        for (const match of game.competition) {
          const matchDate = new Date(match.date);
          const timeDiff = matchDate.getTime() - now.getTime();
          const minutesDiff = Math.floor(timeDiff / (1000 * 60));

          // Si el partido debe empezar (llegó la hora de apuestas)
          if (minutesDiff <= 0 && match.status === 'pending') {
            match.status = 'in_progress';
            gameUpdated = true;
            console.log(`⚽ Partido ${match.matchId} cambió a EN CURSO`);

            // Programar finalización del partido en 2 minutos
            setTimeout(async () => {
              await this.finishMatch(game._id.toString(), match.matchId);
            }, 2 * 60 * 1000); // 2 minutos
          }

          // Sincronizar partidos que deberían haber terminado pero no están marcados como finalizados
          if (minutesDiff <= -3 && match.status === 'in_progress' && !match.isFinished) {
            console.log(`🔄 Sincronizando partido ${match.matchId} que debería haber terminado`);
            await this.finishMatch(game._id.toString(), match.matchId);
            gameUpdated = true;
          }
        }

        if (gameUpdated) {
          await game.save();
        }
      }
    } catch (error) {
      console.error('❌ Error verificando partidos:', error);
    }
  }

  // Finalizar partido y generar resultado
  private async finishMatch(gameId: string, matchId: string) {
    try {
      const game = await Game.findById(gameId);
      if (!game) return;

      const match = game.competition.find(m => m.matchId === matchId);
      if (!match) {
        console.log(`⚠️ Partido ${matchId} no encontrado`);
        return;
      }

      // Verificar si ya está finalizado o procesado
      if (match.status === 'finished' || match.isFinished || match.predictionsProcessed) {
        console.log(`⚠️ Partido ${matchId} ya fue finalizado o procesado. Estado: ${match.status}, Finalizado: ${match.isFinished}, Procesado: ${match.predictionsProcessed}`);
        return;
      }

      if (match.status !== 'in_progress') {
        console.log(`⚠️ Partido ${matchId} no está en progreso. Estado: ${match.status}`);
        return;
      }

      // Generar resultado aleatorio con marcadores consistentes
      const outcomes: ('home' | 'visitor' | 'draw')[] = ['home', 'visitor', 'draw'];
      const randomResult = outcomes[Math.floor(Math.random() * outcomes.length)];
      
      // Generar marcadores que sean consistentes con el resultado
      let homeScore: number;
      let visitorScore: number;
      
      if (randomResult === 'home') {
        homeScore = Math.floor(Math.random() * 3) + 1; // 1-3 goles
        visitorScore = Math.floor(Math.random() * homeScore); // Menos goles que home
      } else if (randomResult === 'visitor') {
        visitorScore = Math.floor(Math.random() * 3) + 1; // 1-3 goles
        homeScore = Math.floor(Math.random() * visitorScore); // Menos goles que visitor
      } else { // draw
        homeScore = Math.floor(Math.random() * 4); // 0-3 goles
        visitorScore = homeScore; // Mismo marcador
      }
      
      match.status = 'finished';
      match.result = {
        homeScore: homeScore,
        visitorScore: visitorScore,
        winner: randomResult
      };
      match.isFinished = true;

      await game.save();
      
      console.log(`🏁 Partido ${matchId} finalizado. Resultado: ${randomResult}`);

      // Actualizar predicciones y calcular puntos/vidas
      await this.updateParticipations(gameId, matchId, randomResult, game.currentWeek);

      // Verificar si todos los partidos de la liga han terminado
      await this.checkGameCompletion(gameId);

    } catch (error) {
      console.error(`❌ Error finalizando partido ${matchId}:`, error);
    }
  }

  // Verificar si todos los partidos de una liga han terminado
  private async checkGameCompletion(gameId: string) {
    try {
      const game = await Game.findById(gameId);
      if (!game) return;

      // Verificar si todos los partidos están finalizados
      const allMatchesFinished = game.competition.every(match => match.status === 'finished');
      
      if (allMatchesFinished && game.isActive) {
        game.isActive = false;
        await game.save();
        
        console.log(`🏁 Liga "${game.name}" completada - Todos los partidos finalizados`);
        
        // Determinar ganador de la liga
        await this.determineLeagueWinner(gameId);
      }
    } catch (error) {
      console.error(`❌ Error verificando completitud de liga:`, error);
    }
  }

  // Determinar el ganador de la liga
  private async determineLeagueWinner(gameId: string) {
    try {
      const participations = await Participation.find({ gameId, isEliminated: false })
        .sort({ livesRemaining: -1, totalPoints: -1 });

      if (participations.length > 0) {
        const winner = participations[0];
        console.log(`🏆 Ganador de la liga: Usuario ${winner.userId} con ${winner.livesRemaining} vidas y ${winner.totalPoints} puntos`);
        
        // Aquí podrías agregar lógica adicional como premios, notificaciones, etc.
      } else {
        console.log(`🤷 No hay ganador - Todos los participantes fueron eliminados`);
      }
    } catch (error) {
      console.error(`❌ Error determinando ganador:`, error);
    }
  }

  // Actualizar participaciones basadas en el resultado
  private async updateParticipations(gameId: string, matchId: string, result: string, currentWeek: number) {
    try {
      const game = await Game.findById(gameId);
      if (!game) {
        console.error(`❌ Juego ${gameId} no encontrado`);
        return;
      }

      const match = game.competition.find(m => m.matchId === matchId);
      if (!match) {
        console.error(`❌ Partido ${matchId} no encontrado en juego ${gameId}`);
        return;
      }

      // Verificar si ya se procesaron las predicciones para este partido
      if (match.predictionsProcessed) {
        console.log(`⚠️ Predicciones del partido ${matchId} ya fueron procesadas`);
        return;
      }

      // Marcar el partido como procesado INMEDIATAMENTE para evitar procesamiento duplicado
      match.predictionsProcessed = true;
      await game.save();
      console.log(`🔒 Partido ${matchId} marcado como procesado para evitar duplicados`);

      const participations = await Participation.find({ gameId });

      // Procesar usuarios que hicieron predicciones
      for (const participation of participations) {
        // Buscar TODAS las predicciones para este partido
        const predictions = participation.predictions.filter(
          p => p.matchId === matchId && p.week === currentWeek
        );

        if (predictions.length > 0) {
          // Verificar si el usuario ya está eliminado (no procesar predicciones de eliminados)
          if (participation.isEliminated) {
            console.log(`⏭️ ${participation.userId} - Usuario eliminado, saltando ${predictions.length} predicciones`);
            continue;
          }

          console.log(`🎯 Procesando ${predictions.length} predicción(es) de ${participation.userId} para partido ${matchId}`);

          // Procesar cada predicción individualmente
          let hasCorrectPrediction = false;
          let hasIncorrectPrediction = false;
          let totalPointsEarned = 0;
          let wasEliminated = false;

          for (const prediction of predictions) {
            // Verificar si ya fue procesada esta predicción
            if (prediction.isCorrect !== undefined) {
              console.log(`⚠️ Predicción ${prediction.matchId} ya fue procesada para usuario ${participation.userId}`);
              continue;
            }

            // Verificar si la predicción es correcta
            let isCorrect = false;
            
            if (result === 'draw') {
              isCorrect = prediction.selectedTeam === 'draw';
            } else {
              isCorrect = prediction.selectedTeam === result;
            }
            
            prediction.isCorrect = isCorrect;

            console.log(`🔍 Usuario: ${participation.userId}, Predicción: ${prediction.selectedTeam}, Resultado: ${result}, Correcto: ${isCorrect}`);

            if (isCorrect) {
              hasCorrectPrediction = true;
              totalPointsEarned += 10; // 10 puntos por acierto
              console.log(`✅ ${participation.userId} acertó predicción ${prediction.selectedTeam}: +10 puntos`);
            } else {
              hasIncorrectPrediction = true;
              console.log(`❌ ${participation.userId} falló predicción ${prediction.selectedTeam}`);
            }
          }

          console.log(`🔍 Antes - Vidas: ${participation.livesRemaining}, Puntos: ${participation.totalPoints}`);

          // Aplicar resultados basados en si tuvo predicciones correctas o incorrectas
          if (hasCorrectPrediction) {
            // Si acertó al menos una predicción, sumar puntos
            participation.totalPoints += totalPointsEarned;
            console.log(`✅ ${participation.userId} acertó: +${totalPointsEarned} puntos totales`);
            
            // Crear notificación de predicción correcta
            try {
              await NotificationService.createPredictionResultNotification(
                participation.userId.toString(),
                gameId,
                game.name,
                matchId,
                `${match.home.name} vs ${match.visitor.name}`,
                true,
                totalPointsEarned,
                0
              );
              console.log(`📢 Notificación de predicción correcta enviada a ${participation.userId}`);
            } catch (error) {
              console.error('Error creando notificación de predicción correcta:', error);
            }
          } else if (hasIncorrectPrediction) {
            // Si falló todas las predicciones, restar vida
            if (participation.livesRemaining > 0) {
              participation.livesRemaining -= 1;
              console.log(`❌ ${participation.userId} falló todas las predicciones: -1 vida (${participation.livesRemaining + 1} → ${participation.livesRemaining})`);
            } else {
              console.log(`⚠️ ${participation.userId} falló pero ya tenía 0 vidas`);
            }

            // Si se queda sin vidas, eliminar
            wasEliminated = participation.livesRemaining <= 0;
            if (wasEliminated) {
              participation.isEliminated = true;
              participation.eliminationWeek = currentWeek;
              console.log(`💀 ${participation.userId} eliminado`);
            }

            // Crear notificación de predicción incorrecta
            try {
              await NotificationService.createPredictionResultNotification(
                participation.userId.toString(),
                gameId,
                game.name,
                matchId,
                `${match.home.name} vs ${match.visitor.name}`,
                false,
                0,
                1
              );
              console.log(`📢 Notificación de predicción incorrecta enviada a ${participation.userId}`);
            } catch (error) {
              console.error('Error creando notificación de predicción incorrecta:', error);
            }
            
            // Si fue eliminado, crear notificación adicional de eliminación (SOLO UNA VEZ)
            if (wasEliminated) {
              try {
                await NotificationService.createEliminationNotification(
                  participation.userId.toString(),
                  gameId,
                  game.name,
                  currentWeek
                );
                console.log(`📢 Notificación de eliminación enviada a ${participation.userId}`);
              } catch (error) {
                console.error('Error creando notificación de eliminación:', error);
              }
            }
          }

          // Marcar como modificado explícitamente
          participation.markModified('predictions');
          participation.markModified('livesRemaining');
          participation.markModified('totalPoints');
          participation.markModified('isEliminated');

          const savedParticipation = await participation.save();
          console.log(`💾 Después - Usuario: ${savedParticipation.userId}, Vidas: ${savedParticipation.livesRemaining}, Puntos: ${savedParticipation.totalPoints}`);
        }
      }

      // Procesar usuarios que no hicieron predicción en empate
      if (result === 'draw') {
        for (const participation of participations) {
          // Buscar si tiene predicción para este partido
          const hasPrediction = participation.predictions.some(
            p => p.matchId === matchId && p.week === currentWeek
          );

          if (!hasPrediction) {
            // Si no hizo predicción y hay empate, NO pierde vidas
            console.log(`⚪ ${participation.userId} no hizo predicción en empate: sin penalización (vidas: ${participation.livesRemaining})`);

            // Crear notificación informativa del resultado del partido (sin penalización)
            try {
              await NotificationService.createMatchResultNotification(
                participation.userId.toString(),
                gameId,
                game.name,
                matchId,
                `${match.home.name} vs ${match.visitor.name}`,
                'draw',
                match.home.name,
                match.visitor.name
              );
            } catch (error) {
              console.error('Error creando notificación de resultado en empate:', error);
            }

            // Marcar como modificado explícitamente
            participation.markModified('livesRemaining');
            participation.markModified('isEliminated');

            const savedParticipation = await participation.save();
            console.log(`💾 Después - Usuario: ${savedParticipation.userId}, Vidas: ${savedParticipation.livesRemaining}, Puntos: ${savedParticipation.totalPoints}`);
          }
        }
      }

      console.log(`📊 Participaciones actualizadas para partido ${matchId}`);

      // Enviar notificación de resultado a TODOS los participantes
      await this.notifyMatchResult(gameId, matchId, result, game, match);

    } catch (error) {
      console.error(`❌ Error actualizando participaciones:`, error);
    }
  }

  // Enviar notificación de resultado a TODOS los usuarios registrados
  private async notifyMatchResult(gameId: string, matchId: string, result: string, game: any, match: any) {
    try {
      // Importar User model dinámicamente para evitar dependencias circulares
      const { default: User } = await import('../models/User');
      
      // Obtener TODOS los usuarios registrados en el sistema
      const allUsers = await User.find({}, '_id');
      
      const matchInfo = `${match.home.name} vs ${match.visitor.name}`;
      
      console.log(`📢 Enviando notificación de resultado a ${allUsers.length} usuarios registrados`);

      // Crear notificación para cada usuario
      const notificationPromises = allUsers.map(user => 
        NotificationService.createMatchResultNotification(
          user._id.toString(),
          gameId,
          game.name,
          matchId,
          matchInfo,
          result,
          match.home.name,
          match.visitor.name
        )
      );

      await Promise.all(notificationPromises);
      console.log(`✅ Notificaciones de resultado enviadas para partido ${matchId} a ${allUsers.length} usuarios`);

    } catch (error) {
      console.error(`❌ Error enviando notificaciones de resultado:`, error);
    }
  }

  // Obtener tiempo restante para apostar
  public static getTimeUntilBetting(matchDate: Date): number {
    const now = new Date();
    return Math.max(0, matchDate.getTime() - now.getTime());
  }

  // Verificar si se puede apostar
  public static canBet(matchDate: Date): boolean {
    const now = new Date();
    return matchDate.getTime() > now.getTime();
  }

  // Obtener estado del partido
  public static getMatchStatus(match: any): string {
    const now = new Date();
    const matchDate = new Date(match.date);
    const timeDiff = matchDate.getTime() - now.getTime();
    const minutesDiff = Math.floor(timeDiff / (1000 * 60));

    // Priorizar el estado de la base de datos
    if (match.status === 'finished' || match.isFinished) {
      return 'Finalizado';
    }
    
    if (match.status === 'in_progress') {
      return 'En Curso';
    }
    
    // Si ya pasó el tiempo y no está marcado como terminado, verificar si debería estar en curso
    if (minutesDiff <= 0) {
      // Si ya pasó el tiempo de inicio pero no está en curso, debería estar "Por Empezar"
      return 'Por Empezar';
    }
    
    if (minutesDiff <= 5) {
      return `${minutesDiff} min restantes`;
    }
    
    return 'Pendiente';
  }

  // Log de estado de todos los partidos (cada 1 minuto)
  private async logMatchStatus() {
    try {
      const now = new Date();
      const games = await Game.find({ isActive: true });
      
      console.log('\n📊 ===== ESTADO DE PARTIDOS =====');
      console.log(`🕐 Hora actual: ${now.toLocaleString('es-AR', { timeZone: 'America/Argentina/Buenos_Aires' })}\n`);

      for (const game of games) {
        console.log(`🏟️ Liga: ${game.name}`);
        console.log(`📅 Jornada actual: ${game.currentWeek}/${game.totalWeeks}`);
        
        let pendingCount = 0;
        let inProgressCount = 0;
        let finishedCount = 0;

        for (const match of game.competition) {
          const timeUntilMatch = match.date.getTime() - now.getTime();
          const minutesRemaining = Math.max(0, Math.floor(timeUntilMatch / (60 * 1000)));
          const secondsRemaining = Math.max(0, Math.floor((timeUntilMatch % (60 * 1000)) / 1000));
          
          let statusText = '';
          let timeText = '';
          
          switch (match.status) {
            case 'pending':
              pendingCount++;
              if (timeUntilMatch > 0) {
                timeText = `faltan ${minutesRemaining}:${secondsRemaining.toString().padStart(2, '0')}`;
                statusText = '⏳';
              } else {
                timeText = 'debe iniciar pronto';
                statusText = '🔄';
              }
              break;
            case 'in_progress':
              inProgressCount++;
              statusText = '🔥';
              timeText = 'EN CURSO';
              break;
            case 'finished':
              finishedCount++;
              statusText = '✅';
              const result = match.result;
              if (result) {
                const winner = result.homeScore > result.visitorScore ? match.home.name :
                             result.visitorScore > result.homeScore ? match.visitor.name : 'Empate';
                timeText = `${winner} (${result.homeScore}-${result.visitorScore})`;
              } else {
                timeText = 'FINALIZADO';
              }
              break;
            default:
              statusText = '❓';
              timeText = 'estado desconocido';
          }
          
          console.log(`   ${statusText} Partido ${match.matchId}: ${match.home.name} vs ${match.visitor.name} - ${timeText}`);
        }
        
        console.log(`   📈 Resumen: ${pendingCount} pendientes, ${inProgressCount} en curso, ${finishedCount} finalizados`);
        console.log(''); // Línea en blanco entre ligas
      }
      
      console.log('📊 ===========================\n');

    } catch (error) {
      console.error('❌ Error logging match status:', error);
    }
  }
}

export default MatchAutomationService;
