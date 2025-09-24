import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/participation_provider.dart';
import '../../models/game.dart';
import '../../models/participation.dart';

class MyGameDetailScreen extends StatefulWidget {
  final Participation participation;

  const MyGameDetailScreen({super.key, required this.participation});

  @override
  State<MyGameDetailScreen> createState() => _MyGameDetailScreenState();
}

class _MyGameDetailScreenState extends State<MyGameDetailScreen> {
  Participation? _participation;

  @override
  void initState() {
    super.initState();
    _participation = widget.participation;

    // Usar addPostFrameCallback para evitar llamadas durante build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
    });
  }

  Future<void> _refreshData() async {
    if (!mounted) return;

    try {
      final provider = Provider.of<ParticipationProvider>(
        context,
        listen: false,
      );
      await provider.loadUserParticipations();

      if (mounted) {
        setState(() {
          _participation = provider.getParticipationForGame(
            widget.participation.game.id,
          );
        });
      }
    } catch (e) {
      // print('Error refreshing data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final game = _participation?.game ?? widget.participation.game;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(game.name, style: const TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: const Color(0xFFEE9000),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildLeagueCard(game),
              const SizedBox(height: 16),
              _buildMyPredictionsCard(game),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeagueCard(Game game) {
    // Calcular información de predicciones del usuario
    final predictions = _participation?.predictions ?? [];
    final totalPredictions = predictions.length;

    

    return Card(
      color: const Color(0xFF2A2A2A),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.sports_soccer, color: Colors.green, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        game.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                   
                      if (totalPredictions > 0)
                        Text(
                          '$totalPredictions predicción${totalPredictions != 1 ? 'es' : ''}',
                          style: const TextStyle(
                            color: Colors.blue,
                            fontSize: 14,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyPredictionsCard(Game game) {
    if (_participation == null) return const SizedBox.shrink();

    final predictions = _participation!.predictions;

    if (predictions.isEmpty) {
      return Card(
        color: const Color(0xFF2A2A2A),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Icon(Icons.psychology, color: Colors.grey, size: 48),
              const SizedBox(height: 12),
              const Text(
                'No tienes predicciones aún',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
              const Text(
                'Haz tu primera predicción en los partidos disponibles',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    // Agrupar predicciones por jornada
    final predictionsByWeek = <int, List<dynamic>>{};
    for (var prediction in predictions) {
      final week = prediction.week;
      predictionsByWeek.putIfAbsent(week, () => []).add(prediction);
    }
    // print('🔍 Number of weeks with predictions: ${predictionsByWeek.length}');
    // print('🔍 Weeks: ${predictionsByWeek.keys.toList()}');

    return Card(
      color: const Color(0xFF2A2A2A),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.psychology, color: Colors.blue, size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Mis Predicciones',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...predictionsByWeek.entries.map(
              (entry) => _buildWeekSection(entry.key, entry.value, game),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekSection(int week, List<dynamic> predictions, Game game) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header simple de la jornada
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFEE9000),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Jornada $week',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${predictions.length} predicción${predictions.length != 1 ? 'es' : ''}',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Lista de predicciones
          ...predictions.map(
            (prediction) => _buildPredictionCard(prediction, game, week),
          ),
        ],
      ),
    );
  }

  Widget _buildPredictionCard(dynamic prediction, Game game, int week) {
    // Buscar el partido correspondiente
    final match =
        game.competition
            .where(
              (m) =>
                  m.matchId == prediction.matchId.toString() ||
                  m.matchId == prediction.matchId,
            )
            .firstOrNull;

    if (match == null) {
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange.withOpacity(0.3)),
        ),
        child: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange, size: 16),
            SizedBox(width: 8),
            Text(
              'Partido no encontrado',
              style: TextStyle(color: Colors.orange, fontSize: 12),
            ),
          ],
        ),
      );
    }

    // Manejar tanto equipos como empate
    String selectedTeamName;
    String selectedTeamFlag;
    
    if (prediction.selectedTeam == 'home') {
      selectedTeamName = match.home.name;
      selectedTeamFlag = match.home.flag;
    } else if (prediction.selectedTeam == 'visitor') {
      selectedTeamName = match.visitor.name;
      selectedTeamFlag = match.visitor.flag;
    } else if (prediction.selectedTeam == 'draw') {
      selectedTeamName = 'Empate';
      selectedTeamFlag = '🤝';
    } else {
      selectedTeamName = 'Desconocido';
      selectedTeamFlag = '❓';
    }
    final isCorrect = prediction.isCorrect;
    
    // Verificar si el partido ya terminó
    final isMatchFinished = _isMatchFinished(match);
    final shouldShowPending = !isMatchFinished && isCorrect == null;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color:
              isCorrect == null
                  ? Colors.blue.withOpacity(0.3)
                  : (isCorrect
                      ? Colors.green.withOpacity(0.3)
                      : Colors.red.withOpacity(0.3)),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Header con jornada y estado
          Row(
            children: [
              if (isCorrect != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isCorrect ? Icons.check_circle : Icons.cancel,
                      color: isCorrect ? Colors.green : Colors.red,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isCorrect ? 'Correcta' : 'Incorrecta',
                      style: TextStyle(
                        color: isCorrect ? Colors.green : Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                )
              else if (shouldShowPending)
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.hourglass_empty, color: Colors.orange, size: 16),
                    SizedBox(width: 4),
                    Text(
                      'Pendiente',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                )
              else
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.sports_soccer, color: Colors.blue, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'En curso',
                      style: const TextStyle(
                        color: Colors.blue,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 8),
          // Partido
          Row(
            children: [
              Text(match.home.flag, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  match.home.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const Text(
                'VS',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  match.visitor.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 8),
              Text(match.visitor.flag, style: const TextStyle(fontSize: 18)),
            ],
          ),
          const SizedBox(height: 8),
          // Tu predicción
          Row(
            children: [
              const Text(
                'Tu predicción: ',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
              Text(selectedTeamFlag, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  selectedTeamName,
                  style: const TextStyle(
                    color: Colors.blue,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool _isMatchFinished(dynamic match) {
    // Verificar si el partido tiene resultado
    if (match.result != null && match.isFinished == true) {
      return true;
    }
    
    // Verificar si han pasado más de 2 minutos desde que empezó el partido
    final now = DateTime.now();
    final matchTime = match.date;
    final timeSinceMatch = now.difference(matchTime).inMinutes;
    
    return timeSinceMatch >= 2;
  }
}
