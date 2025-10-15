import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'models/product.dart';
import 'utils/formatters.dart';
import 'theme/app_theme.dart';
import 'widgets/ui_components.dart';

class ProductDetailPage extends StatelessWidget {
  final Product product;

  const ProductDetailPage({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(product.name),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildDetailCard(
            context: context,
            title: 'Informasi Umum',
            icon: Icons.info_outline,
            children: [
              _buildInfoRow(Icons.qr_code, 'Kode Produk', product.code),
              _buildInfoRow(Icons.category_outlined, 'Kategori', product.category),
              _buildInfoRow(Icons.calendar_today, 'Tanggal Dibuat',
                  DateFormat('dd MMM yyyy').format(product.createdAt)),
            ],
          ),
          const SizedBox(height: 16),
          _buildDetailCard(
            context: context,
            title: 'Harga & Keuntungan',
            icon: Icons.monetization_on_outlined,
            children: [
              _buildInfoRow(
                  Icons.arrow_upward, 'Harga Jual', formatCurrency(product.sellingPrice)),
              _buildInfoRow(Icons.arrow_downward, 'Harga Beli (HPP)',
                  formatCurrency(product.purchasePrice)),
              _buildInfoRow(
                  Icons.trending_up, 'Keuntungan', formatCurrency(product.profit)),
              _buildInfoRow(Icons.pie_chart_outline, 'Margin Keuntungan',
                  '${product.profitMargin.toStringAsFixed(1)}%'),
            ],
          ),
          const SizedBox(height: 16),
          _buildDetailCard(
            context: context,
            title: 'Inventaris',
            icon: Icons.inventory_2_outlined,
            children: [
              _buildInfoRow(Icons.inventory, 'Stok Tersedia', '${product.stock} unit'),
              _buildInfoRow(
                  Icons.warning_amber_rounded, 'Peringatan Stok', 'di bawah ${product.stockAlert} unit'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return UIInfoRow(
      icon: icon,
      label: label,
      value: value,
    );
  }

  Widget _buildDetailCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return UICard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UISectionHeader(
            title: title,
            icon: icon,
          ),
          const UISeparator(),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
}
