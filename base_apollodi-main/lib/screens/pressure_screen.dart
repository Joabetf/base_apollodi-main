import 'package:flutter/material.dart';
import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
import 'bluetooth_screen.dart';

class PressureDisplay extends StatefulWidget {
  @override
  _PressureDisplayState createState() => _PressureDisplayState();
}

class _PressureDisplayState extends State<PressureDisplay> {
  List<FlSpot> pressureData = [];
  Timer? timer;
  String inclinationLevel = 'Sem dados';
  late DateTime startTime; // Adicione esta linha

  @override
  void initState() {
    super.initState();
    startTime = DateTime.now(); // Inicialize o tempo de início aqui
    timer = Timer.periodic(Duration(seconds: 1), (Timer t) => fetchPressureData());
    fetchInclinationData(); // Chama para atualizar os dados de inclinação
    if (BluetoothScreen.targetPressureCharacteristic != null) {
      BluetoothScreen.targetPressureCharacteristic!.setNotifyValue(true);
      BluetoothScreen.targetPressureCharacteristic!.value.listen((value) {
        String data = String.fromCharCodes(value);
        double pressureValue = double.tryParse(data) ?? 0.0;
        setState(() {
          double elapsedTime = DateTime.now().difference(startTime).inSeconds.toDouble(); // Modifique o cálculo do tempo
          pressureData.add(FlSpot(elapsedTime, pressureValue));
          if (pressureData.length > 50) {
            pressureData.removeAt(0);
          }
        });
      });
    }
  }

  void fetchInclinationData() async {
    if (BluetoothScreen.targetAngleCharacteristic != null) {
      BluetoothScreen.targetAngleCharacteristic!.setNotifyValue(true);
      BluetoothScreen.targetAngleCharacteristic!.value.listen((value) {
        String data = String.fromCharCodes(value);
        setState(() {
          inclinationLevel = data;
        });
      });
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void fetchPressureData() {}

  String formatXAxis(double value) {
    return '${value.toInt()}s';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: Column(
          children: <Widget>[
            Text(
              pressureData.isNotEmpty ? '${pressureData.last.y} psi' : '0.0 psi',
              style: TextStyle(fontSize: 24),
            ),
            SizedBox(height: 20),
            Container(
              height: 200,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: 250,
                  borderData: FlBorderData(show: true),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(formatXAxis(value));
                        },
                        reservedSize: 30,
                      ),
                    ),
                  ),
                  gridData: FlGridData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: pressureData,
                      isCurved: false,
                      gradient: LinearGradient(
                        colors: [Colors.blue, Colors.blue],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      barWidth: 4,
                      isStrokeCapRound: true,
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            Colors.blue.withOpacity(0.3),
                            Colors.lightBlue.withOpacity(0.3)
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Inclinação: $inclinationLevel',
              style: TextStyle(fontSize: 16, color: Colors.black),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: Scaffold(
      appBar: AppBar(title: Text('Exibição de Pressão')),
      body: PressureDisplay(),
    ),
  ));
}
