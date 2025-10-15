class Product {
  int? id;
  String name;
  String code;
  double purchasePrice;
  double sellingPrice;
  int stock;
  int stockAlert;
  String category;
  DateTime createdAt;
  String? createdBy;
  String? editedBy;
  DateTime? editedAt;

  Product({
    this.id,
    required this.name,
    required this.code,
    required this.purchasePrice,
    required this.sellingPrice,
    required this.stock,
    required this.stockAlert,
    required this.category,
    required this.createdAt,
    this.createdBy,
    this.editedBy,
    this.editedAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'code': code,
        'purchase_price': purchasePrice,
        'selling_price': sellingPrice,
        'stock': stock,
        'stock_alert': stockAlert,
        'category': category,
        'created_at': createdAt.toIso8601String(),
        if (createdBy != null) 'created_by': createdBy,
        if (editedBy != null) 'edited_by': editedBy,
        if (editedAt != null) 'edited_at': editedAt!.toIso8601String(),
      };

  factory Product.fromMap(Map<String, dynamic> map) => Product(
        id: map['id'],
        name: map['name'],
        code: map['code'],
        purchasePrice: (map['purchase_price'] as num).toDouble(),
        sellingPrice: (map['selling_price'] as num).toDouble(),
        stock: map['stock'],
        stockAlert: map['stock_alert'] ?? 5,
        category: map['category'],
        createdAt: DateTime.parse(map['created_at']),
        createdBy: map['created_by'],
        editedBy: map['edited_by'],
        editedAt: map['edited_at'] != null ? DateTime.parse(map['edited_at']) : null,
      );

  double get profit => sellingPrice - purchasePrice;
  double get profitMargin => sellingPrice > 0 ? (profit / sellingPrice) * 100 : 0;
}
