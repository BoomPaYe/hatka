import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hatka/user/Jobdetail_screen.dart';
import 'package:timeago/timeago.dart' as timeago;

class JobCard extends StatefulWidget {
  final Map<String, dynamic> job;
  final bool showOnlyActive;

  const JobCard({
    Key? key, 
    required this.job, 
    this.showOnlyActive = true, // Default to showing only active jobs
  }) : super(key: key);

  @override
  State<JobCard> createState() => _JobCardState();
}

class _JobCardState extends State<JobCard> {
  bool isLoading = true;
  bool isActive = false; // Track if the job is active
  String activeStatus = '';
  String userName = '';
  String profileImageUrl = '';

  @override
  void initState() {
    super.initState();
    
    // Check if activeStatus is already provided in the job data
    if (widget.job.containsKey('activeStatus')) {
      setState(() {
        activeStatus = widget.job['activeStatus'];
        isActive = activeStatus == 'Active';
        isLoading = false;
      });
    } else if (widget.job.containsKey('isActive')) {
      setState(() {
        isActive = widget.job['isActive'];
        activeStatus = isActive ? 'Active' : 'Inactive';
        isLoading = false;
      });
    } else {
      // Fetch status if not provided
      _fetchPostStatus();
    }
    
    _fetchUserDetails(widget.job['userId'] ?? '');
  }

  Future<void> _fetchPostStatus() async {
    try {
      if (widget.job['id'] == null) {
        setState(() {
          isLoading = false;
        });
        return;
      }
      
      final postDoc = await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.job['id'])
          .get();
          
      if (postDoc.exists && mounted) {
        final postData = postDoc.data();
        if (postData != null && postData.containsKey('isActive')) {
          setState(() {
            isActive = postData['isActive'];
            activeStatus = isActive ? 'Active' : 'Inactive';
            isLoading = false;
          });
        } else {
          setState(() {
            isLoading = false;
          });
        }
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching post status: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _fetchUserDetails(String userId) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      if (userDoc.exists && mounted) {
        final userData = userDoc.data();
        setState(() {
          userName = userData?['name'] ?? 'Unknown User';
          profileImageUrl = userData?['profileImage'] ?? '';
        });
      }
    } catch (e) {
      print('Error fetching user details: $e');
    }
  }

  void _navigateToJobDetail() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => JobDetailScreen(job: widget.job)),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Unknown date';

    if (timestamp is Timestamp) {
      return timeago.format(timestamp.toDate());
    } else if (timestamp is DateTime) {
      return timeago.format(timestamp);
    } else {
      return 'Invalid date';
    }
  }

  @override
  Widget build(BuildContext context) {
    // If we're only showing active jobs and this job is not active, return an empty container
    if (widget.showOnlyActive && !isActive && !isLoading) {
      return const SizedBox.shrink(); // Returns an empty widget
    }

    // If still loading, show a loading indicator
    if (isLoading) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        height: 100,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
            ),
          ],
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // The rest of your build method remains the same
    return GestureDetector(
      onTap: _navigateToJobDetail,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 4),
          ],
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildUserProfileImage(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          widget.job['title'] ?? '',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          _formatDate(widget.job['createdAt']),
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          userName,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        if (activeStatus.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: activeStatus == 'Active'
                                  ? Colors.green.shade100
                                  : Colors.red.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              activeStatus,
                              style: TextStyle(
                                fontSize: 10,
                                color: activeStatus == 'Active'
                                    ? Colors.green.shade800
                                    : Colors.red.shade800,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined,
                            color: Colors.grey.shade500, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          widget.job['location'] ?? 'Unknown Location',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildChip(widget.job['workspaceType'] ?? 'Full-time'),
                        const SizedBox(width: 8),
                        _buildChip(widget.job['internshipType'] ?? 'Remote'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserProfileImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 40,
        height: 40,
        color: Colors.green.shade100,
        child: profileImageUrl.isNotEmpty
            ? Image.network(
                profileImageUrl,
                width: 40,
                height: 40,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _buildDefaultLogo(),
              )
            : _buildDefaultLogo(),
      ),
    );
  }

  Widget _buildDefaultLogo() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.green.shade200,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Icon(
        Icons.work_outline,
        color: Colors.green.shade700,
        size: 20,
      ),
    );
  }

  Widget _buildChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blue.shade500,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}