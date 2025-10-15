import '../models/purchase.dart';
import '../models/purchase_item.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PurchaseDetailPage extends StatefulWidget {
  final Purchase purchase;
  const PurchaseDetailPage({super.key, required this.purchase});

  @override
  State<PurchaseDetailPage> createState() => _PurchaseDetailPageState();
}

class _PurchaseDetailPageState extends State<PurchaseDetailPage> {
  final SupabaseService _supabaseService = SupabaseService();
  List<PurchaseItem> _purchaseItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPurchaseItems();
  }

  Future<void> _loadPurchaseItems() async {
    setState(() {
      _isLoading = true;
    });
    final items = await _supabaseService.getPurchaseItems(widget.purchase.id!);
    if (mounted) {
      setState(() {
        _purchaseItems = items;
        _isLoading = false;
      });
    }
  }

  int get _totalQuantity {
    return _purchaseItems.fold(0, (sum, item) => sum + item.quantity);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Pembelian'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Purchase Summary Header
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
                                      widget.purchase.invoiceNumber,
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
                                          formatDate(widget.purchase.purchaseDate),
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
                          if (widget.purchase.supplier != null &&
                              widget.purchase.supplier!.isNotEmpty) ...[
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
                                    Icons.storefront_outlined,
                                    size: 16,
                                    color: AppColors.foregroundMuted,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Supplier:',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: AppColors.foregroundMuted,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      widget.purchase.supplier!,
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
                          if (widget.purchase.cashierName != null) ...[
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
                                    Icons.person_outline,
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
                                      widget.purchase.cashierName!,
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
                                    'Total Pembelian',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: AppColors.foregroundMuted,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    formatCurrency(widget.purchase.totalAmount),
                                    style: GoogleFonts.inter(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
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
                        'Item Dibeli (${_purchaseItems.length})',
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
                    itemCount: _purchaseItems.length,
                    itemBuilder: (context, index) {
                      final item = _purchaseItems[index];
                      return _buildItemCard(item);
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildItemCard(PurchaseItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
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
                        color: AppColors.primary,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'unit',
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        color: AppColors.primary,
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
                      color: AppColors.foreground,
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
                  formatCurrency(item.totalPrice),
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
      ),
    );
  }
}
