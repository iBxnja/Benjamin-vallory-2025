import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/participation_provider.dart';
import '../../models/game.dart';
import '../../models/participation.dart';
import '../../models/match.dart';
import '../../models/prediction.dart';

class PredictionScreen extends StatefulWidget {
  final Game game;
  final Match match;
  final Participation participation;

  const PredictionScreen({
    super.key,
    required this.game,
    required this.match,
    required this.participation,
  });

  @override
  State<PredictionScreen> createState() => _PredictionScreenState();
}

class _PredictionScreenState extends State<PredictionScreen> {
  String? _selectedTeam;
  bool _isSubmitting = false;
  Prediction? _existingPrediction;

  @override
  void initState() {
    super.initState();
    _loadExistingPrediction();
  }

  void _loadExistingPrediction() {
    _existingPrediction = widget.participation.predictions
        .where((p) => p.matchId == widget.match.matchId && p.week == widget.game.currentWeek)
        .firstOrNull;
    
    if (_existingPrediction != null) {
      _selectedTeam = _existingPrediction!.selectedTeam;
    }
  }

  @override
  Widget build(BuildContext context) {
    // VALIDAR SI EL USUARIO PUEDE HACER PREDICCIONES
    final canMakePrediction = widget.participation.livesRemaining > 0 && !widget.participation.isEliminated;
    
    if (!canMakePrediction) {
      return _buildNoLivesScreen();
    }
    final hasExistingPrediction = _existingPrediction != null;
    
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          hasExistingPrediction ? 'Predicción Realizada' : 'Hacer Predicción',
          style: const TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Match info card
            _buildMatchInfoCard(),
            const SizedBox(height: 24),
            
            // Prediction status or options
            if (hasExistingPrediction)
              _buildExistingPredictionCard()
            else
              _buildPredictionOptions(),
            
            const SizedBox(height: 24),
            
            // Submit button (only if no existing prediction)
            if (!hasExistingPrediction)
              _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchInfoCard() {
    return Card(
      color: const Color(0xFF2A2A2A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Partido',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        widget.match.home.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.match.home.flag,
                        style: const TextStyle(fontSize: 32),
                      ),
                    ],
                  ),
                ),
                const Column(
                  children: [
                    Text(
                      'VS',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Fecha',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      'TBD',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        widget.match.visitor.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.match.visitor.flag,
                        style: const TextStyle(fontSize: 32),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('Semana', '${widget.game.currentWeek}'),
                  _buildStatItem('Vidas', '${widget.participation.livesRemaining}'),
                  _buildStatItem('Puntos', '${widget.participation.totalPoints}'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildExistingPredictionCard() {
    // Manejar tanto equipos como empate
    String selectedTeamName;
    String selectedTeamFlag;
    
    if (_existingPrediction!.selectedTeam == 'home') {
      selectedTeamName = widget.match.home.name;
      selectedTeamFlag = widget.match.home.flag;
    } else if (_existingPrediction!.selectedTeam == 'visitor') {
      selectedTeamName = widget.match.visitor.name;
      selectedTeamFlag = widget.match.visitor.flag;
    } else if (_existingPrediction!.selectedTeam == 'draw') {
      selectedTeamName = 'Empate';
      selectedTeamFlag = '🤝';
    } else {
      selectedTeamName = 'Desconocido';
      selectedTeamFlag = '❓';
    }
    
    return Card(
      color: const Color(0xFF2A3A2A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Predicción Realizada',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Show selected team
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.green,
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    selectedTeamFlag,
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      selectedTeamName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.green,
                    size: 16,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            
            // Show prediction details
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildPredictionDetail(
                  'Realizada',
                  _formatDate(_existingPrediction!.createdAt),
                  Icons.schedule,
                ),
                _buildPredictionDetail(
                  'Estado',
                  _existingPrediction!.isCorrect == null 
                      ? 'Pendiente' 
                      : (_existingPrediction!.isCorrect! ? 'Correcta' : 'Incorrecta'),
                  _existingPrediction!.isCorrect == null 
                      ? Icons.hourglass_empty
                      : (_existingPrediction!.isCorrect! ? Icons.check : Icons.close),
                ),
                if (_existingPrediction!.pointsEarned != null)
                  _buildPredictionDetail(
                    'Puntos',
                    '${_existingPrediction!.pointsEarned}',
                    Icons.star,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPredictionDetail(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.green, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildPredictionOptions() {
    return Card(
      color: const Color(0xFF2A2A2A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '¿Quién ganará?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            
            // Home team option
            _buildTeamOption(
              team: widget.match.home,
              isSelected: _selectedTeam == 'home',
              onTap: () => setState(() => _selectedTeam = 'home'),
            ),
            const SizedBox(height: 12),
            
            // Visitor team option
            _buildTeamOption(
              team: widget.match.visitor,
              isSelected: _selectedTeam == 'visitor',
              onTap: () => setState(() => _selectedTeam = 'visitor'),
            ),
            const SizedBox(height: 12),
            
            // Draw option
            _buildDrawOption(
              isSelected: _selectedTeam == 'draw',
              onTap: () => setState(() => _selectedTeam = 'draw'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamOption({
    required dynamic team,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected 
              ? const Color(0xFF4CAF50).withOpacity(0.2)
              : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected 
                ? const Color(0xFF4CAF50)
                : Colors.grey,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected 
                    ? const Color(0xFF4CAF50)
                    : Colors.grey,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                isSelected ? Icons.check : Icons.circle_outlined,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              team.flag,
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                team.name,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.arrow_forward_ios,
                color: Color(0xFF4CAF50),
                size: 16,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawOption({
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected 
              ? Colors.orange.withOpacity(0.2)
              : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected 
                ? Colors.orange
                : Colors.grey,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected 
                    ? Colors.orange
                    : Colors.grey,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                isSelected ? Icons.check : Icons.circle_outlined,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            const Text(
              '🤝',
              style: TextStyle(fontSize: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Empate',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.orange,
                size: 16,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    final canSubmit = _selectedTeam != null && !_isSubmitting;
    
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: canSubmit ? _submitPrediction : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: canSubmit ? const Color(0xFF4CAF50) : Colors.grey,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isSubmitting
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Enviando...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              )
            : const Text(
                'Confirmar Predicción',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Future<void> _submitPrediction() async {
    if (_selectedTeam == null || _isSubmitting) return; // Prevenir múltiples envíos
    
    print('🎯 Enviando predicción: ${_selectedTeam}');
    print('🎯 GameId: ${widget.game.id}');
    print('🎯 Week: ${widget.match.week ?? widget.game.currentWeek}');
    print('🎯 MatchId: ${widget.match.matchId}');

    setState(() => _isSubmitting = true);

    try {
      final participationProvider = Provider.of<ParticipationProvider>(context, listen: false);
      final success = await participationProvider.makePrediction(
        gameId: widget.game.id,
        week: widget.match.week ?? widget.game.currentWeek,
        matchId: widget.match.matchId,
        selectedTeam: _selectedTeam!,
      );

      if (success && mounted) {
        // print('✅ Predicción enviada exitosamente');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Predicción realizada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        // Recargar participaciones para mostrar la nueva predicción
        await participationProvider.loadUserParticipations();
        Navigator.of(context).pop(true); // Retornar true para indicar éxito
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(participationProvider.error ?? 'Error al hacer la predicción'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildNoLivesScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Sin Vidas',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.red.withOpacity(0.1),
                      Colors.grey.withOpacity(0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.red.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.heart_broken,
                      color: Colors.red,
                      size: 80,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Sin Vidas Restantes',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Has sido eliminado del juego.\nNo puedes hacer más predicciones.',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 16,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Vidas restantes: ${widget.participation.livesRemaining}',
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[800],
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  label: const Text(
                    'Volver',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
