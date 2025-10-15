import '../models/category.dart';
import '../models/daily_sale.dart';
import '../models/product.dart';
import '../models/sale.dart';
import '../models/sale_item.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import '../widgets/ui_components.dart';
import '../widgets/date_filter_dialog.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'sales_report_detail_page.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});
  @override
  _ReportsPageState createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final SupabaseService _supabaseService = SupabaseService();

  DateTime? _startDate;
  DateTime? _endDate;
  String _selectedPeriod = 'this_month';

  double totalRevenue = 0;
  double totalProfit = 0;
  int totalTransactions = 0;
  double totalDiscount = 0;
  double profitMargin = 0;
  int totalReturnedProducts = 0;
  int totalStockSold = 0;
  int totalAvailableStock = 0;
  Map<String, double> categoryRevenue = {};
  int lowStockCount = 0;
  int outOfStockCount = 0;
  List<Product> lowStockProducts = [];
  Map<String, int> bestSellingProducts = {};
  List<DailySale> dailySales = [];
  List<BarChartGroupData> _dayOfWeekData = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Set default to current month
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 1);
    _endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    _selectedPeriod = 'this_month';
    _loadReportData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadReportData() async {
    DateTime? finalEndDate = _endDate != null
        ? DateTime(_endDate!.year, _endDate!.month, _endDate!.day, 23, 59, 59)
        : null;

    final allProducts = await _supabaseService.getProducts();
    final allSales =
        await _supabaseService.getSales(start: _startDate, end: finalEndDate);

    final int tempTotalAvailableStock =
        allProducts.fold(0, (sum, p) => sum + p.stock);

    double tempGrossRevenue = 0;
    double tempProfit = 0;
    double tempTotalDiscount = 0;
    Map<String, double> tempCategoryRevenue = {};
    Map<String, int> tempBestSelling = {};
    Map<int, double> dayOfWeekTotals = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0, 7: 0};
    int tempTotalReturnedItems = 0;
    int tempTotalSoldItems = 0;

    for (final sale in allSales) {
      final items = await _supabaseService.getSaleItems(sale.id!);

      for (final item in items) {
        final product = allProducts.firstWhere(
          (p) => p.id == item.productId,
          orElse: () => Product(
              name: 'Produk Dihapus',
              code: '',
              purchasePrice: item.unitPrice,
              sellingPrice: item.unitPrice,
              stock: 0,
              stockAlert: 5,
              category: 'Lainnya',
              createdAt: DateTime.now()),
        );

        int netQuantity = item.quantity - item.returnedQuantity;
        
        tempTotalDiscount += item.discount;

        if (netQuantity > 0 && item.quantity > 0) {
          double netSellingPricePerUnit = (item.totalPrice - item.discount) / item.quantity;
          double netProfitPerUnit = netSellingPricePerUnit - product.purchasePrice;
          tempProfit += netProfitPerUnit * netQuantity;
          tempTotalSoldItems += netQuantity;
          tempCategoryRevenue[product.category] =
              (tempCategoryRevenue[product.category] ?? 0) + (netSellingPricePerUnit * netQuantity);
          tempBestSelling[product.name] =
              (tempBestSelling[product.name] ?? 0) + netQuantity;
        }

        tempTotalReturnedItems += item.returnedQuantity;
      }

      tempGrossRevenue += sale.finalAmount;
      dayOfWeekTotals[sale.saleDate.weekday] =
          (dayOfWeekTotals[sale.saleDate.weekday] ?? 0) + sale.finalAmount;
    }

    var sortedBestSelling = Map.fromEntries(tempBestSelling.entries.toList()
      ..sort((e1, e2) => e2.value.compareTo(e1.value)));

    if (mounted) {
      setState(() {
        totalRevenue = tempGrossRevenue;
        totalProfit = tempProfit;
        totalTransactions = allSales.length;
        totalDiscount = tempTotalDiscount;
        profitMargin = totalRevenue > 0 ? (totalProfit / totalRevenue) * 100 : 0;
        categoryRevenue = tempCategoryRevenue;
        lowStockProducts =
            allProducts.where((p) => p.stock <= p.stockAlert && p.stock > 0).toList();
        lowStockCount = lowStockProducts.length;
        outOfStockCount = allProducts.where((p) => p.stock == 0).length;
        bestSellingProducts = sortedBestSelling;
        _dayOfWeekData = dayOfWeekTotals.entries.map((entry) {
          return BarChartGroupData(x: entry.key, barRods: [
            BarChartRodData(
                toY: entry.value,
                color: primaryPawColor,
                width: 16,
                borderRadius: BorderRadius.circular(4))
          ]);
        }).toList();

        totalAvailableStock = tempTotalAvailableStock;
        totalStockSold = tempTotalSoldItems;
        totalReturnedProducts = tempTotalReturnedItems;
      });
    }
  }

  void _showDateFilterDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => DateFilterDialog(
        initialStartDate: _startDate,
        initialEndDate: _endDate,
        onApply: (startDate, endDate, period) {
          setState(() {
            _startDate = startDate;
            _endDate = endDate;
            _selectedPeriod = period;
          });
          _loadReportData();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: IconButton(
              onPressed: _showDateFilterDialog,
              icon: Stack(
                children: [
                  Icon(
                    Icons.filter_alt_outlined,
                    color: primaryPawColor,
                  ),
                  if (_selectedPeriod != 'this_month')
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              tooltip: 'Filter Periode',
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Penjualan'),
            Tab(text: 'Stok'),
            Tab(text: 'Produk'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSalesReport(),
          _buildStockReport(),
          _buildBestSellingReport(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Text(
        title,
        style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color,
      {String? subValue}) {
    return UICard(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.foreground,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.foregroundMuted,
            ),
          ),
          if (subValue != null) ...[
            const SizedBox(height: 4),
            Text(
              subValue,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.foregroundSubtle,
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildDateFilter() {
    final DateFormat formatter = DateFormat('dd MMM yyyy');
    String periodText;
    String periodLabel = 'Periode Laporan';
    IconData periodIcon = Icons.calendar_today;
    Color periodColor = primaryPawColor;
    
    // Determine display text based on selected period
    switch (_selectedPeriod) {
      case 'today':
        periodText = 'Hari Ini';
        periodIcon = Icons.today;
        periodColor = Colors.blue;
        break;
      case 'yesterday':
        periodText = 'Kemarin';
        periodIcon = Icons.history;
        periodColor = Colors.orange;
        break;
      case 'last_7_days':
        periodText = '7 Hari Terakhir';
        periodIcon = Icons.date_range;
        periodColor = Colors.green;
        break;
      case 'this_week':
        periodText = 'Minggu Ini';
        periodIcon = Icons.view_week;
        periodColor = Colors.purple;
        break;
      case 'last_week':
        periodText = 'Minggu Lalu';
        periodIcon = Icons.skip_previous;
        periodColor = Colors.indigo;
        break;
      case 'this_month':
        periodText = DateFormat('MMMM yyyy').format(_startDate!);
        periodIcon = Icons.calendar_today;
        periodColor = Colors.teal;
        break;
      case 'last_month':
        periodText = DateFormat('MMMM yyyy').format(_startDate!);
        periodIcon = Icons.calendar_month;
        periodColor = Colors.deepOrange;
        break;
      case 'last_30_days':
        periodText = '30 Hari Terakhir';
        periodIcon = Icons.event_note;
        periodColor = Colors.cyan;
        break;
      case 'this_quarter':
        periodText = 'Kuartal Ini';
        periodIcon = Icons.view_quilt;
        periodColor = Colors.pink;
        break;
      case 'this_year':
        periodText = 'Tahun Ini';
        periodIcon = Icons.event;
        periodColor = Colors.amber;
        break;
      case 'all_time':
        periodText = 'Semua Waktu';
        periodIcon = Icons.all_inclusive;
        periodColor = Colors.grey;
        break;
      case 'custom':
        if (_startDate != null && _endDate != null) {
          periodText = '${formatter.format(_startDate!)} - ${formatter.format(_endDate!)}';
        } else {
          periodText = 'Custom Range';
        }
        periodIcon = Icons.tune;
        break;
      default:
        if (_startDate != null && _endDate != null) {
          periodText = '${formatter.format(_startDate!)} - ${formatter.format(_endDate!)}';
        } else {
          periodText = 'Semua Periode';
        }
    }
    
    // Calculate days in period
    String daysInfo = '';
    if (_startDate != null && _endDate != null) {
      final days = _endDate!.difference(_startDate!).inDays + 1;
      daysInfo = ' • $days hari';
    } else if (_selectedPeriod == 'all_time') {
      daysInfo = ' • Semua data';
    }
    
    return Column(
      children: [
        // Main Filter Card
        UICard(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _showDateFilterDialog,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            periodColor.withOpacity(0.2),
                            periodColor.withOpacity(0.1),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        periodIcon,
                        size: 24,
                        color: periodColor,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                periodLabel,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: AppColors.foregroundMuted,
                                  letterSpacing: 0.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                daysInfo,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: AppColors.foregroundSubtle,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            periodText,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              color: AppColors.foreground,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (_startDate != null && _endDate != null && _selectedPeriod == 'custom') ...[
                            const SizedBox(height: 2),
                            Text(
                              'Custom: ${formatter.format(_startDate!)} - ${formatter.format(_endDate!)}',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: AppColors.foregroundSubtle,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: periodColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: periodColor.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        Icons.edit_calendar,
                        size: 18,
                        color: periodColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Quick Action Buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _showDateFilterDialog,
                icon: Icon(Icons.filter_list, size: 18, color: primaryPawColor),
                label: Text(
                  'Ubah Filter',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: primaryPawColor,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  side: BorderSide(color: primaryPawColor.withOpacity(0.5)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    // Reset to current month
                    final now = DateTime.now();
                    _startDate = DateTime(now.year, now.month, 1);
                    _endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
                    _selectedPeriod = 'this_month';
                  });
                  _loadReportData();
                },
                icon: const Icon(Icons.refresh, size: 18),
                label: Text(
                  'Reset',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSalesReport() {
    return RefreshIndicator(
      onRefresh: _loadReportData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildDateFilter(),
          const SizedBox(height: 16),
          _buildDetailButton(),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.25,
            children: [
              _buildSummaryCard('Pendapatan Bersih', formatCurrency(totalRevenue),
                  Icons.monetization_on, Colors.green),
              _buildSummaryCard('Keuntungan Bersih', formatCurrency(totalProfit),
                  Icons.trending_up, Colors.blue),
              _buildSummaryCard('Total Transaksi', totalTransactions.toString(),
                  Icons.receipt_long, Colors.orange),
              _buildSummaryCard('Total Diskon', formatCurrency(totalDiscount),
                  Icons.sell_outlined, Colors.purple),
              _buildSummaryCard('Margin Profit', '${profitMargin.toStringAsFixed(1)}%',
                  Icons.pie_chart, Colors.teal),
              _buildSummaryCard('Produk Diretur', totalReturnedProducts.toString(),
                  Icons.undo, Colors.red.shade700),
            ],
          ),
          _buildSectionTitle('Penjualan per Hari'),
          _buildDayOfWeekChart(),
          _buildSectionTitle('Pendapatan Bersih per Kategori'),
          Card(
            child: categoryRevenue.isEmpty
                ? const SizedBox(
                    height: 100, child: Center(child: Text('Belum ada data.')))
                : Column(
                    children: categoryRevenue.entries.map((entry) {
                      final totalNetRevenue = categoryRevenue.values.fold(0.0, (prev, val) => prev + val);
                      double percentage =
                          totalNetRevenue > 0 ? (entry.value / totalNetRevenue) : 0;
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(entry.key,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                                Text(formatCurrency(entry.value)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: percentage,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                  primaryPawColor),
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
          )
        ],
      ),
    );
  }

  Widget _buildDetailButton() {
    // Get period info for display
    String periodInfo = '';
    switch (_selectedPeriod) {
      case 'today':
        periodInfo = 'Hari Ini';
        break;
      case 'yesterday':
        periodInfo = 'Kemarin';
        break;
      case 'last_7_days':
        periodInfo = '7 Hari Terakhir';
        break;
      case 'this_week':
        periodInfo = 'Minggu Ini';
        break;
      case 'last_week':
        periodInfo = 'Minggu Lalu';
        break;
      case 'this_month':
        periodInfo = DateFormat('MMMM yyyy').format(_startDate!);
        break;
      case 'last_month':
        periodInfo = DateFormat('MMMM yyyy').format(_startDate!);
        break;
      case 'last_30_days':
        periodInfo = '30 Hari Terakhir';
        break;
      case 'this_quarter':
        periodInfo = 'Kuartal Ini';
        break;
      case 'this_year':
        periodInfo = 'Tahun Ini';
        break;
      case 'all_time':
        periodInfo = 'Semua Periode';
        break;
      case 'custom':
        if (_startDate != null && _endDate != null) {
          periodInfo = DateFormat('dd MMM').format(_startDate!) + ' - ' + DateFormat('dd MMM yyyy').format(_endDate!);
        } else {
          periodInfo = 'Custom';
        }
        break;
      default:
        periodInfo = 'Periode Saat Ini';
    }
    
    return UICard(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SalesReportDetailPage(
                  startDate: _startDate,
                  endDate: _endDate,
                  totalRevenue: totalRevenue,
                  totalProfit: totalProfit,
                  totalTransactions: totalTransactions,
                  totalDiscount: totalDiscount,
                  profitMargin: profitMargin,
                  totalReturnedProducts: totalReturnedProducts,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  primaryPawColor.withOpacity(0.05),
                  primaryPawColor.withOpacity(0.02),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              primaryPawColor,
                              primaryPawColor.withOpacity(0.8),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: primaryPawColor.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.analytics,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Lihat Detail Laporan',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.foreground,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: primaryPawColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    periodInfo,
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: primaryPawColor,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '• Analisis & Insights',
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
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: primaryPawColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward,
                    size: 16,
                    color: primaryPawColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDayOfWeekChart() {
    final List<String> days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    return Card(
      child: SizedBox(
        height: 250,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (group) => Colors.blueGrey,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    return BarTooltipItem(
                      '${days[group.x.toInt() - 1]}\n',
                      const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                      children: [
                        TextSpan(
                          text: formatCurrency(rod.toY),
                          style: const TextStyle(
                              color: Colors.yellow,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      return SideTitleWidget(
                        axisSide: meta.axisSide,
                        space: 4.0,
                        child: Text(days[value.toInt() - 1],
                            style: const TextStyle(fontSize: 10)),
                      );
                    },
                    reservedSize: 30,
                  ),
                ),
                leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              gridData: FlGridData(show: false),
              barGroups: _dayOfWeekData,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStockReport() {
    return RefreshIndicator(
      onRefresh: _loadReportData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.2,
            children: [
              _buildSummaryCard('Total Stok Tersedia',
                  totalAvailableStock.toString(), Icons.inventory_2, Colors.blue.shade700),
              _buildSummaryCard('Total Stok Terjual', totalStockSold.toString(),
                  Icons.shopping_cart_checkout, Colors.purple.shade700),
              _buildSummaryCard('Stok Menipis', lowStockCount.toString(),
                  Icons.warning_amber, Colors.orange.shade800),
              _buildSummaryCard('Stok Habis', outOfStockCount.toString(),
                  Icons.error_outline, Colors.red.shade700),
            ],
          ),
          _buildSectionTitle('Daftar Produk Stok Menipis'),
          Card(
            child: lowStockProducts.isEmpty
                ? const SizedBox(
                    height: 100,
                    child: Center(child: Text('Semua stok aman.')))
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: lowStockProducts.length,
                    itemBuilder: (context, index) {
                      final product = lowStockProducts[index];
                      return ListTile(
                        title: Text(product.name),
                        trailing: Text('Sisa: ${product.stock}',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                      );
                    },
                  ),
          )
        ],
      ),
    );
  }

  Widget _buildBestSellingReport() {
    return RefreshIndicator(
      onRefresh: _loadReportData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionTitle('Produk Terlaris (Berdasarkan Unit)'),
          Card(
            child: bestSellingProducts.isEmpty
                ? const SizedBox(
                    height: 100,
                    child: Center(child: Text('Belum ada penjualan.')))
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: bestSellingProducts.length > 10
                        ? 10
                        : bestSellingProducts.length,
                    itemBuilder: (context, index) {
                      final entry = bestSellingProducts.entries.elementAt(index);
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: primaryPawColor.withOpacity(0.1),
                          foregroundColor: primaryPawColor,
                          child: Text('${index + 1}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        title: Text(entry.key),
                        trailing: Text('${entry.value} unit terjual',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                      );
                    },
                  ),
          )
        ],
      ),
    );
  }
}
