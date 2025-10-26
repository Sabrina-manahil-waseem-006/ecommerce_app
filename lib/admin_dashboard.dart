import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final _requestsRef = FirebaseFirestore.instance.collection(
    'supervisor_requests',
  );

  Future<void> _approveRequest(DocumentSnapshot reqSnap) async {
    final id = reqSnap.id;
    final data = reqSnap.data() as Map<String, dynamic>? ?? {};
    final personal = (data['personalInfo'] ?? {}) as Map<String, dynamic>;
    final email = personal['email'];
    final password = personal['password']; // from the form
    final adminUid = FirebaseAuth.instance.currentUser?.uid ?? 'admin_unknown';

    try {
      // ✅ 1) CHECK IF EMAIL ALREADY EXISTS IN AUTH
      final methods = await FirebaseAuth.instance.fetchSignInMethodsForEmail(
        email,
      );
      if (methods.isNotEmpty) {
        // user exists in auth... clean old record
        final authUser = await FirebaseAuth.instance
            .signInWithEmailAndPassword(email: email, password: password)
            .catchError((_) => null);

        if (authUser != null) {
          // ❗ Delete old orphaned auth account
          await authUser.user?.delete();
        }
      }

      // ✅ 2) CREATE NEW AUTH ACCOUNT
      UserCredential cred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      final newUid = cred.user!.uid;

      // ✅ 3) SAVE SUPERVISOR DATA
      await FirebaseFirestore.instance
          .collection('supervisors')
          .doc(newUid)
          .set({
            ...data,
            'approvedAt': FieldValue.serverTimestamp(),
            'approvedBy': adminUid,
            'status': 'approved',
          });

      // ✅ 4) SAVE BASIC PROFILE IN USERS COLLECTION
      await FirebaseFirestore.instance.collection('users').doc(newUid).set({
        'name': personal['name'],
        'email': email,
        'role': 'supervisor',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // ✅ 5) DELETE ORIGINAL REQUEST
      await _requestsRef.doc(id).delete();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Supervisor Approved Successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Approve failed: $e')));
    }
  }

  Future<void> _rejectRequest(DocumentSnapshot reqSnap) async {
    final id = reqSnap.id;
    final data = reqSnap.data() as Map<String, dynamic>? ?? {};
    final adminUid = FirebaseAuth.instance.currentUser?.uid ?? 'admin_unknown';

    try {
      await FirebaseFirestore.instance
          .collection('supervisor_requests_rejected')
          .doc(id)
          .set({
            ...data,
            'rejectedAt': FieldValue.serverTimestamp(),
            'rejectedBy': adminUid,
            'status': 'rejected',
          });

      await _requestsRef.doc(id).delete();

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Request rejected')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Reject failed: $e')));
    }
  }

  Widget _buildCard(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final personal = (data['personalInfo'] ?? {}) as Map<String, dynamic>;
    final proofUrl = (data['proofFileUrl'] ?? '') as String;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.05),
            blurRadius: 6,
            spreadRadius: 2,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header (Name)
            Text(
              personal['name'] ?? '',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),

            // Email and phone
            Text(
              '📧 ${personal['email'] ?? ''}',
              style: const TextStyle(color: Colors.white70, fontSize: 15),
            ),
            Text(
              '📞 ${personal['phone'] ?? ''}',
              style: const TextStyle(color: Colors.white70, fontSize: 15),
            ),

            const Divider(height: 24, color: Colors.white24),

            // Proof URL
            if (proofUrl.isNotEmpty)
              GestureDetector(
                onTap: () async {
                  final uri = Uri.tryParse(proofUrl);
                  if (uri != null && await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Cannot open proof URL')),
                      );
                    }
                  }
                },
                child: Container(
                  margin: const EdgeInsets.only(top: 10),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    '📎 View Proof Document',
                    style: TextStyle(
                      color: Colors.blueAccent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.check_circle, color: Colors.white),
                  label: const Text(
                    'Approve',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    minimumSize: const Size(130, 45),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => _approveRequest(doc),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.cancel, color: Colors.white),
                  label: const Text(
                    'Reject',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    minimumSize: const Size(130, 45),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => _rejectRequest(doc),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _requestsRef
            .where('status', isEqualTo: 'pending')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(
              child: Text(
                '⚠️ Error: ${snap.error}',
                style: const TextStyle(color: Colors.white),
              ),
            );
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snap.data!.docs;
          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'No pending requests 🎉',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(top: 12, bottom: 20),
            itemCount: docs.length,
            itemBuilder: (context, i) => _buildCard(docs[i]),
          );
        },
      ),
    );
  }
}
