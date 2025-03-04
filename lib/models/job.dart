import 'package:cloud_firestore/cloud_firestore.dart';

class Job {
  final String id;
  final String title;
  final String companyName;
  final String companyLogo;
  final String location;
  final String workspaceType;
  final String internshipType;
  final String categoryId;
  final DateTime createdAt;

  Job({
    required this.id,
    required this.title,
    required this.companyName,
    required this.companyLogo,
    required this.location,
    required this.workspaceType,
    required this.internshipType,
    required this.categoryId,
    required this.createdAt,
  });

  factory Job.fromMap(String id, Map<String, dynamic> map) {
    return Job(
      id: id,
      title: map['title'] ?? '',
      companyName: map['companyName'] ?? '',
      companyLogo: map['companyLogo'] ?? '',
      location: map['location'] ?? '',
      workspaceType: map['workspaceType'] ?? '',
      internshipType: map['internshipType'] ?? '',
      categoryId: map['categoryId'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }
}