class Category {
  final int? id;
  final String name;
  final String? createdBy;
  final String? editedBy;
  final DateTime? createdAt;
  final DateTime? editedAt;

  Category({
    this.id,
    required this.name,
    this.createdBy,
    this.editedBy,
    this.createdAt,
    this.editedAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        if (createdBy != null) 'created_by': createdBy,
        if (editedBy != null) 'edited_by': editedBy,
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
        if (editedAt != null) 'edited_at': editedAt!.toIso8601String(),
      };

  factory Category.fromMap(Map<String, dynamic> map) => Category(
        id: map['id'],
        name: map['name'],
        createdBy: map['created_by'],
        editedBy: map['edited_by'],
        createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : null,
        editedAt: map['edited_at'] != null ? DateTime.parse(map['edited_at']) : null,
      );
}
