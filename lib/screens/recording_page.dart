import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import '../services/route_recording_service.dart';
import '../services/user_profile_service.dart';
import '../services/vehicle_service.dart';
import '../services/route_manager.dart';
import '../models/user_profile.dart' hide Vehicle;
import '../models/vehicle.dart';
import 'dart:developer' as developer;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

class RecordingPage extends StatefulWidget {
  const RecordingPage({super.key});

  @override
  State<RecordingPage> createState() => _RecordingPageState();
}

class _RecordingPageState extends State<RecordingPage> {
  GoogleMapController? _controller;
  Location _location = Location();
  bool _isTracking = false;
  LatLng? _currentPosition;
  Set<Marker> _markers = {};
  bool _locationPermissionChecked = false;
  final RouteRecordingService _routeRecordingService = RouteRecordingService();
  final UserProfileService _userProfileService = UserProfileService();
  final VehicleService _vehicleService = VehicleService();
  UserProfile? _userProfile;
  Vehicle? _selectedVehicle;
  List<Vehicle> _availableVehicles = [];
  bool _isLoading = false;
  bool _canStart = false;
  bool _canFinish = false;
  String _startMessage = '';
  String _finishMessage = '';
  bool _isLoadingVehicles = false;
  bool _showOfflineIndicator = false;
  int _offlineSavedPoints = 0;
  
  // Variáveis para monitorar conectividade
  final Connectivity _connectivity = Connectivity();
  bool _isOnline = true;
  bool _isSyncing = false;
  
  // Variáveis para mostrar status da sincronização
  List<SyncStatus> _syncStatusList = [];
  bool _showSyncPanel = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _loadUserProfile();
    _checkRouteStatus();
    _loadVehicles();
    _initConnectivityListener();
  }

  Future<void> _initConnectivityListener() async {
    // Verificação inicial de conectividade
    await _checkConnectivity();
    
    // Verificar a cada 3 segundos
    Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) {
        _checkConnectivity();
      }
    });
  }
  
  Future<void> _checkConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      final bool isNowOnline = result != ConnectivityResult.none;
      final bool wasOffline = !_isOnline;
      
      if (wasOffline && isNowOnline) {
        // Mudou de offline para online
        print('Conectividade restaurada: OFFLINE -> ONLINE');
        if (mounted) {
          setState(() {
            _isOnline = true;
          });
          // Tenta sincronizar após confirmar que está online
          _syncOfflineRoutes();
        }
      } else if (!isNowOnline && _isOnline) {
        // Mudou de online para offline
        print('Conectividade perdida: ONLINE -> OFFLINE');
        if (mounted) {
          setState(() {
            _isOnline = false;
          });
        }
      }
    } catch (e) {
      print('Erro ao verificar conectividade: $e');
    }
  }
  
  Future<void> _syncOfflineRoutes() async {
    // Verifica se já está sincronizando para evitar múltiplas sincronizações
    if (_isSyncing) {
      print('Sincronização já em andamento, ignorando nova solicitação');
      return;
    }

    // Verificar se existem pontos para sincronizar
    await _updateOfflinePointsCount();
    if (_offlineSavedPoints <= 0) {
      print('Nenhum ponto para sincronizar');
      return;
    }
    
    print('Iniciando sincronização de $_offlineSavedPoints pontos');
    
    setState(() {
      _isSyncing = true;
      _showSyncPanel = true;
      _syncStatusList = []; // Limpa lista de status
    });
    
    try {
      bool syncResult = await _routeRecordingService.syncOfflineRoutes(
        onPointSync: (success, routeIndex, pointIndex, totalPoints) {
          if (mounted) {
            print('Sincronizando ponto $pointIndex/$totalPoints da rota $routeIndex - ${success ? 'sucesso' : 'falha'}');
            setState(() {
              _syncStatusList.add(SyncStatus(
                success: success,
                routeIndex: routeIndex,
                pointIndex: pointIndex,
                totalPoints: totalPoints,
                message: success 
                  ? 'Ponto ${pointIndex + 1}/$totalPoints da rota ${routeIndex + 1} sincronizado'
                  : 'Falha ao sincronizar ponto ${pointIndex + 1}/$totalPoints da rota ${routeIndex + 1}',
              ));
              
              // Limita a quantidade de mensagens visíveis
              if (_syncStatusList.length > 5) {
                _syncStatusList.removeAt(0);
              }
            });
          }
        },
        onRouteComplete: (success, routeIndex) {
          if (mounted) {
            print('Rota $routeIndex ${success ? 'sincronizada com sucesso' : 'falhou ao sincronizar'}');
            setState(() {
              _syncStatusList.add(SyncStatus(
                success: success,
                routeIndex: routeIndex,
                pointIndex: -1,
                totalPoints: -1,
                message: success 
                  ? 'Rota ${routeIndex + 1} sincronizada com sucesso!'
                  : 'Falha ao finalizar rota ${routeIndex + 1}',
                isRouteComplete: true,
              ));
              
              // Limita a quantidade de mensagens visíveis
              if (_syncStatusList.length > 5) {
                _syncStatusList.removeAt(0);
              }
            });
          }
        },
      );
      
      print('Sincronização concluída: ${syncResult ? 'Sucesso' : 'Falha'}');
      
      // Atualiza o status de pontos offline imediatamente
      await _updateOfflinePointsCount();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(syncResult 
              ? 'Sincronização concluída com sucesso!'
              : 'Houve problemas durante a sincronização.'
            ),
            backgroundColor: syncResult ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('Erro durante a sincronização: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro durante a sincronização: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      // Atualiza o contador novamente para garantir precisão
      await _updateOfflinePointsCount();
      
      // Aguarda 5 segundos antes de esconder o painel de sincronização
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) {
          setState(() {
            _showSyncPanel = false;
            _isSyncing = false;
          });
        }
      });
    }
  }
  
  Future<void> _updateOfflinePointsCount() async {
    try {
      // Imprime informações detalhadas sobre as rotas para debug
      await RouteManager.debugPrintRouteInfo();
      
      // Usa o novo método para contar pontos com precisão
      final totalPoints = await RouteManager.getTotalOfflinePointsCount();
      
      if (mounted) {
        setState(() {
          _offlineSavedPoints = totalPoints;
          _showOfflineIndicator = totalPoints > 0;
        });
      }
    } catch (e) {
      print('Erro ao atualizar contagem de pontos offline: $e');
    }
  }

  Future<void> _loadVehicles() async {
    setState(() {
      _isLoadingVehicles = true;
    });
    
    try {
      final vehicles = await _vehicleService.getVehicles();
      if (mounted) {
        setState(() {
          _availableVehicles = vehicles;
          _isLoadingVehicles = false;
        });
      }
    } catch (e) {
      print('Erro ao carregar veículos: $e');
      if (mounted) {
        setState(() {
          _isLoadingVehicles = false;
        });
      }
    }
  }

  Future<void> _checkRouteStatus() async {
    try {
      final routeStatus = await _routeRecordingService.getRouteStatus();
      
      if (mounted && routeStatus.isNotEmpty) {
        final canDo = routeStatus['can_do'];
        
        if (canDo != null && canDo is Map) {
          final startInfo = canDo['start'];
          final finishInfo = canDo['finish'];
          
          setState(() {
            if (startInfo != null && startInfo is Map) {
              _canStart = startInfo['can'] ?? false;
              _startMessage = startInfo['message'] ?? '';
            }
            
            if (finishInfo != null && finishInfo is Map) {
              _canFinish = finishInfo['can'] ?? false;
              _finishMessage = finishInfo['message'] ?? '';
            }
            
            _isTracking = _canFinish; // Se pode finalizar, está gravando
          });
        }
      }
    } catch (e) {
      print('Erro ao verificar status da rota: $e');
    }
  }

  Future<void> _loadUserProfile() async {
    final userProfile = await _userProfileService.getUserProfile();
    if (mounted) {
      setState(() {
        _userProfile = userProfile;
        if (userProfile?.vehicle != null) {
          // Converte do tipo Vehicle do user_profile para o tipo Vehicle do model independente
          _selectedVehicle = Vehicle(
            id: userProfile!.vehicle.id,
            name: userProfile.vehicle.name,
            co2PerKm: userProfile.vehicle.co2PerKm,
            iconPath: userProfile.vehicle.iconPath,
            pointsPerKm: userProfile.vehicle.pointsPerKm,
            createdAt: userProfile.vehicle.createdAt.toString(),
            updatedAt: userProfile.vehicle.updatedAt.toString(),
            iconUrl: userProfile.vehicle.iconUrl,
          );
        }
      });
    }
  }

  Future<void> _checkPermissions() async {
    // Verificar permissão de localização usando permission_handler
    ph.PermissionStatus status = await ph.Permission.location.status;
    
    if (status.isDenied) {
      status = await ph.Permission.location.request();
      if (status.isDenied) {
        // Usuário negou a permissão, voltar para a home
        _navigateToHome();
        return;
      }
    }
    
    if (status.isPermanentlyDenied) {
      // Permissão negada permanentemente, pedir para ir às configurações
      _showPermissionDeniedDialog();
      return;
    }
    
    if (!status.isGranted) {
      // Por qualquer outro motivo não temos permissão, voltar para a home
      _navigateToHome();
      return;
    }

    // Verificar se o serviço de localização está ativado
    bool serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) {
        // O usuário não ativou o serviço de localização, voltar para a home
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Serviço de localização não está ativado.'),
            duration: Duration(seconds: 3),
          ),
        );
        _navigateToHome();
        return;
      }
    }
    
    // Chegando aqui, temos permissão e o serviço está ativado
    setState(() {
      _locationPermissionChecked = true;
    });
    
    _initLocationTracking();
  }

  void _navigateToHome() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Permissão de Localização'),
          content: const Text(
            'A permissão de localização é necessária para usar esta funcionalidade. '
            'Por favor, abra as configurações do aplicativo e conceda a permissão de localização.'
          ),
          actions: [
            TextButton(
              child: const Text('Abrir Configurações'),
              onPressed: () {
                Navigator.of(context).pop();
                ph.openAppSettings();
                _navigateToHome();
              },
            ),
            TextButton(
              child: const Text('Voltar'),
              onPressed: () {
                Navigator.of(context).pop();
                _navigateToHome();
              },
            ),
          ],
        );
      },
    );
  }

  void _initLocationTracking() {
    // Configurar serviço de localização com alta precisão
    _location.changeSettings(
      accuracy: LocationAccuracy.high,
      interval: 500,
      distanceFilter: 2,
    );
    
    // Obter localização atual
    _getCurrentLocation();
    
    // Ouvir atualizações de localização
    _location.onLocationChanged.listen((LocationData locationData) async {
      if (!mounted) return;
      
      if (locationData.latitude != null && locationData.longitude != null) {
        final newPosition = LatLng(locationData.latitude!, locationData.longitude!);

        setState(() {
          _currentPosition = newPosition;
          _updateMarker();
        });
        
        // Se estiver rastreando, manter o mapa centralizado na posição atual e enviar ponto à API
        if (_isTracking && _controller != null) {
          _controller!.animateCamera(
            CameraUpdate.newLatLng(newPosition),
          );
          
          // Usar o serviço modificado para adicionar pontos
          final result = await _routeRecordingService.addRoutePoint(
            latitude: newPosition.latitude,
            longitude: newPosition.longitude,
          );
          
          // Verificar se o ponto foi salvo localmente
          if (result['savedLocally'] == true) {
            setState(() {
              _showOfflineIndicator = true;
              _offlineSavedPoints++;
            });
            
            // Mostrar toast informando que o ponto foi salvo localmente
            if (mounted) {
              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Ponto #$_offlineSavedPoints salvo localmente. Aguardando conexão.'),
                  backgroundColor: Colors.orange,
                  duration: const Duration(seconds: 1),
                ),
              );
            }
          } else {
            if (_showOfflineIndicator) {
              // Atualizar contagem de pontos offline
              _updateOfflinePointsCount();
            }
          }
        }
      }
    });
  }

  void _updateMarker() {
    if (_currentPosition == null) return;
    
    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId('current_location'),
          position: _currentPosition!,
          infoWindow: const InfoWindow(title: 'Sua localização'),
        ),
      };
    });
  }

  Future<void> _getCurrentLocation() async {
    try {
      final locationData = await _location.getLocation();
      if (locationData.latitude != null && locationData.longitude != null) {
        final position = LatLng(locationData.latitude!, locationData.longitude!);
        
        setState(() {
          _currentPosition = position;
          _updateMarker();
        });

        if (_controller != null) {
          _controller!.animateCamera(
            CameraUpdate.newLatLngZoom(position, 15),
          );
        }
      }
    } catch (e) {
      print('ERRO: $e');
    }
  }

  void _showVehicleSelectionDialog() {
    if (_isTracking) return; // Não permitir seleção se já estiver gravando
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Selecione um veículo'),
          content: SizedBox(
            width: double.maxFinite,
            child: _isLoadingVehicles
                ? const Center(child: CircularProgressIndicator())
                : GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 1.0,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    shrinkWrap: true,
                    itemCount: _availableVehicles.length,
                    itemBuilder: (context, index) {
                      final vehicle = _availableVehicles[index];
                      final isSelected = _selectedVehicle?.id == vehicle.id;
                      
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedVehicle = vehicle;
                          });
                          Navigator.of(context).pop();
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Image.network(
                                  vehicle.iconUrl,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(Icons.directions_car, size: 40);
                                  },
                                ),
                              ),
                              Text(
                                vehicle.name,
                                style: const TextStyle(fontSize: 12),
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Fechar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _startRoute() async {
    if (_selectedVehicle == null || _currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione um veículo antes de iniciar a rota.'),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Usa o serviço de rota melhorado que gerencia offline/online automaticamente
      final success = await _routeRecordingService.startRoute(
        vehicleId: _selectedVehicle!.id,
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
      );
      
      // Atualiza o status da rota após iniciar
      await _checkRouteStatus();
      
      setState(() {
        _isLoading = false;
      });

      // Notifica o usuário que a rota foi iniciada
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success 
              ? 'Rota iniciada com sucesso!' 
              : 'Houve um problema ao iniciar a rota.'),
            backgroundColor: success ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro ao iniciar a rota.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _finishRoute() async {
    if (_currentPosition == null) {
      setState(() {
        _isTracking = false;
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Usa o serviço de rota melhorado que gerencia offline/online automaticamente
      final success = await _routeRecordingService.finishRoute(
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
      );
      
      // Atualiza o status da rota após finalizar
      await _checkRouteStatus();
      
      setState(() {
        _isLoading = false;
      });

      // Notifica o usuário que a rota foi finalizada
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success 
              ? 'Rota finalizada com sucesso!' 
              : 'Houve um problema ao finalizar a rota.'),
            backgroundColor: success ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro ao finalizar a rota.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void _handleButtonPress() {
    if (_isTracking) {
      if (_canFinish) {
        _finishRoute();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_finishMessage),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } else {
      if (_canStart) {
        _startRoute();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_startMessage),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_locationPermissionChecked) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Verificando permissões'),
          backgroundColor: Theme.of(context).primaryColor,
          iconTheme: const IconThemeData(color: Colors.white),
          titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Verificando permissões de localização...'),
            ],
          ),
        ),
      );
    }
    
    if (_currentPosition == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Obtendo localização'),
          backgroundColor: Theme.of(context).primaryColor,
          iconTheme: const IconThemeData(color: Colors.white),
          titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Obtendo sua localização atual...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gravação de Rota'),
        backgroundColor: Theme.of(context).primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        actions: [
          // Botão para forçar sincronização
          if (_isOnline && _offlineSavedPoints > 0 && !_isSyncing)
            IconButton(
              icon: const Icon(Icons.sync, color: Colors.white),
              tooltip: 'Sincronizar pontos',
              onPressed: _syncOfflineRoutes,
            ),
          // Botão para limpar dados (debug)
          IconButton(
            icon: const Icon(Icons.delete_forever, color: Colors.white),
            tooltip: 'Limpar dados',
            onPressed: _clearAllRouteData,
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _currentPosition!,
              zoom: 15,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: true,
            mapType: MapType.normal,
            markers: _markers,
            compassEnabled: true,
            onMapCreated: (GoogleMapController controller) {
              _controller = controller;
            },
          ),
          
          // Indicador de modo offline
          if (_showOfflineIndicator)
            Positioned(
              top: 20,
              left: 0,
              right: 0,
              child: GestureDetector(
                onTap: _isOnline && !_isSyncing && _offlineSavedPoints > 0 
                    ? _syncOfflineRoutes 
                    : null,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isSyncing 
                            ? Icons.sync 
                            : (_isOnline ? Icons.cloud_upload : Icons.wifi_off),
                          color: Colors.white, 
                          size: 16
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isSyncing
                            ? 'Sincronizando pontos...'
                            : (_isOnline 
                                ? '$_offlineSavedPoints pontos aguardando sincronização'
                                : '$_offlineSavedPoints pontos salvos localmente'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        if (_isOnline && _offlineSavedPoints > 0 && !_isSyncing)
                          GestureDetector(
                            onTap: _syncOfflineRoutes,
                            child: Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.sync,
                                color: Colors.orange,
                                size: 16,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          
          // Painel de sincronização
          if (_showSyncPanel && _syncStatusList.isNotEmpty)
            Positioned(
              bottom: 100,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.sync, color: Theme.of(context).primaryColor),
                        const SizedBox(width: 8),
                        Text(
                          'Sincronizando dados offline',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _showSyncPanel = false;
                            });
                          },
                          child: Icon(Icons.close, 
                                     size: 16, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                    const Divider(),
                    ..._syncStatusList.map((status) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Icon(
                            status.success ? Icons.check_circle : Icons.error,
                            color: status.success ? Colors.green : Colors.red,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              status.message,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: status.isRouteComplete ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )).toList(),
                  ],
                ),
              ),
            ),
            
          // Botão do veículo reposicionado e redesenhado
          Positioned(
            right: 16,
            top: 16,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: _isTracking ? null : _showVehicleSelectionDialog,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _isTracking ? Colors.grey.withOpacity(0.7) : Theme.of(context).primaryColor.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _selectedVehicle != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                _selectedVehicle!.iconUrl,
                                width: 36,
                                height: 36,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(Icons.directions_car, color: Colors.white);
                                },
                              ),
                            )
                          : const Icon(Icons.directions_car, color: Colors.white),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Veículo',
                            style: const TextStyle(fontSize: 10, color: Colors.white70),
                          ),
                          Text(
                            _selectedVehicle?.name ?? 'Selecionar',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ],
                      ),
                      const SizedBox(width: 4),
                      _isTracking 
                          ? const SizedBox.shrink()
                          : const Icon(Icons.arrow_drop_down, color: Colors.white),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _isLoading
        ? const FloatingActionButton(
            onPressed: null,
            backgroundColor: Colors.grey,
            child: CircularProgressIndicator(color: Colors.white),
          )
        : FloatingActionButton.extended(
            onPressed: (_canStart && !_isTracking) || (_canFinish && _isTracking) 
              ? _handleButtonPress 
              : null,
            icon: Icon(_isTracking ? Icons.stop : Icons.play_arrow, color: Colors.white),
            label: Text(
              _isTracking ? 'Parar' : 'Iniciar',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            backgroundColor: _isTracking 
              ? Colors.red 
              : _canStart 
                ? Theme.of(context).primaryColor 
                : Colors.grey,
          ),
    );
  }
  
  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  // Método para limpar todos os dados de rota (usado para debug)
  Future<void> _clearAllRouteData() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpar todas as rotas?'),
        content: const Text('Isso irá remover todos os pontos salvos localmente. Esta operação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              
              setState(() {
                _isLoading = true;
              });
              
              try {
                await RouteManager.clearAllRouteData();
                await _updateOfflinePointsCount();
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Dados de rotas limpos com sucesso'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                print('Erro ao limpar dados de rotas: $e');
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erro ao limpar dados: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } finally {
                if (mounted) {
                  setState(() {
                    _isLoading = false;
                  });
                }
              }
            },
            child: const Text('Limpar'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );
  }
}

/// Classe auxiliar para armazenar status de sincronização
class SyncStatus {
  final bool success;
  final int routeIndex;
  final int pointIndex;
  final int totalPoints;
  final String message;
  final bool isRouteComplete;
  
  SyncStatus({
    required this.success,
    required this.routeIndex,
    required this.pointIndex,
    required this.totalPoints,
    required this.message,
    this.isRouteComplete = false,
  });
}