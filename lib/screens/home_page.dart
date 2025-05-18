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

/// Homepage com scroll infinito para carregar rotas
///
/// Funcionalidades implementadas:
/// - Carrega inicialmente a primeira página de rotas
/// - Scroll infinito: carrega automaticamente mais 4 rotas quando o usuário chega a 70% da lista
/// - Animações suaves quando novas rotas são carregadas
/// - Indicador de carregamento visível quando mais rotas estão sendo buscadas
/// - Pull-to-refresh para atualizar a lista inteira
/// - Estado vazio com instruções claras

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
  int _currentPage = 1;  // Current page for pagination
  bool _hasMoreRoutes = true;  // Flag to track if more routes are available
  
  // Para animações
  List<bool> _routeVisibility = [];
  
  StreamSubscription? _connectivitySubscription;
  
  @override
  void initState() {
    super.initState();
    // Registrar o observer
    WidgetsBinding.instance.addObserver(this);
    _userProfileFuture = _userProfileService.getUserProfile();
    _loadRoutes();
    
    // Add scroll listener for infinite scrolling
    _scrollController.addListener(_scrollListener);
    
    _initPage();
    
    // Ouvir mudanças de conectividade
    _connectivitySubscription = _connectivityService.connectionChangeStream.listen((isConnected) {
      if (isConnected) {
        // Quando a internet voltar, tenta sincronizar rotas offline
        _syncOfflineRoutes();
      }
    });
  }
  
  // Listen to scroll events to implement infinite scrolling
  void _scrollListener() {
    // Quando o usuário rolar até 70% da lista, comece a carregar mais rotas
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.7 &&
        !_isLoading && _hasMoreRoutes) {
      _loadMoreRoutes();
    }
  }
  
  @override
  void dispose() {
    // Remover o observer
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Recarregar os dados quando o app voltar para o primeiro plano
    if (state == AppLifecycleState.resumed) {
      _refreshData();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Verificar se a página está montada e visível
    // Usando uma flag para evitar atualizações desnecessárias
    if (!_initialLoadDone) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _refreshData();
          _initialLoadDone = true;
        }
      });
    }
  }

  // Reset and load first page of routes
  void _refreshData() {
    setState(() {
      _userProfileFuture = _userProfileService.getUserProfile();
      _allRoutes = []; // Limpar rotas existentes
      _routeVisibility = []; // Limpar visibilidades
      _currentPage = 1; // Reset to first page
      _hasMoreRoutes = true; // Reset the flag
      _loadRoutes();
    });
  }

  // Load the first page of routes
  Future<void> _loadRoutes() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final routes = await _routeService.getRoutes(page: _currentPage);
      
      // Inicializar visibilidade das rotas
      List<bool> visibility = List.generate(routes.length, (index) => false);
      
      setState(() {
        _allRoutes = routes;
        _routeVisibility = visibility;
        _isLoading = false;
        // If we got fewer than 4 routes (or none), there are no more
        if (routes.isEmpty || routes.length < 4) {
          _hasMoreRoutes = false;
        }
      });
      
      // Animar a entrada dos itens após um breve atraso
      await Future.delayed(const Duration(milliseconds: 100));
      for (int i = 0; i < routes.length; i++) {
        if (mounted) {
          setState(() {
            _routeVisibility[i] = true;
          });
          // Pequeno atraso entre cada animação
          await Future.delayed(const Duration(milliseconds: 50));
        }
      }
    } catch (e) {
      print('Erro ao carregar rotas: $e');
      setState(() {
        _isLoading = false;
        _allRoutes = [];
        _hasMoreRoutes = false;
      });
    }
  }
  
  // Load the next page of routes and append to the existing list
  Future<void> _loadMoreRoutes() async {
    if (_isLoading || !_hasMoreRoutes) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      _currentPage++; // Increment to next page
      
      // Adicionar um pequeno atraso para mostrar o indicador de carregamento
      await Future.delayed(const Duration(milliseconds: 800));
      
      final moreRoutes = await _routeService.getRoutes(page: _currentPage);
      final startIndex = _allRoutes.length;
      
      // Adicionar novas visibilidades como falso (inicialmente invisíveis)
      List<bool> newVisibility = List.generate(moreRoutes.length, (index) => false);
      
      setState(() {
        _allRoutes.addAll(moreRoutes); // Append new routes to existing list
        _routeVisibility.addAll(newVisibility);
        _isLoading = false;
        // If we got fewer than 4 routes (or none), there are no more
        if (moreRoutes.isEmpty || moreRoutes.length < 4) {
          _hasMoreRoutes = false;
        }
      });
      
      // Animar a entrada dos novos itens
      await Future.delayed(const Duration(milliseconds: 100));
      for (int i = 0; i < moreRoutes.length; i++) {
        if (mounted) {
          setState(() {
            _routeVisibility[startIndex + i] = true;
          });
          // Pequeno atraso entre cada animação
          await Future.delayed(const Duration(milliseconds: 50));
        }
      }
    } catch (e) {
      print('Erro ao carregar mais rotas: $e');
      // Roll back page counter on error
      _currentPage--;
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Sincroniza rotas offline caso existam
  Future<void> _syncOfflineRoutes() async {
    try {
      print('Verificando e sincronizando rotas offline...');
      await _routeRecordingService.syncOfflineRoutes();
      
      // Atualiza a lista de rotas após sincronização
      _refreshData();
    } catch (e) {
      print('Erro ao sincronizar rotas offline: $e');
    }
  }
  
  Future<void> _initPage() async {
    _refreshData();
    
    // Verifica se existem rotas offline para sincronizar
    final isConnected = await _connectivityService.checkConnectivity();
    if (isConnected) {
      _syncOfflineRoutes();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Column(
          children: [
            // Seção do perfil do usuário
            _buildUserProfileSection(),
            
            // Seção de atividades
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
                    // Recarregar os dados quando retornar da tela de gravação
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
                    // Recarregar os dados quando retornar da tela de configurações
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
      padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 12.0), // Reduzindo o padding
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
                  // Avatar do usuário
                  CircleAvatar(
                    radius: 26, // Reduzindo o tamanho do avatar
                    backgroundImage: NetworkImage(userProfile.avatar.avatarUrl),
                    backgroundColor: Colors.grey[200],
                  ),
                  const SizedBox(width: 12), // Reduzindo o espaçamento
                  
                  // Informações do usuário
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Olá, ${userProfile.userName}!',
                          style: const TextStyle(
                            fontSize: 18, // Reduzindo o tamanho da fonte
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6), // Reduzindo o espaçamento
                        
                        // Barra de progresso e ícone de level na mesma linha
                        Row(
                          children: [
                            // Barra de progresso baseada na pegada de carbono atual e pegada necessária para o próximo nível
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Tooltip(
                                    message: 'Pegada de Carbono: ${userProfile.profileData.totalCarbonFootprint}/${userProfile.profileData.totalCarbonFootprintOfNextLevel}',
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8), // Reduzindo o raio
                                      child: LinearProgressIndicator(
                                        // Calcula o progresso: pegada de carbono atual / pegada de carbono necessária para o próximo nível
                                        value: userProfile.profileData.totalCarbonFootprint / 
                                            userProfile.profileData.totalCarbonFootprintOfNextLevel,
                                        backgroundColor: Colors.grey[200],
                                        color: const Color(0xFF18694F),
                                        minHeight: 10, // Reduzindo a altura da barra
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Nível ${userProfile.profileData.currentLevel} - Progresso de pegada de carbono',
                                    style: const TextStyle(
                                      fontSize: 9, // Reduzindo o tamanho da fonte
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8), // Reduzindo o espaçamento
                            // Ícone de level com tamanho reduzido
                            userProfile.profileData.currentLevelUrl != null
                                ? Image.network(
                                    userProfile.profileData.currentLevelUrl!,
                                    width: 28, // Reduzindo o tamanho
                                    height: 28, // Reduzindo o tamanho
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(
                                        Icons.nature,
                                        color: Colors.green[400],
                                        size: 28, // Reduzindo o tamanho
                                      );
                                    },
                                  )
                                : Icon(
                                    Icons.nature,
                                    color: Colors.green[400],
                                    size: 28, // Reduzindo o tamanho
                                  ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14), // Reduzindo o espaçamento
              
              // Estatísticas do usuário - em três colunas
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
    
    // Create Google Maps static URL for the route
    String mapUrl = 'https://maps.googleapis.com/maps/api/staticmap?size=600x200&maptype=roadmap';
    
    // Add API key if you have one
    mapUrl += '&key=${AppConfig.googleMapsApiKey}';
    
    if (route.routePoints.isNotEmpty) {
      // Create path string from route points
      final pathPoints = route.routePoints.map((point) {
        // Handle different possible formats of route points
        double? lat, lng;
        
        if (point is Map) {
          lat = point['latitude'] is double ? point['latitude'] : double.tryParse(point['latitude'].toString());
          lng = point['longitude'] is double ? point['longitude'] : double.tryParse(point['longitude'].toString());
        } else if (point is dynamic && point.latitude != null && point.longitude != null) {
          lat = point.latitude is double ? point.latitude : double.tryParse(point.latitude.toString());
          lng = point.longitude is double ? point.longitude : double.tryParse(point.longitude.toString());
        }
        
        if (lat != null && lng != null) {
          return '$lat,$lng';
        }
        return '';
      }).where((point) => point.isNotEmpty).join('|');
      
      // Add path if we have points
      if (pathPoints.isNotEmpty) {
        // Add path to map URL with blue color and weight 5
        mapUrl += '&path=color:0x0000ff|weight:5|$pathPoints';
        
        // Add markers for start and end points
        final points = pathPoints.split('|');
        if (points.length >= 2) {
          mapUrl += '&markers=color:green|label:I|${points.first}';
          mapUrl += '&markers=color:red|label:F|${points.last}';
        }
      }
    } else {
      // Fallback to center view if no path points
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
          // Mapa na parte superior
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16.5),
              topRight: Radius.circular(16.5),
            ),
            child: Container(
              height: 130, // Reduzindo a altura do mapa
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Mapa
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
                  
                  // Badge do veículo no canto superior esquerdo
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
                  
                  // Badge de distância no canto superior direito
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
                  
                  // Google Maps attribution
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
          
          // Conteúdo abaixo do mapa
          Padding(
            padding: const EdgeInsets.all(12.0), // Reduzindo o padding
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Data e hora
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Coluna de início
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
                    
                    // Ícone de seta
                    Icon(
                      Icons.arrow_forward,
                      color: Colors.grey[400],
                      size: 16,
                    ),
                    
                    // Coluna de fim
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
                
                const SizedBox(height: 12), // Reduzindo o espaçamento
                
                // Linha divisória com gradiente
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
                
                const SizedBox(height: 10), // Reduzindo o espaçamento
                
                // Métricas
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // Pegada de carbono
                    _buildMetricItem(
                      icon: Icons.eco,
                      iconColor: Colors.teal,
                      label: 'Pegada',
                      value: '${route.carbonFootprint}kg',
                      fontSize: 15, // Reduzindo o tamanho da fonte
                    ),
                    
                    // Linha vertical divisória
                    Container(
                      height: 30,
                      width: 1,
                      color: Colors.grey.withOpacity(0.2),
                    ),
                    
                    // Velocidade média
                    _buildMetricItem(
                      icon: Icons.speed,
                      iconColor: Colors.blue,
                      label: 'Velocidade',
                      value: '${route.velocityAverage}km/h',
                      fontSize: 15, // Reduzindo o tamanho da fonte
                    ),
                    
                    // Linha vertical divisória
                    Container(
                      height: 30,
                      width: 1,
                      color: Colors.grey.withOpacity(0.2),
                    ),
                    
                    // Pontos
                    _buildMetricItem(
                      icon: Icons.star,
                      iconColor: Colors.amber,
                      label: 'Pontos',
                      value: '${route.points}',
                      fontSize: 15, // Reduzindo o tamanho da fonte
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