import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SupervisorService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  Future<Map<String, dynamic>?> getSupervisorData() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final doc = await _firestore.collection('supervisors').doc(user.uid).get();
    return doc.data();
  }

  Future<Map<String, dynamic>?> getCanteenData(String canteenId) async {
    final doc = await _firestore.collection('canteens').doc(canteenId).get();
    return doc.data();
  }

  Future<void> deleteCanteen(String canteenId) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _firestore.collection('canteens').doc(canteenId).delete();
    await _firestore.collection('supervisors').doc(user.uid).update({
      'canteenId': FieldValue.delete(),
      'canteenName': FieldValue.delete(),
    });
  }

  Future<void> submitSupervisorRequest(Map<String, dynamic> requestData) async {
    await _firestore.collection('supervisor_requests').add(requestData);
  }
}
