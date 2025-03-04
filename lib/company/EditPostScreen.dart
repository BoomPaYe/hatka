import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditPostScreen extends StatefulWidget {
  final String postId;
  const EditPostScreen({super.key, required this.postId});

  @override
  _EditPostScreenState createState() => _EditPostScreenState();
}

class _EditPostScreenState extends State<EditPostScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Controllers
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _salaryController = TextEditingController();

  // Form state
  String? _selectedWorkspaceType;
  String? _selectedCategory;
  String? _selectedInternshipType;
  bool _isActive = true;
  bool _isLoading = false;

  // Lists for dropdowns
  final List<String> _workspaceTypes = ['Onsite', 'Remote', 'Hybrid'];
  final List<String> _categories = ['IT', 'Marketing', 'Finance', 'Design'];
  final List<String> _internshipTypes = ['Full-time', 'Part-time'];

  @override
  void initState() {
    super.initState();
    _loadPostData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _salaryController.dispose();
    super.dispose();
  }

  // Load existing post data
  Future<void> _loadPostData() async {
    try {
      DocumentSnapshot doc = await _firestore.collection("posts").doc(widget.postId).get();
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

      setState(() {
        _titleController.text = data["title"] ?? "";
        _locationController.text = data["location"] ?? "";
        _descriptionController.text = data["description"] ?? "";
        _salaryController.text = (data["salary"] ?? "").toString();
        _selectedWorkspaceType = data["workspaceType"];
        _selectedCategory = data["category"];
        _selectedInternshipType = data["internshipType"];
        _isActive = data["isActive"] ?? true;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading post data: $e")),
      );
    }
  }

  // Update post in Firestore
  Future<void> _updatePost() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedWorkspaceType == null ||
        _selectedCategory == null ||
        _selectedInternshipType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select all dropdown options")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Parse salary
      int salary = int.parse(_salaryController.text.trim());

      await _firestore.collection("posts").doc(widget.postId).update({
        "title": _titleController.text.trim(),
        "location": _locationController.text.trim(),
        "description": _descriptionController.text.trim(),
        "salary": salary,
        "workspaceType": _selectedWorkspaceType,
        "category": _selectedCategory,
        "internshipType": _selectedInternshipType,
        "isActive": _isActive,
        "updatedAt": FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Post Updated Successfully!")),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error updating post: $e")),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Post")),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Title Field
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                    hintText: 'Enter post title',
                  ),
                  validator: (value) =>
                      value?.trim().isEmpty ?? true ? 'Title is required' : null,
                ),
                const SizedBox(height: 16),

                // Workspace Type Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedWorkspaceType,
                  decoration: const InputDecoration(
                    labelText: 'Workspace Type',
                    border: OutlineInputBorder(),
                  ),
                  items: _workspaceTypes.map((type) {
                    return DropdownMenuItem(value: type, child: Text(type));
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedWorkspaceType = value);
                  },
                  validator: (value) =>
                      value == null ? 'Please select workspace type' : null,
                ),
                const SizedBox(height: 16),

                // Location Field
                TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                    labelText: 'Location',
                    border: OutlineInputBorder(),
                    hintText: 'Enter location',
                  ),
                  validator: (value) =>
                      value?.trim().isEmpty ?? true ? 'Location is required' : null,
                ),
                const SizedBox(height: 16),

                // Category Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: _categories.map((category) {
                    return DropdownMenuItem(value: category, child: Text(category));
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedCategory = value);
                  },
                  validator: (value) =>
                      value == null ? 'Please select a category' : null,
                ),
                const SizedBox(height: 16),

                // Description Field
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                    hintText: 'Enter post description',
                  ),
                  maxLines: 3,
                  validator: (value) => value?.trim().isEmpty ?? true
                      ? 'Description is required'
                      : null,
                ),
                const SizedBox(height: 16),

                // Salary Field
                TextFormField(
                  controller: _salaryController,
                  decoration: const InputDecoration(
                    labelText: 'Salary',
                    border: OutlineInputBorder(),
                    hintText: 'Enter salary amount',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value?.trim().isEmpty ?? true) {
                      return 'Salary is required';
                    }
                    if (int.tryParse(value!) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Internship Type Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedInternshipType,
                  decoration: const InputDecoration(
                    labelText: 'Internship Type',
                    border: OutlineInputBorder(),
                  ),
                  items: _internshipTypes.map((type) {
                    return DropdownMenuItem(value: type, child: Text(type));
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedInternshipType = value);
                  },
                  validator: (value) =>
                      value == null ? 'Please select internship type' : null,
                ),
                const SizedBox(height: 16),

                // Active/Inactive Toggle
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Status: ',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 10),
                    ToggleButtons(
                      borderRadius: BorderRadius.circular(8),
                      isSelected: [_isActive, !_isActive],
                      onPressed: (index) {
                        setState(() => _isActive = index == 0);
                      },
                      children: const [
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text('Active'),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text('Inactive'),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Submit Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _updatePost,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Update Post',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}