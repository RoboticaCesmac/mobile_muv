import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import '../services/route/route_recording_service.dart';
import '../services/user/user_profile_service.dart';
import '../services/user/vehicle_service.dart';
import '../services/route/route_manager.dart';
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
  int _locationUpdateCounter = 0;
  
  final Connectivity _connectivity = Connectivity();
  bool _isOnline = true;
  bool _isSyncing = false;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  
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
    await _updateConnectivityStatus();
    
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> results) {
      if (mounted) {
        final isNowOnline = !results.contains(ConnectivityResult.none);
        setState(() {
          _isOnline = isNowOnline;
          print('Conectividade alterada: ${_isOnline ? 'ONLINE' : 'OFFLINE'}');
        });
      }
    });
  }
  
  Future<void> _updateConnectivityStatus() async {
    try {
      var connectivityResult = await _connectivity.checkConnectivity();
      if (mounted) {
        setState(() {
          _isOnline = connectivityResult != ConnectivityResult.none;
          print('Status inicial de conectividade: ${_isOnline ? 'ONLINE' : 'OFFLINE'}');
        });
      }
    } catch (e) {
      print('Erro ao verificar conectividade: $e');
    }
  }
  
  Future<void> _updateOfflinePointsCount() async {
    try {
      await RouteManager.debugPrintRouteInfo();
      
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
    ph.PermissionStatus status = await ph.Permission.location.status;
    
    if (status.isDenied) {
      status = await ph.Permission.location.request();
      if (status.isDenied) {
        _navigateToHome();
        return;
      }
    }
    
    if (status.isPermanentlyDenied) {
      _showPermissionDeniedDialog();
      return;
    }
    
    if (!status.isGranted) {
      _navigateToHome();
      return;
    }

    bool serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) {
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
    _location.changeSettings(
      accuracy: LocationAccuracy.high,
      interval: 500,
      distanceFilter: 2,
    );
    
    _getCurrentLocation();
    
    _location.onLocationChanged.listen((LocationData locationData) async {
      if (!mounted) return;
      
      if (locationData.latitude != null && locationData.longitude != null) {
        final newPosition = LatLng(locationData.latitude!, locationData.longitude!);

        setState(() {
          _currentPosition = newPosition;
          _updateMarker();
        });
        
        if (_isTracking && _controller != null) {
          _controller!.animateCamera(
            CameraUpdate.newLatLng(newPosition),
          );
          
          _locationUpdateCounter++;
          
          if (_locationUpdateCounter >= 4) {
            final result = await _routeRecordingService.addRoutePoint(
              latitude: newPosition.latitude,
              longitude: newPosition.longitude,
            );
            
            if (result['savedLocally'] == true) {
              setState(() {
                _showOfflineIndicator = true;
                _offlineSavedPoints++;
              });
              
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
                _updateOfflinePointsCount();
              }
            }
            
            _locationUpdateCounter = 0;
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
      final success = await _routeRecordingService.startRoute(
        vehicleId: _selectedVehicle!.id,
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
      );
      
      await _checkRouteStatus();
      
      setState(() {
        _isLoading = false;
      });

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
      _isSyncing = true;
      _showSyncPanel = true;
      _syncStatusList.clear();
    });

    try {
      final success = await _routeRecordingService.finishRoute(
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        onPointSync: (success, routeIndex, pointIndex, totalPoints) {
          if (mounted) {
            setState(() {
              _syncStatusList.add(SyncStatus(
                success: success,
                routeIndex: routeIndex,
                pointIndex: pointIndex,
                totalPoints: totalPoints,
                message: success 
                  ? 'Ponto ${pointIndex + 1}/$totalPoints da rota ${routeIndex + 1} sincronizado'
                  : 'Falha ao sincronizar ponto ${pointIndex + 1} da rota ${routeIndex + 1}',
              ));
              
              if (_syncStatusList.length > 5) {
                _syncStatusList.removeAt(0);
              }
            });
          }
        },
        onRouteComplete: (success, routeIndex) {
          if (mounted) {
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
              
              if (_syncStatusList.length > 5) {
                _syncStatusList.removeAt(0);
              }
            });
          }
        },
      );
      
      await _checkRouteStatus();
      
      await _updateOfflinePointsCount();
      
      setState(() {
        _isLoading = false;
        
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted) {
            setState(() {
              _showSyncPanel = false;
              _isSyncing = false;
            });
          }
        });
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rota finalizada com sucesso!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isSyncing = false;
        _showSyncPanel = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao finalizar a rota: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
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
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
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
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
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
          
          if (!_isOnline)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: const Text(
                  'Você está offline. Não é possível iniciar ou parar rotas.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
            
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
            onPressed: (!_isOnline || !(_canStart && !_isTracking) && !(_canFinish && _isTracking))
              ? null 
              : _handleButtonPress,
            icon: Icon(_isTracking ? Icons.stop : Icons.play_arrow, color: Colors.white),
            label: Text(
              _isTracking ? 'Parar' : 'Iniciar',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            backgroundColor: !_isOnline
              ? Colors.grey
              : _isTracking 
                ? Colors.red 
                : _canStart 
                  ? Theme.of(context).primaryColor 
                  : Colors.grey,
          ),
    );
  }
  
  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _controller?.dispose();
    super.dispose();
  }
}

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