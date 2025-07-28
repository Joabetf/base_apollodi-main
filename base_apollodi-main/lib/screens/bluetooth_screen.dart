import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class BluetoothScreen extends StatefulWidget {
  static BluetoothCharacteristic? targetCharacteristic;
  static BluetoothCharacteristic? targetPressureCharacteristic;
  static BluetoothCharacteristic? targetAngleCharacteristic;
  static ValueNotifier<String> receivedPressureData = ValueNotifier('');
  static ValueNotifier<String> receivedAngleData = ValueNotifier('');

  @override
  _BluetoothScreenState createState() => _BluetoothScreenState();
}

class _BluetoothScreenState extends State<BluetoothScreen> {
  List<BluetoothDevice> devicesList = [];
  BluetoothDevice? connectedDevice;
  bool isScanning = false;
  final Duration scanInterval = Duration(seconds: 15);
  final TextEditingController angleController = TextEditingController();
  final TextEditingController pressureController = TextEditingController();
  String receivedData = '';

  @override
  void initState() {
    super.initState();
    requestPermissions();
    scanForDevicesPeriodically();
  }

  Future<void> requestPermissions() async {
    await Permission.bluetooth.request();
    await Permission.location.request();
  }

 void scanForDevices() async {
  if (isScanning || connectedDevice != null) return;

  setState(() {
    isScanning = true;
    devicesList.clear();
  });

  FlutterBluePlus.startScan(timeout: Duration(seconds: 5));

  FlutterBluePlus.scanResults.listen((results) async {
    for (var result in results) {
      BluetoothDevice device = result.device;

      if (device.name == 'MOBFOG-IFRN') {
        await FlutterBluePlus.stopScan(); // Parar a varredura
        connectToDevice(device); // Conectar automaticamente
        return;
      }

      setState(() {
        devicesList.add(device);
      });
    }
  });

  await Future.delayed(Duration(seconds: 5));
  FlutterBluePlus.stopScan();
  setState(() {
    isScanning = false;
  });
}

  void scanForDevicesPeriodically() async {
    if (connectedDevice == null) {
      scanForDevices();
      await Future.delayed(scanInterval);
      scanForDevicesPeriodically();
    }
  }

  void connectToDevice(BluetoothDevice device) async {
    await device.connect();
    setState(() {
      connectedDevice = device;
      isScanning = false;
    });
    FlutterBluePlus.stopScan();
    discoverServices(device);
    discoverPressureServices(device);
    discoverAngleServices(device);

    sendCommand('L10');
    sendCommand('L20');
    sendCommand('L30');
    sendCommand('L40');
    sendCommand('L50');
    sendCommand('L60');
  }

  void disconnectFromDevice() async {
    if (connectedDevice != null) {
      await connectedDevice!.disconnect();
      setState(() {
        connectedDevice = null;
        BluetoothScreen.targetCharacteristic = null;
        BluetoothScreen.targetPressureCharacteristic = null;
        BluetoothScreen.targetAngleCharacteristic = null;
        receivedData = '';
        BluetoothScreen.receivedPressureData.value = '';
        BluetoothScreen.receivedAngleData.value = '';
      });
    }
  }

  void discoverPressureServices(BluetoothDevice device) async {
    List<BluetoothService> services = await device.discoverServices();
    for (BluetoothService service in services) {
      for (BluetoothCharacteristic characteristic in service.characteristics) {
        if (characteristic.uuid.toString() ==
            '0972ef8c-7613-4075-ad52-756f33d4da91') {
          setState(() {
            BluetoothScreen.targetPressureCharacteristic = characteristic;
          });
          characteristic.setNotifyValue(true);
          characteristic.value.listen((value) {
            String data = String.fromCharCodes(value);
            print("Dados de Pressão Recebidos: $data");
            BluetoothScreen.receivedPressureData.value = data;
          });
        }
      }
    }
  }

 void discoverAngleServices(BluetoothDevice device) async {
  List<BluetoothService> services = await device.discoverServices();
  for (BluetoothService service in services) {
    for (BluetoothCharacteristic characteristic in service.characteristics) {
      if (characteristic.uuid.toString() ==
          '0f1d2df9-f709-4633-bb27-0c52e13f748a') {
        setState(() {
          BluetoothScreen.targetAngleCharacteristic = characteristic;
        });
        characteristic.setNotifyValue(true);
        characteristic.value.listen((value) {
          String info = String.fromCharCodes(value); 
          print("Dados de Inclinação Recebidos: $info");
          BluetoothScreen.receivedAngleData.value = info;
        });
      }
    }
  }
}

  void discoverServices(BluetoothDevice device) async {
    List<BluetoothService> services = await device.discoverServices();
    for (BluetoothService service in services) {
      for (BluetoothCharacteristic characteristic in service.characteristics) {
        if (characteristic.properties.write) {
          setState(() {
            BluetoothScreen.targetCharacteristic = characteristic;
          });
        }
        if (characteristic.properties.notify) {
          characteristic.setNotifyValue(true);
          characteristic.value.listen((value) {
            setState(() {
              receivedData = String.fromCharCodes(value);
              print(
                  'Dados recebidos das característica principal: $receivedData');
            });
          });
        }
      }
    }
  }

  void sendCommand(String data) async {
    if (BluetoothScreen.targetCharacteristic != null) {
      await BluetoothScreen.targetCharacteristic!.write(data.codeUnits);
    }
  }

  void applySettings() {
    String angle = angleController.text;
    String pressure = pressureController.text;
    sendCommand('ANGLE: $angle');
    sendCommand('PRESSURE: $pressure');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('As configurações foram aplicadas'),
      duration: Duration(seconds: 2),
    ));
  }

  Widget buildBluetoothDeviceList() {
    if (isScanning) {
      return Center(child: CircularProgressIndicator());
    } else if (devicesList.isEmpty) {
      return Center(child: Text('Nenhum dispositivo encontrado'));
    } else {
      return ListView.builder(
        itemCount: devicesList.length,
        itemBuilder: (context, index) {
          BluetoothDevice device = devicesList[index];
          return ListTile(
            title: Text(device.name.isNotEmpty
                ? device.name
                : 'Dispositivo desconhecido'),
            subtitle: Text(device.id.toString()),
            trailing: ElevatedButton(
              onPressed: () => connectToDevice(device),
              child: Text('Conectar', style: TextStyle(color: Colors.black)),
            ),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Configurações'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: connectedDevice != null
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(Icons.bluetooth, size: 40),
                    SizedBox(
                      height: 20,
                    ),
                    Text("Bluetooth", style: TextStyle(fontSize: 24))
                  ]),
                  Text('Conectado a ${connectedDevice!.name}',
                      style: TextStyle(fontSize: 18)),
                  SizedBox(height: 20),
                  TextField(
                    controller: angleController,
                    decoration: InputDecoration(labelText: 'Ângulo'),
                  ),
                  TextField(
                    controller: pressureController,
                    decoration: InputDecoration(
                        labelText:
                            'Pressão'),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: applySettings,
                    child: Text('Aplicar'),
                  ),
                ],
              )
            : Expanded(child: buildBluetoothDeviceList()),
      ),
      floatingActionButton: connectedDevice != null
          ? FloatingActionButton(
              onPressed: disconnectFromDevice,
              child: Icon(Icons.bluetooth_disabled),
              tooltip: 'Desconectar',
            )
          : null,
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: BluetoothScreen(),
  ));
}
