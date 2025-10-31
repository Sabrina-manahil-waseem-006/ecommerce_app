class SupervisorRequest {
  final String id;
  final Map<String, dynamic> personalInfo;
  final String proofFileUrl;
  final String status;
  final DateTime? createdAt;

  SupervisorRequest({
    required this.id,
    required this.personalInfo,
    required this.proofFileUrl,
    required this.status,
    this.createdAt,
  });

  // Factory constructor to convert Firestore document into a model
  factory SupervisorRequest.fromFirestore(
      Map<String, dynamic> data, String id) {
    return SupervisorRequest(
      id: id,
      personalInfo: Map<String, dynamic>.from(data['personalInfo'] ?? {}),
      proofFileUrl: data['proofFileUrl'] ?? '',
      status: data['status'] ?? 'pending',
      createdAt: data['createdAt'] != null
          ? data['createdAt'].toDate() as DateTime
          : null,
    );
  }

  // Optional: Convert model back to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'personalInfo': personalInfo,
      'proofFileUrl': proofFileUrl,
      'status': status,
      'createdAt': createdAt,
    };
  }
}
