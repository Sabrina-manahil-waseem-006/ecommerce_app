import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> approveSupervisorRequest(
      DocumentSnapshot reqSnap, BuildContext context) async {
    final id = reqSnap.id;
    final data = reqSnap.data() as Map<String, dynamic>? ?? {};
    final personal = (data['personalInfo'] ?? {}) as Map<String, dynamic>;
    final email = personal['email'];
    final password = personal['password'];
    final adminUid = FirebaseAuth.instance.currentUser?.uid ?? 'admin_unknown';

    try {
      // Check if email already exists
      final methods =
          await FirebaseAuth.instance.fetchSignInMethodsForEmail(email);
      if (methods.isNotEmpty) {
        final authUser = await FirebaseAuth.instance
            .signInWithEmailAndPassword(email: email, password: password)
            .catchError((_) => null);
        if (authUser != null) await authUser.user?.delete();
      }

      // Create new account
      UserCredential cred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      final newUid = cred.user!.uid;

      // Save supervisor data
      await _firestore.collection('supervisors').doc(newUid).set({
        ...data,
        'approvedAt': FieldValue.serverTimestamp(),
        'approvedBy': adminUid,
        'status': 'approved',
      });

      // Save profile
      await _firestore.collection('users').doc(newUid).set({
        'name': personal['name'],
        'email': email,
        'role': 'supervisor',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Delete original request
      await _firestore.collection('supervisor_requests').doc(id).delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Supervisor Approved Successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Approve failed: $e')),
      );
    }
  }

  Future<void> rejectSupervisorRequest(
      DocumentSnapshot reqSnap, BuildContext context) async {
    final id = reqSnap.id;
    final data = reqSnap.data() as Map<String, dynamic>? ?? {};
    final adminUid = FirebaseAuth.instance.currentUser?.uid ?? 'admin_unknown';

    try {
      await _firestore.collection('supervisor_requests_rejected').doc(id).set({
        ...data,
        'rejectedAt': FieldValue.serverTimestamp(),
        'rejectedBy': adminUid,
        'status': 'rejected',
      });

      await _firestore.collection('supervisor_requests').doc(id).delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request rejected')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reject failed: $e')),
      );
    }
  }
}
