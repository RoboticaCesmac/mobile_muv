import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
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

  @override
  void initState() {
    super.initState();
    _checkPermissions();
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
        
        // Remover log developer para reduzir duplicação
        // developer.log(
        //   'Localização atualizada - Latitude: ${newPosition.latitude}, Longitude: ${newPosition.longitude}',
        //   name: 'LOCATION'
        // );
        
        // Print apenas quando estiver rastreando para reduzir a poluição
        if (_isTracking) {
          print('LOCAL: Lat: ${newPosition.latitude}, Lng: ${newPosition.longitude}');
        }
        
        setState(() {
          _currentPosition = newPosition;
          _updateMarker();
        });
        
        // Se estiver rastreando, manter o mapa centralizado na posição atual
        if (_isTracking && _controller != null) {
          _controller!.animateCamera(
            CameraUpdate.newLatLng(newPosition),
          );
          
          // Remover print duplicado
          // print('RASTREANDO: Lat: ${newPosition.latitude}, Lng: ${newPosition.longitude}');
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
        
        // Remover log developer para reduzir duplicação
        // developer.log(
        //   'Posição inicial obtida - Latitude: ${position.latitude}, Longitude: ${position.longitude}',
        //   name: 'LOCATION'
        // );
        
        // Simplificar mensagem inicial
        if (_isTracking) {
          print('POSIÇÃO INICIAL: Lat: ${position.latitude}, Lng: ${position.longitude}');
        }
        
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
      // Simplificar mensagem de erro
      print('ERRO: $e');
    }
  }

  void _startTracking() {
    setState(() {
      _isTracking = true;
    });
    
    // Imprimir a localização atual ao iniciar o rastreamento
    if (_currentPosition != null) {
      // Remover log developer para reduzir duplicação
      // developer.log(
      //   '*** RASTREAMENTO INICIADO *** - Latitude: ${_currentPosition!.latitude}, Longitude: ${_currentPosition!.longitude}',
      //   name: 'TRACKING'
      // );
      
      // Simplificar mensagem de início
      print('RASTREAMENTO INICIADO: Lat: ${_currentPosition!.latitude}, Lng: ${_currentPosition!.longitude}');
    }
  }

  void _stopTracking() {
    setState(() {
      _isTracking = false;
    });
    
    // Simplificar mensagem de parada
    print('RASTREAMENTO PARADO');
  }

  @override
  Widget build(BuildContext context) {
    if (!_locationPermissionChecked) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Verificando permissões'),
          backgroundColor: Theme.of(context).primaryColor,
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
      ),
      body: GoogleMap(
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
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isTracking ? _stopTracking : _startTracking,
        icon: Icon(_isTracking ? Icons.stop : Icons.play_arrow),
        label: Text(_isTracking ? 'Parar' : 'Iniciar'),
        backgroundColor: _isTracking ? Colors.red : Theme.of(context).primaryColor,
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}