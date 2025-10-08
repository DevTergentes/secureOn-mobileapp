import 'package:flutter/material.dart';

class BottomNavBar extends StatefulWidget {
  final int currentIndex;
  final void Function(int) onTap;

  const BottomNavBar({super.key, required this.currentIndex, required this.onTap});

  @override
  BottomNavBarState createState() => BottomNavBarState();
}

class BottomNavBarState extends State<BottomNavBar> {
  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      backgroundColor: Colors.lightGreen,
      type: BottomNavigationBarType.fixed,
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.bus_alert),
          label: 'My Deliveries',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.history),
          label: 'Records',
        ),
     //   BottomNavigationBarItem(
     //     icon: Icon(Icons.person),
     //     label: 'Profile',
      //  ),
      ],
      currentIndex: widget.currentIndex,
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.white70,
      onTap: widget.onTap,
    );
  }
}
