import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hatka/user/Category_screen.dart';
import 'package:hatka/user/job_card.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'See_all_screen.dart';

class UserMainScreen extends StatefulWidget {
  @override
  _UserMainScreenState createState() => _UserMainScreenState();
}

class _UserMainScreenState extends State<UserMainScreen> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final List<Map<String, dynamic>> categories = [
    {
      'icon': Icons.computer,
      'name': 'Information Technology',
      'category': 'IT'
    },
    {'icon': Icons.attach_money, 'name': 'Finance', 'category': 'Finance'},
    {'icon': Icons.business, 'name': 'Marketing', 'category': 'Marketing'},
    {'icon': Icons.palette, 'name': 'Design', 'category': 'Design'},
    {
      'icon': Icons.engineering,
      'name': 'Engineering',
      'category': 'Engineering'
    },
    {'icon': Icons.more_horiz, 'name': 'See more', 'category': 'more'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              Text(
                'Browse by Categories',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              _buildCategories(),
              const SizedBox(height: 24),
              _buildRecentlyPosted(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Find Your Internships',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildCategories() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return InkWell(
          onTap: () {
            if (category['category'] != 'more') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CategoryJobsScreen(
                    category: category['category'].toString(),
                    categoryName: category['name'].toString(),
                  ),
                ),
              );
            }
          },
          child: Container(
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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  category['icon'] as IconData,
                  size: 28,
                  color: Colors.blue,
                ),
                const SizedBox(height: 8),
                Text(
                  category['name']!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecentlyPosted() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recently Posted',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              TextButton(
                onPressed: () {
                  // Navigate to the AllRecentlyPostedScreen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AllRecentlyPostedScreen(),
                    ),
                  );
                },
                child: const Text('See all'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            // Rest of your existing StreamBuilder code remains the same
            child: StreamBuilder<QuerySnapshot>(
              stream: firestore
                  .collection('posts')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final jobs = snapshot.data?.docs ?? [];

                if (jobs.isEmpty) {
                  return const Center(child: Text('No internships found'));
                }

                return ListView.builder(
                  itemCount: jobs.length,
                  padding: EdgeInsets.zero,
                  itemBuilder: (context, index) {
                    final job = jobs[index].data() as Map<String, dynamic>;

                    // Include the document ID and any additional fields needed by JobCard
                    final Map<String, dynamic> jobWithId = {
                      ...job,
                      'id': jobs[index].id,
                    };

                    // Process the isActive flag and convert it to the activeStatus string that JobCard expects
                    bool isActive = job['isActive'] ?? true;
                    jobWithId['activeStatus'] =
                        isActive ? 'Active' : 'Inactive';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: JobCard(job: jobWithId),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
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

  Widget _buildChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.blue.shade700,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
