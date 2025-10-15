import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/sale.dart';
import '../models/product.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import '../widgets/ui_components.dart';
import '../widgets/date_filter_dialog.dart';

class SalesReportDetailPage extends StatefulWidget {
  final DateTime? startDate;
  final DateTime? endDate;
  final double totalRevenue;
  final double totalProfit;
  final int totalTransactions;
  final double totalDiscount;
  final double profitMargin;
  final int totalReturnedProducts;

  const SalesReportDetailPage({
    super.key,
    this.startDate,
    this.endDate,
    required this.totalRevenue,
    required this.totalProfit,
    required this.totalTransactions,
    required this.totalDiscount,
    required this.profitMargin,
    required this.totalReturnedProducts,
  });

  @override
  State<SalesReportDetailPage> createState() => _SalesReportDetailPageState();
}

class _SalesReportDetailPageState extends State<SalesReportDetailPage> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final SupabaseService _supabaseService = SupabaseService();
  
  bool _isLoading = false;
  
  // Period selection
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  String _selectedPeriod = 'this_month';
  
  // Updated metrics
  double _totalRevenue = 0;
  double _totalProfit = 0;
  int _totalTransactions = 0;
  double _totalDiscount = 0;
  double _profitMargin = 0;
  int _totalReturnedProducts = 0;
  
  // Data untuk detail
  List<Sale> _sales = [];
  Map<String, double> _dailyRevenue = {};
  Map<String, int> _dailyTransactions = {};
  Map<String, double> _hourlyRevenue = {};
  List<Map<String, dynamic>> _topProducts = [];
  List<Map<String, dynamic>> _returnedItems = [];
  
  // Statistik tambahan
  double _averageTransactionValue = 0;
  String _bestDay = '';
  String _bestHour = '';
  double _returnRate = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    
    // Initialize with passed data or current month
    if (widget.startDate != null && widget.endDate != null) {
      _selectedStartDate = widget.startDate;
      _selectedEndDate = widget.endDate;
      _selectedPeriod = 'custom';
    } else {
      // Set to current month by default
      final now = DateTime.now();
      _selectedStartDate = DateTime(now.year, now.month, 1);
      _selectedEndDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      _selectedPeriod = 'this_month';
    }
    
    // Set initial metrics
    _totalRevenue = widget.totalRevenue;
    _totalProfit = widget.totalProfit;
    _totalTransactions = widget.totalTransactions;
    _totalDiscount = widget.totalDiscount;
    _profitMargin = widget.profitMargin;
    _totalReturnedProducts = widget.totalReturnedProducts;
    
    _loadDetailedData();
  }
  
  void _showDateFilterDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => DateFilterDialog(
        initialStartDate: _selectedStartDate,
        initialEndDate: _selectedEndDate,
        onApply: (startDate, endDate, period) {
          setState(() {
            _selectedStartDate = startDate;
            _selectedEndDate = endDate;
            _selectedPeriod = period;
          });
          _loadDetailedData();
        },
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDetailedData() async {
    setState(() => _isLoading = true);

    try {
      // Load sales data with selected period
      _sales = await _supabaseService.getSales(
        start: _selectedStartDate, 
        end: _selectedEndDate
      );
      
      // Recalculate main metrics based on selected period
      await _recalculateMetrics();

      // Process daily data
      Map<String, double> tempDailyRevenue = {};
      Map<String, int> tempDailyTrans = {};
      Map<int, double> tempHourlyRevenue = {};
      Map<String, Map<String, dynamic>> productSales = {};
      List<Map<String, dynamic>> tempReturnedItems = [];

      for (var sale in _sales) {
        // Daily revenue
        String dateKey = DateFormat('yyyy-MM-dd').format(sale.saleDate);
        tempDailyRevenue[dateKey] = 
            (tempDailyRevenue[dateKey] ?? 0) + sale.finalAmount;
        tempDailyTrans[dateKey] = (tempDailyTrans[dateKey] ?? 0) + 1;

        // Hourly revenue
        int hour = sale.saleDate.hour;
        tempHourlyRevenue[hour] = 
            (tempHourlyRevenue[hour] ?? 0) + sale.finalAmount;

        // Get sale items for product analysis
        final items = await _supabaseService.getSaleItems(sale.id!);
        for (var item in items) {
          // Track product sales
          String productKey = item.productName;
          if (!productSales.containsKey(productKey)) {
            productSales[productKey] = {
              'name': item.productName,
              'quantity': 0,
              'revenue': 0.0,
              'discount': 0.0,
            };
          }
          productSales[productKey]!['quantity'] += item.quantity;
          productSales[productKey]!['revenue'] += item.totalPrice;
          productSales[productKey]!['discount'] += item.discount;

          // Track returned items
          if (item.returnedQuantity > 0) {
            tempReturnedItems.add({
              'product': item.productName,
              'quantity': item.returnedQuantity,
              'value': item.unitPrice * item.returnedQuantity,
              'date': sale.saleDate,
              'invoice': sale.invoiceNumber,
            });
          }
        }
      }

      // Sort and get top products
      var sortedProducts = productSales.values.toList()
        ..sort((a, b) => b['revenue'].compareTo(a['revenue']));
      _topProducts = sortedProducts.take(10).toList();

      // Convert hourly data
      _hourlyRevenue = tempHourlyRevenue.map(
        (key, value) => MapEntry('${key.toString().padLeft(2, '0')}:00', value)
      );

      // Calculate statistics
      _averageTransactionValue = _totalTransactions > 0
          ? _totalRevenue / _totalTransactions
          : 0;

      // Find best day
      if (tempDailyRevenue.isNotEmpty) {
        var bestDayEntry = tempDailyRevenue.entries
            .reduce((a, b) => a.value > b.value ? a : b);
        _bestDay = DateFormat('dd MMM yyyy')
            .format(DateTime.parse(bestDayEntry.key));
      }

      // Find best hour
      if (tempHourlyRevenue.isNotEmpty) {
        var bestHourEntry = tempHourlyRevenue.entries
            .reduce((a, b) => a.value > b.value ? a : b);
        _bestHour = '${bestHourEntry.key.toString().padLeft(2, '0')}:00';
      }

      // Calculate return rate
      int totalItemsSold = 0;
      for (var product in productSales.values) {
        totalItemsSold += product['quantity'] as int;
      }
      _returnRate = totalItemsSold > 0
          ? (_totalReturnedProducts / totalItemsSold) * 100
          : 0;

      setState(() {
        _dailyRevenue = tempDailyRevenue;
        _dailyTransactions = tempDailyTrans;
        _returnedItems = tempReturnedItems;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading detailed data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _recalculateMetrics() async {
    if (_sales.isEmpty) {
      setState(() {
        _totalRevenue = 0;
        _totalProfit = 0;
        _totalTransactions = 0;
        _totalDiscount = 0;
        _profitMargin = 0;
        _totalReturnedProducts = 0;
      });
      return;
    }
    
    final allProducts = await _supabaseService.getProducts();
    
    double tempRevenue = 0;
    double tempProfit = 0;
    double tempDiscount = 0;
    int tempReturns = 0;
    
    for (var sale in _sales) {
      tempRevenue += sale.finalAmount;
      
      final items = await _supabaseService.getSaleItems(sale.id!);
      for (var item in items) {
        tempDiscount += item.discount;
        tempReturns += item.returnedQuantity;
        
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
            createdAt: DateTime.now()
          ),
        );
        
        int netQuantity = item.quantity - item.returnedQuantity;
        if (netQuantity > 0 && item.quantity > 0) {
          double netSellingPricePerUnit = (item.totalPrice - item.discount) / item.quantity;
          double netProfitPerUnit = netSellingPricePerUnit - product.purchasePrice;
          tempProfit += netProfitPerUnit * netQuantity;
        }
      }
    }
    
    setState(() {
      _totalRevenue = tempRevenue;
      _totalProfit = tempProfit;
      _totalTransactions = _sales.length;
      _totalDiscount = tempDiscount;
      _profitMargin = tempRevenue > 0 ? (tempProfit / tempRevenue) * 100 : 0;
      _totalReturnedProducts = tempReturns;
    });
  }
  
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Laporan Penjualan'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              onPressed: _showDateFilterDialog,
              icon: Icon(
                Icons.filter_list,
                size: 20,
                color: primaryPawColor,
              ),
              label: Text(
                'Filter',
                style: GoogleFonts.inter(
                  color: primaryPawColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              style: TextButton.styleFrom(
                backgroundColor: primaryPawColor.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Ringkasan'),
            Tab(text: 'Trend'),
            Tab(text: 'Produk'),
            Tab(text: 'Retur'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildSummaryTab(),
                _buildTrendTab(),
                _buildProductTab(),
                _buildReturnTab(),
              ],
            ),
    );
  }

  Widget _buildSummaryTab() {
    return RefreshIndicator(
      onRefresh: _loadDetailedData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildDateRangeCard(),
          const SizedBox(height: 16),
          _buildMainMetricsGrid(),
          const SizedBox(height: 16),
          _buildAdditionalMetricsCard(),
          const SizedBox(height: 16),
          _buildInsightsCard(),
        ],
      ),
    );
  }

  Widget _buildDateRangeCard() {
    final formatter = DateFormat('dd MMMM yyyy');
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
        periodText = DateFormat('MMMM yyyy').format(_selectedStartDate!);
        periodIcon = Icons.calendar_today;
        periodColor = Colors.teal;
        break;
      case 'last_month':
        periodText = DateFormat('MMMM yyyy').format(_selectedStartDate!);
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
        if (_selectedStartDate != null && _selectedEndDate != null) {
          periodText = '${formatter.format(_selectedStartDate!)} - ${formatter.format(_selectedEndDate!)}';
        } else {
          periodText = 'Custom Range';
        }
        periodIcon = Icons.tune;
        break;
      default:
        if (_selectedStartDate != null && _selectedEndDate != null) {
          periodText = '${formatter.format(_selectedStartDate!)} - ${formatter.format(_selectedEndDate!)}';
        } else {
          periodText = 'Semua Periode';
        }
    }
    
    // Calculate days in period
    String daysInfo = '';
    if (_selectedStartDate != null && _selectedEndDate != null) {
      final days = _selectedEndDate!.difference(_selectedStartDate!).inDays + 1;
      daysInfo = ' ($days hari)';
    }
    
    return UICard(
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
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: periodColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    periodIcon,
                    size: 22,
                    color: periodColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        periodLabel,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.foregroundMuted,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$periodText$daysInfo',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.foreground,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: periodColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.edit,
                    size: 16,
                    color: periodColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainMetricsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.3,
      children: [
        _buildMetricCard(
          title: 'Pendapatan Bersih',
          value: formatCurrency(_totalRevenue),
          icon: Icons.monetization_on,
          color: Colors.green,
          trend: _calculateTrend(_totalRevenue),
        ),
        _buildMetricCard(
          title: 'Keuntungan Bersih',
          value: formatCurrency(_totalProfit),
          icon: Icons.trending_up,
          color: Colors.blue,
          trend: _calculateTrend(_totalProfit),
        ),
        _buildMetricCard(
          title: 'Total Transaksi',
          value: _totalTransactions.toString(),
          icon: Icons.receipt_long,
          color: Colors.orange,
          subtitle: 'Rata-rata: ${formatCurrency(_averageTransactionValue)}',
        ),
        _buildMetricCard(
          title: 'Total Diskon',
          value: formatCurrency(_totalDiscount),
          icon: Icons.discount,
          color: Colors.purple,
          percentage: _totalRevenue > 0 
              ? (_totalDiscount / _totalRevenue * 100).toStringAsFixed(1)
              : '0',
        ),
        _buildMetricCard(
          title: 'Margin Profit',
          value: '${_profitMargin.toStringAsFixed(1)}%',
          icon: Icons.pie_chart,
          color: Colors.teal,
          isPercentage: true,
        ),
        _buildMetricCard(
          title: 'Produk Diretur',
          value: _totalReturnedProducts.toString(),
          icon: Icons.undo,
          color: Colors.red,
          subtitle: 'Return Rate: ${_returnRate.toStringAsFixed(1)}%',
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    String? subtitle,
    String? trend,
    String? percentage,
    bool isPercentage = false,
  }) {
    return UICard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              if (percentage != null) ...[
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '$percentage%',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.foregroundMuted,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: isPercentage ? 24 : 18,
              fontWeight: FontWeight.w600,
              color: AppColors.foreground,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.foregroundMuted,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppColors.foregroundSubtle,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAdditionalMetricsCard() {
    return UICard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Metrik Tambahan',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.foreground,
            ),
          ),
          const SizedBox(height: 16),
          _buildMetricRow(
            'Rata-rata Nilai Transaksi',
            formatCurrency(_averageTransactionValue),
            Icons.analytics,
          ),
          const Divider(height: 24),
          _buildMetricRow(
            'Hari Terbaik',
            _bestDay.isNotEmpty ? _bestDay : '-',
            Icons.today,
          ),
          const Divider(height: 24),
          _buildMetricRow(
            'Jam Terbaik',
            _bestHour.isNotEmpty ? _bestHour : '-',
            Icons.access_time,
          ),
          const Divider(height: 24),
          _buildMetricRow(
            'Tingkat Pengembalian',
            '${_returnRate.toStringAsFixed(2)}%',
            Icons.assignment_return,
            valueColor: _returnRate > 5 ? Colors.orange : Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow(
    String label, 
    String value, 
    IconData icon,
    {Color? valueColor}
  ) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.foregroundMuted),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.foregroundMuted,
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: valueColor ?? AppColors.foreground,
          ),
        ),
      ],
    );
  }

  Widget _buildInsightsCard() {
    List<String> insights = [];
    
    if (_profitMargin < 20) {
      insights.add('⚠️ Margin profit rendah (${_profitMargin.toStringAsFixed(1)}%). Pertimbangkan untuk mengevaluasi harga jual atau mengurangi biaya.');
    } else if (_profitMargin > 40) {
      insights.add('✅ Margin profit sangat baik (${_profitMargin.toStringAsFixed(1)}%)!');
    }
    
    double discountRate = _totalRevenue > 0 
        ? (_totalDiscount / _totalRevenue) * 100 
        : 0;
    if (discountRate > 10) {
      insights.add('💰 Diskon tinggi (${discountRate.toStringAsFixed(1)}% dari pendapatan). Evaluasi strategi diskon.');
    }

    if (_returnRate > 5) {
      insights.add('🔄 Tingkat pengembalian cukup tinggi (${_returnRate.toStringAsFixed(1)}%). Periksa kualitas produk atau kepuasan pelanggan.');
    }
    
    if (_averageTransactionValue < 50000) {
      insights.add('📊 Nilai transaksi rata-rata rendah. Pertimbangkan strategi upselling atau bundling.');
    }

    if (insights.isEmpty) {
      insights.add('👍 Performa penjualan terlihat baik!');
    }

    return UICard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, 
                   size: 20, 
                   color: Colors.amber),
              const SizedBox(width: 8),
              Text(
                'Insights',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.foreground,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...insights.map((insight) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              insight,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.foregroundMuted,
                height: 1.5,
              ),
            ),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildTrendTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildDailyRevenueChart(),
        const SizedBox(height: 16),
        _buildHourlyRevenueChart(),
        const SizedBox(height: 16),
        _buildTransactionVolumeChart(),
      ],
    );
  }

  Widget _buildDailyRevenueChart() {
    List<FlSpot> spots = [];
    List<String> dates = _dailyRevenue.keys.toList()..sort();
    
    for (int i = 0; i < dates.length; i++) {
      spots.add(FlSpot(i.toDouble(), _dailyRevenue[dates[i]]!));
    }

    return UICard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pendapatan Harian',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.foreground,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: spots.isEmpty
                ? const Center(child: Text('Tidak ada data'))
                : LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 50000,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: AppColors.border.withOpacity(0.3),
                            strokeWidth: 1,
                          );
                        },
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 60,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                formatCurrencyCompact(value),
                                style: const TextStyle(fontSize: 10),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            interval: dates.length > 7 ? dates.length / 7 : 1,
                            getTitlesWidget: (value, meta) {
                              if (value.toInt() < dates.length) {
                                return Text(
                                  DateFormat('dd/MM')
                                      .format(DateTime.parse(dates[value.toInt()])),
                                  style: const TextStyle(fontSize: 10),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          color: primaryPawColor,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: dates.length <= 7,
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            color: primaryPawColor.withOpacity(0.1),
                          ),
                        ),
                      ],
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipColor: (touchedSpot) => 
                              primaryPawColor.withOpacity(0.8),
                          getTooltipItems: (touchedSpots) {
                            return touchedSpots.map((spot) {
                              return LineTooltipItem(
                                '${DateFormat('dd MMM').format(DateTime.parse(dates[spot.x.toInt()]))}\n${formatCurrency(spot.y)}',
                                const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
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
        ],
      ),
    );
  }

  Widget _buildHourlyRevenueChart() {
    List<BarChartGroupData> barGroups = [];
    
    for (int hour = 0; hour < 24; hour++) {
      String hourKey = '${hour.toString().padLeft(2, '0')}:00';
      double revenue = _hourlyRevenue[hourKey] ?? 0;
      
      barGroups.add(
        BarChartGroupData(
          x: hour,
          barRods: [
            BarChartRodData(
              toY: revenue,
              color: primaryPawColor,
              width: 12,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
          ],
        ),
      );
    }

    return UICard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pendapatan per Jam',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.foreground,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: _hourlyRevenue.values.isEmpty 
                    ? 100000 
                    : _hourlyRevenue.values.reduce((a, b) => a > b ? a : b) * 1.2,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (group) => Colors.blueGrey,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${group.x.toString().padLeft(2, '0')}:00\n${formatCurrency(rod.toY)}',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 3,
                      getTitlesWidget: (value, meta) {
                        if (value % 3 == 0) {
                          return Text(
                            '${value.toInt()}',
                            style: const TextStyle(fontSize: 10),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(show: false),
                barGroups: barGroups,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionVolumeChart() {
    List<FlSpot> spots = [];
    List<String> dates = _dailyTransactions.keys.toList()..sort();
    
    for (int i = 0; i < dates.length; i++) {
      spots.add(FlSpot(i.toDouble(), _dailyTransactions[dates[i]]!.toDouble()));
    }

    return UICard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Volume Transaksi Harian',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.foreground,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: spots.isEmpty
                ? const Center(child: Text('Tidak ada data'))
                : LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: AppColors.border.withOpacity(0.3),
                            strokeWidth: 1,
                          );
                        },
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                value.toInt().toString(),
                                style: const TextStyle(fontSize: 10),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            interval: dates.length > 7 ? dates.length / 7 : 1,
                            getTitlesWidget: (value, meta) {
                              if (value.toInt() < dates.length) {
                                return Text(
                                  DateFormat('dd/MM')
                                      .format(DateTime.parse(dates[value.toInt()])),
                                  style: const TextStyle(fontSize: 10),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          color: Colors.orange,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: dates.length <= 7,
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            color: Colors.orange.withOpacity(0.1),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        UICard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Top 10 Produk Terlaris',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.foreground,
                ),
              ),
              const SizedBox(height: 16),
              if (_topProducts.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text('Tidak ada data produk'),
                  ),
                )
              else
                ...List.generate(_topProducts.length, (index) {
                  final product = _topProducts[index];
                  final revenue = product['revenue'] as double;
                  final maxRevenue = (_topProducts.first['revenue'] as double);
                  final percentage = maxRevenue > 0 ? revenue / maxRevenue : 0.0;
                  
                  return Column(
                    children: [
                      if (index > 0) const Divider(),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    color: index < 3 
                                        ? primaryPawColor.withOpacity(0.1)
                                        : Colors.grey.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${index + 1}',
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.bold,
                                        color: index < 3 
                                            ? primaryPawColor 
                                            : Colors.grey,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product['name'],
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.foreground,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Text(
                                            '${product['quantity']} unit',
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              color: AppColors.foregroundMuted,
                                            ),
                                          ),
                                          if (product['discount'] > 0) ...[
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 6,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.orange.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                'Disc: ${formatCurrencyCompact(product['discount'])}',
                                                style: GoogleFonts.inter(
                                                  fontSize: 10,
                                                  color: Colors.orange.shade700,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  formatCurrency(revenue),
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.foreground,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: percentage,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                index < 3 ? primaryPawColor : Colors.grey,
                              ),
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReturnTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        UICard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Statistik Retur',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.foreground,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _returnRate > 5 
                          ? Colors.orange.withOpacity(0.1)
                          : Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Rate: ${_returnRate.toStringAsFixed(1)}%',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _returnRate > 5 
                            ? Colors.orange.shade700
                            : Colors.green.shade700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildReturnStatCard(
                      'Total Item Diretur',
                      _totalReturnedProducts.toString(),
                      Icons.undo,
                      Colors.red,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildReturnStatCard(
                      'Nilai Retur',
                      formatCurrencyCompact(_calculateReturnValue()),
                      Icons.money_off,
                      Colors.orange,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        UICard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Detail Produk Diretur',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.foreground,
                ),
              ),
              const SizedBox(height: 16),
              if (_returnedItems.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text('Tidak ada produk yang diretur'),
                  ),
                )
              else
                ...List.generate(
                  _returnedItems.length > 10 ? 10 : _returnedItems.length,
                  (index) {
                    final item = _returnedItems[index];
                    return Column(
                      children: [
                        if (index > 0) const Divider(),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.assignment_return,
                              color: Colors.red,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            item['product'],
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${item['quantity']} unit • ${formatCurrency(item['value'])}',
                                style: GoogleFonts.inter(fontSize: 12),
                              ),
                              Text(
                                DateFormat('dd MMM yyyy').format(item['date']),
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: AppColors.foregroundSubtle,
                                ),
                              ),
                            ],
                          ),
                          trailing: Text(
                            item['invoice'],
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppColors.foregroundMuted,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              if (_returnedItems.length > 10)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    'Dan ${_returnedItems.length - 10} item lainnya...',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.foregroundMuted,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReturnStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.foreground,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppColors.foregroundMuted,
            ),
          ),
        ],
      ),
    );
  }

  String _calculateTrend(double value) {

    return '';
  }

  double _calculateReturnValue() {
    return _returnedItems.fold(
      0,
      (sum, item) => sum + (item['value'] as double),
    );
  }

  String formatCurrencyCompact(double value) {
    if (value >= 1000000) {
      return 'Rp ${(value / 1000000).toStringAsFixed(1)}jt';
    } else if (value >= 1000) {
      return 'Rp ${(value / 1000).toStringAsFixed(1)}rb';
    }
    return formatCurrency(value);
  }
}
