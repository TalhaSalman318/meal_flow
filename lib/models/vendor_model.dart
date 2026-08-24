class VendorModel {
  final String id;
  final String profileId;
  final String vendorCode;
  final String vendorName;
  final String? contactPerson;
  final String? phone;
  final String? email;
  final String status;

  const VendorModel({
    required this.id,
    required this.profileId,
    required this.vendorCode,
    required this.vendorName,
    this.contactPerson,
    this.phone,
    this.email,
    required this.status,
  });

  factory VendorModel.fromMap(Map<String, dynamic> map) {
    final vendorCode = map['vendor_code'];
    final vendorName = map['vendor_name'];

    if (vendorCode is! String || vendorCode.trim().isEmpty) {
      throw const FormatException('Vendor code is missing or invalid.');
    }

    if (vendorName is! String || vendorName.trim().isEmpty) {
      throw const FormatException('Vendor name is missing or invalid.');
    }

    return VendorModel(
      id: map['id'] as String,
      profileId: map['profile_id'] as String,
      vendorCode: vendorCode,
      vendorName: vendorName,
      contactPerson: map['contact_person'] as String?,
      phone: map['phone'] as String?,
      email: map['email'] as String?,
      status: map['status'] as String? ?? 'ACTIVE',
    );
  }

  bool get isActive => status.toUpperCase() == 'ACTIVE';
}
