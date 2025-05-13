import 'package:flutter/material.dart';
import 'package:project01/Screen/login.dart';
import 'package:project01/Screen/register.dart';

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Register/Login")),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(50, 10, 50, 0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Image.asset(
                "assets/images/481294383_1069057821931551_1987990633305513186_n.jpg",
              ),
              SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: Icon(Icons.add),
                  label: Text("Register"),
                  style: ElevatedButton.styleFrom(
                    textStyle: TextStyle(fontSize: 20),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => RegisterScreen()),
                    );
                  },
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: Icon(Icons.login),
                  label: Text("Login"),
                  style: ElevatedButton.styleFrom(
                    textStyle: TextStyle(fontSize: 20),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => LoginPage()),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
