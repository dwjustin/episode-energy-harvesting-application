import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/device_list_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeRight,
    DeviceOrientation.landscapeLeft,
  ]).then((_) {
    runApp(EnergyHarvestApp());
  });
}

class EnergyHarvestApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Energy Harvest',
      theme: ThemeData(
        fontFamily: 'SUIT',
        primarySwatch: Colors.blue,
        brightness: Brightness.dark,
      ),
      home: DeviceListScreen(),
    );
  }
}