import '../models/customer.dart';
import '../models/discount.dart';
import '../models/product.dart';
import '../models/sale.dart';
import '../models/sale_item.dart';
import '../services/supabase_service.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NewSalePage extends StatefulWidget {
  const NewSalePage({super.key});
  @override
  _NewSalePageState createState() => _NewSalePageState();
}

class _NewSalePageState extends State<NewSalePage> {
  final SupabaseService _supabaseService = SupabaseService();
  final TextEditingController _searchController = TextEditingController();
  List<Product> products = [];
  List<Product> filteredProducts = [];
  List<SaleItem> cartItems = [];
  Customer? _selectedCustomer;
  List<Discount> _customerDiscounts = [];
  final Map<int, List<Discount>> _productDiscounts = {};

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _searchController.addListener(_filterProducts);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    final productList = await _supabaseService.getProducts();
    if (mounted) {
      setState(() {
        products = productList;
        filteredProducts = productList;
      });
    }
  }

  void _filterProducts() {
    final query = _searchController.text.toLowerCase();
    setState(() => filteredProducts = products
        .where((p) =>
            p.name.toLowerCase().contains(query) ||
            p.code.toLowerCase().contains(query))
        .toList());
  }

  void _addToCart(Product product) async {
    final existingIndex =
        cartItems.indexWhere((item) => item.productId == product.id);

    if (existingIndex != -1) {
      final itemInCart = cartItems[existingIndex];
      if (itemInCart.quantity < product.stock) {
        setState(() {
          itemInCart.quantity++;
          itemInCart.totalPrice = itemInCart.quantity * itemInCart.unitPrice;
        });
        // Reapply discount for updated quantity
        await _applyDiscountToItem(itemInCart);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Jumlah pesanan untuk ${product.name} sudah mencapai batas stok.'),
            backgroundColor: Colors.orange.shade800,
          ),
        );
      }
    } else {
      // Create new cart item
      final newItem = SaleItem(
        saleId: 0,
        productId: product.id!,
        productName: product.name,
        quantity: 1,
        unitPrice: product.sellingPrice,
        totalPrice: product.sellingPrice,
      );

      setState(() {
        cartItems.add(newItem);
      });

      // Apply automatic discount
      await _applyDiscountToItem(newItem);
    }
  }

  /// Apply automatic discount to a cart item based on product and customer discounts
  Future<void> _applyDiscountToItem(SaleItem item) async {
    try {
      // 1. Check for product-specific discount (higher priority)
      if (!_productDiscounts.containsKey(item.productId)) {
        final productDiscounts = await _supabaseService.getActiveDiscountsForProduct(item.productId);
        _productDiscounts[item.productId] = productDiscounts;
      }

      final productDiscountList = _productDiscounts[item.productId] ?? [];

      if (productDiscountList.isNotEmpty) {
        // Use the first active product discount
        final discount = productDiscountList.first;
        _applyDiscountCalculation(item, discount, isProductDiscount: true);
        return;
      }

      // 2. If no product discount, check for customer discount
      if (_customerDiscounts.isNotEmpty) {
        final discount = _customerDiscounts.first;
        _applyDiscountCalculation(item, discount, isProductDiscount: false);
        return;
      }

      // 3. No discount applies - ensure discount is cleared
      setState(() {
        item.discount = 0;
        item.discountReason = null;
      });

    } catch (e) {
      print('Error applying discount: $e');
    }
  }

  /// Calculate and apply discount to item
  void _applyDiscountCalculation(SaleItem item, Discount discount, {required bool isProductDiscount}) {
    double discountAmount = 0;

    if (discount.valueType == 'percentage') {
      discountAmount = (item.totalPrice * discount.value / 100);
    } else {
      // Fixed discount - multiply by quantity for total discount
      discountAmount = discount.value * item.quantity;
    }

    // Ensure discount doesn't exceed total price
    if (discountAmount > item.totalPrice) {
      discountAmount = item.totalPrice;
    }

    setState(() {
      item.discount = discountAmount;
      item.discountReason = '${discount.name} (${isProductDiscount ? 'Diskon Produk' : 'Diskon Pelanggan'})';
    });
  }


  Future<void> _showCustomerSelectionDialog() async {
    final customers = await _supabaseService.getCustomers();
    if (!mounted) return;

    final selected = await showDialog<Customer?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pilih Pelanggan'),
        content: SizedBox(
          width: double.maxFinite,
          child: customers.isEmpty
          ? const Center(child: Text("Belum ada data pelanggan. Silakan tambah di menu Lainnya > Pelanggan."),)
          : ListView.builder(
            shrinkWrap: true,
            itemCount: customers.length,
            itemBuilder: (context, index) {
              final customer = customers[index];
              return ListTile(
                title: Text(customer.name),
                subtitle: Text(customer.phone ?? 'No phone'),
                onTap: () => Navigator.pop(context, customer),
              );
            },
          ),
        ),
      ),
    );

    if (selected != null) {
      setState(() => _selectedCustomer = selected);

      // Load customer discounts
      await _loadCustomerDiscounts(selected.id!);

      // Reapply discounts to all cart items
      for (var item in cartItems) {
        await _applyDiscountToItem(item);
      }
    }
  }

  /// Load active discounts for selected customer
  Future<void> _loadCustomerDiscounts(int customerId) async {
    try {
      final discounts = await _supabaseService.getActiveDiscountsForCustomer(customerId);
      setState(() {
        _customerDiscounts = discounts;
      });
    } catch (e) {
      print('Error loading customer discounts: $e');
    }
  }

  Future<void> _showItemDiscountDialog(int index) async {
    final item = cartItems[index];
    final formKey = GlobalKey<FormState>();
    final discountController = TextEditingController(
        text: item.discount > 0 ? item.discount.toStringAsFixed(0) : '');
    final reasonController = TextEditingController(text: item.discountReason ?? '');

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Diskon untuk ${item.productName}'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (item.discount > 0)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      'Diskon otomatis: ${formatCurrency(item.discount)}',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                TextFormField(
                  controller: discountController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Jumlah Diskon Manual (Rp)',
                    prefixText: 'Rp ',
                    helperText: 'Kosongkan untuk pakai diskon otomatis',
                  ),
                  validator: (v) {
                    if (v != null && v.isNotEmpty) {
                      final amount = double.tryParse(v) ?? 0.0;
                      if (amount > item.totalPrice) {
                        return 'Diskon > harga';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: reasonController,
                  decoration: const InputDecoration(labelText: 'Keterangan Diskon'),
                  validator: (v) {
                    // Only require reason if manual discount is entered
                    if (discountController.text.isNotEmpty && (v == null || v.isEmpty)) {
                      return 'Keterangan wajib diisi untuk diskon manual';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(context, {
                    'discount': double.tryParse(discountController.text) ?? 0.0,
                    'reason': reasonController.text.isEmpty ? null : reasonController.text,
                  });
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );

    if (result != null) {
      // If manual discount is set (non-zero), use it. Otherwise reapply automatic discount
      if (result['discount'] > 0) {
        setState(() {
          cartItems[index].discount = result['discount'];
          cartItems[index].discountReason = result['reason'];
        });
      } else {
        // Reapply automatic discount
        await _applyDiscountToItem(cartItems[index]);
      }
    }
  }

  double get subtotal => cartItems.fold(0, (sum, item) => sum + item.totalPrice);
  double get totalDiscount => cartItems.fold(0, (sum, item) => sum + item.discount);
  double get finalAmount => subtotal - totalDiscount;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Transaksi Baru')),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Card(
                  margin: EdgeInsets.zero,
                  child: ListTile(
                    leading: const Icon(Icons.person_outline, color: primaryPawColor),
                    title: const Text('Pelanggan'),
                    subtitle: Text(
                      _selectedCustomer?.name ?? 'Pilih Pelanggan',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _selectedCustomer == null ? Colors.red.shade700 : null
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _showCustomerSelectionDialog,
                  ),
                ),
              ),
              Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                          hintText: 'Cari produk...',
                          prefixIcon: Icon(Icons.search, color: Colors.grey[500])))),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 250),
                  itemCount: filteredProducts.length,
                  itemBuilder: (context, index) {
                    final product = filteredProducts[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(product.name,
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Stok: ${product.stock}'),
                        trailing: Text(formatCurrency(product.sellingPrice),
                            style: TextStyle(
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 15)),
                        onTap: product.stock > 0 ? () => _addToCart(product) : null,
                        enabled: product.stock > 0,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          _buildCartSection(),
        ],
      ),
    );
  }

  Widget _buildCartSection() => DraggableScrollableSheet(
        initialChildSize: 0.35,
        minChildSize: 0.2,
        maxChildSize: 0.85,
        snap: true,
        snapSizes: const [0.2, 0.35, 0.85],
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 15,
                    offset: const Offset(0, -5))
              ]),
          child: Column(
            children: [
              // Drag handle indicator
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Cart content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Keranjang (${cartItems.length})',
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        if (cartItems.isNotEmpty)
                          TextButton(
                              onPressed: () => setState(() {
                                    cartItems.clear();
                                  }),
                              child: const Text('Kosongkan',
                                  style: TextStyle(color: Colors.red))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    cartItems.isEmpty
                        ? SizedBox(
                            height: 100,
                            child: Center(
                                child: Text('Keranjang masih kosong.',
                                    style: TextStyle(color: Colors.grey[600]))))
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: cartItems.length,
                            itemBuilder: (context, index) =>
                                _buildCartItem(cartItems[index], index)),
                    const Divider(height: 24),
                    _buildTotalRow('Subtotal', formatCurrency(subtotal)),
                    const SizedBox(height: 8),
                    _buildTotalRow('Total Diskon', '- ${formatCurrency(totalDiscount)}'),
                    const Divider(height: 16),
                    _buildTotalRow('Total Bayar', formatCurrency(finalAmount),
                        isTotal: true),
                    const SizedBox(height: 20),
                    SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                            onPressed: cartItems.isNotEmpty && _selectedCustomer != null
                                ? _processSale
                                : null,
                            child: const Text('Proses Penjualan'))),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildCartItem(SaleItem item, int index) {

    final product = products.firstWhere(
      (p) => p.id == item.productId, 

      orElse: () => Product(name: item.productName, stock: 0, code: '', category: '', createdAt: DateTime.now(), purchasePrice: 0, sellingPrice: 0, stockAlert: 0)
    );
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.productName,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        Text(
                          '${item.quantity} dari ${product.stock} unit',
                          style: TextStyle(
                            color: item.quantity >= product.stock ? Colors.red.shade700 : Colors.grey[600], 
                            fontSize: 12
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(formatCurrency(item.totalPrice),
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: Colors.red, size: 20),
                      onPressed: () =>
                          setState(() => cartItems.removeAt(index))),
                ],
              ),
              if (item.discount > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Diskon: ${item.discountReason}',
                          style: TextStyle(
                              color: Colors.orange.shade800, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '- ${formatCurrency(item.discount)}',
                        style: TextStyle(
                            color: Colors.orange.shade800,
                            fontWeight: FontWeight.bold,
                            fontSize: 12),
                      ),
                    ],
                  ),
                ),
              const Divider(height: 10),
              SizedBox(
                height: 30,
                child: TextButton.icon(
                  onPressed: () => _showItemDiscountDialog(index),
                  icon: const Icon(Icons.sell_outlined, size: 16),
                  label: const Text('Beri Diskon'),
                  style: TextButton.styleFrom(
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTotalRow(String title, String amount, {bool isTotal = false}) =>
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: TextStyle(
                  fontSize: isTotal ? 18 : 14,
                  fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                  color: isTotal ? const Color(0xFF212529) : Colors.grey[700])),
          Text(amount,
              style: TextStyle(
                  fontSize: isTotal ? 20 : 16,
                  fontWeight: FontWeight.bold,
                  color: isTotal
                      ? Theme.of(context).primaryColor
                      : const Color(0xFF212529))),
        ],
      );

  Future<void> _processSale() async {
    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Validasi Gagal: Silakan pilih pelanggan terlebih dahulu.'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      final invoiceNumber = 'INV${DateTime.now().millisecondsSinceEpoch}';
      final sale = Sale(
        invoiceNumber: invoiceNumber,
        saleDate: DateTime.now(),
        totalAmount: subtotal,
        finalAmount: finalAmount,
        items: cartItems,
        customerId: _selectedCustomer?.id,
        customerName: _selectedCustomer?.name,
      );

      await _supabaseService.processSale(sale);

      scaffoldMessenger.showSnackBar(const SnackBar(
          content: Text('Penjualan berhasil!'), backgroundColor: Colors.green));
      navigator.pop(true);
    } catch (e) {
      scaffoldMessenger.showSnackBar(SnackBar(
        content: Text('Gagal: ${e.toString()}'),
        backgroundColor: Colors.red,
      ));
    }
  }
}
