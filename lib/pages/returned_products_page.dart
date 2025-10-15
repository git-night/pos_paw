import '../models/sale.dart';
import '../models/sale_item.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ReturnedProductsPage extends StatefulWidget {
  const ReturnedProductsPage({super.key});

  @override
  State<ReturnedProductsPage> createState() => _ReturnedProductsPageState();
}

class _ReturnedProductsPageState extends State<ReturnedProductsPage> {
  final SupabaseService _supabaseService = SupabaseService();
  List<SaleItem> _returnedItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReturnedItems();
  }

  Future<void> _loadReturnedItems() async {
    setState(() => _isLoading = true);

    try {
      // Get all sales with returns
      final sales = await _supabaseService.getSales();
      final salesWithReturns = sales.where((s) => s.totalReturn > 0).toList();

      // Collect all returned items
      List<SaleItem> allReturnedItems = [];
      for (var sale in salesWithReturns) {
        final items = await _supabaseService.getSaleItems(sale.id!);
        final returnedItems = items.where((item) => item.returnedQuantity > 0).toList();

        // Add sale info to items for display
        for (var item in returnedItems) {
          item.saleId = sale.id!;
          // Store invoice number in discountReason temporarily for display
          item.discountReason = sale.invoiceNumber;
        }

        allReturnedItems.addAll(returnedItems);
      }

      if (mounted) {
        setState(() {
          _returnedItems = allReturnedItems;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat data: $e')),
        );
      }
    }
  }

  int get _totalReturnedQuantity {
    return _returnedItems.fold(0, (sum, item) => sum + item.returnedQuantity);
  }

  double get _totalReturnedValue {
    return _returnedItems.fold(
      0.0,
      (sum, item) => sum + (item.unitPrice * item.returnedQuantity),
    );
  }

  Map<String, List<SaleItem>> get _groupedByProduct {
    Map<String, List<SaleItem>> grouped = {};
    for (var item in _returnedItems) {
      if (!grouped.containsKey(item.productName)) {
        grouped[item.productName] = [];
      }
      grouped[item.productName]!.add(item);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Produk Retur'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Statistics Cards
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  color: AppColors.backgroundSecondary,
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Total Unit',
                          _totalReturnedQuantity.toString(),
                          Icons.inventory_2_outlined,
                          AppColors.warning,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'Total Nilai',
                          formatCurrency(_totalReturnedValue),
                          Icons.payments_outlined,
                          AppColors.destructive,
                        ),
                      ),
                    ],
                  ),
                ),
                // Products List
                Expanded(
                  child: _returnedItems.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _groupedByProduct.length,
                          itemBuilder: (context, index) {
                            final productName = _groupedByProduct.keys.elementAt(index);
                            final items = _groupedByProduct[productName]!;
                            return _buildProductCard(productName, items);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.foregroundMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 18,
              color: AppColors.foreground,
              fontWeight: FontWeight.w700,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.muted,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.assignment_return_outlined,
              size: 64,
              color: AppColors.foregroundMuted,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Tidak ada produk retur',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.foreground,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Belum ada produk yang diretur',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.foregroundMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(String productName, List<SaleItem> items) {
    final totalReturned = items.fold(0, (sum, item) => sum + item.returnedQuantity);
    final totalValue = items.fold(
      0.0,
      (sum, item) => sum + (item.unitPrice * item.returnedQuantity),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: const EdgeInsets.only(bottom: 8),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.inventory_2_outlined,
              size: 24,
              color: AppColors.warning,
            ),
          ),
          title: Text(
            productName,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.foreground,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                  ),
                  child: Text(
                    '$totalReturned unit diretur',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.warning,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  formatCurrency(totalValue),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.destructive,
                  ),
                ),
              ],
            ),
          ),
          children: items.map((item) => _buildReturnItem(item)).toList(),
        ),
      ),
    );
  }

  Widget _buildReturnItem(SaleItem item) {
    final returnValue = item.unitPrice * item.returnedQuantity;
    final invoiceNumber = item.discountReason ?? 'N/A';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.muted.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.receipt_outlined,
                      size: 12,
                      color: AppColors.foregroundMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      invoiceNumber,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.foregroundMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.destructive.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        '${item.returnedQuantity}x',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.destructive,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '@ ${formatCurrency(item.unitPrice)}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.foregroundMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            formatCurrency(returnValue),
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.foreground,
            ),
          ),
        ],
      ),
    );
  }
}
