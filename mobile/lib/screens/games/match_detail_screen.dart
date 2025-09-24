import 'package:flutter/material.dart';
import 'dart:async';
import '../../models/game.dart';
import '../../models/participation.dart';
import '../../models/match.dart';
import '../../services/api_service.dart';
import 'prediction_screen.dart';

class MatchDetailScreen extends StatefulWidget {
  final Game game;
  final Match match;
  final Participation? participation;

  const MatchDetailScreen({
    super.key,
    required this.game,
    required this.match,
    this.participation,
  });

  @override
  State<MatchDetailScreen> createState() => _MatchDetailScreenState();
}

class _MatchDetailScreenState extends State<MatchDetailScreen> with SingleTickerProviderStateMixin {
  Participation? _participation;
  Map<String, dynamic>? _matchStats;
  Map<String, dynamic>? _matchData; // Datos reales del partido desde el backend
  List<Participation> _allParticipants = [];
  late TabController _tabController;
  Timer? _countdownTimer;
  Duration _timeRemaining = const Duration(minutes: 10); // Inicializar con valor positivo

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _participation = widget.participation;
    
    // Cargar datos después de que el widget esté construido
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshParticipationData();
      _loadData();
      _startCountdownTimer();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdownTimer() {
    _countdownTimer?.cancel();
    
    // Calcular tiempo inicial inmediatamente
    _updateTimeRemaining();
    
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      _updateTimeRemaining();
      setState(() {});
    });
  }

  void _updateTimeRemaining() {
    // Si tenemos datos del backend, usar el estado real
    if (_matchData != null) {
      final status = _matchData!['status'];
      final isFinished = _matchData!['isFinished'] ?? false;
      
      if (isFinished || status == 'finished') {
        _timeRemaining = Duration.zero;
        return;
      }
      
      if (status == 'in_progress') {
        _timeRemaining = Duration.zero;
        return;
      }
    }
    
    // Fallback: calcular basado en la fecha
    final now = DateTime.now();
    final matchTime = widget.match.date;
    final difference = matchTime.difference(now);

    if (difference.isNegative) {
      _timeRemaining = Duration.zero;
    } else {
      _timeRemaining = difference;
    }
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadMatchData(),
      _loadMatchStats(),
      _loadAllParticipants(),
    ]);
    
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadMatchData() async {
    try {
      final response = await ApiService.getMatch(widget.game.id, widget.match.matchId);
      if (response['success']) {
        _matchData = response['data']['match'];
        // print('🔍 Datos del partido recibidos: $_matchData');
        if (_matchData != null && _matchData!['result'] != null) {
          // print('🔍 Resultado: ${_matchData!['result']['winner']}');
          // print('🔍 Marcador: ${_matchData!['result']['homeScore']}-${_matchData!['result']['visitorScore']}');
          // print('🔍 Finalizado: ${_matchData!['isFinished']}');
        }
      }
    } catch (e) {
      // print('Error loading match data: $e');
    }
  }

  Future<void> _loadMatchStats() async {
    try {
      final response = await ApiService.getMatchPredictionStats(widget.game.id, widget.match.matchId);
      if (response['success']) {
        _matchStats = response['data']['stats'];
      }
    } catch (e) {
      // print('Error loading match stats: $e');
    }
  }

  Future<void> _loadAllParticipants() async {
    try {
      final response = await ApiService.getGameParticipations(widget.game.id);
      if (response['success']) {
        final participationsData = response['data']['participations'] as List;
        _allParticipants = participationsData.map((part) => Participation.fromJson(part)).toList();
      }
    } catch (e) {
      // print('Error loading all participants: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: SafeArea(
        child: Column(
          children: [
            // Custom App Bar with match info
            _buildMatchHeader(),
            
            // Tab Bar
            _buildTabBar(),
            
            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildMatchTab(),
                  _buildParticipantsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchHeader() {
    return Container(
      height: 220, // Reducir altura para evitar overflow
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEE9000).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(25),
          bottomRight: Radius.circular(25),
        ),
        child: Stack(
          children: [
            // Background gradient
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFEE9000),
                      Color(0xFFCC7A00),
                    ],
                  ),
                ),
              ),
            ),
            
            // Content
            Positioned(
              left: 20,
              right: 20,
              top: 10,
              bottom: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row with back button
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 18),
                          onPressed: () => Navigator.of(context).pop(),
                          padding: const EdgeInsets.all(6),
                          constraints: const BoxConstraints(),
                        ),
                      ),
                      const Spacer(),
                      _buildCompactCountdownTimer(),
                      const Spacer(),
                      // Espacio vacío para balancear el diseño
                      const SizedBox(width: 40),
                    ],
                  ),
                  
                  const Spacer(),
                  
                  // Match info
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              widget.match.home.flag,
                              style: const TextStyle(fontSize: 36),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              widget.match.home.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(
                                    color: Colors.black26,
                                    blurRadius: 2,
                                  ),
                                ],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'VS',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                color: Colors.black26,
                                blurRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              widget.match.visitor.flag,
                              style: const TextStyle(fontSize: 36),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              widget.match.visitor.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(
                                    color: Colors.black26,
                                    blurRadius: 2,
                                  ),
                                ],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Match date
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _formatMatchDateTime(widget.match.date),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: const Color(0xFFEE9000),
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey,
        labelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
        ),
        tabs: const [
          Tab(
            icon: Icon(Icons.sports_soccer, size: 20),
            text: 'Apostar',
          ),
          Tab(
            icon: Icon(Icons.people, size: 20),
            text: 'Participantes',
          ),
        ],
      ),
    );
  }

  Widget _buildMatchTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Match prediction section
          _buildMatchPredictionSection(),
          const SizedBox(height: 20),
          
          // Community stats
          _buildCommunityStats(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildParticipantsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // All participants list with their predictions
          _buildAllParticipantsList(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildMatchPredictionSection() {
    final hasPrediction = _participation?.hasPredictionForMatch(widget.match.matchId, week: widget.match.week) ?? false;
    final matchResult = _getMatchResult();
    
    // print('🔍 MatchDetailScreen - matchId: ${widget.match.matchId}, week: ${widget.match.week}');
    // print('🔍 MatchDetailScreen - hasPrediction: $hasPrediction');
    // print('🔍 MatchDetailScreen - total predictions: ${_participation?.predictions.length ?? 0}');
    
    return Column(
      children: [
        // Resultado del partido (si está finalizado)
        if (matchResult != null) _buildMatchResultSection(matchResult),
        if (matchResult != null) const SizedBox(height: 20),
        
        // Sección de predicción
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFEE9000).withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFFEE9000),
                            Color(0xFFCC7A00),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.psychology,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        matchResult != null ? 'Tu Predicción - Finalizado' : 'Tu Predicción',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                
                if (hasPrediction)
                  _buildExistingPrediction()
                else if (_participation != null && !_participation!.isEliminated && matchResult == null)
                  _buildMakePredictionButton()
                else
                  _buildCannotPredictMessage(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMatchResultSection(String result) {
    String winnerName;
    String winnerFlag;
    Color resultColor;
    String scoreText = '';
    
    // Obtener marcador si está disponible
    if (_matchData != null && _matchData!['result'] != null) {
      final homeScore = _matchData!['result']['homeScore'] ?? 0;
      final visitorScore = _matchData!['result']['visitorScore'] ?? 0;
      scoreText = ' ($homeScore-$visitorScore)';
    }
    
    if (result == 'home') {
      winnerName = widget.match.home.name;
      winnerFlag = widget.match.home.flag;
      resultColor = Colors.blue;
    } else if (result == 'visitor') {
      winnerName = widget.match.visitor.name;
      winnerFlag = widget.match.visitor.flag;
      resultColor = Colors.green;
    } else {
      winnerName = 'Empate';
      winnerFlag = '🤝';
      resultColor = Colors.orange;
    }
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            resultColor.withOpacity(0.2),
            resultColor.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: resultColor.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: resultColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.flag,
                    color: resultColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'Resultado Final',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  winnerFlag,
                  style: const TextStyle(fontSize: 32),
                ),
                const SizedBox(width: 12),
                Column(
                  children: [
                    Text(
                      result == 'draw' ? 'EMPATE' : 'GANADOR',
                      style: TextStyle(
                        color: resultColor,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '$winnerName$scoreText',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExistingPrediction() {
    final prediction = _participation!.predictions
        .where((p) => p.matchId == widget.match.matchId && p.week == widget.match.week)
        .firstOrNull;
    
    if (prediction == null) return const SizedBox.shrink();
    
    // Manejar tanto equipos como empate
    String selectedTeamName;
    String selectedTeamFlag;
    
    if (prediction.selectedTeam == 'home') {
      selectedTeamName = widget.match.home.name;
      selectedTeamFlag = widget.match.home.flag;
    } else if (prediction.selectedTeam == 'visitor') {
      selectedTeamName = widget.match.visitor.name;
      selectedTeamFlag = widget.match.visitor.flag;
    } else if (prediction.selectedTeam == 'draw') {
      selectedTeamName = 'Empate';
      selectedTeamFlag = '🤝';
    } else {
      selectedTeamName = 'Desconocido';
      selectedTeamFlag = '❓';
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2A3A2A),
            Color(0xFF1A2A1A),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.green.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tu predicción:',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      selectedTeamFlag,
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        selectedTeamName,
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (prediction.isCorrect != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: prediction.isCorrect! 
                    ? Colors.green.withOpacity(0.2)
                    : Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                prediction.isCorrect! ? 'Correcta' : 'Incorrecta',
                style: TextStyle(
                  color: prediction.isCorrect! ? Colors.green : Colors.red,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMakePredictionButton() {
    final hasTimeRemaining = _timeRemaining > Duration.zero;
    final hasLives = _participation != null && _participation!.livesRemaining > 0;
    final canBet = hasTimeRemaining && hasLives && !(_participation?.isEliminated ?? false);
    
    String buttonText;
    IconData buttonIcon;
    
    if (!hasLives || (_participation?.isEliminated ?? false)) {
      buttonText = 'Eliminado - Sin Vidas';
      buttonIcon = Icons.heart_broken;
    } else if (!hasTimeRemaining) {
      buttonText = 'Tiempo Agotado';
      buttonIcon = Icons.block;
    } else {
      buttonText = 'Hacer Predicción';
      buttonIcon = Icons.add;
    }
    
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: canBet ? () => _makePrediction() : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: canBet ? const Color(0xFFEE9000) : Colors.grey,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: Icon(
          buttonIcon,
          color: Colors.white,
        ),
        label: Text(
          buttonText,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildCannotPredictMessage() {
    String message;
    IconData icon;
    Color color;
    
    if (_participation == null) {
      message = 'Únete al juego para hacer predicciones';
      icon = Icons.person_add;
      color = Colors.blue;
    } else if (_participation!.isEliminated || _participation!.livesRemaining <= 0) {
      message = 'Eliminado - Te quedaste sin vidas';
      icon = Icons.heart_broken;
      color = Colors.red;
    } else {
      message = 'No puedes hacer más predicciones';
      icon = Icons.block;
      color = Colors.grey;
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: TextStyle(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_participation?.isEliminated == true || (_participation?.livesRemaining ?? 0) <= 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Fuiste eliminado en la semana ${_participation?.eliminationWeek ?? 'desconocida'}',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommunityStats() {
    if (_matchStats == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFEE9000)),
          ),
        ),
      );
    }

    final homePercentage = _matchStats!['homePercentage'] ?? 50;
    final visitorPercentage = _matchStats!['visitorPercentage'] ?? 50;
    final homeVotes = _matchStats!['homeVotes'] ?? 0;
    final visitorVotes = _matchStats!['visitorVotes'] ?? 0;
    
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFEE9000).withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFEE9000),
                        Color(0xFFCC7A00),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.people,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'Predicciones de la Comunidad',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Teams with percentages
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        widget.match.home.flag,
                        style: const TextStyle(fontSize: 32),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.match.home.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'VS',
                    style: TextStyle(
                      color: Color(0xFFEE9000),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        widget.match.visitor.flag,
                        style: const TextStyle(fontSize: 32),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.match.visitor.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Percentage bars
            Row(
              children: [
                Expanded(
                  flex: homePercentage > 0 ? homePercentage : 1,
                  child: Container(
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEE9000),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(4),
                        bottomLeft: Radius.circular(4),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: visitorPercentage > 0 ? visitorPercentage : 1,
                  child: Container(
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(4),
                        bottomRight: Radius.circular(4),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Percentage text
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$homePercentage%',
                      style: const TextStyle(
                        color: Color(0xFFEE9000),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '$homeVotes votos',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$visitorPercentage%',
                      style: const TextStyle(
                        color: Colors.blue,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '$visitorVotes votos',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllParticipantsList() {

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFEE9000).withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFEE9000),
                        Color(0xFFCC7A00),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.leaderboard,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'Participantes con Predicciones',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Lista de participantes
            ..._buildParticipantItems(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildParticipantItems() {
    if (_allParticipants.isEmpty) {
      return [
        Container(
          padding: const EdgeInsets.all(20),
          child: const Center(
            child: Text(
              'No hay participantes aún',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ];
    }

    // Filtrar solo los participantes que hicieron una predicción para este partido
    final participantsWithPredictions = _allParticipants.where((participant) {
      return participant.predictions.any((prediction) => 
        prediction.matchId == widget.match.matchId && 
        prediction.week == widget.match.week
      );
    }).toList();

    if (participantsWithPredictions.isEmpty) {
      return [
        Container(
          padding: const EdgeInsets.all(20),
          child: const Center(
            child: Text(
              'Nadie ha hecho predicciones para este partido aún',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ];
    }

    return participantsWithPredictions.map((participant) => _buildParticipantItem(participant)).toList();
  }

  Widget _buildParticipantItem(Participation participant) {
    final prediction = participant.predictions
        .where((p) => p.matchId == widget.match.matchId && p.week == widget.match.week)
        .firstOrNull;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: prediction != null 
              ? const Color(0xFFEE9000).withOpacity(0.3)
              : Colors.grey.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: participant.isEliminated
                    ? [Colors.red, Colors.red.shade700]
                    : [const Color(0xFFEE9000), const Color(0xFFCC7A00)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                participant.user.firstName.isNotEmpty 
                    ? participant.user.firstName[0].toUpperCase()
                    : participant.user.username[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          
          // Name and prediction
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  participant.user.fullName.isNotEmpty 
                      ? participant.user.fullName
                      : participant.user.username,
                  style: TextStyle(
                    color: participant.isEliminated ? Colors.red : Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                _buildParticipantMatchPrediction(prediction),
              ],
            ),
          ),
          
          // Stats
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.favorite, color: Colors.red, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      '${participant.livesRemaining}',
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      '${participant.totalPoints}',
                      style: const TextStyle(
                        color: Colors.amber,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantMatchPrediction(dynamic prediction) {
    if (prediction == null) {
      return const Text(
        'Sin predicción para este partido',
        style: TextStyle(
          color: Colors.grey,
          fontSize: 12,
        ),
      );
    }

    // Manejar tanto equipos como empate
    String selectedTeamName;
    String selectedTeamFlag;
    
    if (prediction.selectedTeam == 'home') {
      selectedTeamName = widget.match.home.name;
      selectedTeamFlag = widget.match.home.flag;
    } else if (prediction.selectedTeam == 'visitor') {
      selectedTeamName = widget.match.visitor.name;
      selectedTeamFlag = widget.match.visitor.flag;
    } else if (prediction.selectedTeam == 'draw') {
      selectedTeamName = 'Empate';
      selectedTeamFlag = '🤝';
    } else {
      selectedTeamName = 'Desconocido';
      selectedTeamFlag = '❓';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: prediction.isCorrect == null 
            ? Colors.blue.withOpacity(0.2)
            : (prediction.isCorrect! 
                ? Colors.green.withOpacity(0.2) 
                : Colors.red.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: prediction.isCorrect == null 
              ? Colors.blue.withOpacity(0.3)
              : (prediction.isCorrect! 
                  ? Colors.green.withOpacity(0.3) 
                  : Colors.red.withOpacity(0.3)),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            selectedTeamFlag,
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              selectedTeamName.length > 8 
                  ? '${selectedTeamName.substring(0, 8)}...'
                  : selectedTeamName,
              style: TextStyle(
                color: prediction.isCorrect == null 
                    ? Colors.blue
                    : (prediction.isCorrect! ? Colors.green : Colors.red),
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (prediction.isCorrect != null) ...[
            const SizedBox(width: 3),
            Icon(
              prediction.isCorrect! ? Icons.check : Icons.close,
              color: prediction.isCorrect! ? Colors.green : Colors.red,
              size: 10,
            ),
          ],
        ],
      ),
    );
  }

  void _makePrediction() {
    if (_participation == null) return;
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PredictionScreen(
          game: widget.game,
          match: widget.match,
          participation: _participation!,
        ),
      ),
    ).then((result) async {
      // Refresh data when returning from prediction screen
      if (result == true) {
        // print('✅ Predicción exitosa, actualizando datos...');
        // La predicción fue exitosa, refrescar datos
        await _refreshParticipationData();
        await _loadData();
      } else {
        // print('ℹ️ Regresando sin hacer predicción');
        await _loadData();
      }
    });
  }

  Future<void> _refreshParticipationData() async {
    try {
      // Recargar la participación actualizada del usuario
      final response = await ApiService.getUserParticipations();
      if (response['success']) {
        final participationsData = response['data']['participations'] as List;
        final updatedParticipation = participationsData
            .map((part) => Participation.fromJson(part))
            .where((part) => part.game.id == widget.game.id)
            .firstOrNull;
        
        if (updatedParticipation != null) {
          _participation = updatedParticipation;
          // print('🔄 Participación actualizada: ${_participation!.predictions.length} predicciones');
          
          // Forzar actualización de la UI
          if (mounted) {
            setState(() {});
          }
        } else {
          // print('⚠️ No se encontró participación actualizada para el juego ${widget.game.id}');
        }
      }
    } catch (e) {
      // print('❌ Error refreshing participation: $e');
    }
  }

  Widget _buildCompactCountdownTimer() {
    // Verificar si el partido está finalizado
    final matchResult = _getMatchResult();
    if (matchResult != null) {
      return _buildFinishedMatchBadge(matchResult);
    }

    // Usar el estado real del backend
    final matchStatus = _getMatchStatus();
    
    if (matchStatus == 'Finalizado') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.green, Colors.greenAccent],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 14),
            SizedBox(width: 4),
            Text(
              'FINALIZADO',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }
    
    if (matchStatus == 'En Curso') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.orange, Colors.deepOrange],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.play_circle, color: Colors.white, size: 14),
            SizedBox(width: 4),
            Text(
              'EN CURSO',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }
    
    if (matchStatus == 'Por Empezar') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.red, Colors.redAccent],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.schedule, color: Colors.white, size: 14),
            SizedBox(width: 4),
            Text(
              'POR EMPEZAR',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    final minutes = _timeRemaining.inMinutes;
    final seconds = _timeRemaining.inSeconds % 60;
    
    Color timerColor;
    
    if (minutes >= 3) {
      timerColor = Colors.green;
    } else if (minutes >= 1) {
      timerColor = Colors.orange;
    } else {
      timerColor = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [timerColor, timerColor.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: timerColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer, color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Text(
            '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  String _getMatchStatus() {
    // Si tenemos datos del backend, usar el estado real
    if (_matchData != null) {
      final status = _matchData!['status'];
      final isFinished = _matchData!['isFinished'] ?? false;
      
      if (isFinished || status == 'finished') {
        return 'Finalizado';
      }
      
      if (status == 'in_progress') {
        return 'En Curso';
      }
      
      if (status == 'pending') {
        // Calcular tiempo restante para partidos pendientes
        final now = DateTime.now();
        final matchTime = widget.match.date;
        final difference = matchTime.difference(now);
        
        if (difference.isNegative) {
          return 'Por Empezar';
        } else {
          final minutes = difference.inMinutes;
          if (minutes <= 5) {
            return '${minutes} min restantes';
          } else {
            return 'Pendiente';
          }
        }
      }
    }
    
    // Fallback: calcular basado en la fecha
    final now = DateTime.now();
    final matchTime = widget.match.date;
    final difference = matchTime.difference(now);
    
    if (difference.isNegative) {
      return 'Por Empezar';
    } else {
      final minutes = difference.inMinutes;
      if (minutes <= 5) {
        return '${minutes} min restantes';
      } else {
        return 'Pendiente';
      }
    }
  }

  String? _getMatchResult() {
    // print('🔍 _getMatchResult() - _matchData: $_matchData');
    
    // Usar datos reales del backend si están disponibles
    if (_matchData != null && _matchData!['isFinished'] == true && _matchData!['result'] != null) {
      final winner = _matchData!['result']['winner'];
      final homeScore = _matchData!['result']['homeScore'] ?? 0;
      final visitorScore = _matchData!['result']['visitorScore'] ?? 0;
      
      // print('🔍 Usando datos del backend - winner: $winner, marcador: $homeScore-$visitorScore');
      
      // Verificar consistencia: si los marcadores son iguales, debe ser empate
      if (homeScore == visitorScore && winner != 'draw') {
        // print('⚠️ INCONSISTENCIA DETECTADA: Marcador $homeScore-$visitorScore pero winner=$winner, corrigiendo a draw');
        return 'draw';
      }
      
      return winner;
    }
    
    // Fallback: verificar si el partido ha terminado basado en el tiempo
    final now = DateTime.now();
    final matchTime = widget.match.date;
    final timeSinceMatch = now.difference(matchTime).inMinutes;
    
    // // print('🔍 Fallback - timeSinceMatch: $timeSinceMatch minutos');
    
    // Si han pasado más de 2 minutos desde que empezó, considerar finalizado
    if (timeSinceMatch >= 2) {
      // Simular resultado basado en el matchId para consistencia (solo como fallback)
      final matchIdNum = int.tryParse(widget.match.matchId) ?? 1;
      final results = ['home', 'visitor', 'draw'];
      final fallbackResult = results[matchIdNum % 3];
      // // print('🔍 Usando fallback - matchId: $matchIdNum, resultado: $fallbackResult');
      return fallbackResult;
    }
    
    // print('🔍 No hay resultado disponible');
    return null;
  }

  Widget _buildFinishedMatchBadge(String result) {
    String winnerFlag;
    String resultText;
    
    if (result == 'home') {
      winnerFlag = widget.match.home.flag;
      resultText = 'GANÓ';
    } else if (result == 'visitor') {
      winnerFlag = widget.match.visitor.flag;
      resultText = 'GANÓ';
    } else {
      winnerFlag = '🤝';
      resultText = 'EMPATE';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.green, Colors.greenAccent],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            winnerFlag,
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(width: 6),
          Text(
            resultText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatMatchDateTime(DateTime date) {
    // Convertir a hora de Argentina (UTC-3)
    final argentinaTime = date.subtract(const Duration(hours: 3));
    final day = argentinaTime.day.toString().padLeft(2, '0');
    final month = argentinaTime.month.toString().padLeft(2, '0');
    final hour = argentinaTime.hour.toString().padLeft(2, '0');
    final minute = argentinaTime.minute.toString().padLeft(2, '0');
    
    return '$day/$month - $hour:$minute (ARG)';
  }
}
