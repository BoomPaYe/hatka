import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Enhanced signup with more robust validation
  Future<String?> signup({
    required String name,
    required String email,
    required String password,
    required String role,
    required String phonenumber,
  }) async {
    // Email validation regex
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

    // Validate inputs before processing
    if (name.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }

    if (!emailRegex.hasMatch(email.trim())) {
      return 'Invalid email format';
    }

    if (password.length < 6) {
      return 'Password must be at least 6 characters';
    }

    try {
      UserCredential userCredential =
      await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'name': name.trim(),
        'email': email.trim(),
        'phonenumber': phonenumber.trim(),
        'role': role,
        'createdAt': FieldValue.serverTimestamp(), // Track creation time
      });

      return null; // Success
    } on FirebaseAuthException catch (e) {
      // More specific error handling for signup
      switch (e.code) {
        case 'email-already-in-use':
          return 'Email already registered';
        case 'weak-password':
          return 'Password is too weak';
        default:
          return e.message ?? 'Signup failed';
      }
    } catch (e) {
      return e.toString();
    }
  }

  // Your existing login method remains excellent
  Future<String?> login({
    required String email,
    required String password
  }) async {
    // [Keep your existing implementation]
  }

  // Enhanced signOut with optional redirect
  Future<void> signOut({VoidCallback? onSignedOut}) async {
    await _auth.signOut();
    onSignedOut?.call(); // Optional callback for navigation
  }

  // Get current user's full details
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // More robust user ID retrieval
  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  // Retrieve user role (can be used after login)
  Future<String?> getCurrentUserRole() async {
    final userId = getCurrentUserId();
    if (userId == null) return null;

    try {
      final userDoc = await _firestore
          .collection('users')
          .doc(userId)
          .get();

      return userDoc.exists ? userDoc['role'] : null;
    } catch (e) {
      print('Error fetching user role: $e');
      return null;
    }
  }

  // Password reset method
  Future<String?> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return null; // Success
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Password reset failed';
    }
  }
}