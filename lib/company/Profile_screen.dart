import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hatka/company/Settings_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _aboutcompanyController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  String? _imageUrl;
  String? _companyName;
  String? _email;
  String? _phonenumber;
  String? _selectedCategory;
  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  // Fetch user profile from Firestore
  void _fetchUserProfile() async {
    print("Starting to fetch user profile");
    try {
      User? user = _auth.currentUser;
      print("Current user ID: ${user?.uid}");

      if (user != null) {
        DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(user.uid).get();
        print("Firestore document fetched: ${userDoc.exists}");
        print("Raw document data: ${userDoc.data()}");

        if (userDoc.exists) {
          Map<String, dynamic> userData =
              userDoc.data() as Map<String, dynamic>;
          print("Profile image URL from Firebase: ${userData['profileImage']}");

          if (mounted) {
            setState(() {
              _imageUrl = userData['profileImage'];
              _companyName = userData['name'] ?? "Company Name";
              _email = userData['email'] ?? "No Email";
              _phonenumber = userData['phonenumber'] ?? "";
              _aboutcompanyController.text = userData['aboutCompany'] ?? "";
              _locationController.text = userData['location'] ?? "";
              _selectedCategory = userData['category'] ?? "Marketing";

              print("State updated - Image URL: $_imageUrl");
            });
          }
        } else {
          print("User document doesn't exist in Firestore");
        }
      } else {
        print("No user is currently logged in");
      }
    } catch (e, stackTrace) {
      print("Error fetching profile: $e");
      print("Stack trace: $stackTrace");
    }
  }

  Future<void> _uploadImage() async {
    try {
      setState(() => _isLoading = true);

      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image == null) {
        print("No image selected");
        return;
      }

      print("Image selected: ${image.path}");
      File file = File(image.path);

      String cloudinaryUrl =
          "https://api.cloudinary.com/v1_1/dbo1t0quj/image/upload";
      String uploadPreset = "imagestore";

      var request = http.MultipartRequest('POST', Uri.parse(cloudinaryUrl))
        ..fields['upload_preset'] = uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', file.path));

      print("Uploading image to Cloudinary...");
      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var jsonData = json.decode(responseData);

      print("Cloudinary response: $jsonData");

      if (jsonData.containsKey('secure_url')) {
        String newImageUrl = jsonData['secure_url'];
        print("New image URL: $newImageUrl");

        // Update Firestore with new image URL
        await _firestore
            .collection('users')
            .doc(_auth.currentUser!.uid)
            .update({
          'profileImage': newImageUrl,
        });

        if (mounted) {
          setState(() {
            _imageUrl = newImageUrl;
            print("State updated with new image URL");
          });
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Profile image updated successfully")),
        );
      }
    } catch (e, stackTrace) {
      print("Error uploading image: $e");
      print("Stack trace: $stackTrace");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to upload image: ${e.toString()}")),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveProfileData() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      User? user = _auth.currentUser;
      if (user != null) {
        // Create data map with all fields
        Map<String, dynamic> profileData = {
          'name': _companyName,
          'email': _email,
          'phonenumber': _phonenumber,
          'aboutCompany': _aboutcompanyController.text,
          'location': _locationController.text,
          'category': _selectedCategory,
          'profileImage': _imageUrl,
          'lastUpdated': FieldValue.serverTimestamp(),
        };

        // Remove null values
        profileData.removeWhere((key, value) => value == null);

        await _firestore
            .collection('users')
            .doc(user.uid)
            .set(profileData, SetOptions(merge: true));

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Profile updated successfully")),
        );
      }
    } catch (e) {
      print("Error saving profile: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to save profile")),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Profile"),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.grey.shade300,
                              backgroundImage:
                                  _imageUrl != null && _imageUrl!.isNotEmpty
                                      ? NetworkImage(_imageUrl!)
                                      : null,
                              child: _imageUrl == null || _imageUrl!.isEmpty
                                  ? Icon(Icons.person,
                                      size: 50, color: Colors.grey.shade600)
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: IconButton(
                                onPressed: _uploadImage,
                                icon: Icon(Icons.camera_alt),
                                style: IconButton.styleFrom(
                                  backgroundColor:
                                      Theme.of(context).primaryColor,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _companyName ?? "Company Name",
                                style: TextStyle(
                                    fontSize: 22, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 5),
                              Text(
                                "Phone: ${_phonenumber ?? 'Not Provided'}",
                                style: TextStyle(fontSize: 16),
                              ),
                              SizedBox(height: 5),
                              Text(
                                "Email: ${_email ?? 'Not Provided'}",
                                style: TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.settings),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const SettingsScreen()),
                            );
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 24),
                    Text(
                      "About Company",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    TextFormField(
                      controller: _aboutcompanyController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: "Enter company details",
                      ),
                      maxLines: 5,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter company details';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    Text(
                      "Location",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    TextFormField(
                      controller: _locationController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: "Enter location",
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter location';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    Text(
                      "Category",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      items: ["Marketing", "IT"].map((String category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() => _selectedCategory = newValue);
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a category';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 24),
                    Center(
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveProfileData,
                        child: _isSaving
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text("Save Profile"),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                              horizontal: 32, vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
