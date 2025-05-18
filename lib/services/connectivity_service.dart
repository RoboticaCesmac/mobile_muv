import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _connectionStatusController = StreamController<bool>.broadcast();
  
  // Status atual da conexão
  bool _isConnected = true;
  
  ConnectivityService() {
    // Inicializa monitorando a conectividade
    _initConnectivity();
    // Escuta mudanças de conectividade
    _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }
  
  // Stream que pode ser ouvida para mudanças de estado de conexão
  Stream<bool> get connectionChangeStream => _connectionStatusController.stream;
  
  // Status atual da conexão
  bool get isConnected => _isConnected;
  
  // Inicializa verificando a conectividade
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
  
  // Atualiza o status de conexão com base no resultado de conectividade
  void _updateConnectionStatus(List<ConnectivityResult> results) {
    bool isConnected = results.contains(ConnectivityResult.mobile) || 
                      results.contains(ConnectivityResult.wifi) ||
                      results.contains(ConnectivityResult.ethernet);
    
    // Atualiza somente se houve mudança
    if (_isConnected != isConnected) {
      _isConnected = isConnected;
      _connectionStatusController.add(_isConnected);
      print('Status de conexão alterado: ${_isConnected ? 'CONECTADO' : 'DESCONECTADO'}');
    }
  }
  
  // Verifica a conectividade manualmente
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