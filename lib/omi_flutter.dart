import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// A Calculator.
class Calculator {
  /// Returns [value] plus 1.
  int addOne(int value) => value + 1;
}

class OmiFlutter {
  List<BluetoothDevice> devicesList = [];

  /// Scans for Bluetooth devices
  ///
  /// Returns a stream of discovered devices.
  /// The scan will automatically stop after [timeout] duration.
  Future<List<BluetoothDevice>> deviceScan() async {
    devicesList.clear(); // Clear existing devices before scanning

    // Set up the listener before starting the scan
    FlutterBluePlus.onScanResults.listen((results) {
      if (results.isNotEmpty) {
        ScanResult r = results.last; // the most recently found device
        print('${r.device.remoteId}: "${r.advertisementData.advName}" found!');
        if (!devicesList.contains(r.device)) {
          devicesList.add(r.device);
        }
      }
    }, onError: (e) => print(e));

    // Start scan and wait for the full duration to collect devices
    await FlutterBluePlus.startScan(timeout: Duration(seconds: 4));

    // Wait for the scan to complete
    await FlutterBluePlus.isScanning.where((val) => val == false).first;

    // Return the collected devices
    return List<BluetoothDevice>.from(devicesList);
  }

  Future<void> deviceConnect() async {
    await devicesList[0].connect(autoConnect: true);
  }

  Future<void> deviceDisconnect() async {
    await devicesList[0].disconnect();
  }
}
