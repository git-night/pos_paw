import '../models/sale.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'return_detail_page.dart';
import 'returned_products_page.dart';

class ReturnsPage extends StatefulWidget {
  const ReturnsPage({super.key});

  @override
  State<ReturnsPage> createState() => _ReturnsPageState();
}

class _ReturnsPageState extends State<ReturnsPage> {
  final SupabaseService _supabaseService = SupabaseService();
  final TextEditingController _searchController = TextEditingController();
  List<Sale> _sales = [];
  List<Sale> _filteredSales = [];

  @override
  void initState() {
    super.initState();
    _loadSales();
    _searchController.addListener(_filterSales);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSales() async {
    final salesList = await _supabaseService.getSales();
    if (mounted) {
      setState(() {
        _sales = salesList;
        _filteredSales = salesList;
      });
    }
  }

  void _filterSales() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredSales = _sales
          .where((s) => s.invoiceNumber.toLowerCase().contains(query))
          .toList();
    });
  }

  int get _totalReturns {
    return _sales.where((s) => s.totalReturn > 0).length;
  }

  double get _totalReturnAmount {
    return _sales.fold(0.0, (sum, s) => sum + s.totalReturn);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Retur'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Statistics Cards
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            color: AppColors.backgroundSecondary,
            child: Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Retur',
                    _totalReturns.toString(),
                    Icons.assignment_return_outlined,
                    AppColors.primary,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ReturnedProductsPage(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Nilai Retur',
                    formatCurrency(_totalReturnAmount),
                    Icons.payments_outlined,
                    AppColors.warning,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ReturnedProductsPage(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari nomor invoice...',
                prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
              ),
            ),
          ),
          // Sales List
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadSales,
              child: _filteredSales.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: _filteredSales.length,
                      itemBuilder: (context, index) {
                        final sale = _filteredSales[index];
                        return _buildSaleCard(sale);
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color, {
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
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
                  if (onTap != null)
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: AppColors.foregroundMuted,
                    ),
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
        ),
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
            'Tidak ada invoice penjualan',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.foreground,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Invoice penjualan akan muncul di sini',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.foregroundMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaleCard(Sale sale) {
    final hasReturn = sale.totalReturn > 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ReturnDetailPage(sale: sale),
            ),
          );
          if (result == true) {
            _loadSales();
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              sale.invoiceNumber,
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.foreground,
                              ),
                            ),
                            if (hasReturn) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.warning.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: AppColors.warning.withOpacity(0.3),
                                  ),
                                ),
                                child: Text(
                                  'Ada Retur',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.warning,
                                  ),
                                ),
                              ),
                            ],
                          ],
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
                              formatDate(sale.saleDate),
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
                  Icon(
                    Icons.chevron_right,
                    color: AppColors.foregroundMuted,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Penjualan',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.foregroundMuted,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        formatCurrency(sale.finalAmount),
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  if (hasReturn)
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
                          formatCurrency(sale.totalReturn),
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
          ),
        ),
      ),
    );
  }
}

