class Student {
  final String id;
  final String name;
  final String mobile;
  final String? email;
  final String city;
  final String gender;
  final String occupation;
  final String paymentStatus;
  final String applicationStatus;
  final String referenceNumber;
  final DateTime? createdAt;

  Student({
    required this.id,
    required this.name,
    required this.mobile,
    this.email,
    required this.city,
    required this.gender,
    required this.occupation,
    required this.paymentStatus,
    required this.applicationStatus,
    required this.referenceNumber,
    this.createdAt,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'],
      name: json['name'],
      mobile: json['mobile'],
      email: json['email'],
      city: json['city'],
      gender: json['gender'],
      occupation: json['occupation'],
      paymentStatus: json['payment_status'] ?? 'pending',
      applicationStatus: json['application_status'] ?? 'payment_pending',
      referenceNumber: json['reference_number'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    );
  }
}
