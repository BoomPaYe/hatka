import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

// Add this constant at the top of your file
const String CLOUDINARY_UPLOAD_URL =
    'https://api.cloudinary.com/v1_1/dbo1t0quj/image/upload';
const String CLOUDINARY_UPLOAD_PRESET = 'imagestore';

class Education {
  final String school;
  final String detail;
  final String years;

  Education({
    required this.school,
    required this.detail,
    required this.years,
  });

  Map<String, dynamic> toMap() {
    return {
      'school': school,
      'detail': detail,
      'years': years,
    };
  }

  static Education fromMap(Map<String, dynamic> map) {
    return Education(
      school: map['school'] ?? '',
      detail: map['detail'] ?? '',
      years: map['years'] ?? '',
    );
  }
}

class ProfileMainScreen extends StatefulWidget {
  const ProfileMainScreen({Key? key}) : super(key: key);

  @override
  _ProfileMainScreenState createState() => _ProfileMainScreenState();
}

class _ProfileMainScreenState extends State<ProfileMainScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();
  final List<String> PREDEFINED_SKILLS = [
    'Flutter', 'Dart', 'Firebase', 'React', 'JavaScript', 
    'HTML/CSS', 'Java', 'Python', 'Swift', 'Kotlin',
    'UI/UX Design', 'Node.js', 'MongoDB', 'SQL', 'Git',
    'REST API', 'GraphQL', 'AWS', 'Google Cloud', 'DevOps',
    'Project Management', 'Agile', 'Scrum', 'Team Leadership'
  ];

  String _name = '';
  String _email = '';
  String _phone = '';
  String _about = '';
  String _profileImage = '';
  List<Education> _educationList = [];
  List<String> _skillsList = [];
  bool _isLoading = true;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(currentUser.uid).get();

        if (userDoc.exists && userDoc.data() != null) {
          Map<String, dynamic> userData =
              userDoc.data() as Map<String, dynamic>;

          // Debug output of the entire userData
          print('User data: $userData');

          setState(() {
            _name = userData['name'] ?? '';
            _email = userData['email'] ?? '';
            _phone = userData['phonenumber'] ?? '';
            _about = userData['about'] ?? '';
            _profileImage = userData['profileImage'] ?? '';

            // Parse education data
            _educationList = [];
            if (userData['education'] != null) {
              for (var edu in userData['education']) {
                _educationList.add(Education.fromMap(edu));
              }
            }

            // Parse skills data with improved handling of different formats
            _skillsList = [];
            if (userData['skills'] != null) {
              print('Skills data type: ${userData['skills'].runtimeType}');
              print('Skills content: ${userData['skills']}');
              
              var skillsData = userData['skills'];
              if (skillsData is List) {
                for (var skill in skillsData) {
                  _skillsList.add(skill.toString());
                }
              } else if (skillsData is Map) {
                skillsData.forEach((key, value) {
                  if (value == true) {
                    _skillsList.add(key.toString());
                  }
                });
              } else if (skillsData is String) {
                // Handle if it's a comma-separated string
                _skillsList = skillsData.split(',').map((s) => s.trim()).toList();
              }
              
              print('Loaded skills: $_skillsList');
            } else {
              print('No skills found in user data');
            }
          });
        } else {
          print('User document does not exist or has no data');
        }
      } else {
        print('No current user found');
      }
    } catch (e) {
      print('Error loading profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading profile: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickAndUploadProfileImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70, // Reduce image quality to save bandwidth
      );

      if (image == null) return;

      // Show loading indicator
      setState(() {
        _isUploading = true;
      });

      // Upload to Cloudinary
      String cloudinaryUrl = await _uploadToCloudinary(File(image.path));

      // Update Firestore with new image URL
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        await _firestore.collection('users').doc(currentUser.uid).update({
          'profileImage': cloudinaryUrl,
        });

        setState(() {
          _profileImage = cloudinaryUrl;
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
        _isUploading = false;
      });
    }
  }

  Future<String> _uploadToCloudinary(File imageFile) async {
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

  void _editAbout() {
    TextEditingController aboutController = TextEditingController(text: _about);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit About'),
        content: TextField(
          controller: aboutController,
          decoration: const InputDecoration(
            hintText: 'Tell us about yourself',
          ),
          maxLines: 5,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              String newAbout = aboutController.text.trim();
              User? currentUser = _auth.currentUser;
              if (currentUser != null) {
                await _firestore
                    .collection('users')
                    .doc(currentUser.uid)
                    .update({
                  'about': newAbout,
                });
                setState(() {
                  _about = newAbout;
                });
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _editContactInfo() {
    TextEditingController emailController = TextEditingController(text: _email);
    TextEditingController phoneController = TextEditingController(text: _phone);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Contact Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              String newEmail = emailController.text.trim();
              String newPhone = phoneController.text.trim();
              User? currentUser = _auth.currentUser;
              if (currentUser != null) {
                await _firestore
                    .collection('users')
                    .doc(currentUser.uid)
                    .update({
                  'email': newEmail,
                  'phonenumber': newPhone,
                });
                setState(() {
                  _email = newEmail;
                  _phone = newPhone;
                });
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Profile',
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.blue,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile header with image and contact info
                    Center(
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              CircleAvatar(
                                radius: 50,
                                backgroundColor: Colors.grey.shade200,
                                backgroundImage: _profileImage.isNotEmpty
                                    ? NetworkImage(_profileImage)
                                    : null,
                                child: _profileImage.isEmpty
                                    ? const Icon(Icons.person, size: 50)
                                    : null,
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.blue,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: _isUploading
                                      ? Container(
                                          padding: const EdgeInsets.all(10),
                                          height: 40,
                                          width: 40,
                                          child:
                                              const CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : IconButton(
                                          icon: const Icon(Icons.camera_alt,
                                              color: Colors.white, size: 20),
                                          onPressed: _pickAndUploadProfileImage,
                                        ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _name,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.email,
                                  size: 16, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(_email,
                                  style: const TextStyle(color: Colors.grey)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.phone,
                                  size: 16, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(_phone,
                                  style: const TextStyle(color: Colors.grey)),
                            ],
                          ),
                          TextButton(
                            onPressed: _editContactInfo,
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.edit, size: 16),
                                SizedBox(width: 4),
                                Text('Edit Contact Info'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // About section
                    _buildSectionHeader('About', _editAbout),
                    const SizedBox(height: 8),
                    Text(
                      _about.isNotEmpty
                          ? _about
                          : 'Add information about yourself...',
                      style: TextStyle(
                        color: _about.isEmpty ? Colors.grey : Colors.black,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Education section
                    _buildSectionHeader('Education', _addEducation),
                    const SizedBox(height: 8),
                    ..._educationList
                        .map((education) => _buildEducationItem(education))
                        .toList(),
                    if (_educationList.isEmpty)
                      const Text(
                        'Add your education history...',
                        style: TextStyle(color: Colors.grey),
                      ),

                    const SizedBox(height: 24),

                    // Skills section
                    _buildSectionHeader('Skills', _addSkill),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _skillsList.isEmpty
                          ? []
                          : _skillsList
                              .map((skill) => _buildSkillChip(skill))
                              .toList(),
                    ),
                    if (_skillsList.isEmpty)
                      const Text(
                        'Add your professional skills...',
                        style: TextStyle(color: Colors.grey),
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback onEdit) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.edit, size: 20),
          onPressed: onEdit,
        ),
      ],
    );
  }

  Widget _buildEducationItem(Education education) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 12,
            height: 12,
            margin: const EdgeInsets.only(top: 5, right: 8),
            decoration: const BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  education.school,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (education.detail.isNotEmpty) Text(education.detail),
                Text(
                  education.years,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillChip(String skill) {
    return Chip(
      label: Text(skill),
      backgroundColor: Colors.blue.shade50,
      deleteIcon: const Icon(Icons.close, size: 16),
      labelStyle: const TextStyle(color: Colors.blue),
      side: BorderSide(color: Colors.blue.shade200),
      onDeleted: () async {
        setState(() {
          _skillsList.remove(skill);
        });

        User? currentUser = _auth.currentUser;
        if (currentUser != null) {
          await _firestore.collection('users').doc(currentUser.uid).update({
            'skills': _skillsList,
          });
        }
      },
    );
  }

  void _addEducation() {
    TextEditingController schoolController = TextEditingController();
    TextEditingController detailController = TextEditingController();
    TextEditingController yearsController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Education'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: schoolController,
              decoration: const InputDecoration(
                labelText: 'School Name',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: detailController,
              decoration: const InputDecoration(
                labelText: 'Detail/Degree',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: yearsController,
              decoration: const InputDecoration(
                labelText: 'Years (e.g., 2018-2022)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              String school = schoolController.text.trim();
              String detail = detailController.text.trim();
              String years = yearsController.text.trim();

              if (school.isNotEmpty && years.isNotEmpty) {
                Education newEducation = Education(
                  school: school,
                  detail: detail,
                  years: years,
                );

                _educationList.add(newEducation);

                User? currentUser = _auth.currentUser;
                if (currentUser != null) {
                  List<Map<String, dynamic>> educationMaps =
                      _educationList.map((e) => e.toMap()).toList();

                  await _firestore
                      .collection('users')
                      .doc(currentUser.uid)
                      .update({
                    'education': educationMaps,
                  });

                  setState(() {});
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _addSkill() {
    List<String> selectedSkills = [];
    TextEditingController customSkillController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Select Skills'),
          content: Container(
            width: double.maxFinite,
            height: 400, // Fixed height to ensure scrolling works
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Choose from predefined skills:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: PREDEFINED_SKILLS.map((skill) {
                        bool isSelected = selectedSkills.contains(skill);
                        return FilterChip(
                          label: Text(skill),
                          selected: isSelected,
                          onSelected: (selected) {
                            setDialogState(() {
                              if (selected) {
                                selectedSkills.add(skill);
                              } else {
                                selectedSkills.remove(skill);
                              }
                            });
                          },
                          selectedColor: Colors.blue.shade100,
                          checkmarkColor: Colors.blue,
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Add custom skill:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: customSkillController,
                        decoration: const InputDecoration(
                          hintText: 'Enter custom skill',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        if (customSkillController.text.trim().isNotEmpty) {
                          setDialogState(() {
                            selectedSkills.add(customSkillController.text.trim());
                            customSkillController.clear();
                          });
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                
                if (selectedSkills.isNotEmpty) {
                  // Add selected skills to the existing skills list without duplicates
                  Set<String> uniqueSkills = Set.from(_skillsList);
                  uniqueSkills.addAll(selectedSkills);
                  
                  setState(() {
                    _skillsList = uniqueSkills.toList();
                  });

                  User? currentUser = _auth.currentUser;
                  if (currentUser != null) {
                    try {
                      await _firestore
                          .collection('users')
                          .doc(currentUser.uid)
                          .update({
                        'skills': _skillsList,
                      });
                      print('Skills updated successfully: $_skillsList');
                    } catch (e) {
                      print('Error updating skills: $e');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error updating skills: $e')),
                      );
                    }
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}