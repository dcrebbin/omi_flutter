import 'dart:async';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class OmiFlutter {
  static BluetoothDevice? connectedDevice;
  static List<BluetoothDevice> devicesList = [];

  static const String audioServiceUUID = "19B10000-E8F2-537E-4F6C-D104768A1214";
  static const String audioCharacteristicUUID =
      "19B10001-E8F2-537E-4F6C-D104768A1214";
  static const String audioCodecCharacteristicUUID =
      "19B10002-E8F2-537E-4F6C-D104768A1214";
  static const String lightCodecCharacteristicUUID =
      "19B10003-E8F2-537E-4F6C-D104768A1214";

  static const String batteryServiceUUID = "2A19";

  static StreamSubscription? connectionSubscription;
  static int batteryLevel = 0;
  static bool isRecording = false;

  static Map<String, BluetoothCharacteristic> characteristics = {};

  static List<BluetoothService> services = [];

  String guidToServiceMap(String uuid) {
    switch (uuid) {
      case audioServiceUUID:
        return "audioService";
      case batteryServiceUUID:
        return "batteryService";
      case audioCharacteristicUUID:
        return "audioCharacteristic";
      case audioCodecCharacteristicUUID:
        return "audioCodecCharacteristic";
      case lightCodecCharacteristicUUID:
        return "lightCodecCharacteristic";
      default:
        return "unknown";
    }
  }

  /// Scans for Bluetooth devices
  ///
  /// Returns a stream of discovered devices.
  /// The scan will automatically stop after [timeout] duration.
  ///
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
      await retrieveDeviceInfo();
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

  Map<String, BluetoothCharacteristic> mapCharacteristics() {
    if (connectedDevice == null) {
      return {};
    }
    print("services: ${services.length}");
    services.forEach((service) {
      service.characteristics.forEach((characteristic) {
        print("characteristic: ${characteristic.characteristicUuid}");
        var characteristicName = guidToServiceMap(
          characteristic.characteristicUuid.str.toUpperCase(),
        );

        print("characteristicName: $characteristicName");

        if (characteristicName != "unknown") {
          print(
            "found characteristic: ${characteristic.characteristicUuid.toString().toUpperCase()}",
          );
          characteristics[characteristicName] = characteristic;
        }
      });
    });
    if (characteristics.isEmpty) {
      print("No characteristics found");
    } else {
      print("Successfully mapped characteristics");
    }
    return characteristics;
  }

  Future<Map<String, BluetoothCharacteristic>> retrieveDeviceInfo() async {
    services = [];
    if (connectedDevice == null) {
      return {};
    }
    try {
      var characteristics = await connectedDevice!.discoverServices();
      services = characteristics;
      print("Successfully retrieved services");
      return mapCharacteristics();
    } catch (e) {
      print(e);
      return {};
    }
  }

  Future<String> getBatteryLevel() async {
    try {
      var characteristic = characteristics["batteryService"];
      var value = await characteristic?.read();
      print("Battery level: $value");
      return value.toString().replaceAll("[", "").replaceAll("]", "");
    } catch (e) {
      print(e);
      return "ERROR";
    }
  }
}
