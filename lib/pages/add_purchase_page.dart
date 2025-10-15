import '../models/product.dart';
import '../models/purchase.dart';
import '../models/purchase_item.dart';
import '../services/supabase_service.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import 'package:flutter/material.dart';

class AddPurchasePage extends StatefulWidget {
  const AddPurchasePage({super.key});

  @override
  _AddPurchasePageState createState() => _AddPurchasePageState();
}

class _AddPurchasePageState extends State<AddPurchasePage> {
  final SupabaseService _supabaseService = SupabaseService();
  final _searchController = TextEditingController();
  final _invoiceController =
      TextEditingController(text: 'PO-${DateTime.now().millisecondsSinceEpoch}');
  final _supplierController = TextEditingController();

  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  List<PurchaseItem> _cartItems = [];

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _searchController.addListener(_filterProducts);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _invoiceController.dispose();
    _supplierController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    final productList = await _supabaseService.getProducts();
    if (mounted)
      setState(() {
        _products = productList;
        _filteredProducts = productList;
      });
  }

  void _filterProducts() {
    final query = _searchController.text.toLowerCase();
    setState(() => _filteredProducts = _products
        .where((p) =>
            p.name.toLowerCase().contains(query) ||
            p.code.toLowerCase().contains(query))
        .toList());
  }

  void _showAddItemDialog(Product product) {
    final qtyController = TextEditingController(text: '1');
    final priceController =
        TextEditingController(text: product.purchasePrice.toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Tambah ${product.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: qtyController,
                decoration: const InputDecoration(labelText: 'Jumlah'),
                keyboardType: TextInputType.number),
            const SizedBox(height: 8),
            TextField(
                controller: priceController,
                decoration:
                    const InputDecoration(labelText: 'Harga Beli per Unit'),
                keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              final quantity = int.tryParse(qtyController.text) ?? 0;
              final price = double.tryParse(priceController.text) ?? 0.0;
              if (quantity > 0 && price >= 0) {
                setState(() {
                  _cartItems.add(PurchaseItem(
                    purchaseId: 0,
                    productId: product.id!,
                    productName: product.name,
                    quantity: quantity,
                    unitPrice: price,
                    totalPrice: quantity * price,
                  ));
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Tambah'),
          ),
        ],
      ),
    );
  }

  double get _totalAmount =>
      _cartItems.fold(0.0, (sum, item) => sum + item.totalPrice);

  Future<void> _processPurchase() async {
    if (_cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Keranjang pembelian kosong.'),
          backgroundColor: Colors.orange));
      return;
    }

    final purchase = Purchase(
      invoiceNumber: _invoiceController.text.isNotEmpty
          ? _invoiceController.text
          : 'PO-${DateTime.now().millisecondsSinceEpoch}',
      purchaseDate: DateTime.now(),
      totalAmount: _totalAmount,
      supplier: _supplierController.text,
    );

    try {
      await _supabaseService.processPurchase(purchase, _cartItems);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Pembelian berhasil dicatat & stok diperbarui!'),
            backgroundColor: Colors.green));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Gagal: ${e.toString()}'),
            backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Catat Pembelian Baru')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                    hintText: 'Cari produk untuk tambah stok...',
                    prefixIcon: Icon(Icons.search, color: Colors.grey[500]))),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filteredProducts.length,
              itemBuilder: (context, index) {
                final product = _filteredProducts[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(product.name,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Stok saat ini: ${product.stock}'),
                    trailing: const Icon(Icons.add_circle_outline,
                        color: primaryPawColor),
                    onTap: () => _showAddItemDialog(product),
                  ),
                );
              },
            ),
          ),
          _buildPurchaseSummary(),
        ],
      ),
    );
  }

  Widget _buildPurchaseSummary() {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 15,
                offset: const Offset(0, -5))
          ]),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Ringkasan Pembelian (${_cartItems.length})',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SizedBox(
              height: 120,
              child: _cartItems.isEmpty
                  ? Center(
                      child: Text('Pilih produk untuk ditambahkan.',
                          style: TextStyle(color: Colors.grey[600])))
                  : ListView.builder(
                      itemCount: _cartItems.length,
                      itemBuilder: (context, index) {
                        final item = _cartItems[index];
                        return ListTile(
                          title: Text(item.productName),
                          subtitle: Text(
                              '${item.quantity}x @ ${formatCurrency(item.unitPrice)}'),
                          trailing: Text(formatCurrency(item.totalPrice),
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          dense: true,
                        );
                      }),
            ),
            const Divider(height: 16),
            Row(
              children: [
                Expanded(
                    child: TextField(
                        controller: _invoiceController,
                        decoration:
                            const InputDecoration(labelText: 'No. Ref / Invoice'))),
                const SizedBox(width: 16),
                Expanded(
                    child: TextField(
                        controller: _supplierController,
                        decoration: const InputDecoration(
                            labelText: 'Supplier (Opsional)'))),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700])),
                Text(formatCurrency(_totalAmount),
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor)),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                    onPressed: _cartItems.isNotEmpty ? _processPurchase : null,
                    child: const Text('Simpan Pembelian'))),
          ],
        ),
      ),
    );
  }
}
