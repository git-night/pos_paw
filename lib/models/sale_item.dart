class SaleItem {
  int? id;
  int saleId;
  int productId;
  String productName;
  int quantity;
  double unitPrice;
  double totalPrice;
  int returnedQuantity;
  double discount;
  String? discountReason;

  SaleItem({
    this.id,
    required this.saleId,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    this.returnedQuantity = 0,
    this.discount = 0.0,
    this.discountReason,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'sale_id': saleId,
        'product_id': productId,
        'product_name': productName,
        'quantity': quantity,
        'unit_price': unitPrice,
        'total_price': totalPrice,
        'returned_quantity': returnedQuantity,
        'discount': discount,
        'discount_reason': discountReason,
      };

  factory SaleItem.fromMap(Map<String, dynamic> map) => SaleItem(
        id: map['id'],
        saleId: map['sale_id'],
        productId: map['product_id'],
        productName: map['product_name'],
        quantity: map['quantity'],
        unitPrice: (map['unit_price'] as num).toDouble(),
        totalPrice: (map['total_price'] as num).toDouble(),
        returnedQuantity: map['returned_quantity'] ?? 0,
        discount: (map['discount'] as num?)?.toDouble() ?? 0.0,
        discountReason: map['discount_reason'],
      );

  int get returnableQuantity => quantity - returnedQuantity;
  double get finalPrice => totalPrice - discount;
}
