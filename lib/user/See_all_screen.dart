import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hatka/user/job_card.dart';
import 'package:timeago/timeago.dart' as timeago;

class AllRecentlyPostedScreen extends StatelessWidget {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  AllRecentlyPostedScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Internships'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.blue,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
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
              itemBuilder: (context, index) {
                final job = jobs[index].data() as Map<String, dynamic>;

                // Include the document ID and any additional fields needed by JobCard
                final Map<String, dynamic> jobWithId = {
                  ...job,
                  'id': jobs[index].id,
                };

                // Process the isActive flag
                bool isActive = job['isActive'] ?? true;
                jobWithId['activeStatus'] = isActive ? 'Active' : 'Inactive';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: JobCard(job: jobWithId),
                );
              },
            );
          },
        ),
      ),
    );
  }
}