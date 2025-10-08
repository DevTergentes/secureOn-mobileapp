
import 'package:fastflow_app/iam/screens/signup_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../main_screen.dart';


class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');
    final role = prefs.getString('role');

    print('SplashScreen → userId: $userId');
    print('SplashScreen → role: $role');


    await Future.delayed(const Duration(seconds: 3));

    if (userId != null && role != null) {
      // Ya está logueado → ir a MainScreen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    } else {
      // No está logueado → ir a Signup
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => SignupScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ClipOval(
                child: Image.asset('assets/logo.png', height: 300, fit: BoxFit.cover,),
              ),
              const SizedBox(height: 20),
              const CircularProgressIndicator(color: Colors.lightGreen),
            ],
          ),
        ),
      );
    }
  }