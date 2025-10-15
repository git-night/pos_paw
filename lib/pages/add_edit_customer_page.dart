import '../models/customer.dart';
import '../services/supabase_service.dart';
import 'package:flutter/material.dart';

class AddEditCustomerPage extends StatefulWidget {
  final Customer? customer;
  const AddEditCustomerPage({Key? key, this.customer}) : super(key: key);

  @override
  State<AddEditCustomerPage> createState() => _AddEditCustomerPageState();
}

class _AddEditCustomerPageState extends State<AddEditCustomerPage> {
  final _formKey = GlobalKey<FormState>();
  final _supabaseService = SupabaseService();
  late TextEditingController _name, _phone, _email, _address;
  bool get _isEditing => widget.customer != null;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.customer?.name ?? '');
    _phone = TextEditingController(text: widget.customer?.phone ?? '');
    _email = TextEditingController(text: widget.customer?.email ?? '');
    _address = TextEditingController(text: widget.customer?.address ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _saveCustomer() async {
    if (_formKey.currentState!.validate()) {
      final customer = Customer(
        id: _isEditing ? widget.customer!.id : null,
        name: _name.text,
        phone: _phone.text,
        email: _email.text,
        address: _address.text,
      );
      if (_isEditing) {
        await _supabaseService.updateCustomer(customer);
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Data pelanggan berhasil diperbarui')));
      } else {
        await _supabaseService.insertCustomer(customer);
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Pelanggan baru berhasil ditambahkan')));
      }
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          AppBar(title: Text(_isEditing ? 'Edit Pelanggan' : 'Tambah Pelanggan')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Nama Pelanggan'),
                validator: (v) => v!.isEmpty ? 'Nama wajib diisi' : null),
            const SizedBox(height: 16),
            TextFormField(
                controller: _phone,
                decoration: const InputDecoration(labelText: 'Nomor Telepon'),
                keyboardType: TextInputType.phone),
            const SizedBox(height: 16),
            TextFormField(
                controller: _email,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 16),
            TextFormField(
                controller: _address,
                decoration: const InputDecoration(labelText: 'Alamat'),
                maxLines: 3),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: _saveCustomer,
          child: Text(_isEditing ? 'Simpan Perubahan' : 'Simpan Pelanggan'),
        ),
      ),
    );
  }
}

