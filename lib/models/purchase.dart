class Purchase {
  int? id;
  String invoiceNumber;
  DateTime purchaseDate;
  double totalAmount;
  String? supplier;
  String? createdBy;
  String? cashierName;

  Purchase({
    this.id,
    required this.invoiceNumber,
    required this.purchaseDate,
    required this.totalAmount,
    this.supplier,
    this.createdBy,
    this.cashierName,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'invoice_number': invoiceNumber,
        'purchase_date': purchaseDate.toIso8601String(),
        'total_amount': totalAmount,
        'supplier': supplier,
        if (createdBy != null) 'created_by': createdBy,
      };

  factory Purchase.fromMap(Map<String, dynamic> map) => Purchase(
        id: map['id'],
        invoiceNumber: map['invoice_number'],
        purchaseDate: DateTime.parse(map['purchase_date']),
        totalAmount: (map['total_amount'] as num).toDouble(),
        supplier: map['supplier'],
        createdBy: map['created_by'],
      );
}
