import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';

class DateFilterDialog extends StatefulWidget {
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;
  final Function(DateTime?, DateTime?, String) onApply;

  const DateFilterDialog({
    super.key,
    this.initialStartDate,
    this.initialEndDate,
    required this.onApply,
  });

  @override
  State<DateFilterDialog> createState() => _DateFilterDialogState();
}

class _DateFilterDialogState extends State<DateFilterDialog> 
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  
  DateTime? _startDate;
  DateTime? _endDate;
  String _selectedFilter = '';
  bool _isCustomRange = false;
  
  final List<Map<String, dynamic>> _quickFilters = [
    {
      'id': 'today',
      'label': 'Hari Ini',
      'icon': Icons.today,
      'color': Colors.blue,
    },
    {
      'id': 'yesterday',
      'label': 'Kemarin',
      'icon': Icons.history,
      'color': Colors.orange,
    },
    {
      'id': 'last_7_days',
      'label': '7 Hari Terakhir',
      'icon': Icons.date_range,
      'color': Colors.green,
    },
    {
      'id': 'this_week',
      'label': 'Minggu Ini',
      'icon': Icons.view_week,
      'color': Colors.purple,
    },
    {
      'id': 'last_week',
      'label': 'Minggu Lalu',
      'icon': Icons.skip_previous,
      'color': Colors.indigo,
    },
    {
      'id': 'this_month',
      'label': 'Bulan Ini',
      'icon': Icons.calendar_today,
      'color': Colors.teal,
    },
    {
      'id': 'last_month',
      'label': 'Bulan Lalu',
      'icon': Icons.calendar_month,
      'color': Colors.deepOrange,
    },
    {
      'id': 'last_30_days',
      'label': '30 Hari Terakhir',
      'icon': Icons.event_note,
      'color': Colors.cyan,
    },
    {
      'id': 'this_quarter',
      'label': 'Kuartal Ini',
      'icon': Icons.view_quilt,
      'color': Colors.pink,
    },
    {
      'id': 'this_year',
      'label': 'Tahun Ini',
      'icon': Icons.event,
      'color': Colors.amber,
    },
    {
      'id': 'all_time',
      'label': 'Semua Waktu',
      'icon': Icons.all_inclusive,
      'color': Colors.grey,
    },
    {
      'id': 'custom',
      'label': 'Custom Range',
      'icon': Icons.tune,
          'color': AppColors.primary,
    },
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    );
    _animationController.forward();
    
    _startDate = widget.initialStartDate;
    _endDate = widget.initialEndDate;
    _determineInitialFilter();
  }
  
  void _determineInitialFilter() {
    if (_startDate == null || _endDate == null) {
      _selectedFilter = 'all_time';
      return;
    }
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startOfDay = DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
    final endOfDay = DateTime(_endDate!.year, _endDate!.month, _endDate!.day, 23, 59, 59);
    
    // Check for today
    if (startOfDay == today && endOfDay.day == today.day) {
      _selectedFilter = 'today';
    }
    // Check for this month
    else if (startOfDay == DateTime(now.year, now.month, 1) &&
             endOfDay.day == DateTime(now.year, now.month + 1, 0).day) {
      _selectedFilter = 'this_month';
    }
    // Check for last month
    else if (startOfDay == DateTime(now.year, now.month - 1, 1) &&
             endOfDay.day == DateTime(now.year, now.month, 0).day) {
      _selectedFilter = 'last_month';
    }
    // Otherwise it's custom
    else {
      _selectedFilter = 'custom';
      _isCustomRange = true;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  void _selectQuickFilter(String filterId) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    setState(() {
      _selectedFilter = filterId;
      _isCustomRange = false;
      
      switch (filterId) {
        case 'today':
          _startDate = today;
          _endDate = DateTime(today.year, today.month, today.day, 23, 59, 59);
          break;
        case 'yesterday':
          final yesterday = today.subtract(const Duration(days: 1));
          _startDate = yesterday;
          _endDate = DateTime(yesterday.year, yesterday.month, yesterday.day, 23, 59, 59);
          break;
        case 'last_7_days':
          _startDate = today.subtract(const Duration(days: 6));
          _endDate = DateTime(today.year, today.month, today.day, 23, 59, 59);
          break;
        case 'this_week':
          final weekday = today.weekday;
          final monday = today.subtract(Duration(days: weekday - 1));
          _startDate = monday;
          _endDate = DateTime(today.year, today.month, today.day, 23, 59, 59);
          break;
        case 'last_week':
          final weekday = today.weekday;
          final lastMonday = today.subtract(Duration(days: weekday + 6));
          final lastSunday = lastMonday.add(const Duration(days: 6));
          _startDate = lastMonday;
          _endDate = DateTime(lastSunday.year, lastSunday.month, lastSunday.day, 23, 59, 59);
          break;
        case 'this_month':
          _startDate = DateTime(now.year, now.month, 1);
          _endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
          break;
        case 'last_month':
          _startDate = DateTime(now.year, now.month - 1, 1);
          _endDate = DateTime(now.year, now.month, 0, 23, 59, 59);
          break;
        case 'last_30_days':
          _startDate = today.subtract(const Duration(days: 29));
          _endDate = DateTime(today.year, today.month, today.day, 23, 59, 59);
          break;
        case 'this_quarter':
          final quarter = ((now.month - 1) ~/ 3);
          final startMonth = quarter * 3 + 1;
          _startDate = DateTime(now.year, startMonth, 1);
          final endMonth = startMonth + 2;
          _endDate = DateTime(now.year, endMonth + 1, 0, 23, 59, 59);
          break;
        case 'this_year':
          _startDate = DateTime(now.year, 1, 1);
          _endDate = DateTime(now.year, 12, 31, 23, 59, 59);
          break;
        case 'all_time':
          _startDate = null;
          _endDate = null;
          break;
        case 'custom':
          _isCustomRange = true;
          // Keep existing dates or set to default
          _startDate ??= today.subtract(const Duration(days: 30));
          _endDate ??= DateTime(today.year, today.month, today.day, 23, 59, 59);
          break;
      }
    });
  }
  
  Future<void> _selectCustomDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : DateTimeRange(
              start: DateTime.now().subtract(const Duration(days: 30)),
              end: DateTime.now(),
            ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.background,
              onSurface: AppColors.foreground,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = DateTime(
          picked.end.year, 
          picked.end.month, 
          picked.end.day, 
          23, 59, 59
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Container(
          constraints: const BoxConstraints(
            maxWidth: 500,
            maxHeight: 600,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildQuickFilters(),
                      if (_isCustomRange) ...[
                        const SizedBox(height: 24),
                        _buildCustomRangeSection(),
                      ],
                      const SizedBox(height: 24),
                      _buildDatePreview(),
                    ],
                  ),
                ),
              ),
              _buildActions(),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: primaryPawColor.withOpacity(0.1),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: primaryPawColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.filter_list,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filter Periode',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.foreground,
                  ),
                ),
                Text(
                  'Pilih periode untuk laporan penjualan',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.foregroundMuted,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.close,
              color: AppColors.foregroundMuted,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildQuickFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Filter Cepat',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.foreground,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _quickFilters.map((filter) {
            final isSelected = _selectedFilter == filter['id'];
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _selectQuickFilter(filter['id']),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? filter['color'].withOpacity(0.2)
                          : AppColors.background,
                      border: Border.all(
                        color: isSelected 
                            ? filter['color']
                            : AppColors.border,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          filter['icon'],
                          size: 16,
                          color: isSelected 
                              ? filter['color']
                              : AppColors.foregroundMuted,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          filter['label'],
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: isSelected 
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: isSelected 
                                ? filter['color']
                                : AppColors.foreground,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
  
  Widget _buildCustomRangeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pilih Rentang Tanggal',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.foreground,
          ),
        ),
        const SizedBox(height: 12),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _selectCustomDateRange,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.background,
                border: Border.all(color: AppColors.primary),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_month,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dari - Sampai',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.foregroundMuted,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _startDate != null && _endDate != null
                              ? '${DateFormat('dd MMM yyyy').format(_startDate!)} - ${DateFormat('dd MMM yyyy').format(_endDate!)}'
                              : 'Klik untuk memilih tanggal',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.foreground,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.edit_calendar,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildDatePreview() {
    String previewText = '';
    
    if (_selectedFilter == 'all_time') {
      previewText = 'Menampilkan data dari semua periode';
    } else if (_startDate != null && _endDate != null) {
      final days = _endDate!.difference(_startDate!).inDays + 1;
      previewText = 'Menampilkan data $days hari\n${DateFormat('dd MMMM yyyy').format(_startDate!)} - ${DateFormat('dd MMMM yyyy').format(_endDate!)}';
    }
    
    if (previewText.isEmpty) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blue.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 18,
            color: Colors.blue[700],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              previewText,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.blue[700],
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
        border: Border(
          top: BorderSide(
            color: AppColors.border,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Batal',
                style: GoogleFonts.inter(
                  color: AppColors.foregroundMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: () {
                widget.onApply(_startDate, _endDate, _selectedFilter);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                'Terapkan Filter',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}