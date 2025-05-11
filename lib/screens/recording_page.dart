import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import '../services/route_recording_service.dart';
import '../services/user_profile_service.dart';
import '../services/vehicle_service.dart';
import '../models/user_profile.dart' hide Vehicle;
import '../models/vehicle.dart';
import 'dart:developer' as developer;

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

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _loadUserProfile();
    _checkRouteStatus();
    _loadVehicles();
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
    _location.onLocationChanged.listen((LocationData locationData) {
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
          
          // Enviar ponto da rota à API
          _routeRecordingService.addRoutePoint(
            latitude: newPosition.latitude,
            longitude: newPosition.longitude,
          );
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

  Future<void> _startTracking() async {
    if (_selectedVehicle == null || _currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível iniciar a gravação. Tente novamente.'),
          backgroundColor: Colors.red,
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

      if (success) {
        await _checkRouteStatus(); // Atualizar o status após iniciar
        
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gravação de rota iniciada!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao iniciar a gravação da rota.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _stopTracking() async {
    if (_currentPosition == null) {
      setState(() {
        _isTracking = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _routeRecordingService.finishRoute(
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
      );

      await _checkRouteStatus(); // Atualizar o status após finalizar
      
      setState(() {
        _isLoading = false;
      });

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rota finalizada com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao finalizar a rota.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  void _handleButtonPress() {
    if (_isTracking) {
      if (_canFinish) {
        _stopTracking();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_finishMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      if (_canStart) {
        _startTracking();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_startMessage),
            backgroundColor: Colors.red,
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
}