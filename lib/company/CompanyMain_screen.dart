import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:hatka/company/EditPostScreen.dart';

class CompanyMainScreen extends StatefulWidget {
  const CompanyMainScreen({super.key});

  @override
  State<CompanyMainScreen> createState() => _CompanyMainScreenState();
}

class _CompanyMainScreenState extends State<CompanyMainScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _userName;
  String? _profileImage;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  // Load user profile data
  Future<void> _loadUserProfile() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId != null) {
        final userDoc = await _firestore.collection('users').doc(userId).get();
        if (userDoc.exists) {
          setState(() {
            _userName = userDoc.data()?['name'];
            _profileImage = userDoc.data()?['profileImage'];
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading user profile: $e');
    }
  }

  // Function to delete a post
  Future<void> _deletePost(String postId, BuildContext context) async {
    try {
      await _firestore.collection("posts").doc(postId).delete();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Post Deleted Successfully!")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error deleting post: $e")),
      );
    }
  }

  // Show delete confirmation dialog
  Future<void> _showDeleteConfirmation(
      String postId, BuildContext context) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirm Delete"),
          content: const Text("Are you sure you want to delete this post?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _deletePost(postId, context);
              },
              child: const Text("Delete", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = _auth.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Job Posts"),
        actions: [
          // Optional: Add a refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      body: userId == null
          ? const Center(child: Text("Please log in to view your posts"))
          : StreamBuilder(
              stream: _firestore
                  .collection("posts")
                  .where("userId", isEqualTo: userId)
                  .orderBy("createdAt", descending: true)
                  .snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      "You haven't created any job posts yet",
                      style: TextStyle(fontSize: 16),
                    ),
                  );
                }
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: snapshot.data!.docs.map((doc) {
                    Map<String, dynamic> data =
                        doc.data() as Map<String, dynamic>;
                    String postId = doc.id;

                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Company Logo & Job Title
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: Colors.grey[200],
                                  radius: 24,
                                  backgroundImage: _profileImage != null
                                      ? NetworkImage(_profileImage!)
                                      : null,
                                  child: _profileImage == null
                                      ? const Icon(Icons.business)
                                      : null,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        data["title"] ?? "No title",
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        _userName ?? "Your Company",
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: data["isActive"] == true
                                        ? Colors.green[100]
                                        : Colors.grey[100],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    data["isActive"] == true
                                        ? "Active"
                                        : "Inactive",
                                    style: TextStyle(
                                      color: data["isActive"] == true
                                          ? Colors.green[800]
                                          : Colors.red[800],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // Location
                            Row(
                              children: [
                                const Icon(Icons.location_on,
                                    color: Colors.blue, size: 20),
                                const SizedBox(width: 5),
                                Text(data["location"] ?? "Unknown Location"),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // Salary
                            Row(
                              children: [
                                const Icon(Icons.attach_money,
                                    color: Colors.green, size: 20),
                                const SizedBox(width: 5),
                                Text(
                                  "${NumberFormat('#,###').format(data["salary"] ?? 0)}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // Internship & Workspace Type
                            Row(
                              children: [
                                Chip(
                                  label:
                                      Text(data["internshipType"] ?? "Unknown"),
                                  backgroundColor: Colors.blue[100],
                                ),
                                const SizedBox(width: 10),
                                Chip(
                                  label:
                                      Text(data["workspaceType"] ?? "Unknown"),
                                  backgroundColor: Colors.purple[100],
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // Date Posted
                            Align(
                              alignment: Alignment.bottomRight,
                              child: Text(
                                data["createdAt"] != null
                                    ? "Posted on ${DateFormat('dd MMM yyyy').format(data["createdAt"].toDate())}"
                                    : "Date unknown",
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ),

                            const SizedBox(height: 10),

                            // Edit & Delete Buttons
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.amber,
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            EditPostScreen(postId: postId),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.edit,
                                      color: Colors.black87),
                                  label: const Text(
                                    "Edit",
                                    style: TextStyle(color: Colors.black87),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                  ),
                                  onPressed: () =>
                                      _showDeleteConfirmation(postId, context),
                                  icon: const Icon(Icons.delete,
                                      color: Colors.white),
                                  label: const Text(
                                    "Delete",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
    );
  }
}
