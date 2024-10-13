import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NetworkInfo {
  final Connectivity connectivity;

  NetworkInfo(this.connectivity);

  // Asynchronous method to check if the device is connected to the internet.
  Future<bool> isConnected() async {
    final connectivityResult = await connectivity.checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) return false;
    return true;
  }

  // Stream to listen to connectivity changes.
  Stream<bool> get onConnectivityChanged {
    return connectivity.onConnectivityChanged.map((connectivityResult) {
      if (connectivityResult.contains(ConnectivityResult.none)) return false;
      return true;
    });
  }
}

// Provider to provide the Connectivity instance.
final connectivityProvider = Provider<Connectivity>((ref) {
  return Connectivity();
});

// Provider to provide the NetworkInfo instance.
final networkInfoProvider = Provider<NetworkInfo>((ref) {
  final connectivity = ref.watch(connectivityProvider);
  return NetworkInfo(connectivity);
});

// Provider to provide a stream of boolean values to listen to connectivity changes.
final connectivityStreamProvider = StreamProvider<bool>((ref) {
  final networkInfo = ref.watch(networkInfoProvider);
  return networkInfo.onConnectivityChanged;
});
