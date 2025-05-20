import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _connectionStatusController = StreamController<bool>.broadcast();
  
  bool _isConnected = true;
  
  ConnectivityService() {
    _initConnectivity();
    _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }
  
  Stream<bool> get connectionChangeStream => _connectionStatusController.stream;
  
  bool get isConnected => _isConnected;
  
  Future<void> _initConnectivity() async {
    List<ConnectivityResult> result;
    try {
      result = await _connectivity.checkConnectivity();
      _updateConnectionStatus(result);
    } catch (e) {
      print('Erro ao verificar conectividade: $e');
      _isConnected = false;
      _connectionStatusController.add(false);
    }
  }
  
  void _updateConnectionStatus(List<ConnectivityResult> results) {
    bool isConnected = results.contains(ConnectivityResult.mobile) || 
                      results.contains(ConnectivityResult.wifi) ||
                      results.contains(ConnectivityResult.ethernet);
    
    if (_isConnected != isConnected) {
      _isConnected = isConnected;
      _connectionStatusController.add(_isConnected);
      print('Status de conexão alterado: ${_isConnected ? 'CONECTADO' : 'DESCONECTADO'}');
    }
  }
  
  Future<bool> checkConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      return results.contains(ConnectivityResult.mobile) || 
             results.contains(ConnectivityResult.wifi) ||
             results.contains(ConnectivityResult.ethernet);
    } catch (e) {
      print('Erro ao verificar conectividade: $e');
      return false;
    }
  }
  
  void dispose() {
    _connectionStatusController.close();
  }
} 