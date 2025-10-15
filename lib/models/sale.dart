import 'sale_item.dart';

class Sale {
  int? id;
  String invoiceNumber;
  DateTime saleDate;
  double totalAmount;
  double finalAmount;
  List<SaleItem> items;
  int? customerId;
  String? customerName;
  final double totalReturn;
  String? createdBy;
  String? cashierName;

  Sale({
    this.id,
    required this.invoiceNumber,
    required this.saleDate,
    required this.totalAmount,
    required this.finalAmount,
    required this.items,
    this.customerId,
    this.customerName,
    this.totalReturn = 0.0,
    this.createdBy,
    this.cashierName,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'invoice_number': invoiceNumber,
        'sale_date': saleDate.toIso8601String(),
        'total_amount': totalAmount,
        'final_amount': finalAmount,
        'customer_id': customerId,
        'customer_name': customerName,
        'total_return': totalReturn,
        if (createdBy != null) 'created_by': createdBy,
      };

  factory Sale.fromMap(Map<String, dynamic> map) => Sale(
        id: map['id'],
        invoiceNumber: map['invoice_number'],
        saleDate: DateTime.parse(map['sale_date']),
        totalAmount: (map['total_amount'] as num).toDouble(),
        finalAmount: (map['final_amount'] as num).toDouble(),
        items: [],
        customerId: map['customer_id'],
        customerName: map['customer_name'],
        totalReturn: (map['total_return'] as num?)?.toDouble() ?? 0.0,
        createdBy: map['created_by'],
        cashierName: map['cashier_name'],
      );
}
