import 'package:flutter/material.dart';
import 'package:hatka/user/Profile_screen.dart';
import 'package:hatka/user/Resource_screen.dart';
import 'package:hatka/user/Search_screen.dart';
import 'package:hatka/user/UserMain_screen.dart';

class UserScreen extends StatefulWidget {
  const UserScreen({Key? key}) : super(key: key);

  @override
  State<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(),
      bottomNavigationBar: _buildBottom(),
    );
  }

// Define the cartItems list
  // Define an empty list initially
  Widget _buildBody() {
    return IndexedStack(
      index: _currentIndex,
      children: [
        UserMainScreen(),
        SearchScreen(),
        CareerResourceApp(),
        ProfileScreen(),
      ],
    );
  }

  int _currentIndex = 0;

  Widget _buildBottom() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (selectedIndex) {
        setState(() {
          _currentIndex = selectedIndex;
        });
      },
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.blue,
      unselectedItemColor: Colors.grey,
      items: [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
        BottomNavigationBarItem(icon: Icon(Icons.search), label: "Search"),
        BottomNavigationBarItem(icon: Icon(Icons.book), label: "Resource"),
        BottomNavigationBarItem(icon: Icon(Icons.people), label: "Profile"),
      ],
    );
  }
}
