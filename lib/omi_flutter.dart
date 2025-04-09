import 'package:flutter_blue/flutter_blue.dart';

/// A Calculator.
class Calculator {
  /// Returns [value] plus 1.
  int addOne(int value) => value + 1;
}

class OmiFlutter {
  final FlutterBlue flutterBlue = FlutterBlue.instance;
  List<BluetoothDevice> devicesList = [];

  /// Scans for Bluetooth devices
  ///
  /// Returns a stream of discovered devices.
  /// The scan will automatically stop after [timeout] duration.
  Stream<List<BluetoothDevice>> deviceScan({
    Duration timeout = const Duration(seconds: 4),
  }) {
    // Clear previous results
    devicesList.clear();

    // Start scanning
    flutterBlue.startScan(timeout: timeout);

    // Listen to scan results
    return flutterBlue.scanResults.map((results) {
      for (ScanResult result in results) {
        if (!devicesList.contains(result.device)) {
          devicesList.add(result.device);
        }
      }
      return devicesList;
    });
  }

  Future<void> stopScan() async {
    await flutterBlue.stopScan();
  }

  Future<void> deviceConnect() async {
    await devicesList[0].connect(autoConnect: true);
  }

  Future<void> deviceDisconnect() async {
    await devicesList[0].disconnect();
  }
}
