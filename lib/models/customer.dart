class Customer {
  final int? id;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final String? createdBy;
  final String? editedBy;
  final DateTime? createdAt;
  final DateTime? editedAt;

  Customer({
    this.id,
    required this.name,
    this.phone,
    this.email,
    this.address,
    this.createdBy,
    this.editedBy,
    this.createdAt,
    this.editedAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'phone': phone,
        'email': email,
        'address': address,
        if (createdBy != null) 'created_by': createdBy,
        if (editedBy != null) 'edited_by': editedBy,
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
        if (editedAt != null) 'edited_at': editedAt!.toIso8601String(),
      };

  factory Customer.fromMap(Map<String, dynamic> map) => Customer(
        id: map['id'],
        name: map['name'],
        phone: map['phone'],
        email: map['email'],
        address: map['address'],
        createdBy: map['created_by'],
        editedBy: map['edited_by'],
        createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : null,
        editedAt: map['edited_at'] != null ? DateTime.parse(map['edited_at']) : null,
      );
}
