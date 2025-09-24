import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/participation_provider.dart';
import '../../models/game.dart';
import '../../models/participation.dart';
import 'match_detail_screen.dart';

class GameDetailScreen extends StatefulWidget {
  final Game game;

  const GameDetailScreen({super.key, required this.game});

  @override
  State<GameDetailScreen> createState() => _GameDetailScreenState();
}

class _GameDetailScreenState extends State<GameDetailScreen> {
  Participation? _participation;
  int _selectedWeek = 1;
  Timer? _refreshTimer;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _loadParticipation();

    // Recargar participaciones después de que el widget esté construido
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshParticipations();
    });

    // Configurar refresh automático cada 30 segundos para actualizar estados de partidos
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _refreshParticipations();
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadParticipation() async {
    final participationProvider = Provider.of<ParticipationProvider>(
      context,
      listen: false,
    );

    _participation = participationProvider.getParticipationForGame(
      widget.game.id,
    );

    setState(() {});
  }

  Future<void> _refreshParticipations() async {
    if (_isRefreshing) return; // Evitar múltiples refreshes simultáneos

    final participationProvider = Provider.of<ParticipationProvider>(
      context,
      listen: false,
    );

    try {
      setState(() {
        _isRefreshing = true;
      });

      // Recargar participaciones del usuario
      await participationProvider.loadUserParticipations();

      // Recargar datos del juego para obtener estados actualizados de partidos
      await participationProvider.loadGameData(widget.game.id);

      _participation = participationProvider.getParticipationForGame(
        widget.game.id,
      );

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      // print('Error refreshing participations: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  Future<void> _joinGame() async {
    final participationProvider = Provider.of<ParticipationProvider>(
      context,
      listen: false,
    );
    final success = await participationProvider.joinGame(widget.game.id);

    if (success && mounted) {
      await _loadParticipation();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Te has unido al juego exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            participationProvider.error ?? 'Error al unirse al juego',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshParticipations,
          color: const Color(0xFFEE9000),
          backgroundColor: const Color(0xFF2A2A2A),
          child: SingleChildScrollView(
            physics:
                const AlwaysScrollableScrollPhysics(), // Permitir pull-to-refresh siempre
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Custom App Bar
                _buildCustomAppBar(),

                // Week selector (full width)
                _buildFullWidthWeekSelector(),

                // Body content
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Participation status
                      if (_participation != null) ...[
                        _buildParticipationCard(),
                        const SizedBox(height: 20),
                      ],

                      // Matches list for selected week
                      _buildAllMatchesList(),
                      const SizedBox(height: 20),

                      // Join game button
                      if (_participation == null && widget.game.isActive)
                        _buildJoinButton(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomAppBar() {
    // Mapear cada liga a una imagen específica
    String getLeagueImage(String gameName) {
      if (gameName.toLowerCase().contains('premier') ||
          gameName.toLowerCase().contains('liga premier')) {
        return 'assets/image1.jpg';
      } else if (gameName.toLowerCase().contains('liga') ||
          gameName.toLowerCase().contains('la liga')) {
        return 'assets/iamge2.jpg';
      } else if (gameName.toLowerCase().contains('champions')) {
        return 'assets/image3.jpeg';
      } else {
        return 'assets/image4.jpg'; // Default
      }
    }

    return Container(
      height: 200,
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
            // Background image
            Positioned.fill(
              child: Image.asset(
                getLeagueImage(widget.game.name),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFEE9000), Color(0xFFCC7A00)],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Gradient overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.4),
                      Colors.black.withOpacity(0.8),
                    ],
                  ),
                ),
              ),
            ),

            // Content
            Positioned(
              left: 20,
              right: 20,
              top: 15,
              bottom: 15,
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
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                            size: 20,
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(),
                        ),
                      ),
                      const Spacer(),
                     
                    ],
                  ),

                  const Spacer(),

                  // League info
                  Text(
                    widget.game.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Stats row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEE9000),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.group,
                              color: Colors.white,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${widget.game.participantCount}/${widget.game.maxParticipants}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Por Penka ✓',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipationCard() {
    if (_participation == null) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors:
              _participation!.isEliminated
                  ? [const Color(0xFF3A2A2A), const Color(0xFF2A1A1A)]
                  : [const Color(0xFF2A3A2A), const Color(0xFF1A2A1A)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              _participation!.isEliminated
                  ? Colors.red.withOpacity(0.3)
                  : Colors.green.withOpacity(0.3),
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
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (_participation!.isEliminated
                            ? Colors.red
                            : Colors.green)
                        .withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _participation!.isEliminated ? Icons.close : Icons.person,
                    color:
                        _participation!.isEliminated
                            ? Colors.red
                            : Colors.green,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _participation!.isEliminated
                            ? 'Eliminado'
                            : 'Participando',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color:
                              _participation!.isEliminated
                                  ? Colors.red
                                  : Colors.green,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _participation!.isEliminated
                            ? 'Eliminado en semana ${_participation!.eliminationWeek}'
                            : '${_participation!.predictions.length} predicciones realizadas',
                        style: const TextStyle(
                          color: Colors.grey,
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

  Widget _buildAllMatchesList() {
    // Filtrar partidos por la jornada seleccionada
    // Si no hay campo week, mostrar todos los partidos para la jornada 1
    final matches =
        widget.game.competition.where((match) {
          // Si el match tiene el campo week, usarlo, sino asumir que pertenece a la jornada 1
          final matchWeek = match.week ?? 1;
          return matchWeek == _selectedWeek;
        }).toList();

    // Si no hay partidos para la jornada seleccionada pero es la jornada 1,
    // mostrar todos los partidos (compatibilidad con datos antiguos)
    if (matches.isEmpty && _selectedWeek == 1) {
      return _buildAllMatchesListFallback();
    }

    if (matches.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: Text(
              'No hay partidos en esta liga',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      );
    }

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
                      colors: [Color(0xFFEE9000), Color(0xFFCC7A00)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.sports_soccer,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'Todos los Partidos',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEE9000).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${matches.length}',
                    style: const TextStyle(
                      color: Color(0xFFEE9000),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...matches.map((match) => _buildMatchCard(match)),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchCard(dynamic match) {
    final hasPrediction =
        _participation?.hasPredictionForMatch(match.matchId) ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              hasPrediction
                  ? const Color(0xFFEE9000).withOpacity(0.5)
                  : Colors.grey.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToMatchDetail(match),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Teams row
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          children: [
                            Text(
                              match.home.flag,
                              style: const TextStyle(fontSize: 32),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              match.home.name,
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
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'VS',
                        style: const TextStyle(
                          color: Color(0xFFEE9000),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          children: [
                            Text(
                              match.visitor.flag,
                              style: const TextStyle(fontSize: 32),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              match.visitor.name,
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
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Match info row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Fecha y hora del partido
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.schedule,
                            color: Colors.blue,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatMatchDateTime(match.date),
                            style: const TextStyle(
                              color: Colors.blue,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Estado de predicción solamente
                    if (hasPrediction)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check, color: Colors.green, size: 14),
                            SizedBox(width: 4),
                            Text(
                              'Predicho',
                              style: TextStyle(
                                color: Colors.green,
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
          ),
        ),
      ),
    );
  }

  Widget _buildJoinButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEE9000), Color(0xFFCC7A00)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: const Color(0xFFEE9000).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _joinGame,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Text(
          'Unirse al Juego',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [Shadow(color: Colors.black26, blurRadius: 2)],
          ),
        ),
      ),
    );
  }

  String _formatMatchDateTime(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$day/$month - $hour:$minute';
  }

  void _navigateToMatchDetail(dynamic match) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder:
                (context) => MatchDetailScreen(
                  game: widget.game,
                  match: match,
                  participation: _participation,
                ),
          ),
        )
        .then((_) {
          // Refresh data when returning
          _refreshParticipations();
        });
  }

  Widget _buildFullWidthWeekSelector() {
    // Obtener número total de jornadas
    final totalWeeks = widget.game.totalWeeks;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          // Título superior
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Seleccionar Jornada',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Carousel de jornadas (ancho completo)
          Container(
            height: 100, // Reducir altura
            padding: const EdgeInsets.symmetric(
              vertical: 12,
            ), // Reducir padding vertical
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: totalWeeks,
              itemBuilder: (context, index) {
                final weekNumber = index + 1;
                final isSelected = _selectedWeek == weekNumber;
                final isCurrent = widget.game.currentWeek == weekNumber;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedWeek = weekNumber;
                    });
                  },
                  child: Container(
                    width: 120, // Ancho fijo para cada jornada
                    margin: const EdgeInsets.only(right: 20),
                    decoration: BoxDecoration(
                      gradient:
                          isSelected
                              ? const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFFEE9000), Color(0xFFCC7A00)],
                              )
                              : LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  const Color(0xFF3A3A3A),
                                  const Color(0xFF3A3A3A),
                                ],
                              ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize:
                          MainAxisSize
                              .min, // Importante: usar solo el espacio necesario
                      children: [
                        Text(
                          'Jornada',
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey[400],
                            fontSize: 11, // Texto más pequeño
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2), // Espacio reducido
                        Text(
                          '$weekNumber',
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white,
                            fontSize: 18, // Número más pequeño
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllMatchesListFallback() {
    // Método fallback para mostrar todos los partidos cuando no hay sistema de jornadas
    final matches = widget.game.competition;

    if (matches.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: Text(
              'No hay partidos en esta liga',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      );
    }

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
                      colors: [Color(0xFFEE9000), Color(0xFFCC7A00)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.sports_soccer,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'Todos los Partidos',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEE9000).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${matches.length}',
                    style: const TextStyle(
                      color: Color(0xFFEE9000),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...matches.map((match) => _buildMatchCard(match)),
          ],
        ),
      ),
    );
  }
}
