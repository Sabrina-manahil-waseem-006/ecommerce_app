import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  // ---------- SIGN UP ----------
  Future<String?> signUp(String email, String password, String name) async {
    try {
      UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Use UID as Firestore document ID
      await _firestore.collection('users').doc(cred.user!.uid).set({
        'name': name,
        'email': email,
        'role': 'user', // default role
        'createdAt': FieldValue.serverTimestamp(),
      });

      return null; // success
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return "Error: $e";
    }
  }

  // ---------- LOGIN ----------
  Future<String?> signIn(String email, String password) async {
    try {
      UserCredential cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Verify user record exists
      final userDoc = await _firestore
          .collection('users')
          .doc(cred.user!.uid)
          .get();
      if (!userDoc.exists) {
        await _auth.signOut(); // logout if record missing
        return "User record not found in Firestore";
      }

      return null; // success
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return "Error: $e";
    }
  }

  // ---------- GET ROLE ----------
  Future<String?> getUserRole() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (!doc.exists) return null;

    return doc.data()?['role'];
  }

  // ---------- LOGOUT ----------
  Future<void> signOut() async => await _auth.signOut();
}
