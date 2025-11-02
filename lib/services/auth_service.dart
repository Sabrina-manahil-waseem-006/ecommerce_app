import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 🔹 Login
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      final uid = cred.user!.uid;
      final userDoc = await _firestore.collection('users').doc(uid).get();

      if (!userDoc.exists) {
        await _auth.signOut();
        return {'error': 'User record not found'};
      }

      final userData = userDoc.data()!;
      return {'role': userData['role'], 'id': uid};
    } on FirebaseAuthException catch (e) {
      return {'error': e.message ?? 'Login failed'};
    } catch (e) {
      return {'error': 'Something went wrong. Try again.'};
    }
  }

  // 🔹 Signup
  Future<String?> signup(String name, String email, String password) async {
    try {
      final userCred = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);

      await _firestore.collection('users').doc(userCred.user!.uid).set({
        'name': name,
        'email': email,
        'role': 'user',
        'createdAt': FieldValue.serverTimestamp(),
      });

      return null; // success
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  // 🔹 Logout
  Future<void> logout() async {
    await _auth.signOut();
  }
}
