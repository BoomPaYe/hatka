import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hatka/company/CompanyMain_screen.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  _CreatePostScreenState createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _salaryController = TextEditingController();

  // Dropdown selections
  String? _selectedWorkspaceType;
  String? _selectedCategory;
  String? _selectedInternshipType;

  // Active/Inactive toggle
  bool _isActive = true;
  bool _isSubmitting = false; // Prevents multiple taps

  @override
  void initState() {
    super.initState();
    _initializeFirebase();
  }

  // Ensure Firebase is initialized
  Future<void> _initializeFirebase() async {
    await Firebase.initializeApp();
    print("✅ Firebase Initialized Successfully");
  }

  // Function to submit form and save to Firestore
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      print("❌ Form validation failed!");
      return;
    }

    if (_isSubmitting) return; // Prevent multiple taps
    setState(() => _isSubmitting = true);

    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ User not logged in!')),
      );
      print("❌ User not logged in!");
      setState(() => _isSubmitting = false);
      return;
    }

    try {
      int salary = int.tryParse(_salaryController.text.trim()) ?? 0;

      // Save post in Firestore
      await FirebaseFirestore.instance.collection("posts").add({
        "userId": user.uid,
        "title": _titleController.text.trim(),
        "location": _locationController.text.trim(),
        "description": _descriptionController.text.trim(),
        "salary": salary,
        "workspaceType": _selectedWorkspaceType ?? "",
        "category": _selectedCategory ?? "",
        "internshipType": _selectedInternshipType ?? "",
        "isActive": _isActive,
        "createdAt": FieldValue.serverTimestamp(),
      });

      print("✅ Post Created Successfully!");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Post Created Successfully!')),
      );

      // Navigate to Company Main Screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => CompanyMainScreen()),
      );
    } catch (e) {
      print("❌ Error creating post: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error: $e')),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Post")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Title
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                    labelText: "Title", border: OutlineInputBorder()),
                validator: (value) =>
                    value!.isEmpty ? "Title is required" : null,
              ),
              const SizedBox(height: 10),

              // Workspace Type Dropdown
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                    labelText: "Workspace Type", border: OutlineInputBorder()),
                items: ['Onsite', 'Remote', 'Hybrid'].map((type) {
                  return DropdownMenuItem(value: type, child: Text(type));
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedWorkspaceType = value);
                },
                validator: (value) =>
                    value == null ? "Please select a workspace type" : null,
              ),
              const SizedBox(height: 16),

              // Location
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                    labelText: "Location", border: OutlineInputBorder()),
                validator: (value) =>
                    value!.isEmpty ? "Location is required" : null,
              ),
              const SizedBox(height: 10),

              // Category Dropdown
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                    labelText: "Category", border: OutlineInputBorder()),
                items: ['IT', 'Marketing', 'Finance', 'Design'].map((category) {
                  return DropdownMenuItem(
                      value: category, child: Text(category));
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedCategory = value);
                },
                validator: (value) =>
                    value == null ? "Please select a category" : null,
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                    labelText: "Description", border: OutlineInputBorder()),
                validator: (value) =>
                    value!.isEmpty ? "Description is required" : null,
                maxLines: 3,
              ),
              const SizedBox(height: 10),

              // Salary
              TextFormField(
                controller: _salaryController,
                decoration: const InputDecoration(
                    labelText: "Salary", border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                validator: (value) =>
                    value!.isEmpty ? "Salary is required" : null,
              ),
              const SizedBox(height: 10),

              // Internship Type Dropdown
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                    labelText: "Internship Type", border: OutlineInputBorder()),
                items: ['Full-time', 'Part-time'].map((type) {
                  return DropdownMenuItem(value: type, child: Text(type));
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedInternshipType = value);
                },
                validator: (value) =>
                    value == null ? "Please select an internship type" : null,
              ),
              const SizedBox(height: 10),

              // Active/Inactive Toggle Button
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Status: ",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 10),
                  ToggleButtons(
                    borderRadius: BorderRadius.circular(10),
                    isSelected: [_isActive, !_isActive],
                    onPressed: (index) {
                      setState(() => _isActive = index == 0);
                    },
                    children: const [
                      Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: Text("Active")),
                      Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: Text("Inactive")),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitForm,
                  child: _isSubmitting
                      ? const CircularProgressIndicator()
                      : const Text("Create"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
