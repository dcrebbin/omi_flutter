import 'dart:async';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class OmiFlutter {
  static BluetoothDevice? connectedDevice;
  static List<BluetoothDevice> devicesList = [];

  /// Scans for Bluetooth devices
  ///
  /// Returns a stream of discovered devices.
  /// The scan will automatically stop after [timeout] duration.
  Future<List<BluetoothDevice>> deviceScan() async {
    final completer = Completer<void>();

    var subscription = FlutterBluePlus.onScanResults.listen(
      (results) {
        if (results.isNotEmpty) {
          ScanResult r = results.last;
          if (!devicesList.contains(r.device)) {
            devicesList.add(r.device);
          }
        }
      },
      onError: (e) {
        print(e);
        if (!completer.isCompleted) completer.complete();
      },
    );

    await FlutterBluePlus.startScan(timeout: Duration(seconds: 4));
    await FlutterBluePlus.isScanning.where((val) => val == false).first;
    await Future.delayed(Duration(milliseconds: 100));
    await subscription.cancel();

    print("Devices found: ${devicesList.length}");
    return List<BluetoothDevice>.from(devicesList);
  }

  Future<bool> deviceConnect(String deviceId) async {
    try {
      print('Connecting to device $deviceId');
      print(connectedDevice);
      DeviceIdentifier deviceIdentifier = DeviceIdentifier(deviceId);
      if (devicesList.isEmpty) {
        print('No devices found');
        return false;
      }
      await devicesList
          .firstWhere((element) => element.remoteId == deviceIdentifier)
          .connect();
      connectedDevice = devicesList.firstWhere(
        (element) => element.remoteId == deviceIdentifier,
      );
      return true;
    } catch (e) {
      print(e);
      return false;
    }
  }

  Future<bool> deviceDisconnect(String deviceId) async {
    print('Disconnecting from device $deviceId');
    try {
      DeviceIdentifier deviceIdentifier = DeviceIdentifier(deviceId);
      await devicesList
          .firstWhere((element) => element.remoteId == deviceIdentifier)
          .disconnect();
      connectedDevice = null;
      return true;
    } catch (e) {
      print(e);
      return false;
    }
  }

  Future<List<BluetoothService>> retrieveDeviceInfo() async {
    if (connectedDevice == null) {
      return [];
    }
    try {
      var characteristics = await connectedDevice!.discoverServices();
      print(characteristics);
      return characteristics;
    } catch (e) {
      print(e);
      return [];
    }
  }
}
