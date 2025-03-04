import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:timeago/timeago.dart' as timeago;

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({Key? key}) : super(key: key);

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _bookmarkedJobs = [];
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  
  @override
  void initState() {
    super.initState();
    _fetchBookmarks();
  }

  Future<void> _fetchBookmarks() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      if (_currentUserId.isEmpty) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      // Fetch bookmarks from Firestore
      final bookmarksSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUserId)
          .collection('bookmarks')
          .orderBy('bookmarkedAt', descending: true)
          .get();

      final jobs = bookmarksSnapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data(),
        };
      }).toList();

      if (mounted) {
        setState(() {
          _bookmarkedJobs = jobs;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching bookmarks: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('Failed to load bookmarks');
      }
    }
  }

  Future<void> _removeBookmark(String jobId) async {
    try {
      // Show loading indicator
      _showLoadingDialog();
      
      // Delete the bookmark
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUserId)
          .collection('bookmarks')
          .doc(jobId)
          .delete();

      // Close loading indicator
      Navigator.of(context).pop();
      
      // Update the UI
      if (mounted) {
        setState(() {
          _bookmarkedJobs.removeWhere((job) => job['id'] == jobId);
        });
      }

      _showSuccessSnackBar('Removed from bookmarks');
    } catch (e) {
      // Close loading indicator
      Navigator.of(context).pop();
      
      print('Error removing bookmark: $e');
      _showErrorSnackBar('Failed to remove bookmark');
    }
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text("Removing bookmark..."),
            ],
          ),
        );
      },
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookmarks'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchBookmarks,
            tooltip: 'Refresh bookmarks',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _bookmarkedJobs.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _fetchBookmarks,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _bookmarkedJobs.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final job = _bookmarkedJobs[index];
                      return _buildJobCard(job);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bookmark_border,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 20),
          Text(
            'No bookmarked jobs yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Jobs you bookmark will appear here',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
          ),
          // const SizedBox(height: 24),
          // ElevatedButton.icon(
          //   onPressed: () {
          //     Navigator.pushReplacementNamed(context, '/jobs');
          //   },
          //   icon: const Icon(Icons.search),
          //   label: const Text('Browse Jobs'),
          //   style: ElevatedButton.styleFrom(
          //     padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget _buildJobCard(Map<String, dynamic> job) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Dismissible(
        key: Key(job['id']),
        background: Container(
          color: Colors.red,
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          child: const Icon(
            Icons.delete,
            color: Colors.white,
          ),
        ),
        direction: DismissDirection.endToStart,
        confirmDismiss: (direction) async {
          return await showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text("Remove Bookmark"),
                content: const Text("Are you sure you want to remove this job from your bookmarks?"),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text("CANCEL"),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text("REMOVE"),
                  ),
                ],
              );
            },
          );
        },
        onDismissed: (direction) {
          _removeBookmark(job['id']);
        },
        child: InkWell(
          onTap: () {
            // Navigate to job details screen
            Navigator.pushNamed(
              context,
              '/job-details',
              arguments: job,
            ).then((_) => _fetchBookmarks()); // Refresh when returning
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCompanyLogo(job),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            job['title']?.toString() ?? 'Position',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.blue,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            job['companyName']?.toString() ?? 'Company',
                            style: const TextStyle(
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 14, color: Colors.grey),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  job['location']?.toString() ?? 'Location',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.bookmark, color: Colors.blue),
                      onPressed: () => _removeBookmark(job['id']),
                      iconSize: 24,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Remove bookmark',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (job['internshipType'] != null)
                      _buildDetailChip(job['internshipType'].toString(), Colors.blue),
                    if (job['category'] != null)
                      _buildDetailChip(job['category'].toString(), Colors.blue),
                    if (job['workModel'] != null)
                      _buildDetailChip(job['workModel'].toString(), Colors.purple),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (job['salary'] != null)
                      Row(
                        children: [
                          const Icon(Icons.attach_money, color: Colors.green, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            job['salary'].toString(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    Text(
                      _formatDate(job['bookmarkedAt']),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompanyLogo(Map<String, dynamic> job) {
    String? companyLogo = job['companyLogo']?.toString();
    return Hero(
      tag: 'company-logo-${job['id']}',
      child: companyLogo != null && companyLogo.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: Image.network(
                companyLogo,
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildDefaultLogo(job),
              ),
            )
          : _buildDefaultLogo(job),
    );
  }

  Widget _buildDefaultLogo(Map<String, dynamic> job) {
    final String companyName = job['companyName']?.toString() ?? 'Company';
    final String initial = companyName.isNotEmpty ? companyName[0].toUpperCase() : 'C';
    
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.blue,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildDetailChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return '';

    if (timestamp is Timestamp) {
      return 'Saved ${timeago.format(timestamp.toDate())}';
    }
    return '';
  }
}