import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hatka/user/Applications.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:firebase_auth/firebase_auth.dart';

class JobDetailScreen extends StatefulWidget {
  final Map<String, dynamic> job;

  const JobDetailScreen({Key? key, required this.job}) : super(key: key);

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen>
    with WidgetsBindingObserver {
  Map<String, dynamic>? userData;
  Map<String, dynamic>? jobDetails;
  bool isLoading = true;
  bool isBookmarked = false;
  String currentUserId = '';
  bool isBookmarkProcessing = false;
  bool isJobActive = true; // Default to true until we know otherwise

  @override
  void initState() {
    super.initState();
    // Register this as an observer to detect app lifecycle changes
    WidgetsBinding.instance.addObserver(this);
    currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    // Initial data fetch
    _fetchData();

    // Check bookmark status after frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkIfBookmarked();
    });
  }

  @override
  void dispose() {
    // Remove observer when widget is disposed
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When app resumes, refresh bookmark status
    if (state == AppLifecycleState.resumed) {
      _checkIfBookmarked();
    }
  }

  // This is called when the route is about to change
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkIfBookmarked();
  }

  // This is called when the widget is inserted back into the tree
  @override
  void activate() {
    super.activate();
    _checkIfBookmarked();
  }

  @override
  void didUpdateWidget(JobDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the job details changed, refresh bookmark status
    if (oldWidget.job['id'] != widget.job['id']) {
      _checkIfBookmarked();
    }
  }

  Future<void> _fetchData() async {
    try {
      // Fetch complete job details from posts collection
      final jobDoc = await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.job['id'])
          .get();

      // Fetch user/company data
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.job['userId'])
          .get();

      if (mounted) {
        setState(() {
          jobDetails = jobDoc.exists ? jobDoc.data() : widget.job;
          // Check if job is active - look for isActive field, defaulting to true if not found
          isJobActive = jobDetails?['isActive'] ?? widget.job['isActive'] ?? true;
          userData = userDoc.exists ? userDoc.data() : null;
          isLoading = false;
        });
      }

      // Check bookmark status now that we have job details
      _checkIfBookmarked();
    } catch (e) {
      print('Error fetching details: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _checkIfBookmarked() async {
    try {
      if (currentUserId.isEmpty || !mounted) return;

      // Force a real-time check from Firestore to get the latest status
      final bookmarkDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .collection('bookmarks')
          .doc(widget.job['id'])
          .get(GetOptions(source: Source.server));

      if (mounted) {
        setState(() {
          isBookmarked = bookmarkDoc.exists;
        });
      }
    } catch (e) {
      print('Error checking bookmark: $e');
    }
  }

  // Add a listener for bookmark changes
  void _setupBookmarkListener() {
    if (currentUserId.isEmpty) return;

    FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .collection('bookmarks')
        .doc(widget.job['id'])
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        setState(() {
          isBookmarked = snapshot.exists;
        });
      }
    });
  }

  Future<void> _toggleBookmark() async {
    // Prevent multiple clicks by checking if an operation is already in progress
    if (isBookmarkProcessing) return;

    try {
      if (currentUserId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please log in to bookmark jobs'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Set processing flag to prevent UI interactions
      setState(() {
        isBookmarkProcessing = true;
      });

      // Reference to this user's bookmarks collection
      final bookmarkRef = FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .collection('bookmarks')
          .doc(widget.job['id']);

      // Get the latest bookmark status before toggling
      final bookmarkDoc = await bookmarkRef.get();
      final currentBookmarkStatus = bookmarkDoc.exists;

      if (currentBookmarkStatus) {
        // Remove from bookmarks
        await bookmarkRef.delete();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Removed from bookmarks'),
            backgroundColor: Colors.grey,
          ),
        );
      } else {
        // Add to bookmarks
        final jobToSave = {
          ...jobDetails ?? widget.job,
          'id': widget.job['id'], // Make sure ID is properly saved
          'bookmarkedAt': FieldValue.serverTimestamp(),
          'companyName': userData?['name'] ?? 'Company Name',
          'companyLogo': userData?['profileImage'] ?? '',
        };

        await bookmarkRef.set(jobToSave);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Added to bookmarks'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Update UI with the new state (opposite of what we just checked)
      if (mounted) {
        setState(() {
          isBookmarked = !currentBookmarkStatus;
          isBookmarkProcessing = false; // Reset processing flag
        });
      }
    } catch (e) {
      print('Error toggling bookmark: $e');
      if (mounted) {
        setState(() {
          isBookmarkProcessing = false; // Reset processing flag even on error
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _navigateToApplicationScreen() {
    // Navigate to application screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ApplicationScreen(job: jobDetails ?? widget.job),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Setup bookmark listener on first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupBookmarkListener();
    });

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Internship Detail',
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              color: isBookmarked ? Colors.blue : null,
            ),
            // Disable the button if processing is in progress
            onPressed: isBookmarkProcessing ? null : _toggleBookmark,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Job header with logo
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCompanyLogo(),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                jobDetails?['title'] ??
                                    widget.job['title'] ??
                                    'Product Development Intern',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    userData?['name'] ?? 'Company Name',
                                    style: const TextStyle(
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    _formatDate(jobDetails?['createdAt'] ??
                                        widget.job['createdAt']),
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Job status indicator
                  if (!isJobActive)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'This position is no longer active',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),

                  // Location
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on,
                            color: Colors.blue, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          jobDetails?['location'] ??
                              widget.job['location'] ??
                              'Phnom Penh',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),

                  // Salary
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8.0),
                    child: Row(
                      children: [
                        Icon(Icons.attach_money, color: Colors.green, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Salary: ${jobDetails?['salary'] ?? widget.job['salary'] ?? '200\$'}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),

                  // Tags
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children: [
                        _buildDetailChip(
                            jobDetails?['internshipType'] ??
                                widget.job['internshipType'] ??
                                'Full-Time',
                            Colors.blue),
                        _buildDetailChip(
                            jobDetails?['workspaceType'] ??
                                widget.job['workspaceType'] ??
                                'Telecommunications',
                            Colors.blue),
                        _buildDetailChip(
                            jobDetails?['category'] ??
                                widget.job['category'] ??
                                'On-site',
                            Colors.blue),
                      ],
                    ),
                  ),

                  const Divider(height: 1),

                  // Tabs
                  DefaultTabController(
                    length: 2,
                    child: Column(
                      children: [
                        const TabBar(
                          tabs: [
                            Tab(text: 'Description'),
                            Tab(text: 'Company Details'),
                          ],
                          labelColor: Colors.black,
                          indicatorColor: Colors.blue,
                        ),
                        SizedBox(
                          height: 280, // Reduced height to minimize spacing
                          child: TabBarView(
                            children: [
                              // Description tab
                              SingleChildScrollView(
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Job Description',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        jobDetails?['description'] ??
                                            'No description available',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          height: 1.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // Company Details tab - made similar to Description tab
                              SingleChildScrollView(
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Company Info
                                      const Text(
                                        'Company Information',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        userData?['aboutCompany'] ??
                                            'No company information available',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          height: 1.5,
                                        ),
                                      ),
                                      const SizedBox(height: 16),

                                      // Contact Info
                                      const Text(
                                        'Contact Information',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          const Icon(Icons.phone,
                                              size: 16, color: Colors.grey),
                                          const SizedBox(width: 8),
                                          Text(
                                            userData?['phonenumber'] ??
                                                'Not specified',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              height: 1.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.email,
                                              size: 16, color: Colors.grey),
                                          const SizedBox(width: 8),
                                          Text(
                                            userData?['email'] ??
                                                'Not specified',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              height: 1.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          // Disable the button if the job is not active
          onPressed: isJobActive ? _navigateToApplicationScreen : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: isJobActive ? Colors.blue : Colors.grey.shade300,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            isJobActive ? 'Apply Now' : 'Position No Longer Available',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isJobActive ? Colors.white : Colors.grey.shade600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompanyLogo() {
    if (userData != null &&
        userData!['profileImage'] != null &&
        userData!['profileImage'].toString().isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: Image.network(
          userData!['profileImage'],
          width: 50,
          height: 50,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildDefaultLogo(),
        ),
      );
    } else {
      return Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.green,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Center(
          child: Text(
            userData?['name']?.substring(0, 1).toUpperCase() ?? 'S',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }
  }

  Widget _buildDefaultLogo() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(25),
      ),
      child: Icon(Icons.business, color: Colors.grey[400]),
    );
  }

  Widget _buildDetailChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.blue,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return '';

    if (timestamp is Timestamp) {
      return timeago.format(timestamp.toDate());
    } else if (timestamp is String) {
      try {
        return timeago.format(DateTime.parse(timestamp));
      } catch (e) {
        return timestamp;
      }
    }
    return '';
  }
}

// Placeholder for the Application Screen
