import 'package:flutter/material.dart';
import 'package:where_have_you_been_1/pages/category_page.dart';
import 'pages/main_page.dart';
import 'pages/list_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  static List<Widget> _widgetOptions = <Widget>[
    MainPage(),
    ListPage(),
    CategoryPage()
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Bu fonksiyonla seçili simgeye daire ekekledim
  Widget _buildIcon(IconData icon, bool isSelected) {
    return Container(
      decoration: isSelected
          ? BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.3),
      )
          : null,
      child: Icon(icon, size: 30, color: isSelected ? Colors.white : Colors.grey[400]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: CircularNotchedRectangle(),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade500, Colors.blue.shade900],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              IconButton(
                icon: _buildIcon(Icons.location_on, _selectedIndex == 0),
                onPressed: () => _onItemTapped(0),
              ),
              IconButton(
                icon: _buildIcon(Icons.list, _selectedIndex == 1),
                onPressed: () => _onItemTapped(1),
              ),
              IconButton(
                icon: _buildIcon(Icons.category, _selectedIndex == 2),
                onPressed: () => _onItemTapped(2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}





