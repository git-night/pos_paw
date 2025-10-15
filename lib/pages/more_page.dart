import '../utils/constants.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'categories_page.dart';
import 'customers_page.dart';
import 'login_page.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'purchases_page.dart';
import 'reports_page.dart';
import 'returns_page.dart';

class MorePage extends StatelessWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // User Profile Section
          if (authService.isLoggedIn) ...[
            Card(
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide.none,
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: AppColors.accent.withOpacity(0.1),
                      child: const Icon(
                        Icons.person,
                        size: 32,
                        color: AppColors.accent,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            authService.userFullName ?? 'User',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.foreground,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            authService.userEmail ?? '',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppColors.foregroundMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          Padding(
            padding: const EdgeInsets.only(left: 8.0, bottom: 8.0, top: 8.0),
            child: Text(
              "MANAJEMEN TOKO",
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.bold,
                color: pawTextColor.withOpacity(0.7),
                letterSpacing: 1.2,
              ),
            ),
          ),
          Card(
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide.none,
            ),
            child: Column(
              children: [
                _buildMorePageTile(
                  context,
                  icon: Icons.bar_chart_rounded,
                  title: 'Laporan',
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const ReportsPage()));
                  },
                ),
                const Divider(
                    height: 1, indent: 16, endIndent: 16, color: pawBorderColor),
                _buildMorePageTile(
                  context,
                  icon: Icons.people_alt_rounded,
                  title: 'Pelanggan',
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const CustomersPage()));
                  },
                ),
                const Divider(
                    height: 1, indent: 16, endIndent: 16, color: pawBorderColor),
                _buildMorePageTile(
                  context,
                  icon: Icons.category_rounded,
                  title: 'Kategori',
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const CategoriesPage()));
                  },
                ),
                const Divider(
                    height: 1, indent: 16, endIndent: 16, color: pawBorderColor),
                _buildMorePageTile(
                  context,
                  icon: Icons.shopping_basket_rounded,
                  title: 'Pembelian',
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const PurchasesPage()));
                  },
                ),
                const Divider(
                    height: 1, indent: 16, endIndent: 16, color: pawBorderColor),
                _buildMorePageTile(
                  context,
                  icon: Icons.undo_rounded,
                  title: 'Retur',
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const ReturnsPage()));
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Padding(
            padding: const EdgeInsets.only(left: 8.0, bottom: 8.0, top: 8.0),
            child: Text(
              "AKUN",
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.bold,
                color: pawTextColor.withOpacity(0.7),
                letterSpacing: 1.2,
              ),
            ),
          ),
          Card(
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide.none,
            ),
            child: Column(
              children: [
                _buildMorePageTile(
                  context,
                  icon: Icons.logout_rounded,
                  title: 'Keluar',
                  onTap: () => _handleLogout(context),
                  color: AppColors.destructive,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Konfirmasi Keluar',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        content: Text(
          'Apakah Anda yakin ingin keluar dari aplikasi?',
          style: GoogleFonts.inter(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Batal',
              style: GoogleFonts.inter(color: AppColors.foregroundMuted),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.destructive,
            ),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final authService = AuthService();
        await authService.signOut();

        if (context.mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginPage()),
            (route) => false,
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Gagal keluar. Silakan coba lagi',
                style: GoogleFonts.inter(),
              ),
              backgroundColor: AppColors.destructive,
            ),
          );
        }
      }
    }
  }

  Widget _buildMorePageTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    final itemColor = color ?? pawTextColor.withOpacity(0.8);
    return ListTile(
      leading: Icon(icon, color: itemColor),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: color ?? Colors.grey.shade400,
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }
}

