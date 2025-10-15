import '../models/category.dart';
import '../models/product.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import 'package:flutter/material.dart';

class EditProductPage extends StatefulWidget {
  final Product product;
  const EditProductPage({Key? key, required this.product}) : super(key: key);

  @override
  _EditProductPageState createState() => _EditProductPageState();
}

class _EditProductPageState extends State<EditProductPage> {
  final _formKey = GlobalKey<FormState>();
  final _supabaseService = SupabaseService();

  late TextEditingController _nameController;
  late TextEditingController _codeController;
  late TextEditingController _purchasePriceController;
  late TextEditingController _sellingPriceController;
  late TextEditingController _stockController;
  late TextEditingController _stockAlertController;
  String? _selectedCategory;
  List<Category> _categories = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product.name);
    _codeController = TextEditingController(text: widget.product.code);
    _purchasePriceController =
        TextEditingController(text: widget.product.purchasePrice.toStringAsFixed(0));
    _sellingPriceController =
        TextEditingController(text: widget.product.sellingPrice.toStringAsFixed(0));
    _stockController =
        TextEditingController(text: widget.product.stock.toString());
    _stockAlertController =
        TextEditingController(text: widget.product.stockAlert.toString());
    _selectedCategory = widget.product.category;
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final categoryList = await _supabaseService.getCategories();
    if (mounted) {
      setState(() {
        _categories = categoryList;
        if (_selectedCategory != null &&
            !_categories.any((c) => c.name == _selectedCategory)) {
          _categories.add(Category(name: _selectedCategory!));
        }
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _purchasePriceController.dispose();
    _sellingPriceController.dispose();
    _stockController.dispose();
    _stockAlertController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      final updatedProduct = Product(
        id: widget.product.id,
        name: _nameController.text,
        code: _codeController.text,
        purchasePrice: double.tryParse(_purchasePriceController.text) ?? 0,
        sellingPrice: double.tryParse(_sellingPriceController.text) ?? 0,
        stock: int.tryParse(_stockController.text) ?? 0,
        stockAlert: int.tryParse(_stockAlertController.text) ?? 5,
        category: _selectedCategory ?? 'Lainnya',
        createdAt: widget.product.createdAt,
      );

      await _supabaseService.updateProduct(updatedProduct);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Produk berhasil diperbarui'),
              backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Produk')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Detail Produk",
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Nama Produk'),
                      validator: (v) =>
                          v!.isEmpty ? 'Nama produk wajib diisi' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: AppTheme.dropdownDecoration(labelText: 'Kategori'),
                      isExpanded: true,
                      style: AppTheme.dropdownItemStyle(),
                      dropdownColor: AppColors.card,
                      icon: Icon(Icons.keyboard_arrow_down, size: 20),
                      items: _categories.map((Category category) {
                        return DropdownMenuItem<String>(
                          value: category.name,
                          child: Text(category.name, style: AppTheme.dropdownItemStyle()),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          _selectedCategory = newValue;
                        });
                      },
                      validator: (value) =>
                          value == null ? 'Pilih kategori' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _codeController,
                      decoration: const InputDecoration(labelText: 'Kode Produk'),
                      validator: (v) => v!.isEmpty ? 'Kode wajib diisi' : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _purchasePriceController,
                            decoration:
                                const InputDecoration(labelText: 'Harga Beli'),
                            keyboardType: TextInputType.number,
                            validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _sellingPriceController,
                            decoration:
                                const InputDecoration(labelText: 'Harga Jual'),
                            keyboardType: TextInputType.number,
                            validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _stockController,
                            decoration: const InputDecoration(labelText: 'Stok'),
                            keyboardType: TextInputType.number,
                            validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _stockAlertController,
                            decoration: const InputDecoration(
                                labelText: 'Peringatan Stok'),
                            keyboardType: TextInputType.number,
                            validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: _saveChanges,
          child: const Text('Simpan Perubahan'),
        ),
      ),
    );
  }
}
