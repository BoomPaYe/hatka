import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hatka/Screen/login_screen.dart';
import 'package:hatka/user/ProfileMain_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hatka/user/Bookmark_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

// Cloudinary constants for image upload
const String CLOUDINARY_UPLOAD_URL =
    'https://api.cloudinary.com/v1_1/dbo1t0quj/image/upload';
const String CLOUDINARY_UPLOAD_PRESET = 'imagestore';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();

  User? currentUser;
  String? userName;
  String? profileImage;
  bool isLoading = true;
  bool isUploading = false;

  @override
  void initState() {
    super.initState();
    checkCurrentUser();
  }

  Future<void> checkCurrentUser() async {
    setState(() {
      isLoading = true;
    });

    currentUser = _auth.currentUser;

    if (currentUser != null) {
      try {
        DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(currentUser!.uid).get();

        if (userDoc.exists) {
          Map<String, dynamic> userData =
              userDoc.data() as Map<String, dynamic>;

          // Debug: Print the entire userData to see what fields are available
          print('User data: $userData');

          setState(() {
            userName = userData['name'] ?? 'User';

            // Check for both possible field names
            profileImage = userData['profileImage'] ?? userData['profileImage'];

            // Debug: Print the retrieved profile image URL
            print('Retrieved profile image URL: $profileImage');
          });
        } else {
          print('User document does not exist for uid: ${currentUser!.uid}');
        }
      } catch (e) {
        print('Error fetching user data: $e');
      }
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      setState(() {
        currentUser = null;
        userName = null;
        profileImage = null;
      });
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  Future<void> pickAndUploadProfileImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70, // Reduce image quality to save bandwidth
      );

      if (image == null) return;

      // Show loading indicator
      setState(() {
        isUploading = true;
      });

      // Upload to Cloudinary
      String cloudinaryUrl = await uploadToCloudinary(File(image.path));

      // Update Firestore with new image URL
      if (currentUser != null) {
        await _firestore.collection('users').doc(currentUser!.uid).update({
          'profileImage': cloudinaryUrl,
          'profileImage':
              cloudinaryUrl, // Update both fields to ensure compatibility
        });

        setState(() {
          profileImage = cloudinaryUrl;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile image updated successfully')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile image: $e')),
      );
    } finally {
      setState(() {
        isUploading = false;
      });
    }
  }

  Future<String> uploadToCloudinary(File imageFile) async {
    try {
      // Create multipart request
      final request =
          http.MultipartRequest('POST', Uri.parse(CLOUDINARY_UPLOAD_URL));

      // Add required fields for upload
      request.fields['upload_preset'] = CLOUDINARY_UPLOAD_PRESET;

      // Add file
      request.files.add(await http.MultipartFile.fromPath(
          'file', imageFile.path,
          filename: 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg'));

      // Send request
      final response = await request.send();

      // Check if successful
      if (response.statusCode == 200) {
        // Parse response
        final responseData = await response.stream.toBytes();
        final responseString = String.fromCharCodes(responseData);
        final jsonData = jsonDecode(responseString);

        // Return the secure URL of the uploaded image
        return jsonData['secure_url'] as String;
      } else {
        final responseData = await response.stream.toBytes();
        final responseString = String.fromCharCodes(responseData);
        throw Exception(
            'Failed to upload image: ${response.statusCode}, $responseString');
      }
    } catch (e) {
      throw Exception('Error uploading to Cloudinary: $e');
    }
  }

  void navigateToScreen(BuildContext context, String screenName) {
    if (screenName == 'Login') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LoginScreen(),
        ),
      ).then((_) {
        // Refresh the profile when returning from login screen
        checkCurrentUser();
      });
    } else if (screenName == 'My Application') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DetailScreen(title: 'My Application'),
        ),
      );
    } else if (screenName == 'Bookmark') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BookmarksScreen(),
        ),
      );
    } else if (screenName == 'Setting') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DetailScreen(title: 'Setting'),
        ),
      );
    } else if (screenName == 'View Profile') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProfileMainScreen(),
        ),
      ).then((_) {
        // Refresh the profile when returning from profile main screen
        checkCurrentUser();
      });
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DetailScreen(title: screenName),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Profile'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Profile header
                  Row(
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.grey.shade200,
                            backgroundImage:
                                profileImage != null && profileImage!.isNotEmpty
                                    ? NetworkImage(profileImage!)
                                    : AssetImage('assets/default_profile.png')
                                        as ImageProvider,
                            child: profileImage == null || profileImage!.isEmpty
                                ? Icon(Icons.person, size: 30)
                                : null,
                          ),
                          // if (!isUploading)
                          // Positioned(
                          //   bottom: -5,
                          //   right: -5,
                          //   child: Container(
                          //     decoration: BoxDecoration(
                          //       color: Colors.blue,
                          //       borderRadius: BorderRadius.circular(15),
                          //     ),
                          //     child: IconButton(
                          //       icon: Icon(Icons.camera_alt, color: Colors.white, size: 16),
                          //       padding: EdgeInsets.all(5),
                          //       constraints: BoxConstraints(),
                          //       onPressed: pickAndUploadProfileImage,
                          //     ),
                          //   ),
                          // ),
                          // if (isUploading)
                          // Positioned(
                          //   bottom: -5,
                          //   right: -5,
                          //   child: Container(
                          //     padding: EdgeInsets.all(5),
                          //     width: 25,
                          //     height: 25,
                          //     decoration: BoxDecoration(
                          //       color: Colors.blue,
                          //       borderRadius: BorderRadius.circular(15),
                          //     ),
                          //     child: CircularProgressIndicator(
                          //       strokeWidth: 2,
                          //       color: Colors.white,
                          //     ),
                          //   ),
                          // ),
                        ],
                      ),
                      SizedBox(width: 15),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName ?? 'Guest User',
                            style: TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              navigateToScreen(context, 'View Profile');
                            },
                            child: Text('View Profile'),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              alignment: Alignment.centerLeft,
                              minimumSize: Size(0, 0),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                  SizedBox(height: 30),

                  // Menu items
                  ProfileMenuItem(
                    icon: Icons.description_outlined,
                    title: 'My Application',
                    onTap: () => navigateToScreen(context, 'My Application'),
                  ),

                  ProfileMenuItem(
                    icon: Icons.bookmark_outline,
                    title: 'Bookmark',
                    onTap: () => navigateToScreen(context, 'Bookmark'),
                  ),

                  ProfileMenuItem(
                    icon: Icons.settings,
                    title: 'Setting',
                    onTap: () => navigateToScreen(context, 'Setting'),
                  ),

                  ProfileMenuItem(
                    icon: currentUser != null ? Icons.logout : Icons.login,
                    title: currentUser != null ? 'Log out' : 'Log in',
                    onTap: () {
                      if (currentUser != null) {
                        signOut();
                      } else {
                        navigateToScreen(context, 'Login');
                      }
                    },
                  ),
                ],
              ),
            ),
    );
  }
}

class ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final Function onTap;

  const ProfileMenuItem({
    Key? key,
    required this.icon,
    required this.title,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onTap(),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          children: [
            Icon(icon, color: Colors.blue),
            SizedBox(width: 15),
            Text(
              title,
              style: TextStyle(fontSize: 16),
            ),
            Spacer(),
            Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

// Placeholder screen for navigation destinations
class DetailScreen extends StatelessWidget {
  final String title;

  DetailScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Text('This is the $title screen'),
      ),
    );
  }
}
