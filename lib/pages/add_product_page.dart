import '../models/category.dart';
import '../models/product.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import 'dart:math';
import 'package:flutter/material.dart';

class AddProductPage extends StatefulWidget {
  const AddProductPage({Key? key}) : super(key: key);
  @override
  _AddProductPageState createState() => _AddProductPageState();
}

class ProductVariant {
  TextEditingController nameController = TextEditingController();
  TextEditingController codeController =
      TextEditingController(text: 'PAW${Random().nextInt(99999)}');
  TextEditingController purchasePriceController = TextEditingController();
  TextEditingController sellingPriceController = TextEditingController();
  TextEditingController stockController = TextEditingController();
  TextEditingController stockAlertController = TextEditingController(text: '5');
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();
  final _supabaseService = SupabaseService();

  final _productNameController = TextEditingController();
  String? _selectedCategory;
  List<Category> _categories = [];
  List<ProductVariant> _variants = [ProductVariant()];
  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final categoryList = await _supabaseService.getCategories();
    if (!mounted) return;
    setState(() {
      _categories = categoryList;
      if (_selectedCategory != null &&
          !_categories.any((c) => c.name == _selectedCategory)) {
        _categories.add(Category(name: _selectedCategory!));
      }
    });
  }

  @override
  void dispose() {
    _productNameController.dispose();
    for (var variant in _variants) {
      variant.nameController.dispose();
      variant.codeController.dispose();
      variant.purchasePriceController.dispose();
      variant.sellingPriceController.dispose();
      variant.stockController.dispose();
      variant.stockAlertController.dispose();
    }
    super.dispose();
  }

  void _addVariant() {
    setState(() {
      _variants.add(ProductVariant());
    });
  }

  void _removeVariant(int index) {
    if (_variants.length > 1) {
      setState(() {
        _variants.removeAt(index);
      });
    }
  }

  Future<void> _saveProducts() async {
    if (_formKey.currentState!.validate()) {
      final String mainProductName = _productNameController.text;
      final String category = _selectedCategory ?? 'Lainnya';
      int savedCount = 0;

      try {
        for (var variant in _variants) {
          final String variantName = variant.nameController.text;
          final String finalProductName = variantName.isNotEmpty
              ? '$mainProductName - $variantName'
              : mainProductName;

          final product = Product(
            name: finalProductName,
            code: variant.codeController.text,
            category: category,
            purchasePrice:
                double.tryParse(variant.purchasePriceController.text) ?? 0,
            sellingPrice:
                double.tryParse(variant.sellingPriceController.text) ?? 0,
            stock: int.tryParse(variant.stockController.text) ?? 0,
            stockAlert: int.tryParse(variant.stockAlertController.text) ?? 5,
            createdAt: DateTime.now(),
          );
          await _supabaseService.insertProduct(product);
          savedCount++;
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('$savedCount produk/varian berhasil ditambahkan')));
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Gagal menyimpan: ${e.toString()}'),
              backgroundColor: Colors.red));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Tambah Produk Baru')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildGeneralInfoCard(),
            const SizedBox(height: 16),
            ..._buildVariantCards(),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _addVariant,
              icon: const Icon(Icons.add),
              label: const Text("Tambah Varian"),
              style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16)),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: _saveProducts,
          child: const Text('Simpan Produk'),
        ),
      ),
    );
  }

  Widget _buildGeneralInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Informasi Umum", style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextFormField(
              controller: _productNameController,
              decoration: const InputDecoration(
                  labelText: 'Nama Produk Utama (misal: Baju Kucing)'),
              validator: (v) => v!.isEmpty ? 'Nama produk wajib diisi' : null,
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
              validator: (value) => value == null ? 'Pilih kategori' : null,
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildVariantCards() {
    return List.generate(_variants.length, (index) {
      return Card(
        margin: const EdgeInsets.only(bottom: 16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Varian ${index + 1}",
                      style: Theme.of(context).textTheme.titleLarge),
                  if (_variants.length > 1)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _removeVariant(index),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _variants[index].nameController,
                decoration: const InputDecoration(
                    labelText: 'Nama Varian (misal: Coklat Size M)'),
                validator: (v) => v!.isEmpty ? 'Nama varian wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _variants[index].codeController,
                decoration: const InputDecoration(labelText: 'Kode Produk'),
                validator: (v) => v!.isEmpty ? 'Kode wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _variants[index].purchasePriceController,
                      decoration: const InputDecoration(labelText: 'Harga Beli'),
                      keyboardType: TextInputType.number,
                      validator: (v) => v!.isEmpty ? 'Wajib' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _variants[index].sellingPriceController,
                      decoration: const InputDecoration(labelText: 'Harga Jual'),
                      keyboardType: TextInputType.number,
                      validator: (v) => v!.isEmpty ? 'Wajib' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _variants[index].stockController,
                      decoration: const InputDecoration(labelText: 'Stok'),
                      keyboardType: TextInputType.number,
                      validator: (v) => v!.isEmpty ? 'Wajib' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _variants[index].stockAlertController,
                      decoration:
                          const InputDecoration(labelText: 'Peringatan Stok'),
                      keyboardType: TextInputType.number,
                      validator: (v) => v!.isEmpty ? 'Wajib' : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }
}
