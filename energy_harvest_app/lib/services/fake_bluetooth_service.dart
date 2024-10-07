import 'dart:async';
import 'dart:math';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';


class FakeBluetoothSerialService {
  List<BluetoothDevice> _fakeDevices = [];
  StreamController<List<BluetoothDevice>> _devicesController = StreamController<List<BluetoothDevice>>.broadcast();

  Stream<List<BluetoothDevice>> get devices => _devicesController.stream;

  FakeBluetoothSerialService() {
    _generateFakeDevices();
  }

  void _generateFakeDevices() {
    _fakeDevices = List.generate(5, (index) {
      return BluetoothDevice(
        address: '00:11:22:33:44:5$index',
        name: 'Fake HC-06 Device $index',
      );
    });
  }

  Future<List<BluetoothDevice>> getBondedDevices() async {
    await Future.delayed(const Duration(seconds: 1));
    return _fakeDevices;
  }

  Future<bool> connect(BluetoothDevice device) async {
    await Future.delayed(const Duration(seconds: 1));
    return true;
  }

  Stream<String> getEnergyValues() {
    return Stream.periodic(const Duration(seconds: 2), (count) {
      double value = 400 + Random().nextDouble() * 100; // Random value between 100 and 200
      return value.toStringAsFixed(1);
    });
  }

}