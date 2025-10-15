import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/discount.dart';
import '../services/supabase_service.dart';
import 'add_edit_discount_page.dart';

class DiscountsPage extends StatefulWidget {
  const DiscountsPage({super.key});

  @override
  State<DiscountsPage> createState() => _DiscountsPageState();
}

class _DiscountsPageState extends State<DiscountsPage> {
  final SupabaseService _service = SupabaseService();
  List<Discount> _discounts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final items = await _service.getDiscounts();
      if (!mounted) return;
      setState(() {
        _discounts = items;
      });
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().contains('PGRST205')
          ? 'Tabel discounts belum tersedia. Jalankan SQL di docs/sql/discounts.sql pada Supabase.'
          : 'Gagal memuat diskon: $e';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  void _confirmDelete(Discount d) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text('Yakin ingin menghapus diskon "${d.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          TextButton(
            onPressed: () async {
              await _service.deleteDiscount(d.id!);
              if (mounted) Navigator.pop(context);
              _load();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Diskon berhasil dihapus')),
                );
              }
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manajemen Diskon')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _discounts.isEmpty
                  ? const Center(child: Text('Belum ada data diskon.'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _discounts.length,
                      itemBuilder: (context, index) {
                        final d = _discounts[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: d.isTimeActive ? Colors.green.shade50 : Colors.grey.shade200,
                              child: Icon(Icons.sell_outlined,
                                  color: d.isTimeActive ? Colors.green.shade800 : Colors.grey.shade600),
                            ),
                            title: Text(d.name, style: GoogleFonts.montserrat(fontWeight: FontWeight.w600)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text('${d.targetType == 'product' ? 'Produk' : 'Pelanggan'} • ${d.targetLabel}'),
                                Text('Tipe: ${d.valueType == 'percentage' ? 'Persentase' : 'Nominal'} • Nilai: ${d.valueLabel}'),
                                if (d.startAt != null || d.endAt != null)
                                  Text(
                                    'Periode: '
                                    '${d.startAt != null ? _fmtDate(d.startAt!) : 'Tanpa awal'} - '
                                    '${d.endAt != null ? _fmtDate(d.endAt!) : 'Tanpa akhir'}',
                                    style: TextStyle(color: Colors.grey.shade700),
                                  ),
                              ],
                            ),
                            trailing: PopupMenuButton<String>(
                              onSelected: (v) async {
                                if (v == 'edit') {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => AddEditDiscountPage(discount: d),
                                    ),
                                  );
                                  _load();
                                } else if (v == 'delete') {
                                  _confirmDelete(d);
                                }
                              },
                              itemBuilder: (context) => const [
                                PopupMenuItem(value: 'edit', child: Text('Edit')),
                                PopupMenuItem(value: 'delete', child: Text('Hapus', style: TextStyle(color: Colors.red))),
                              ],
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
            MaterialPageRoute(builder: (_) => const AddEditDiscountPage()),
          );
          _load();
        },
        label: const Text('Tambah Diskon'),
        icon: const Icon(Icons.add),
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