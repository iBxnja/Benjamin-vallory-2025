import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/game_provider.dart';
import '../../providers/participation_provider.dart';
import '../../providers/banner_provider.dart';
import '../../services/api_service.dart';
import '../games/game_detail_screen.dart';
import '../games/my_game_detail_screen.dart';
import '../profile/profile_screen.dart';
import '../notifications/notifications_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  int _unreadCount = 0;
  Timer? _notificationTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
    
    // Configurar refresh automático de notificaciones cada 30 segundos
    _notificationTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _loadUnreadCount();
      }
    });
  }

  @override
  void dispose() {
    _notificationTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    final participationProvider = Provider.of<ParticipationProvider>(context, listen: false);
    final bannerProvider = Provider.of<BannerProvider>(context, listen: false);
    
    await Future.wait([
      gameProvider.loadGames(),
      participationProvider.loadUserParticipations(),
      bannerProvider.loadBanners(),
      _loadUnreadCount(),
    ]);
  }

  Future<void> _loadUnreadCount() async {
    try {
      final response = await ApiService.getUnreadNotificationsCount();
      if (response['success']) {
        final newCount = response['data']['unreadCount'] ?? 0;
        // print('📱 Notificaciones no leídas: $newCount (anterior: $_unreadCount)');
        setState(() {
          _unreadCount = newCount;
        });
      }
    } catch (e) {
      // print('Error loading unread count: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          Stack(
            children: [
              IconButton(
                onPressed: () async {
                  final result = await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const NotificationsScreen(),
                    ),
                  );
                  if (result == true) {
                    _loadUnreadCount(); // Refresh count when returning
                  }
                },
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              if (_unreadCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFFEE9000),
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 20,
                      minHeight: 20,
                    ),
                    child: Text(
                      _unreadCount > 99 ? '99+' : _unreadCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: const [
            _GamesTab(),
            _MyGamesTab(),
            _ProfileTab(),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF2A2A2A),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTabItem(
                  icon: Icons.sports_soccer,
                  label: 'Juegos',
                  index: 0,
                  isSelected: _currentIndex == 0,
                ),
                _buildTabItem(
                  icon: Icons.games,
                  label: 'Mis Juegos',
                  index: 1,
                  isSelected: _currentIndex == 1,
                ),
                _buildTabItem(
                  icon: Icons.person,
                  label: 'Perfil',
                  index: 2,
                  isSelected: _currentIndex == 2,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabItem({
    required IconData icon,
    required String label,
    required int index,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? const Color(0xFFFF9800).withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: isSelected 
              ? Border.all(color: const Color(0xFFFF9800), width: 1)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFFFF9800) : Colors.grey,
              size: 24,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFFFF9800),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _GamesTab extends StatelessWidget {
  const _GamesTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, gameProvider, child) {
        if (gameProvider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
            ),
          );
        }

        if (gameProvider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red[300],
                ),
                const SizedBox(height: 16),
                Text(
                  'Error al cargar juegos',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.red[300],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  gameProvider.error!,
                  style: const TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => gameProvider.loadGames(),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          );
        }

        if (gameProvider.games.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.sports_soccer,
                  size: 64,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'No hay juegos disponibles',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => _refreshGamesTab(context),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Banners section
              _BannersSection(),
              const SizedBox(height: 20),
              
              // Games section
              const Text(
                'Ligas Disponibles',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              
              // Games list
              ...gameProvider.games.map((game) => _GameCard(game: game)),
            ],
          ),
        );
      },
    );
  }

  Future<void> _refreshGamesTab(BuildContext context) async {
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    final bannerProvider = Provider.of<BannerProvider>(context, listen: false);
    
    await Future.wait([
      gameProvider.loadGames(),
      bannerProvider.loadBanners(),
    ]);
  }
}

class _BannersSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<BannerProvider>(
      builder: (context, bannerProvider, child) {
        if (bannerProvider.isLoading || bannerProvider.banners.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Novedades',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: bannerProvider.banners.length,
                itemBuilder: (context, index) {
                  final banner = bannerProvider.banners[index];
                  return _BannerCard(banner: banner, index: index);
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _BannerCard extends StatelessWidget {
  final dynamic banner;
  final int index;

  const _BannerCard({required this.banner, required this.index});


  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFEE9000),
            Color(0xFFCC7A00),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Star icon in top left
          const Positioned(
            top: 16,
            left: 16,
            child: Icon(
              Icons.star,
              color: Colors.white,
              size: 24,
            ),
          ),
          
          // Content
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  banner.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black26,
                        blurRadius: 2,
                      ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  banner.description,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.white70,
                    shadows: [
                      Shadow(
                        color: Colors.black26,
                        blurRadius: 2,
                      ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MyGamesTab extends StatelessWidget {
  const _MyGamesTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<ParticipationProvider>(
      builder: (context, participationProvider, child) {
        if (participationProvider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
            ),
          );
        }

        if (participationProvider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red[300],
                ),
                const SizedBox(height: 16),
                Text(
                  'Error al cargar participaciones',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.red[300],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  participationProvider.error!,
                  style: const TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => participationProvider.loadUserParticipations(),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          );
        }

        if (participationProvider.participations.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.games,
                  size: 64,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'No estás participando en ningún juego',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Únete a un juego para comenzar',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => participationProvider.loadUserParticipations(),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Title section
              const Text(
                'Mis Juegos',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              
              // Participations list
              ...participationProvider.participations.map((participation) => 
                _ParticipationCard(participation: participation)
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context) {
    return const ProfileScreen();
  }
}

class _GameCard extends StatelessWidget {
  final dynamic game;

  const _GameCard({required this.game});

  // Mapear cada liga a una imagen específica
  String _getLeagueImage(String gameName) {
    if (gameName.toLowerCase().contains('premier') || gameName.toLowerCase().contains('liga premier')) {
      return 'assets/image1.jpg';
    } else if (gameName.toLowerCase().contains('liga') || gameName.toLowerCase().contains('la liga')) {
      return 'assets/iamge2.jpg';
    } else if (gameName.toLowerCase().contains('champions')) {
      return 'assets/image3.jpeg';
    } else {
      return 'assets/image4.jpg'; // Default
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.transparent,
            Color(0xFFEE9000),
            Colors.transparent,
          ],
          stops: [0.0, 0.5, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
          BoxShadow(
            color: const Color(0xFFEE9000).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Container(
        margin: const EdgeInsets.all(2), // Espacio para el borde degradé
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Colors.black, // Fondo para que se vea el borde
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
          children: [
            // Background image
            Positioned.fill(
              child: Image.asset(
                _getLeagueImage(game.name),
                fit: BoxFit.cover,
                colorBlendMode: game.isActive ? null : BlendMode.saturation,
                color: game.isActive ? null : Colors.grey,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: game.isActive 
                            ? [
                                const Color(0xFF1A1A1A),
                                const Color(0xFF2A2A2A),
                              ]
                            : [
                                Colors.grey.shade800,
                                Colors.grey.shade900,
                              ],
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.sports_soccer,
                        color: game.isActive ? Colors.white : Colors.grey,
                        size: 48,
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
                      Colors.transparent,
                      game.isActive 
                          ? Colors.black.withOpacity(0.7)
                          : Colors.black.withOpacity(0.9),
                    ],
                  ),
                ),
              ),
            ),

            // Liga completada overlay
            if (!game.isActive)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.flag,
                          color: Colors.white,
                          size: 40,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'LIGA COMPLETADA',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            // Content
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // League name
                  Text(
                    game.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black,
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Stats row
                  Row(
                    children: [
                      // Creator info
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.person,
                              color: Color(0xFFFF9800),
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'Por Penka',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Container(
                              width: 16,
                              height: 16,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFF9800),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.verified,
                                color: Colors.white,
                                size: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      
                      // Time and participants
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatDate(game.startDate),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.group,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${game.participantCount}/${game.maxParticipants}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
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
            
            // Tap area
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => GameDetailScreen(game: game),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}';
  }
}

class _ParticipationCard extends StatelessWidget {
  final dynamic participation;

  const _ParticipationCard({required this.participation});

  // Mapear cada liga a una imagen específica
  String _getLeagueImage(String gameName) {
    if (gameName.toLowerCase().contains('premier') || gameName.toLowerCase().contains('liga premier')) {
      return 'assets/image1.jpg';
    } else if (gameName.toLowerCase().contains('liga') || gameName.toLowerCase().contains('la liga')) {
      return 'assets/iamge2.jpg';
    } else if (gameName.toLowerCase().contains('champions')) {
      return 'assets/image3.jpeg';
    } else {
      return 'assets/image4.jpg'; // Default
    }
  }

  // Calcular días hasta el inicio
  int _getDaysUntilStart(DateTime startDate) {
    final now = DateTime.now();
    final difference = startDate.difference(now).inDays;
    return difference > 0 ? difference : 0;
  }

  @override
  Widget build(BuildContext context) {
    final daysUntilStart = _getDaysUntilStart(participation.game.startDate);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.transparent,
            Color(0xFFEE9000),
            Colors.transparent,
          ],
          stops: [0.0, 0.5, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: const Color(0xFFEE9000).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Container(
        margin: const EdgeInsets.all(2), // Espacio para el borde degradé
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: Colors.black, // Fondo para que se vea el borde
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
          children: [
            // Background image
            Positioned.fill(
              child: Image.asset(
                _getLeagueImage(participation.game.name),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF2A2A2A),
                          Color(0xFF1A1A1A),
                        ],
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.sports_soccer,
                        color: Colors.white,
                        size: 48,
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
                      Colors.black.withOpacity(0.3),
                      Colors.black.withOpacity(0.8),
                    ],
                  ),
                ),
              ),
            ),
            
            // Status badge
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: participation.isEliminated 
                      ? Colors.red 
                      : const Color(0xFFEE9000),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  participation.isEliminated ? 'Eliminado' : 'Participando',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            
            // Content
            Positioned(
              left: 20,
              right: 20,
              bottom: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // League name
                  Text(
                    participation.game.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black,
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Status info
                  if (participation.isEliminated)
                    Text(
                      'Eliminado en semana ${participation.eliminationWeek}',
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            color: Colors.black,
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    )
                  else if (daysUntilStart > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEE9000),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Inicia en $daysUntilStart día${daysUntilStart != 1 ? 's' : ''}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        '¡En curso!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
            
            // Tap area
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => MyGameDetailScreen(participation: participation),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(18),
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
