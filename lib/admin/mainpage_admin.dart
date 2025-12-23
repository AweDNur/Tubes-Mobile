import 'package:flutter/material.dart';
import 'data_siswa.dart';
import 'set_location.dart';
import 'profile_admin.dart';

class MainPageGuru extends StatefulWidget {
  const MainPageGuru({super.key});

  @override
  State<MainPageGuru> createState() => _MainPageState();
}

class _MainPageState extends State<MainPageGuru> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    DataSiswa(),
    SetLocationPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.location_on), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: ''),
        ],
      ),
    );
  }
}
