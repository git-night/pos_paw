import 'package:flutter/foundation.dart';

class Discount {
  final int? id;
  final String name;
  // 'product' or 'customer'
  final String targetType;
  final int? targetProductId;
  final int? targetCustomerId;
  // 'percentage' or 'fixed'
  final String valueType;
  final double value;
  final DateTime? startAt;
  final DateTime? endAt;
  final bool isActive;
  final String? createdBy;
  final String? editedBy;
  final DateTime? createdAt;
  final DateTime? editedAt;

  const Discount({
    this.id,
    required this.name,
    required this.targetType,
    this.targetProductId,
    this.targetCustomerId,
    required this.valueType,
    required this.value,
    this.startAt,
    this.endAt,
    this.isActive = true,
    this.createdBy,
    this.editedBy,
    this.createdAt,
    this.editedAt,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'target_type': targetType,
        'target_product_id': targetProductId,
        'target_customer_id': targetCustomerId,
        'value_type': valueType,
        'value': value,
        if (startAt != null) 'start_at': startAt!.toIso8601String(),
        if (endAt != null) 'end_at': endAt!.toIso8601String(),
        'is_active': isActive,
        if (createdBy != null) 'created_by': createdBy,
        if (editedBy != null) 'edited_by': editedBy,
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
        if (editedAt != null) 'edited_at': editedAt!.toIso8601String(),
      };

  factory Discount.fromMap(Map<String, dynamic> map) => Discount(
        id: map['id'] as int?,
        name: map['name'] as String,
        targetType: map['target_type'] as String,
        targetProductId: map['target_product_id'] as int?,
        targetCustomerId: map['target_customer_id'] as int?,
        valueType: map['value_type'] as String,
        value: (map['value'] as num).toDouble(),
        startAt: map['start_at'] != null ? DateTime.parse(map['start_at']) : null,
        endAt: map['end_at'] != null ? DateTime.parse(map['end_at']) : null,
        isActive: (map['is_active'] as bool?) ?? true,
        createdBy: map['created_by'] as String?,
        editedBy: map['edited_by'] as String?,
        createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : null,
        editedAt: map['edited_at'] != null ? DateTime.parse(map['edited_at']) : null,
      );

  bool get isTimeActive {
    final now = DateTime.now();
    final afterStart = startAt == null || now.isAfter(startAt!) || now.isAtSameMomentAs(startAt!);
    final beforeEnd = endAt == null || now.isBefore(endAt!) || now.isAtSameMomentAs(endAt!);
    return isActive && afterStart && beforeEnd;
  }

  String get targetLabel =>
      targetType == 'product' ? 'Produk #$targetProductId' : 'Pelanggan #$targetCustomerId';

  String get valueLabel => valueType == 'percentage' ? '${value.toStringAsFixed(0)}%' : 'Rp ${value.toStringAsFixed(0)}';
}