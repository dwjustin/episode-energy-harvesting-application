import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import '../services/fake_bluetooth_service.dart';
import '../utils/permissions.dart';
import 'energy_display_screen.dart';

class DeviceListScreen extends StatefulWidget {
  @override
  _DeviceListScreenState createState() => _DeviceListScreenState();
}

class _DeviceListScreenState extends State<DeviceListScreen> {
  List<BluetoothDevice> devices = [];
  FakeBluetoothSerialService fakeBluetoothService = FakeBluetoothSerialService();
  bool useFakeBluetoothService = true; // Set to false to use real Bluetooth

  @override
  void initState() {
    super.initState();
    _initializeBluetoothScan();
  }

  void _initializeBluetoothScan() async {
    bool permissionsGranted = await requestPermissions();
    if (permissionsGranted) {
      getDevices();
    } else {
      print('Required permissions not granted');
    }
  }

  void getDevices() async {
    if (useFakeBluetoothService) {
      List<BluetoothDevice> bondedDevices = await fakeBluetoothService.getBondedDevices();
      setState(() {
        devices = bondedDevices;
      });
    } else {
      try {
        print('Attempting to get bonded devices...');
        List<BluetoothDevice> bondedDevices = await FlutterBluetoothSerial.instance.getBondedDevices();
        print('Bonded devices: ${bondedDevices.length}');
        setState(() {
          devices = bondedDevices;
        });
        devices.forEach((device) {
          print('Device: ${device.name}, ${device.address}');
        });
      } catch (e) {
        print('Error getting bonded devices: $e');
      }
    }
  }

  void onDeviceTap(BluetoothDevice device) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EnergyDisplayScreen(
          device: device,
          fakeBluetoothService: useFakeBluetoothService ? fakeBluetoothService : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Device'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          getDevices();
        },
        child: ListView.builder(
          itemCount: devices.length,
          itemBuilder: (context, index) {
            BluetoothDevice device = devices[index];
            return ListTile(
              title: Text(device.name ?? 'Unknown Device'),
              subtitle: Text(device.address),
              onTap: () => onDeviceTap(device),
            );
          },
        ),
      ),
    );
  }
}