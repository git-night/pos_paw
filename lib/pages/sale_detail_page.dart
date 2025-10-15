import '../models/sale.dart';
import '../models/sale_item.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SaleDetailPage extends StatefulWidget {
  final Sale sale;
  const SaleDetailPage({super.key, required this.sale});

  @override
  State<SaleDetailPage> createState() => _SaleDetailPageState();
}

class _SaleDetailPageState extends State<SaleDetailPage> {
  final SupabaseService _supabaseService = SupabaseService();
  List<SaleItem> _saleItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSaleItems();
  }

  Future<void> _loadSaleItems() async {
    setState(() {
      _isLoading = true;
    });
    final items = await _supabaseService.getSaleItems(widget.sale.id!);
    if (mounted) {
      setState(() {
        _saleItems = items;
        _isLoading = false;
      });
    }
  }

  int get _totalQuantity {
    return _saleItems.fold(0, (sum, item) => sum + item.quantity);
  }

  @override
  Widget build(BuildContext context) {
    final double totalItemDiscount = _saleItems.fold(0.0, (sum, item) => sum + item.discount);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Invoice'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Sale Summary Header
                Container(
                  padding: const EdgeInsets.all(16),
                  color: AppColors.backgroundSecondary,
                  child: Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.receipt_long_outlined,
                                  size: 24,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.sale.invoiceNumber,
                                      style: GoogleFonts.inter(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.foreground,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.calendar_today_outlined,
                                          size: 12,
                                          color: AppColors.foregroundMuted,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          formatDate(widget.sale.saleDate),
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: AppColors.foregroundMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (widget.sale.customerName != null &&
                              widget.sale.customerName!.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.muted,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.person_outline,
                                    size: 16,
                                    color: AppColors.foregroundMuted,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Pelanggan:',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: AppColors.foregroundMuted,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      widget.sale.customerName!,
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.foreground,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          if (widget.sale.cashierName != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.muted,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.badge_outlined,
                                    size: 16,
                                    color: AppColors.foregroundMuted,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Kasir:',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: AppColors.foregroundMuted,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      widget.sale.cashierName!,
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.foreground,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          const Divider(height: 1),
                          const SizedBox(height: 16),
                          _buildAmountSection(totalItemDiscount),
                        ],
                      ),
                    ),
                  ),
                ),
                // Items List
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 20,
                        color: AppColors.foreground,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Item Dibeli (${_saleItems.length})',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.foreground,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: _saleItems.length,
                    itemBuilder: (context, index) {
                      final item = _saleItems[index];
                      return _buildItemCard(item);
                    },
                  ),
                ),
              ],
            ),
    );
  }


  Widget _buildAmountSection(double totalItemDiscount) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Item',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.foregroundMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$_totalQuantity item',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.foreground,
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Subtotal',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.foregroundMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  formatCurrency(widget.sale.totalAmount),
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.foreground,
                  ),
                ),
              ],
            ),
          ],
        ),
        if (totalItemDiscount > 0) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.brown.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.brown.shade200),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.discount_outlined,
                  size: 16,
                  color: Colors.brown.shade600,
                ),
                const SizedBox(width: 8),
                Text(
                  'Total Diskon:',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.brown.shade600,
                  ),
                ),
                const Spacer(),
                Text(
                  '- ${formatCurrency(totalItemDiscount)}',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.brown.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
        if (widget.sale.totalReturn > 0) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF5E6D3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFD4A574)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.assignment_return_outlined,
                  size: 16,
                  color: const Color(0xFF8B6914),
                ),
                const SizedBox(width: 8),
                Text(
                  'Total Retur:',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF8B6914),
                  ),
                ),
                const Spacer(),
                Text(
                  '- ${formatCurrency(widget.sale.totalReturn)}',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF6B4E03),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        const Divider(height: 1),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Total Bayar Akhir',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.foreground,
              ),
            ),
            Text(
              formatCurrency(widget.sale.finalAmount),
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildItemCard(SaleItem item) {
    final isFullyReturned = item.quantity > 0 && item.quantity == item.returnedQuantity;
    final itemColor = isFullyReturned ? AppColors.foregroundMuted : AppColors.primary;
    final textColor = isFullyReturned ? AppColors.foregroundMuted : AppColors.foreground;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: itemColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${item.quantity}',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: itemColor,
                        height: 1.0,
                        decoration: isFullyReturned ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'unit',
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        color: itemColor,
                        fontWeight: FontWeight.w500,
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.productName,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                      decoration: isFullyReturned ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.muted,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${formatCurrency(item.unitPrice)} / unit',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.foregroundMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (item.discount > 0) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.discount_outlined,
                            size: 12,
                            color: Colors.orange.shade700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${formatCurrency(item.discount)}',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: Colors.orange.shade800,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (item.discountReason != null && item.discountReason!.isNotEmpty) ...[
                            const SizedBox(width: 4),
                            Text(
                              '(${item.discountReason})',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: Colors.orange.shade600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                  if (item.returnedQuantity > 0) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.assignment_return_outlined,
                            size: 12,
                            color: Colors.red.shade700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Diretur: ${item.returnedQuantity} unit',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: Colors.red.shade800,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Total',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: AppColors.foregroundMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  formatCurrency(item.finalPrice),
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                    decoration: isFullyReturned ? TextDecoration.lineThrough : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
