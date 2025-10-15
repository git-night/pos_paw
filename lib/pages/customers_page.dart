import '../services/supabase_service.dart';
import '../models/customer.dart';
import 'add_edit_customer_page.dart';
import 'package:flutter/material.dart';

class CustomersPage extends StatefulWidget {
  const CustomersPage({super.key});
  @override
  State<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends State<CustomersPage> {
  final SupabaseService _supabaseService = SupabaseService();
  List<Customer> _customers = [];

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    final customerList = await _supabaseService.getCustomers();
    if (mounted) {
      setState(() => _customers = customerList);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manajemen Pelanggan')),
      body: RefreshIndicator(
        onRefresh: _loadCustomers,
        child: _customers.isEmpty
            ? const Center(child: Text('Belum ada data pelanggan.'))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _customers.length,
                itemBuilder: (context, index) {
                  final customer = _customers[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading:
                          const CircleAvatar(child: Icon(Icons.person_outline)),
                      title: Text(customer.name,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(customer.phone ?? 'No phone'),
                      trailing: PopupMenuButton(
                        itemBuilder: (context) => const [
                          PopupMenuItem(value: 'edit', child: Text('Edit')),
                        ],
                        onSelected: (value) async {
                          if (value == 'edit') {
                            await Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        AddEditCustomerPage(customer: customer)));
                            _loadCustomers();
                          }
                        },
                      ),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const AddEditCustomerPage()));
          _loadCustomers();
        },
        label: const Text('Tambah Pelanggan'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}

