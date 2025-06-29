import 'package:flutter/material.dart';
import 'package:project01/providers/theme_provider.dart';
import 'package:provider/provider.dart';

class ThemeChangerPage extends StatelessWidget {
  const ThemeChangerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("เปลี่ยนธีม")),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text('เมนู'),
            ),
            ListTile(
              title: const Text('เปลี่ยนธีม'),
              leading: Icon(
                context.watch<ThemeProvider>().themeMode == ThemeMode.dark
                    ? Icons.light_mode
                    : Icons.dark_mode,
              ),
              onTap: () {
                final themeProvider = context.read<ThemeProvider>();
                themeProvider.setThemeMode(
                  themeProvider.themeMode == ThemeMode.dark
                      ? ThemeMode.light
                      : ThemeMode.dark,
                );
                Navigator.pop(context); // ปิด Drawer หลังจากเลือก
              },
            ),
          ],
        ),
      ),
      body: Center(child: const Text('เลือกธีมจากเมนูข้าง')),
    );
  }
}
