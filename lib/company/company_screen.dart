import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hatka/company/Applicants_screen.dart';
import 'package:hatka/company/CompanyMain_screen.dart';
import 'package:hatka/company/Create_screen.dart';
import 'package:hatka/company/Profile_screen.dart';

class CompanyScreen extends StatefulWidget {
  const CompanyScreen({Key? key}) : super(key: key);

  @override
  State<CompanyScreen> createState() => _CompanyScreenState();
}

class _CompanyScreenState extends State<CompanyScreen> {
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
        CompanyMainScreen(),
        CreatePostScreen(),
        ApplicantScreen(),
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
      selectedItemColor: Color.fromARGB(255, 30, 26, 237),
      unselectedItemColor: Colors.grey,
      items: [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
        BottomNavigationBarItem(
            icon: Icon(Icons.create_new_folder), label: "Create"),
        BottomNavigationBarItem(
            icon: Icon(Icons.document_scanner_outlined), label: "Applicants"),
        BottomNavigationBarItem(icon: Icon(Icons.people), label: "Profile"),
      ],
    );
  }
}
