import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _totalPoints = 0;
  int _totalGames = 0;
  int _currentLives = 3;
  bool _isLoadingStats = true;
  List<dynamic> _ranking = [];
  bool _isLoadingRanking = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserStats();
    _loadRanking();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserStats() async {
    try {
      // print('🔍 Iniciando _loadUserStats...');
      final response = await ApiService.getUserParticipations();
      // print('🔍 Respuesta completa: $response');
      
      if (response['success']) {
        final participationsData = response['data']['participations'] as List;
        // print('🔍 Datos de participaciones: $participationsData');

        _totalPoints = 0;
        _totalGames = participationsData.length;
        
        // OBTENER LAS VIDAS DEL USUARIO DIRECTAMENTE DEL AUTHPROVIDER
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final userLives = authProvider.user?.lives ?? 3;
        _currentLives = userLives; // Usar las vidas del perfil del usuario
        
        // print('🔍 Vidas del usuario desde AuthProvider: $userLives');

        int minLives = userLives; // Empezar con las vidas del usuario
        bool hasParticipations = false;

        for (var participationData in participationsData) {
          // print('🔍 Procesando participación: $participationData');
          _totalPoints += (participationData['totalPoints'] as int? ?? 0);

          // Tomar las vidas mínimas de TODAS las participaciones (incluso eliminadas)
          final livesRemaining =
              participationData['livesRemaining'] as int? ?? userLives;
          final isEliminated =
              participationData['isEliminated'] as bool? ?? false;

          // print('🔍 livesRemaining: $livesRemaining, isEliminated: $isEliminated');

          hasParticipations = true;

          // Si está eliminado, tiene 0 vidas
          if (isEliminated) {
            minLives = 0;
            // print('🔍 Usuario eliminado, minLives = 0');
          } else if (livesRemaining < minLives) {
            minLives = livesRemaining;
            // print('🔍 Nuevo minLives: $minLives');
          }
        }

        // Si tiene participaciones, usar las vidas mínimas de las participaciones
        // Si no tiene participaciones, usar las vidas del perfil del usuario
        if (hasParticipations) {
          _currentLives = minLives;
          // print('🔍 Usando vidas de participaciones: $minLives');
        } else {
          _currentLives = userLives;
          // print('🔍 Usando vidas del perfil del usuario: $userLives');
        }

        // print('🔍 === RESULTADO FINAL ===');
        // print('🔍 Vidas calculadas para mostrar: $_currentLives');
        // print('🔍 Total participaciones: ${participationsData.length}');
        // print('🔍 minLives calculado: $minLives');
        
        for (var i = 0; i < participationsData.length; i++) {
          var p = participationsData[i];
          // print('🔍 Participación $i: vidas=${p['livesRemaining']}, eliminado=${p['isEliminated']}, gameId=${p['gameId']}');
        }
        // print('🔍 ======================');

        if (mounted) {
          setState(() {
            _isLoadingStats = false;
          });
        }
      } else {
        // print('🔍 Error en respuesta: ${response['message']}');
      }
    } catch (e) {
      // print('Error loading user stats: $e');
      if (mounted) {
        setState(() {
          _isLoadingStats = false;
        });
      }
    }
  }

  Future<void> _loadRanking() async {
    try {
      final response = await ApiService.getUserRanking();
      if (response['success']) {
        _ranking = response['data'] as List;
        if (mounted) {
          setState(() {
            _isLoadingRanking = false;
          });
        }
      }
    } catch (e) {
      // print('Error loading ranking: $e');
      if (mounted) {
        setState(() {
          _isLoadingRanking = false;
        });
      }
    }
  }

  Future<void> _refreshProfile() async {
    // print('🔄 Iniciando refresh del perfil...');
    
    setState(() {
      _isLoadingStats = true;
      _isLoadingRanking = true;
    });

    try {
      // Cargar datos en paralelo
      await Future.wait([_loadUserStats(), _loadRanking()]);

      // También refrescar datos del usuario
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.refreshUser();
      
      // print('✅ Refresh completado');
    } catch (e) {
      // print('❌ Error en refresh: $e');
      
      // Asegurar que los estados de carga se reseteen incluso si hay error
      if (mounted) {
        setState(() {
          _isLoadingStats = false;
          _isLoadingRanking = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (authProvider.user == null) {
          return const Scaffold(
            backgroundColor: Color(0xFF1A1A1A),
            body: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFEE9000)),
              ),
            ),
          );
        }

        final user = authProvider.user!;

        return Scaffold(
          backgroundColor: const Color(0xFF1A1A1A),
          appBar: AppBar(
            backgroundColor: const Color(0xFF1A1A1A),
            elevation: 0,
            title: const Text(
              'Perfil',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFFEE9000),
              indicatorWeight: 3,
              labelColor: const Color(0xFFEE9000),
              unselectedLabelColor: Colors.grey,
              labelStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.normal,
              ),
              tabs: const [
                Tab(icon: Icon(Icons.person), text: 'Mi Perfil'),
                Tab(icon: Icon(Icons.leaderboard), text: 'Ranking'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              // Tab 1: Mi Perfil
              RefreshIndicator(
                onRefresh: _refreshProfile,
                color: const Color(0xFFEE9000),
                backgroundColor: const Color(0xFF2A2A2A),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Simple profile header
                      _buildSimpleProfileHeader(user, context),
                      const SizedBox(height: 30),

                      // Stats cards
                      _buildStatsCards(user),
                      const SizedBox(height: 30),

                      // Menu options
                      _buildMenuOptions(context, authProvider),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),

              // Tab 2: Ranking
              RefreshIndicator(
                onRefresh: _refreshProfile,
                color: const Color(0xFFEE9000),
                backgroundColor: const Color(0xFF2A2A2A),
                child: _buildRankingTab(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSimpleProfileHeader(dynamic user, BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEE9000), Color(0xFFCC7A00)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          // Avatar
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(50),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 3,
              ),
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 50),
          ),
          const SizedBox(height: 16),

          // User name
          Text(
            user.fullName.isNotEmpty ? user.fullName : user.username,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // Username
          Text(
            '@${user.username}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),

          // Email
          Text(
            user.email,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          const SizedBox(height: 16),

          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  user.isActive ? Icons.check_circle : Icons.cancel,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  user.isActive ? 'Usuario Activo' : 'Usuario Inactivo',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards(dynamic user) {
    return Column(
      children: [
        // Primera fila
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: _currentLives <= 0 ? Icons.heart_broken : Icons.favorite,
                label: 'Vidas Actuales',
                value: _isLoadingStats ? '...' : '$_currentLives',
                color: _currentLives <= 0 ? Colors.grey : Colors.red,
                isLoading: _isLoadingStats,
                isEliminated: _currentLives <= 0,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                icon: Icons.star,
                label: 'Puntos Totales',
                value: _isLoadingStats ? '...' : '$_totalPoints',
                color: Colors.amber,
                isLoading: _isLoadingStats,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Segunda fila
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.sports_soccer,
                label: 'Ligas',
                value: _isLoadingStats ? '...' : '$_totalGames',
                color: const Color(0xFFEE9000),
                isLoading: _isLoadingStats,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                icon: Icons.calendar_today,
                label: 'Miembro desde',
                value: _formatDate(user.createdAt),
                color: Colors.blue,
                isLoading: false,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    bool isLoading = false,
    bool isEliminated = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 12),

          // Value with loading state
          isLoading
              ? SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  strokeWidth: 2,
                ),
              )
              : Column(
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      color: isEliminated ? Colors.grey : Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (isEliminated) ...[
                    const SizedBox(height: 4),
                    Text(
                      'ELIMINADO',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuOptions(BuildContext context, AuthProvider authProvider) {
    return Column(
      children: [
        // Help
        _buildMenuCard(
          icon: Icons.help_outline,
          title: 'Ayuda',
          subtitle: 'Aprende cómo jugar Survivor',
          onTap: () => _showHelpDialog(context),
          color: Colors.blue,
        ),
        const SizedBox(height: 16),

        // Logout
        _buildMenuCard(
          icon: Icons.logout,
          title: 'Cerrar Sesión',
          subtitle: 'Salir de tu cuenta',
          onTap: () => _showLogoutDialog(context, authProvider),
          color: Colors.red,
          isDestructive: true,
        ),
      ],
    );
  }

  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color color,
    bool isDestructive = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: isDestructive ? Colors.red : Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF2A2A2A), Color(0xFF1A1A1A)],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.blue.withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.help_outline,
                            color: Colors.blue,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Text(
                            '¿Cómo jugar?',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    const Text(
                      'Survivor es un juego de predicciones deportivas donde debes sobrevivir el mayor tiempo posible eligiendo equipos ganadores.\n\n• Cada predicción incorrecta te quita una vida\n• Si te quedas sin vidas, quedas eliminado\n• El último jugador en pie gana',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Entendido',
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
          ),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFF2A2A2A),
            title: const Text(
              'Cerrar Sesión',
              style: TextStyle(color: Colors.white),
            ),
            content: const Text(
              '¿Estás seguro de que quieres cerrar sesión?',
              style: TextStyle(color: Colors.grey),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await authProvider.logout();
                  if (context.mounted) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                    );
                  }
                },
                child: const Text(
                  'Cerrar Sesión',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildRankingTab() {
    if (_isLoadingRanking) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFEE9000)),
        ),
      );
    }

    if (_ranking.isEmpty) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.leaderboard_outlined, color: Colors.grey[600], size: 64),
                const SizedBox(height: 16),
                Text(
                  'No hay datos de ranking',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Los usuarios aparecerán aquí cuando\nempiecen a jugar',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _ranking.length,
      itemBuilder: (context, index) {
        final user = _ranking[index];
        return _buildRankingItem(user, index);
      },
    );
  }

  Widget _buildRankingItem(dynamic user, int index) {
    final position = user['position'] ?? (index + 1);
    final isTop3 =
        position <= 3 &&
        user['currentLives'] > 0; // Solo top 3 si no está eliminado
    final isEliminated = user['currentLives'] == 0;

    Color positionColor;
    IconData positionIcon;

    if (isEliminated) {
      positionColor = Colors.red;
      positionIcon = Icons.close;
    } else {
      switch (position) {
        case 1:
          positionColor = const Color(0xFFFFD700); // Gold
          positionIcon = Icons.emoji_events;
          break;
        case 2:
          positionColor = const Color(0xFFC0C0C0); // Silver
          positionIcon = Icons.emoji_events;
          break;
        case 3:
          positionColor = const Color(0xFFCD7F32); // Bronze
          positionIcon = Icons.emoji_events;
          break;
        default:
          positionColor = Colors.grey;
          positionIcon = Icons.person;
          break;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient:
            isEliminated
                ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.red.withOpacity(0.1),
                    Colors.grey.withOpacity(0.2),
                  ],
                )
                : isTop3
                ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    positionColor.withOpacity(0.1),
                    positionColor.withOpacity(0.05),
                  ],
                )
                : null,
        color: (isTop3 || isEliminated) ? null : const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(16),
        border:
            isEliminated
                ? Border.all(color: Colors.red.withOpacity(0.4), width: 1)
                : isTop3
                ? Border.all(color: positionColor.withOpacity(0.3), width: 1)
                : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Position badge
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: positionColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: positionColor.withOpacity(0.5),
                  width: 2,
                ),
              ),
              child:
                  isEliminated
                      ? Icon(Icons.close, color: Colors.red, size: 24)
                      : isTop3
                      ? Icon(positionIcon, color: positionColor, size: 24)
                      : Center(
                        child: Text(
                          '$position',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
            ),
            const SizedBox(width: 16),

            // User info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          user['fullName']?.isNotEmpty == true
                              ? user['fullName']
                              : user['username'] ?? 'Usuario',
                          style: TextStyle(
                            color: isEliminated ? Colors.grey : Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isEliminated)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.red.withOpacity(0.8),
                                Colors.red.withOpacity(0.6),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.red, width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withOpacity(0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.close, color: Colors.white, size: 12),
                              SizedBox(width: 4),
                              Text(
                                'ELIMINADO',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '@${user['username'] ?? 'username'}',
                    style: TextStyle(color: Colors.grey[400], fontSize: 14),
                  ),
                ],
              ),
            ),

            // Stats
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      user['currentLives'] > 0
                          ? Icons.favorite
                          : Icons.heart_broken,
                      color:
                          user['currentLives'] > 0 ? Colors.red : Colors.grey,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${user['currentLives'] ?? 0}',
                      style: TextStyle(
                        color:
                            user['currentLives'] > 0 ? Colors.red : Colors.grey,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${user['totalPoints'] ?? 0}',
                      style: const TextStyle(
                        color: Colors.amber,
                        fontSize: 14,
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
}
