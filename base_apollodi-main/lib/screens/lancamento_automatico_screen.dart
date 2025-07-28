import 'package:flutter/material.dart';
import 'pressure_screen.dart';
import 'bluetooth_screen.dart';

void sendCommand(String data) async {
  if (BluetoothScreen.targetCharacteristic != null) {
    await BluetoothScreen.targetCharacteristic!.write(data.codeUnits);
  }
} // Função para enviar comandos via Bluetooth

class LancamentoAutomaticoScreen extends StatefulWidget {
  @override
  _LancamentoAutomaticoScreenState createState() => _LancamentoAutomaticoScreenState();
}

class _LancamentoAutomaticoScreenState extends State<LancamentoAutomaticoScreen> {
  Map<String, bool> buttonStates = {
    'Nova missão': false,
    'Iniciar missão': false,
    'Abortar': false,
  }; // Cria uma lista com os botões

  @override
  void initState() {
    super.initState();
  } // Inicia funções da tela 

  void _resetAllButtons() {
    setState(() {
      buttonStates.keys.forEach((title) {
        buttonStates[title] = false;
      });
    });
  } // Resetar botões 

  void handleButtonPress(String title, String commandOn) {
    sendCommand(commandOn);
    setState(() {
      buttonStates[title] = true;
    });
  } // Função para enviar comandos enquanto pressiona botões 

  void handleButtonRelease(String title, String commandOff) {
    sendCommand(commandOff);
    setState(() {
      buttonStates[title] = false;
    });
  } // Função para enviar comandos enquanto botões não estão pressionados 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lançamento Automático'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            PressureDisplay(),
            SizedBox(height: 15),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              children: buttonStates.entries.map((entry) {
                String title = entry.key;
                bool isActive = entry.value;
                IconData icon;
                Color color;
                String commandOn;
                String commandOff; // Cria lista para variáveis com informações dos botões

                switch (title) {
                  case 'Nova missão':
                    icon = Icons.add;
                    color = Colors.green;
                    commandOn = 'L11';
                    commandOff = 'L10';
                    break; 
                  case 'Iniciar missão':
                    icon = Icons.rocket_launch;
                    color = Colors.green;
                    commandOn = 'L20';
                    commandOff = 'L21';
                    break; 
                  case 'Abortar':
                    icon = Icons.cancel;
                    color = Colors.deepOrange;
                    commandOn = 'L30';
                    commandOff = 'L31';
                    break; 
                  default:
                    icon = Icons.help;
                    color = Colors.grey;
                    commandOn = '';
                    commandOff = '';
                }

                return buildButton(
                  context,
                  title,
                  icon,
                  color,
                  commandOn,
                  commandOff,
                  isActive,
                ); // Funções para relacionar variáveis de informações com botões
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildButton(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    String commandOn,
    String commandOff,
    bool isActive,
  ) { // Função para criar botões
    return GestureDetector( // Função para identificar gesto dos botões e enviar comandos
      onTapDown: (_) => handleButtonPress(title, commandOn),
      onTapUp: (_) => handleButtonRelease(title, commandOff),
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 3, horizontal: 3),
        child: Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(icon, color: isActive ? color : Colors.grey, size: 50),
              Text(
                title,
                style: TextStyle(color: isActive ? color : Colors.grey, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: LancamentoAutomaticoScreen(),
  ));
}
