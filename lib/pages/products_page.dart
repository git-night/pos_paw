import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/product.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../product_detail_page.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});
  @override
  _ProductsPageState createState() => _ProductsPageState();
}
class _ProductsPageState extends State<ProductsPage> {
  final SupabaseService _supabaseService = SupabaseService();
  List<Product> products = [];
  List<Product> filteredProducts = [];
  final TextEditingController searchController = TextEditingController();
  @override
  void initState() {
    super.initState();
    _loadProducts();
    searchController.addListener(_filterProducts);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    final productList = await _supabaseService.getProducts();
    if (mounted)
      setState(() {
        products = productList;
        filteredProducts = productList;
      });
  }

  void _filterProducts() {
    final query = searchController.text.toLowerCase();
    setState(() => filteredProducts = products
        .where((p) =>
            p.name.toLowerCase().contains(query) ||
            p.code.toLowerCase().contains(query) ||
            p.category.toLowerCase().contains(query))
        .toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Produk')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Cari produk...',
                hintStyle: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.foregroundMuted,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: AppColors.foregroundMuted,
                  size: 20,
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
            child: RefreshIndicator(
              onRefresh: _loadProducts,
              child: filteredProducts.isEmpty
                  ? const Center(child: Text('Belum ada produk.'))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filteredProducts.length,
                      itemBuilder: (context, index) =>
                          _buildProductCard(filteredProducts[index])),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Product product) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProductDetailPage(product: product),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(product.name,
                              style: GoogleFonts.montserrat(
                                  fontSize: 17, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(
                              'Kode: ${product.code} • Kategori: ${product.category}',
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
                Divider(height: 24, color: Colors.grey[200]),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildInfoItem(
                        Icons.inventory_2_outlined,
                        'Stok: ${product.stock}',
                        product.stock <= product.stockAlert
                            ? Colors.orange.shade700
                            : Colors.green.shade700),
                    _buildInfoItem(
                        Icons.show_chart_rounded,
                        '${formatCurrency(product.profit)} (${product.profitMargin.toStringAsFixed(0)}%)',
                        Colors.green.shade800),
                    _buildInfoItem(Icons.attach_money,
                        formatCurrency(product.sellingPrice), Colors.blue.shade800),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

  Widget _buildInfoItem(IconData icon, String text, Color color) => Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(text, style: GoogleFonts.montserrat(fontWeight: FontWeight.w500)),
        ],
      );

  void _confirmDelete(Product product) => showDialog(
      context: context,
      builder: (context) => AlertDialog(
              title: const Text('Konfirmasi Hapus'),
              content: Text('Yakin ingin menghapus produk "${product.name}"?'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Batal')),
                TextButton(
                    onPressed: () async {
                      await _supabaseService.deleteProduct(product.id!);
                      if (mounted) Navigator.pop(context);
                      _loadProducts();
                      if (mounted)
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Produk berhasil dihapus')));
                    },
                    child: const Text('Hapus', style: TextStyle(color: Colors.red)))
              ]));
}
