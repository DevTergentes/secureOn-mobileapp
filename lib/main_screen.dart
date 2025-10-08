import 'package:fastflow_app/incidents/screens/incident_list_screen.dart';
import 'package:fastflow_app/management/screens/home_company_screen.dart';
import 'package:fastflow_app/management/screens/home_employee_screen.dart';
import 'package:fastflow_app/management/screens/servicios_list.dart';
import 'package:flutter/material.dart';

import 'package:fastflow_app/management/screens/deliveries_list_screen.dart';

import 'package:fastflow_app/shared/bottom_navigation_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'management/screens/record_screen.dart';

class MainScreen extends StatefulWidget {
  final int initialIndex;
  const MainScreen({super.key,this.initialIndex = 0});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _currentIndex = 0;
  String? _userRole;
  bool _isLoading = true;


  List<Widget> _getScreensForRole(String role) {
    if (role == 'COMPANY') {
      return [
        HomeCompanyScreen(),
        ServiciosListScreen(),
        DeliveriesListScreen(),
        RecordScreen(),
      ];
    } else if (role == 'EMPLOYEE') {
      return [
        HomeEmployeeScreen(),
        DeliveriesListScreen(),
        RecordScreen(),
      ];
    } else {
      return const [Center(child: Text('Unauthorized role'))];
    }
    }

  List<BottomNavigationBarItem> _getNavItemsForRole(String role) {
    if (role == 'COMPANY') {
      return const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'Services'),
        BottomNavigationBarItem(icon: Icon(Icons.bus_alert), label: 'Deliveries'),
        BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Records'),
      ];
    } else if (role == 'EMPLOYEE') {
      return const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.bus_alert), label: 'My Deliveries'),
        BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Records'),
      ];
    } else {
      return const [
        BottomNavigationBarItem(icon: Icon(Icons.block), label: 'Unauthorized'),
      ];
    }
  }

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('role');
    print('Loaded role: $role');
    setState(() {
      _userRole = role;
      _isLoading = false;
    });
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Si el rol no está definido o es desconocido
    if (_userRole == null) {
      return const Scaffold(
        body: Center(child: Text('No role found')),
      );
    }

    final screens = _getScreensForRole(_userRole!);
    final navItems = _getNavItemsForRole(_userRole!);

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        items: navItems,
        selectedItemColor: Colors.lightGreen,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
      ),
    );

  }
}
