class User {
  final String id;
  final String? email;  // Email is now nullable for phone auth users
  final String? displayEmail;  // Generated email for display
  final String? fullName;
  final String role;
  final String? phone;
  final String? address;
  final bool isActive;
  final String? avatarUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;
  final DateTime? lastLogin;
  final String? employeeId;
  final String? department;
  final DateTime? hireDate;
  final String? notes;

  User({
    required this.id,
    this.email,
    this.displayEmail,
    this.fullName,
    this.role = 'cashier',
    this.phone,
    this.address,
    this.isActive = true,
    this.avatarUrl,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.lastLogin,
    this.employeeId,
    this.department,
    this.hireDate,
    this.notes,
  });

  // Convert User to Map for database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'display_email': displayEmail,
      'full_name': fullName,
      'role': role,
      'phone': phone,
      'address': address,
      'is_active': isActive,
      'avatar_url': avatarUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'created_by': createdBy,
      'last_login': lastLogin?.toIso8601String(),
      'employee_id': employeeId,
      'department': department,
      'hire_date': hireDate?.toIso8601String(),
      'notes': notes,
    };
  }

  // Create User from Map (database response)
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as String,
      email: map['email'] as String?,
      displayEmail: map['display_email'] as String?,
      fullName: map['full_name'] as String?,
      role: map['role'] as String? ?? 'cashier',
      phone: map['phone'] as String?,
      address: map['address'] as String?,
      isActive: map['is_active'] as bool? ?? true,
      avatarUrl: map['avatar_url'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      createdBy: map['created_by'] as String?,
      lastLogin: map['last_login'] != null 
          ? DateTime.parse(map['last_login'] as String)
          : null,
      employeeId: map['employee_id'] as String?,
      department: map['department'] as String?,
      hireDate: map['hire_date'] != null
          ? DateTime.parse(map['hire_date'] as String)
          : null,
      notes: map['notes'] as String?,
    );
  }

  // Copy with method for updating user
  User copyWith({
    String? id,
    String? email,
    String? displayEmail,
    String? fullName,
    String? role,
    String? phone,
    String? address,
    bool? isActive,
    String? avatarUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    DateTime? lastLogin,
    String? employeeId,
    String? department,
    DateTime? hireDate,
    String? notes,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      displayEmail: displayEmail ?? this.displayEmail,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      isActive: isActive ?? this.isActive,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      lastLogin: lastLogin ?? this.lastLogin,
      employeeId: employeeId ?? this.employeeId,
      department: department ?? this.department,
      hireDate: hireDate ?? this.hireDate,
      notes: notes ?? this.notes,
    );
  }

  // Check if user is admin
  bool get isAdmin => role == 'admin';

  // Check if user is manager
  bool get isManager => role == 'manager';

  // Check if user is cashier
  bool get isCashier => role == 'cashier';

  // Check if user is manager or above
  bool get isManagerOrAbove => isAdmin || isManager;

  // Get display name (full name or email)
  String get displayName {
    if (fullName != null && fullName!.isNotEmpty) {
      return fullName!;
    }
    if (email != null && email!.isNotEmpty) {
      return email!.split('@').first;
    }
    return 'User ${id.substring(0, 8)}';
  }
  
  // Get identifier for display (email, displayEmail, or ID)
  String get identifier => email ?? displayEmail ?? 'User ${id.substring(0, 8)}';

  // Get role display name in Indonesian
  String get roleDisplayName {
    switch (role) {
      case 'admin':
        return 'Administrator';
      case 'manager':
        return 'Manajer';
      case 'cashier':
        return 'Kasir';
      default:
        return 'Kasir';
    }
  }

  @override
  String toString() {
    return 'User(id: $id, email: $email, fullName: $fullName, role: $role, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}