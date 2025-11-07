import 'package:flutter/material.dart';
import 'page/map/map_page.dart';
import 'page/post/post_page.dart';
import 'page/profile/profile_page.dart';

/// Flutter code sample for [NavigationBar].

void main() => runApp(const NavigationBarApp());

class NavigationBarApp extends StatelessWidget {
  const NavigationBarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(useMaterial3: true),
      home: const NavigationExample(),
    );
  }
}

class NavigationExample extends StatefulWidget {
  const NavigationExample({super.key});

  @override
  State<NavigationExample> createState() => _NavigationExampleState();
}

class _NavigationExampleState extends State<NavigationExample> {
  int currentPageIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (int index) {
          setState(() {
            currentPageIndex = index;
          });
        },
        indicatorColor: Theme.of(context).primaryColor,
        selectedIndex: currentPageIndex,
        destinations: const <Widget>[
          NavigationDestination(
            selectedIcon: Icon(Icons.map_outlined),
            icon: Icon(Icons.map),
            label: 'Map',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.add_outlined),
            icon: Icon(Icons.add),
            label: 'Post',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.person_outlined),
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
      body: SizedBox.expand(
        child:
            <Widget>[
              const MapPage(),
              const PostPage(),
              const ProfilePage(),
            ][currentPageIndex],
      ),
    );
  }
}
