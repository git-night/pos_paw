import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/customer.dart';
import '../models/product.dart';
import '../models/discount.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';

class AddEditDiscountPage extends StatefulWidget {
  final Discount? discount;
  const AddEditDiscountPage({super.key, this.discount});

  @override
  State<AddEditDiscountPage> createState() => _AddEditDiscountPageState();
}

class _AddEditDiscountPageState extends State<AddEditDiscountPage> {
  final _formKey = GlobalKey<FormState>();
  final _service = SupabaseService();

  final _nameCtrl = TextEditingController();
  final _valueCtrl = TextEditingController();

  String _targetType = 'product';
  String _valueType = 'percentage';
  int? _selectedProductId;
  int? _selectedCustomerId;
  DateTime? _startAt;
  DateTime? _endAt;
  bool _isActive = true;

  List<Product> _products = [];
  List<Customer> _customers = [];
  bool _loadingRefs = true;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final products = await _service.getProducts();
    final customers = await _service.getCustomers();

    if (widget.discount != null) {
      final d = widget.discount!;
      _nameCtrl.text = d.name;
      _valueCtrl.text = d.value.toString();
      _targetType = d.targetType;
      _valueType = d.valueType;
      _selectedProductId = d.targetProductId;
      _selectedCustomerId = d.targetCustomerId;
      _startAt = d.startAt;
      _endAt = d.endAt;
      _isActive = d.isActive;
    }

    if (!mounted) return;
    setState(() {
      _products = products;
      _customers = customers;
      _loadingRefs = false;
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _valueCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool start}) async {
    final initial = start ? (_startAt ?? DateTime.now()) : (_endAt ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (start) {
          _startAt = DateTime(picked.year, picked.month, picked.day);
        } else {
          _endAt = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
        }
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final value = double.tryParse(_valueCtrl.text) ?? 0;

    final payload = Discount(
      id: widget.discount?.id,
      name: _nameCtrl.text.trim(),
      targetType: _targetType,
      targetProductId: _targetType == 'product' ? _selectedProductId : null,
      targetCustomerId: _targetType == 'customer' ? _selectedCustomerId : null,
      valueType: _valueType,
      value: value,
      startAt: _startAt,
      endAt: _endAt,
      isActive: _isActive,
    );

    try {
      if (widget.discount == null) {
        await _service.insertDiscount(payload);
      } else {
        await _service.updateDiscount(payload);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.discount == null ? 'Diskon ditambahkan' : 'Diskon diperbarui')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(title: Text(widget.discount == null ? 'Tambah Diskon' : 'Edit Diskon')),
      body: SafeArea(
        child: _loadingRefs
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  24 + MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).viewPadding.bottom,
                ),
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                physics: const AlwaysScrollableScrollPhysics(),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(labelText: 'Nama Diskon'),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _targetType,
                            decoration: AppTheme.dropdownDecoration(labelText: 'Target'),
                            isExpanded: true,
                            style: AppTheme.dropdownItemStyle(),
                            dropdownColor: AppColors.card,
                            icon: Icon(Icons.keyboard_arrow_down, size: 20),
                            items: [
                              DropdownMenuItem(
                                value: 'product',
                                child: Text('Produk', style: AppTheme.dropdownItemStyle(), overflow: TextOverflow.ellipsis),
                              ),
                              DropdownMenuItem(
                                value: 'customer',
                                child: Text('Pelanggan', style: AppTheme.dropdownItemStyle(), overflow: TextOverflow.ellipsis),
                              ),
                            ],
                            onChanged: (v) => setState(() {
                              _targetType = v ?? 'product';
                              _selectedProductId = null;
                              _selectedCustomerId = null;
                            }),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _valueType,
                            decoration: AppTheme.dropdownDecoration(labelText: 'Tipe'),
                            isExpanded: true,
                            style: AppTheme.dropdownItemStyle(),
                            dropdownColor: AppColors.card,
                            icon: Icon(Icons.keyboard_arrow_down, size: 20),
                            items: [
                              DropdownMenuItem(
                                value: 'percentage',
                                child: Text('Persen (%)', style: AppTheme.dropdownItemStyle(), overflow: TextOverflow.ellipsis),
                              ),
                              DropdownMenuItem(
                                value: 'fixed',
                                child: Text('Nominal', style: AppTheme.dropdownItemStyle(), overflow: TextOverflow.ellipsis),
                              ),
                            ],
                            onChanged: (v) => setState(() => _valueType = v ?? 'percentage'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_targetType == 'product')
                      DropdownButtonFormField<int>(
                        value: _selectedProductId,
                        decoration: AppTheme.dropdownDecoration(labelText: 'Pilih Produk'),
                        isExpanded: true,
                        style: AppTheme.dropdownItemStyle(),
                        dropdownColor: AppColors.card,
                        icon: Icon(Icons.keyboard_arrow_down, size: 20),
                        items: _products
                            .map((p) => DropdownMenuItem(
                                  value: p.id,
                                  child: Text('[${p.code}] ${p.name}', style: AppTheme.dropdownItemStyle()),
                                ))
                            .toList(),
                        validator: (v) => v == null ? 'Pilih produk' : null,
                        onChanged: (v) => setState(() => _selectedProductId = v),
                      ),
                    if (_targetType == 'customer')
                      DropdownButtonFormField<int>(
                        value: _selectedCustomerId,
                        decoration: AppTheme.dropdownDecoration(labelText: 'Pilih Pelanggan'),
                        isExpanded: true,
                        style: AppTheme.dropdownItemStyle(),
                        dropdownColor: AppColors.card,
                        icon: Icon(Icons.keyboard_arrow_down, size: 20),
                        items: _customers
                            .map((c) => DropdownMenuItem(
                                  value: c.id,
                                  child: Text(c.name, style: AppTheme.dropdownItemStyle()),
                                ))
                            .toList(),
                        validator: (v) => v == null ? 'Pilih pelanggan' : null,
                        onChanged: (v) => setState(() => _selectedCustomerId = v),
                      ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _valueCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,10}')),
                      ],
                      decoration: InputDecoration(
                        labelText: _valueType == 'percentage' ? 'Nilai Diskon (%)' : 'Nilai Diskon (Rp)',
                        prefixText: _valueType == 'fixed' ? 'Rp ' : null,
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Wajib diisi';
                        final n = double.tryParse(v) ?? -1;
                        if (n <= 0) return 'Harus > 0';
                        if (_valueType == 'percentage' && (n <= 0 || n > 100)) return '0 < % <= 100';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _pickDate(start: true),
                            child: InputDecorator(
                              decoration: const InputDecoration(labelText: 'Mulai Berlaku'),
                              child: Text(_startAt == null ? 'Tanpa awal' : _fmtDate(_startAt!)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: () => _pickDate(start: false),
                            child: InputDecorator(
                              decoration: const InputDecoration(labelText: 'Berakhir'),
                              child: Text(_endAt == null ? 'Tanpa akhir' : _fmtDate(_endAt!)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _isActive,
                      title: const Text('Aktif'),
                      onChanged: (v) => setState(() => _isActive = v),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _save,
                        child: Text(widget.discount == null ? 'Simpan' : 'Update'),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
      ),
    );
  }

  String _fmtDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${dt.day.toString().padLeft(2, '0')} ${months[dt.month - 1]} ${dt.year}';
  }
}