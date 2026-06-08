import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _connectivityController = StreamController<bool>.broadcast();
  bool _isOnline = true;

  Stream<bool> get onConnectivityChanged => _connectivityController.stream;

  Future<void> init() async {
    // Check initial connectivity
    _isOnline = await isConnected();
    _connectivityController.add(_isOnline);

    // Listen for connectivity changes
    _connectivity.onConnectivityChanged.listen((result) async {
      _isOnline = _checkConnectivity(result);
      _connectivityController.add(_isOnline);
    });
  }

  Future<bool> isConnected() async {
    final result = await _connectivity.checkConnectivity();
    return _checkConnectivity(result);
  }

  bool get isOnline => _isOnline;

  bool _checkConnectivity(dynamic result) {
    // Handle both single ConnectivityResult and List<ConnectivityResult>
    List<ConnectivityResult> results;
    if (result is ConnectivityResult) {
      results = [result];
    } else if (result is List<ConnectivityResult>) {
      results = result;
    } else {
      return false;
    }

    return results.contains(ConnectivityResult.wifi) ||
           results.contains(ConnectivityResult.mobile) ||
           results.contains(ConnectivityResult.ethernet) ||
           results.contains(ConnectivityResult.vpn) ||
           results.contains(ConnectivityResult.other);
  }

  void dispose() {
    _connectivityController.close();
  }
}
