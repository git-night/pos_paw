import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/sale.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import 'sale_detail_page.dart';

class SalesPage extends StatefulWidget {
  const SalesPage({super.key});
  @override
  _SalesPageState createState() => _SalesPageState();
}

class _SalesPageState extends State<SalesPage> {
  final SupabaseService _supabaseService = SupabaseService();
  final TextEditingController _searchController = TextEditingController();
  List<Sale> sales = [];
  List<Sale> filteredSales = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_applyFilter);
    _loadSales();
  }

  Future<void> _loadSales() async {
    final salesList = await _supabaseService.getSales();
    if (!mounted) return;
    setState(() {
      sales = salesList;
    });
    _applyFilter();
  }

  void _applyFilter() {
    final q = _searchController.text.trim().toLowerCase();
    setState(() {
      if (q.isEmpty) {
        filteredSales = List.from(sales);
      } else {
        filteredSales = sales.where((s) => s.invoiceNumber.toLowerCase().contains(q)).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Penjualan')),
      body: RefreshIndicator(
        onRefresh: _loadSales,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Cari invoice...',
                  hintStyle: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.foregroundMuted,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: AppColors.foregroundMuted,
                    size: 20,
                  ),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          icon: Icon(
                            Icons.clear_rounded,
                            size: 20,
                            color: AppColors.foregroundMuted,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            _applyFilter();
                          },
                        ),
                  filled: true,
                  fillColor: AppColors.muted,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            Expanded(
              child: filteredSales.isEmpty
                  ? const Center(child: Text('Belum ada transaksi.'))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filteredSales.length,
                      itemBuilder: (context, index) => _buildSaleCard(filteredSales[index]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaleCard(Sale sale) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () async {
          await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => SaleDetailPage(sale: sale)));
          _loadSales();
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Invoice: ${sale.invoiceNumber}',
                      style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    formatDate(sale.saleDate),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              if (sale.cashierName != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.person_outline, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      'Kasir: ${sale.cashierName}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ],
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Bayar'),
                  Text(
                    formatCurrency(sale.finalAmount),
                    style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: primaryPawColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
