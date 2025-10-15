import '../utils/constants.dart';
import 'dashboard_page.dart';
import 'more_page.dart';
import 'new_sale_page.dart';
import 'package:flutter/material.dart';
import 'products_page.dart';
import 'sales_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      DashboardPage(key: UniqueKey()),
      const ProductsPage(),
      SalesPage(),
      const MorePage()
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _refreshPage(int index) {
    if (mounted) {
      setState(() {
        if (index == 0) _pages[0] = DashboardPage(key: UniqueKey());
        if (index == 1) _pages[1] = const ProductsPage();
        if (index == 2) _pages[2] = SalesPage();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _pages),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const NewSalePage()));
          if (result == true) {
            _refreshPage(0);
            _refreshPage(1);
            _refreshPage(2); 
          }
        },
        child: const Icon(Icons.add),
        elevation: 2.0,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        padding: const EdgeInsets.symmetric(horizontal: 0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            _buildNavItem(
                icon: Icons.dashboard_rounded,
                label: 'Beranda',
                index: 0),
            _buildNavItem(
                icon: Icons.inventory_2_rounded, label: 'Produk', index: 1),
            const SizedBox(width: 36),
            _buildNavItem(
                icon: Icons.receipt_long_rounded,
                label: 'Transaksi',
                index: 2),
            _buildNavItem(icon: Icons.menu_rounded, label: 'Lainnya', index: 3),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
      {required IconData icon, required String label, required int index}) {
    final isSelected = _selectedIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => _onItemTapped(index),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isSelected ? primaryPawColor : Colors.grey.shade400),
              const SizedBox(height: 2), 
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? primaryPawColor : Colors.grey.shade400,
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
