import '../models/sale.dart';
import '../models/sale_item.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ReturnDetailPage extends StatefulWidget {
  final Sale sale;
  const ReturnDetailPage({super.key, required this.sale});

  @override
  State<ReturnDetailPage> createState() => _ReturnDetailPageState();
}

class _ReturnDetailPageState extends State<ReturnDetailPage> {
  final SupabaseService _supabaseService = SupabaseService();
  List<SaleItem> _saleItems = [];
  Map<int, int> _returnQuantities = {};
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
        _returnQuantities = {for (var item in items) item.id!: 0};
        _isLoading = false;
      });
    }
  }

  void _confirmAndProcessReturn() {
    final Map<SaleItem, int> itemsToReturn = {};
    for (final item in _saleItems) {
      final qty = _returnQuantities[item.id!] ?? 0;
      if (qty > 0) {
        itemsToReturn[item] = qty;
      }
    }

    if (itemsToReturn.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Pilih minimal satu produk untuk diretur.'),
        backgroundColor: Colors.orange,
      ));
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Konfirmasi Retur', textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Anda akan meretur item berikut dari invoice:'),
            const SizedBox(height: 4),
            Text(widget.sale.invoiceNumber,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const Divider(height: 20),
            ...itemsToReturn.entries
                .map((entry) => Text('• ${entry.value}x ${entry.key.productName}')),
            const SizedBox(height: 16),
            const Text('Stok akan dikembalikan. Lanjutkan?'),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              try {
                await _supabaseService.processPartialReturn(itemsToReturn);

                final updatedItems =
                    await _supabaseService.getSaleItems(widget.sale.id!);
                int totalQuantity = 0;
                int totalReturned = 0;
                for (var item in updatedItems) {
                  totalQuantity += item.quantity;
                  totalReturned += item.returnedQuantity;
                }

                if (mounted) {
                  Navigator.pop(ctx);
                }

                if (totalQuantity > 0 && totalQuantity == totalReturned) {
                  await _supabaseService.deleteSale(widget.sale.id!);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Semua item telah diretur. Invoice dihapus.'),
                      backgroundColor: Colors.blue,
                    ));
                    Navigator.pop(context, true);
                  }
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Produk berhasil diretur.'),
                      backgroundColor: Colors.green,
                    ));
                    Navigator.pop(context, true);
                  }
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Gagal memproses retur: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ));
                }
              }
            },
            child: const Text('Ya, Proses Retur'),
          ),
        ],
      ),
    );
  }

  int get _totalReturnQty {
    return _returnQuantities.values.fold(0, (sum, qty) => sum + qty);
  }

  double get _totalReturnAmount {
    double total = 0;
    for (var item in _saleItems) {
      final qty = _returnQuantities[item.id!] ?? 0;
      total += (item.unitPrice * qty);
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pilih Item Retur'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Invoice Summary Card
                Container(
                  padding: const EdgeInsets.all(16),
                  color: AppColors.backgroundSecondary,
                  child: Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.receipt_long_outlined,
                                  size: 20,
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
                                    const SizedBox(height: 2),
                                    Text(
                                      formatDate(widget.sale.saleDate),
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: AppColors.foregroundMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                formatCurrency(widget.sale.finalAmount),
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                          if (_totalReturnQty > 0) ...[
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
                                      'Item Diretur',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        color: AppColors.foregroundMuted,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '$_totalReturnQty item',
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
                                      'Nilai Retur',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        color: AppColors.foregroundMuted,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      formatCurrency(_totalReturnAmount),
                                      style: GoogleFonts.inter(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.destructive,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                // Items List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _saleItems.length,
                    itemBuilder: (context, index) {
                      final item = _saleItems[index];
                      final returnable = item.returnableQuantity;
                      final currentReturnQty = _returnQuantities[item.id!] ?? 0;

                      return _buildReturnItemCard(
                        item,
                        returnable,
                        currentReturnQty,
                      );
                    },
                  ),
                ),
              ],
            ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton.icon(
          onPressed: _confirmAndProcessReturn,
          icon: const Icon(Icons.assignment_return),
          label: Text(_totalReturnQty > 0
              ? 'Proses Retur ($_totalReturnQty item)'
              : 'Proses Retur'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.destructive,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildReturnItemCard(SaleItem item, int returnable, int currentReturnQty) {
    final isReturnable = returnable > 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isReturnable
                        ? AppColors.primary.withOpacity(0.1)
                        : AppColors.muted,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.inventory_2_outlined,
                    size: 24,
                    color: isReturnable
                        ? AppColors.primary
                        : AppColors.foregroundMuted,
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
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.foreground,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _buildInfoChip(
                            'Dibeli: ${item.quantity}',
                            Icons.shopping_bag_outlined,
                            AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          _buildInfoChip(
                            'Diretur: ${item.returnedQuantity}',
                            Icons.assignment_return_outlined,
                            AppColors.warning,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        formatCurrency(item.unitPrice),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.foregroundMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (!isReturnable) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.muted,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: AppColors.foregroundMuted,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Semua item sudah diretur',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.foregroundMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (isReturnable) ...[
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Jumlah diretur:',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.foreground,
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: currentReturnQty == 0
                                ? null
                                : () => setState(() =>
                                    _returnQuantities[item.id!] =
                                        currentReturnQty - 1),
                            borderRadius: const BorderRadius.horizontal(
                              left: Radius.circular(8),
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              child: Icon(
                                Icons.remove,
                                size: 20,
                                color: currentReturnQty == 0
                                    ? AppColors.foregroundMuted.withOpacity(0.3)
                                    : AppColors.foreground,
                              ),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(
                            border: Border.symmetric(
                              vertical: BorderSide(color: AppColors.border),
                            ),
                          ),
                          child: Text(
                            currentReturnQty.toString(),
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.foreground,
                            ),
                          ),
                        ),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: currentReturnQty >= returnable
                                ? null
                                : () => setState(() =>
                                    _returnQuantities[item.id!] =
                                        currentReturnQty + 1),
                            borderRadius: const BorderRadius.horizontal(
                              right: Radius.circular(8),
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              child: Icon(
                                Icons.add,
                                size: 20,
                                color: currentReturnQty >= returnable
                                    ? AppColors.foregroundMuted.withOpacity(0.3)
                                    : AppColors.foreground,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (currentReturnQty > 0) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.destructive.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.destructive.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Nilai retur item ini:',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.destructive,
                        ),
                      ),
                      Text(
                        formatCurrency(item.unitPrice * currentReturnQty),
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.destructive,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
