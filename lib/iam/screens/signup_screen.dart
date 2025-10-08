import 'package:fastflow_app/iam/screens/create_signup.dart';
import 'package:fastflow_app/iam/screens/login_screen.dart';
import 'package:flutter/material.dart';



class SignupScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipOval(
              child: Image.asset('assets/logo.png', height: 100, fit: BoxFit.cover,),
            ),
            const SizedBox(height: 20),
            const Text('The best IoT security for business and you.', textAlign: TextAlign.center, style: TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            const Text(
              'Start your trips with us',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RegisterScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.lightGreen,
                foregroundColor: Colors.black,),
              child: const Text('Create account'),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                );
              },
              style: ElevatedButton.styleFrom(    
                foregroundColor: Colors.black,),
              child: const Text('Login'),
            ),
          ],
        ),
      ),
      ),
    );
  }
}