import 'package:flutter/material.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'screens/lancamento_manual_screen.dart';
import 'screens/lancamento_automatico_screen.dart';
import 'screens/bluetooth_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MeuApp());
}

class MeuApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Controle de Lançamento',
      theme: ThemeData(
        primarySwatch: Colors.amber,
      ),
      home: TelaPrincipal(),
    );
  }
}

class TelaPrincipal extends StatefulWidget {
  @override
  _TelaPrincipalState createState() => _TelaPrincipalState();
}

class _TelaPrincipalState extends State<TelaPrincipal> {
  int _selectedIndex = 0;

  static List<Widget> _widgetOptions = <Widget>[
    BluetoothScreen(),
    LancamentoManualScreen(),
    LancamentoAutomaticoScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(50),
          topRight: Radius.circular(50),
        ),
        child: ConvexAppBar(
          backgroundColor: Colors.white,
          activeColor: Colors.amber,
          color: Colors.black,
          style: TabStyle.react,
          items: [
            TabItem(icon: Icons.settings, title: _selectedIndex == 0 ? 'Config.' : ''),
            TabItem(icon: Icons.back_hand, title: _selectedIndex == 1 ? 'Manual' : ''),
            TabItem(icon: Icons.rocket_launch, title: _selectedIndex == 2 ? 'Automático' : ''),
          ],
          initialActiveIndex: _selectedIndex,
          onTap: _onItemTapped,
          curveSize: 150,
          height: 70,
        ),
      ),
    );
  }
}
