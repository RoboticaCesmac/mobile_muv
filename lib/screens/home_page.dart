import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/user_profile.dart';
import '../models/route_data.dart';
import '../services/user_profile_service.dart';
import '../services/route_service.dart';
import '../screens/recording_page.dart';
import '../screens/settings_page.dart';
import '../config/app_config.dart';
import '../services/connectivity_service.dart';
import '../services/route_recording_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  final _userProfileService = UserProfileService();
  final _routeService = RouteService();
  final _routeRecordingService = RouteRecordingService();
  final _connectivityService = ConnectivityService();
  Future<UserProfile?>? _userProfileFuture;
  List<RouteData> _allRoutes = [];
  bool _isLoading = false;
  bool _initialLoadDone = false;
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 1;
  bool _hasMoreRoutes = true;
  
  List<bool> _routeVisibility = [];
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _userProfileFuture = _userProfileService.getUserProfile();
    _loadRoutes();
    
    _scrollController.addListener(_scrollListener);
    
    _initPage();
  }
  
  void _scrollListener() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.7 &&
        !_isLoading && _hasMoreRoutes) {
      _loadMoreRoutes();
    }
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshData();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    if (!_initialLoadDone) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _refreshData();
          _initialLoadDone = true;
        }
      });
    }
  }

  void _refreshData() {
    setState(() {
      _userProfileFuture = _userProfileService.getUserProfile();
      _allRoutes = [];
      _routeVisibility = [];
      _currentPage = 1;
      _hasMoreRoutes = true;
      _loadRoutes();
    });
  }

  Future<void> _loadRoutes() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final routes = await _routeService.getRoutes(page: _currentPage);
      
      if (routes.isEmpty) {
        setState(() {
          _hasMoreRoutes = false;
          _isLoading = false;
        });
        return;
      }
      
      List<bool> visibility = List.generate(routes.length, (index) => false);
      
      setState(() {
        _allRoutes = routes;
        _routeVisibility = visibility;
        _isLoading = false;
        _hasMoreRoutes = routes.length >= 4; // Se receber menos de 4 rotas, não há mais páginas
      });
      
      await Future.delayed(const Duration(milliseconds: 100));
      for (int i = 0; i < routes.length; i++) {
        if (mounted) {
          setState(() {
            _routeVisibility[i] = true;
          });
          await Future.delayed(const Duration(milliseconds: 50));
        }
      }
    } catch (e) {
      print('Erro ao carregar rotas: $e');
      setState(() {
        _isLoading = false;
        _hasMoreRoutes = false;
      });
    }
  }
  
  Future<void> _loadMoreRoutes() async {
    if (_isLoading || !_hasMoreRoutes) {
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    _currentPage++;
    
    try {
      final routes = await _routeService.getRoutes(page: _currentPage);
      
      if (routes.isEmpty) {
        setState(() {
          _hasMoreRoutes = false;
          _isLoading = false;
          _currentPage--; // Volta para a página anterior se não houver mais rotas
        });
        return;
      }
      
      setState(() {
        _allRoutes.addAll(routes);
        _routeVisibility.addAll(List.generate(routes.length, (index) => false));
        _isLoading = false;
        _hasMoreRoutes = routes.length >= 4; // Se receber menos de 4 rotas, não há mais páginas
      });
      
      // Anima a entrada das novas rotas
      for (int i = _allRoutes.length - routes.length; i < _allRoutes.length; i++) {
        if (mounted) {
          setState(() {
            _routeVisibility[i] = true;
          });
          await Future.delayed(const Duration(milliseconds: 50));
        }
      }
    } catch (e) {
      print('Erro ao carregar mais rotas: $e');
      setState(() {
        _isLoading = false;
        _currentPage--; // Volta para a página anterior em caso de erro
      });
    }
  }

  Future<void> _initPage() async {
    _refreshData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Column(
          children: [
            _buildUserProfileSection(),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Atividade',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.grid_view),
                              onPressed: () {},
                              color: Colors.grey,
                            ),
                            IconButton(
                              icon: const Icon(Icons.view_list),
                              onPressed: () {},
                              color: const Color(0xFF004341),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Lista de atividades
                  Expanded(
                    child: Column(
                      children: [
                        Expanded(
                          child: _isLoading && _allRoutes.isEmpty
                              ? const Center(child: CircularProgressIndicator())
                              : _allRoutes.isEmpty
                                  ? RefreshIndicator(
                                      onRefresh: () async {
                                        _refreshData();
                                        return Future.value();
                                      },
                                      color: const Color(0xFF004341),
                                      displacement: 20.0,
                                      strokeWidth: 3.0,
                                      child: ListView(
                                        physics: const AlwaysScrollableScrollPhysics(),
                                        children: [
                                          SizedBox(
                                            height: MediaQuery.of(context).size.height * 0.6,
                                            child: Center(
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  const Icon(
                                                    Icons.route_outlined,
                                                    size: 64,
                                                    color: Colors.grey,
                                                  ),
                                                  const SizedBox(height: 16),
                                                  const Text(
                                                    'Nenhuma rota disponível',
                                                    style: TextStyle(
                                                      color: Colors.grey,
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 16),
                                                  Text(
                                                    'Puxe para baixo para atualizar',
                                                    style: TextStyle(
                                                      color: Colors.grey[600],
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Icon(
                                                    Icons.arrow_downward,
                                                    color: Colors.grey[600],
                                                    size: 20,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : Column(
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                '${_allRoutes.length} ${_allRoutes.length == 1 ? 'rota' : 'rotas'} encontradas',
                                                style: TextStyle(
                                                  color: Colors.grey[700],
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Expanded(
                                          child: RefreshIndicator(
                                            onRefresh: () async {
                                              _refreshData();
                                              return Future.value();
                                            },
                                            color: const Color(0xFF004341),
                                            displacement: 20.0,
                                            strokeWidth: 3.0,
                                            triggerMode: RefreshIndicatorTriggerMode.anywhere,
                                            child: ListView.builder(
                                              controller: _scrollController,
                                              scrollDirection: Axis.vertical,
                                              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                                              padding: const EdgeInsets.all(10),
                                              // Add 1 to itemCount if we have more routes to show the loading indicator
                                              itemCount: _allRoutes.length + (_hasMoreRoutes ? 1 : 0),
                                              itemBuilder: (context, index) {
                                                // Show loading indicator at the end
                                                if (index == _allRoutes.length && _hasMoreRoutes) {
                                                  return Container(
                                                    padding: const EdgeInsets.symmetric(vertical: 15.0),
                                                    child: Row(
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      children: [
                                                        const SizedBox(
                                                          width: 24,
                                                          height: 24,
                                                          child: CircularProgressIndicator(
                                                            strokeWidth: 3.0,
                                                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF004341)),
                                                          ),
                                                        ),
                                                        const SizedBox(width: 10),
                                                        Text(
                                                          'Carregando mais rotas...',
                                                          style: TextStyle(
                                                            color: Colors.grey[700],
                                                            fontSize: 14,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                }
                                                
                                                // Cartão de rota com animação de fade in
                                                return AnimatedOpacity(
                                                  duration: const Duration(milliseconds: 500),
                                                  opacity: index < _routeVisibility.length && _routeVisibility[index] ? 1.0 : 0.0,
                                                  child: AnimatedPadding(
                                                    duration: const Duration(milliseconds: 500),
                                                    padding: EdgeInsets.only(
                                                      bottom: 15, 
                                                      top: index < _routeVisibility.length && _routeVisibility[index] ? 0 : 20
                                                    ),
                                                    child: _buildRouteCard(_allRoutes[index]),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(left: 24, right: 24, bottom: 20),
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home, 'Início', true),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const RecordingPage()),
                  ).then((_) {
                    _refreshData();
                  });
                },
                child: _buildNavItem(Icons.fiber_manual_record, 'Gravar', false),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SettingsPage()),
                  ).then((shouldRefresh) {
                    if (shouldRefresh == true) {
                      _refreshData();
                    }
                  });
                },
                child: _buildNavItem(Icons.settings, 'Config', false),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserProfileSection() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 12.0),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: FutureBuilder<UserProfile?>(
        future: _userProfileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Erro: ${snapshot.error}'),
            );
          } else if (!snapshot.hasData || snapshot.data == null) {
            return const Center(
              child: Text('Dados não disponíveis'),
            );
          }

          final userProfile = snapshot.data!;

          return Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundImage: NetworkImage(userProfile.avatar.avatarUrl),
                    backgroundColor: Colors.grey[200],
                  ),
                  const SizedBox(width: 12),
                  
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Olá, ${userProfile.userName}!',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Tooltip(
                                    message: 'Pegada de Carbono: ${userProfile.profileData.totalCarbonFootprint}/${userProfile.profileData.totalCarbonFootprintOfNextLevel}',
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: LinearProgressIndicator(
                                        value: userProfile.profileData.totalCarbonFootprint / 
                                            userProfile.profileData.totalCarbonFootprintOfNextLevel,
                                        backgroundColor: Colors.grey[200],
                                        color: const Color(0xFF18694F),
                                        minHeight: 10,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Nível ${userProfile.profileData.currentLevel} - Progresso de pegada de carbono',
                                    style: const TextStyle(
                                      fontSize: 9,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            userProfile.profileData.currentLevelUrl != null
                                ? Image.network(
                                    userProfile.profileData.currentLevelUrl!,
                                    width: 28,
                                    height: 28,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(
                                        Icons.nature,
                                        color: Colors.green[400],
                                        size: 28,
                                      );
                                    },
                                  )
                                : Icon(
                                    Icons.nature,
                                    color: Colors.green[400],
                                    size: 28,
                                  ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    Icons.star,
                    'Pontos',
                    '${userProfile.profileData.totalPoints}',
                    Colors.green,
                    statIconSize: 16,
                    fontSize: 14,
                  ),
                  _buildStatItem(
                    Icons.place,
                    'Distância',
                    '${userProfile.profileData.distanceTraveled}km',
                    Colors.orange,
                    statIconSize: 16,
                    fontSize: 14,
                  ),
                  _buildStatItem(
                    Icons.eco,
                    'Pegada',
                    '${userProfile.profileData.totalCarbonFootprint}kg',
                    Colors.teal,
                    statIconSize: 16,
                    fontSize: 14,
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String title, String value, Color color, 
      {double fontSize = 16, double statIconSize = 18}) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: statIconSize),
        ),
        const SizedBox(height: 4),
        Text(title, style: TextStyle(color: Colors.grey, fontSize: fontSize - 2)),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: fontSize,
          ),
        ),
      ],
    );
  }

  Widget _buildRouteCard(RouteData route) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    
    String mapUrl = 'https://maps.googleapis.com/maps/api/staticmap?size=600x200&maptype=roadmap';
    
    mapUrl += '&key=${AppConfig.googleMapsApiKey}';
    
    if (route.routePoints.isNotEmpty) {
      final pathPoints = route.routePoints.values.map((point) {
        return '${point.latitude},${point.longitude}';
      }).join('|');
      
      if (pathPoints.isNotEmpty) {
        mapUrl += '&path=color:0x0000ff|weight:5|$pathPoints';
        
        final points = pathPoints.split('|');
        if (points.length >= 2) {
          mapUrl += '&markers=color:green|label:I|${points.first}';
          mapUrl += '&markers=color:red|label:F|${points.last}';
        }
      }
    } else {
      mapUrl += '&center=São+Paulo&zoom=13';
    }
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.grey.withOpacity(0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16.5),
              topRight: Radius.circular(16.5),
            ),
            child: Container(
              height: 130,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    mapUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[200],
                        child: const Center(
                          child: Icon(Icons.map, size: 40, color: Colors.grey),
                        ),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: Colors.grey[200],
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded / 
                                  loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        ),
                      );
                    },
                  ),
                  
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getColorForVehicleName(route.vehicle.name),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        route.vehicle.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.straighten, size: 16, color: Colors.green[700]),
                          const SizedBox(width: 4),
                          Text(
                            '${route.distanceKm}km',
                            style: TextStyle(
                              color: Colors.green[700],
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      color: Colors.white.withOpacity(0.7),
                      child: const Text(
                        'Google Maps',
                        style: TextStyle(fontSize: 10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Início',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          dateFormat.format(route.startedAt),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    
                    Icon(
                      Icons.arrow_forward,
                      color: Colors.grey[400],
                      size: 16,
                    ),
                    
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Fim',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          dateFormat.format(route.endedAt),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.grey.withOpacity(0.1),
                        Colors.grey.withOpacity(0.3),
                        Colors.grey.withOpacity(0.1),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 10),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMetricItem(
                      icon: Icons.eco,
                      iconColor: Colors.teal,
                      label: 'Pegada',
                      value: '${route.carbonFootprint}kg',
                      fontSize: 15,
                    ),
                    
                    Container(
                      height: 30,
                      width: 1,
                      color: Colors.grey.withOpacity(0.2),
                    ),
                    
                    _buildMetricItem(
                      icon: Icons.speed,
                      iconColor: Colors.blue,
                      label: 'Velocidade',
                      value: '${route.velocityAverage}km/h',
                      fontSize: 15,
                    ),
                    
                    Container(
                      height: 30,
                      width: 1,
                      color: Colors.grey.withOpacity(0.2),
                    ),
                    
                    _buildMetricItem(
                      icon: Icons.star,
                      iconColor: Colors.amber,
                      label: 'Pontos',
                      value: '${route.points}',
                      fontSize: 15,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMetricItem({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    double fontSize = 16,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: iconColor,
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: fontSize,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Color _getColorForVehicleName(String name) {
    if (name.toLowerCase().contains('carro')) {
      return Colors.red.shade400;
    } else if (name.toLowerCase().contains('ônibus')) {
      return Colors.amber.shade700;
    } else if (name.toLowerCase().contains('bicicleta')) {
      return Colors.green.shade400;
    }
    return Colors.blue;
  }

  Widget _buildNavItem(IconData icon, String label, bool isSelected) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isSelected 
                ? const Color(0xFF004341) 
                : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: isSelected ? Colors.white : Colors.grey,
            size: 20,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFF004341) : Colors.grey,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
} 