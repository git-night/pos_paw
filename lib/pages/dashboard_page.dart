import 'dart:math';
import '../models/customer.dart';
import '../models/daily_sale.dart';
import '../models/purchase.dart';
import '../models/sale.dart';
import '../models/sale_item.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import '../widgets/ui_components.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});
  @override
  _DashboardPageState createState() => _DashboardPageState();
}


class _DashboardPageState extends State<DashboardPage> {
  final SupabaseService _supabaseService = SupabaseService();
  double monthlyOmset = 0.0;
  double monthlyProfit = 0.0;
  int monthlyTransactions = 0;
  
  List<ActivityViewModel> _allActivities = [];
  List<ActivityViewModel> _paginatedActivities = [];
  int _currentPage = 0;
  final int _itemsPerPage = 5;

  List<Map<String, dynamic>> topCategories = [];
  List<Map<String, dynamic>> topCustomers = [];
  List<DailySale> dailySalesData = [];
  List<FlSpot> dailySalesSpots = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  void _updatePaginatedActivities() {
    final int startIndex = _currentPage * _itemsPerPage;
    final int endIndex = startIndex + _itemsPerPage;

    setState(() {
      if (startIndex >= _allActivities.length) {
        _paginatedActivities = [];
      } else {
        _paginatedActivities = _allActivities.sublist(
            startIndex, endIndex > _allActivities.length ? _allActivities.length : endIndex);
      }
    });
  }

  Future<void> _loadDashboardData() async {
    if (!mounted) return;

    final stats = await _supabaseService.getSalesStatsForMonth(DateTime.now());
    final allSales = await _supabaseService.getSales();
    final allPurchases = await _supabaseService.getPurchases();
    final categories = await _supabaseService.getTopCategories(3);
    final customers = await _supabaseService.getTopCustomers(3);
    final dailySaleRaw = await _supabaseService.getDailySales();

    List<ActivityViewModel> activities = [];
    for (final sale in allSales) {
      final items = await _supabaseService.getSaleItems(sale.id!);
      bool hasReturns = items.any((item) => item.returnedQuantity > 0);
      activities.add(ActivityViewModel(
        type: hasReturns ? ActivityType.returnedSale : ActivityType.sale,
        date: sale.saleDate,
        title: hasReturns ? 'Retur Penjualan' : 'Penjualan Baru',
        subtitle: 'Invoice: ${sale.invoiceNumber}',
        amountText: formatCurrency(sale.finalAmount),
        icon: hasReturns ? Icons.undo_rounded : Icons.receipt_long_outlined,
        iconColor: hasReturns ? Colors.orange.shade700 : Colors.green.shade700,
      ));
    }

    for (final purchase in allPurchases) {
      activities.add(ActivityViewModel(
        type: ActivityType.purchase,
        date: purchase.purchaseDate,
        title: 'Pembelian Stok',
        subtitle: 'Ref: ${purchase.invoiceNumber}',
        amountText: formatCurrency(purchase.totalAmount),
        icon: Icons.add_shopping_cart_rounded,
        iconColor: Colors.blue.shade700,
      ));
    }
    activities.sort((a, b) => b.date.compareTo(a.date));

    List<DailySale> tempDailySales = dailySaleRaw.map((item) {
      return DailySale(
          DateTime.parse(item['date']), (item['total'] as num).toDouble());
    }).toList();

    List<FlSpot> tempSpots = [];
    for (int i = 0; i < tempDailySales.length; i++) {
      tempSpots.add(FlSpot(i.toDouble(), tempDailySales[i].total));
    }

    if (mounted) {
      setState(() {
        monthlyOmset = stats['omset'] ?? 0.0;
        monthlyProfit = stats['profit'] ?? 0.0;
        monthlyTransactions = (stats['transactions'] ?? 0.0).toInt();
        
        _allActivities = activities;
        _currentPage = 0;
        _updatePaginatedActivities();

        topCategories = categories;
        topCustomers = customers;
        dailySalesData = tempDailySales;
        dailySalesSpots = tempSpots;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          children: [
            const SizedBox(height: 60),
            _buildHeader(),
            const SizedBox(height: 24),
            _buildMainCard(),
            const SizedBox(height: 24),
            _buildStatsRow(),
            const SizedBox(height: 24),
            _buildSalesChart(),
            const SizedBox(height: 24),
            ..._buildRecentActivity(),
            const SizedBox(height: 24),
            _buildTrends(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('My Dashboard', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        CircleAvatar(backgroundColor: primaryPawColor.withOpacity(0.1), child: const Icon(Icons.pets, color: primaryPawColor))
      ],
    );
  }
// --- Ganti method _buildMainCard di _DashboardPageState dengan kode ini ---

Widget _buildMainCard() {
    String currentMonth = DateFormat('MMMM yyyy').format(DateTime.now());
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accent, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Omset Bersih Bulan Ini',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            formatCurrency(monthlyOmset),
            style: GoogleFonts.inter(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            currentMonth,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard('Keuntungan Bersih', formatCurrency(monthlyProfit),
              Icons.trending_up, Colors.green),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
              'Transaksi', '$monthlyTransactions', Icons.receipt_long, Colors.blue),
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return UICard(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.foregroundMuted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.foreground,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalesChart() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Statistik Penjualan',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('7 hari terakhir dengan penjualan',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.foregroundMuted,
                )),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: dailySalesSpots.isEmpty
                  ? const Center(child: Text("Belum ada data penjualan."))
                  : LineChart(
                      LineChartData(
                        gridData: FlGridData(show: false),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          topTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          rightTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 30,
                              interval: 1,
                              getTitlesWidget: (value, meta) {
                                if (value.toInt() < dailySalesData.length) {
                                  final date = dailySalesData[value.toInt()].date;
                                  return SideTitleWidget(
                                    axisSide: meta.axisSide,
                                    space: 8.0,
                                    child: Text(
                                      DateFormat('dd/MM').format(date),
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        color: AppColors.foregroundMuted,
                                      ),
                                    ),
                                  );
                                }
                                return const Text('');
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: dailySalesSpots,
                            isCurved: true,
                            color: primaryPawColor,
                            barWidth: 4,
                            isStrokeCapRound: true,
                            dotData: FlDotData(
                              show: true,
                              getDotPainter: (spot, percent, barData, index) {
                                return FlDotCirclePainter(
                                  radius: 4,
                                  color: Colors.white,
                                  strokeWidth: 2,
                                  strokeColor: primaryPawColor,
                                );
                              },
                            ),
                            belowBarData: BarAreaData(
                              show: true,
                              gradient: LinearGradient(
                                colors: [
                                  primaryPawColor.withOpacity(0.3),
                                  primaryPawColor.withOpacity(0.0)
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                        ],
                        lineTouchData: LineTouchData(
                          touchTooltipData: LineTouchTooltipData(
                            getTooltipColor: (touchedSpot) =>
                                primaryPawColor.withOpacity(0.9),
                            getTooltipItems: (touchedSpots) {
                              return touchedSpots.map((spot) {
                                final date = dailySalesData[spot.x.toInt()].date;
                                return LineTooltipItem(
                                  '${DateFormat('dd MMM').format(date)}\n${spot.y.toInt()} produk',
                                  GoogleFonts.inter(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                );
                              }).toList();
                            },
                          ),
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  void _goToPage(int page) {
    setState(() {
      _currentPage = page;
    });
    _updatePaginatedActivities();
  }

  List<int> _getPageNumbers() {
    final totalPages = (_allActivities.length / _itemsPerPage).ceil();
    if (totalPages <= 5) {
      return List.generate(totalPages, (index) => index);
    } else {
      List<int> pages = [];
      int startPage;
      int endPage;

      if (_currentPage <= 2) {
        startPage = 0;
        endPage = 4;
      } else if (_currentPage >= totalPages - 3) {
        startPage = totalPages - 5;
        endPage = totalPages - 1;
      } else {
        startPage = _currentPage - 2;
        endPage = _currentPage + 2;
      }

      for (int i = startPage; i <= endPage; i++) {
        pages.add(i);
      }
      return pages;
    }
  }

  Widget _buildPageButton({
    IconData? icon,
    String? text,
    required VoidCallback? onPressed,
    bool isSelected = false,
  }) {
    final isDisabled = onPressed == null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2.0),
      child: Container(
        height: 36,
        constraints: const BoxConstraints(minWidth: 36),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accent
              : isDisabled
                  ? Colors.transparent
                  : AppColors.background,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected
                ? AppColors.accent
                : isDisabled
                    ? AppColors.border.withOpacity(0.3)
                    : AppColors.border,
            width: 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isDisabled ? null : onPressed,
            borderRadius: BorderRadius.circular(6),
            splashColor: AppColors.accent.withOpacity(0.1),
            highlightColor: AppColors.accent.withOpacity(0.05),
            child: Container(
              padding: text != null
                  ? const EdgeInsets.symmetric(horizontal: 12)
                  : EdgeInsets.zero,
              alignment: Alignment.center,
              child: text != null
                  ? Text(
                      text,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : isDisabled
                                ? AppColors.foregroundMuted.withOpacity(0.4)
                                : AppColors.foreground,
                      ),
                    )
                  : Icon(
                      icon,
                      size: 18,
                      color: isDisabled
                          ? AppColors.foregroundMuted.withOpacity(0.4)
                          : AppColors.foreground,
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaginationControls() {
    final totalPages = (_allActivities.length / _itemsPerPage).ceil();
    if (totalPages <= 1) return const SizedBox.shrink();

    final startItem = (_currentPage * _itemsPerPage) + 1;
    final endItem = ((_currentPage + 1) * _itemsPerPage).clamp(0, _allActivities.length);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          // Page info text
          Text(
            'Menampilkan $startItem-$endItem dari ${_allActivities.length} aktivitas',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.foregroundMuted,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 12),
          // Pagination buttons
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildPageButton(
                  icon: Icons.chevron_left,
                  onPressed: _currentPage > 0 ? () => _goToPage(_currentPage - 1) : null,
                ),
                const SizedBox(width: 4),
                ..._getPageNumbers().map(
                  (pageIndex) => _buildPageButton(
                    text: '${pageIndex + 1}',
                    isSelected: _currentPage == pageIndex,
                    onPressed: () => _goToPage(pageIndex),
                  ),
                ),
                const SizedBox(width: 4),
                _buildPageButton(
                  icon: Icons.chevron_right,
                  onPressed: _currentPage < totalPages - 1 ? () => _goToPage(_currentPage + 1) : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildRecentActivity() {
    return [
      Text('Aktivitas Terbaru',
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.bold)),
      const SizedBox(height: 16),
      if (_paginatedActivities.isEmpty)
        const Card(
            child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text("Belum ada aktivitas."))),
      ..._paginatedActivities.map((activity) => Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: activity.iconColor.withOpacity(0.1),
                child: Icon(activity.icon, color: activity.iconColor),
              ),
              title: Text(activity.title,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(activity.subtitle),
              trailing: SizedBox(
                width: 120,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      activity.amountText,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('dd MMM, HH:mm').format(activity.date),
                      style: const TextStyle(color: Colors.grey, fontSize: 10),
                      overflow: TextOverflow.ellipsis,
                    )
                  ],
                ),
              ),
            ),
          )),
      
      const SizedBox(height: 8),
      _buildPaginationControls(),
    ];
  }

  Widget _buildTrends() {
    return DefaultTabController(
      length: 2,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Tren Penjualan', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Container(
          height: 50,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: pawBorderColor.withOpacity(0.5))),
          child: const TabBar(tabs: [Tab(text: 'Kategori'), Tab(text: 'Pelanggan')]),
        ),
        SizedBox(
          height: 220,
          child: TabBarView(
            children: [
              _buildTopList(topCategories, 'category', Icons.category_outlined),
              _buildTopList(topCustomers, 'customer_name', Icons.person_outline)
            ],
          ),
        )
      ]),
    );
  }
  Widget _buildTopList(List<Map<String, dynamic>> data, String key, IconData icon) {
    if (data.isEmpty) return const Center(child: Padding(padding: EdgeInsets.all(16.0), child: Text("Data belum cukup untuk ditampilkan.")));
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 12),
      children: data.map((item) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: ListTile(
          leading: CircleAvatar(child: Icon(icon)),
          title: Text(item[key].toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
          trailing: Text(formatCurrency((item['total'] as num).toDouble()), style: const TextStyle(fontWeight: FontWeight.bold, color: primaryPawColor)),
        ),
      )).toList(),
    );
  }
}
