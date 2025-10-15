class PurchaseItem {
  int? id;
  int purchaseId;
  int productId;
  String productName;
  int quantity;
  double unitPrice;
  double totalPrice;

  PurchaseItem(
      {this.id,
      required this.purchaseId,
      required this.productId,
      required this.productName,
      required this.quantity,
      required this.unitPrice,
      required this.totalPrice});

  Map<String, dynamic> toMap() => {
        'id': id,
        'purchase_id': purchaseId,
        'product_id': productId,
        'product_name': productName,
        'quantity': quantity,
        'unit_price': unitPrice,
        'total_price': totalPrice
      };

  factory PurchaseItem.fromMap(Map<String, dynamic> map) => PurchaseItem(
      id: map['id'],
      purchaseId: map['purchase_id'],
      productId: map['product_id'],
      productName: map['product_name'],
      quantity: map['quantity'],
      unitPrice: (map['unit_price'] as num).toDouble(),
      totalPrice: (map['total_price'] as num).toDouble());
}
