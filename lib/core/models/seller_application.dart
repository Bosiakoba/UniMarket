class SellerApplication {
  const SellerApplication({
    required this.fullName,
    required this.studentEmail,
    required this.storeName,
    required this.studentIdUploaded,
    required this.appliedAt,
  });

  final String fullName;
  final String studentEmail;
  final String storeName;
  final bool studentIdUploaded;
  final DateTime appliedAt;
}
