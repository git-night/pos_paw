import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../models/customer.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../models/discount.dart';
import '../models/sale.dart';
import '../models/sale_item.dart';
import '../models/purchase.dart';
import '../models/purchase_item.dart';
import '../models/user.dart' as app_user;

final supabase = Supabase.instance.client;

class SupabaseService {
  // Helper to get current user ID
  String? get _currentUserId => supabase.auth.currentUser?.id;
  Future<List<Customer>> getCustomers() async {
    final data =
        await supabase.from('customers').select().order('name', ascending: true);
    return data.map((e) => Customer.fromMap(e)).toList();
  }

  Future<void> insertCustomer(Customer customer) async {
    final data = customer.toMap()..remove('id');
    if (_currentUserId != null) {
      data['created_by'] = _currentUserId;
    }
    await supabase.from('customers').insert(data);
  }

  Future<void> updateCustomer(Customer customer) async {
    final data = customer.toMap();
    if (_currentUserId != null) {
      data['edited_by'] = _currentUserId;
    }
    await supabase
        .from('customers')
        .update(data)
        .eq('id', customer.id!);
  }

  Future<void> deleteCustomer(int id) async {
    await supabase.from('customers').delete().eq('id', id);
  }

  Future<List<Category>> getCategories() async {
    final data =
        await supabase.from('categories').select().order('name', ascending: true);
    return data.map((e) => Category.fromMap(e)).toList();
  }

  Future<void> insertCategory(Category category) async {
    final data = category.toMap()..remove('id');
    if (_currentUserId != null) {
      data['created_by'] = _currentUserId;
    }
    await supabase.from('categories').insert(data);
  }

  Future<void> deleteCategory(int id) async {
    await supabase.from('categories').delete().eq('id', id);
  }

  Future<List<Product>> getProducts() async {
    final data = await supabase.from('products').select();
    return data.map((e) => Product.fromMap(e)).toList();
  }

  Future<Product?> getProductById(int id) async {
    try {
      final data = await supabase.from('products').select().eq('id', id).single();
      return Product.fromMap(data);
    } catch (e) {
      return null;
    }
  }

  Future<void> insertProduct(Product product) async {
    final data = product.toMap()..remove('id');
    if (_currentUserId != null) {
      data['created_by'] = _currentUserId;
    }
    await supabase.from('products').insert(data);
  }

  Future<void> updateProduct(Product product) async {
    final data = product.toMap();
    if (_currentUserId != null) {
      data['edited_by'] = _currentUserId;
    }
    await supabase
        .from('products')
        .update(data)
        .eq('id', product.id!);
  }

  Future<void> deleteProduct(int id) async {
    await supabase.from('products').delete().eq('id', id);
  }

  Future<List<Sale>> getSales({DateTime? start, DateTime? end}) async {
    // Build base query without join first
    var query = supabase.from('sales').select();
    if (start != null && end != null) {
      query = query
          .gte('sale_date', start.toIso8601String())
          .lte('sale_date', end.toIso8601String());
    }
    final data = await query.order('id', ascending: false);

    // Fetch all sales first
    final sales = data.map((e) => Sale.fromMap(e)).toList();

    // Then fetch user names for each sale with created_by
    for (var sale in sales) {
      if (sale.createdBy != null) {
        try {
          final userData = await supabase
              .from('users')
              .select('full_name')
              .eq('id', sale.createdBy!)
              .maybeSingle();

          if (userData != null) {
            sale.cashierName = userData['full_name'] as String?;
          }
        } catch (e) {
          // If users table doesn't exist or error, just skip
          print('Could not fetch user name for sale ${sale.id}: $e');
        }
      }
    }

    return sales;
  }

  Future<List<SaleItem>> getSaleItems(int saleId) async {
    final data = await supabase.from('sale_items').select().eq('sale_id', saleId);
    return data.map((e) => SaleItem.fromMap(e)).toList();
  }

  Future<void> deleteSale(int id) async {
    await supabase.from('sales').delete().eq('id', id);
  }

  Future<List<Purchase>> getPurchases() async {
    final data =
        await supabase.from('purchases').select().order('id', ascending: false);

    // Fetch all purchases first
    final purchases = data.map((e) => Purchase.fromMap(e)).toList();

    // Then fetch user names for each purchase with created_by
    for (var purchase in purchases) {
      if (purchase.createdBy != null) {
        try {
          final userData = await supabase
              .from('users')
              .select('full_name')
              .eq('id', purchase.createdBy!)
              .maybeSingle();

          if (userData != null) {
            purchase.cashierName = userData['full_name'] as String?;
          }
        } catch (e) {
          // If users table doesn't exist or error, just skip
          print('Could not fetch user name for purchase ${purchase.id}: $e');
        }
      }
    }

    return purchases;
  }

  Future<List<PurchaseItem>> getPurchaseItems(int purchaseId) async {
    final data =
        await supabase.from('purchase_items').select().eq('purchase_id', purchaseId);
    return data.map((e) => PurchaseItem.fromMap(e)).toList();
  }

  // ========= DISCOUNTS =========
  Future<List<Discount>> getDiscounts() async {
    final data = await supabase
        .from('discounts')
        .select()
        .order('created_at', ascending: false);
    return data.map((e) => Discount.fromMap(e)).toList();
  }

  Future<void> insertDiscount(Discount discount) async {
    final payload = discount.toMap();
    payload.remove('id');
    if (_currentUserId != null) payload['created_by'] = _currentUserId;
    await supabase.from('discounts').insert(payload);
  }

  Future<void> updateDiscount(Discount discount) async {
    final payload = discount.toMap();
    if (_currentUserId != null) payload['edited_by'] = _currentUserId;
    await supabase.from('discounts').update(payload).eq('id', discount.id!);
  }

  Future<void> deleteDiscount(int id) async {
    await supabase.from('discounts').delete().eq('id', id);
  }

  /// Get active discounts that apply to a specific customer
  Future<List<Discount>> getActiveDiscountsForCustomer(int customerId) async {
    final now = DateTime.now().toIso8601String();
    final data = await supabase
        .from('discounts')
        .select()
        .eq('is_active', true)
        .eq('target_type', 'customer')
        .eq('target_customer_id', customerId)
        .or('start_at.is.null,start_at.lte.$now')
        .or('end_at.is.null,end_at.gte.$now');

    return data.map((e) => Discount.fromMap(e)).toList();
  }

  Future<List<Discount>> getActiveDiscountsForProduct(int productId) async {
    final now = DateTime.now().toIso8601String();
    final data = await supabase
        .from('discounts')
        .select()
        .eq('is_active', true)
        .eq('target_type', 'product')
        .eq('target_product_id', productId)
        .or('start_at.is.null,start_at.lte.$now')
        .or('end_at.is.null,end_at.gte.$now');

    return data.map((e) => Discount.fromMap(e)).toList();
  }

  Future<void> processSale(Sale sale) async {
    final itemsAsJson = sale.items
        .map((item) => {
              'product_id': item.productId,
              'product_name': item.productName,
              'quantity': item.quantity,
              'unit_price': item.unitPrice,
              'total_price': item.totalPrice,
              'discount': item.discount,
              'discount_reason': item.discountReason,
            })
        .toList();

    final params = {
      'p_invoice_number': sale.invoiceNumber,
      'p_total_amount': sale.totalAmount,
      'p_final_amount': sale.finalAmount,
      'p_customer_id': sale.customerId,
      'p_customer_name': sale.customerName,
      'p_sale_items': itemsAsJson,
    };

    if (_currentUserId != null) {
      params['p_created_by'] = _currentUserId;
    }

    await supabase.rpc('process_new_sale', params: params);
  }

  Future<void> processPurchase(
      Purchase purchase, List<PurchaseItem> items) async {
    final itemsAsJson = items
        .map((item) => {
              'product_id': item.productId,
              'product_name': item.productName,
              'quantity': item.quantity,
              'unit_price': item.unitPrice,
              'total_price': item.totalPrice,
            })
        .toList();

    final params = {
      'p_invoice_number': purchase.invoiceNumber,
      'p_total_amount': purchase.totalAmount,
      'p_supplier': purchase.supplier,
      'p_purchase_items': itemsAsJson,
    };

    if (_currentUserId != null) {
      params['p_created_by'] = _currentUserId;
    }

    await supabase.rpc('process_new_purchase', params: params);
  }

  Future<void> processPartialReturn(Map<SaleItem, int> itemsToReturn) async {
    final itemsAsJson = itemsToReturn.entries
        .map((entry) => {
              'sale_item_id': entry.key.id,
              'product_id': entry.key.productId,
              'quantity': entry.value,
            })
        .toList();

    await supabase.rpc('process_partial_return', params: {
      'p_items_to_return': itemsAsJson,
    });
  }

  Future<List<Map<String, dynamic>>> getDailySales(
      {DateTime? start, DateTime? end}) async {
    final sales = await getSales(start: start, end: end);
    Map<String, int> dailyProductCounts = {};

    for (var sale in sales) {
      final dateKey = DateFormat('yyyy-MM-dd').format(sale.saleDate);
      final items = await getSaleItems(sale.id!);
      int totalProducts = 0;
      for (var item in items) {
        totalProducts += (item.quantity - item.returnedQuantity);
      }

      dailyProductCounts[dateKey] = (dailyProductCounts[dateKey] ?? 0) + totalProducts;
    }

    var sortedEntries = dailyProductCounts.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    var last7Days = sortedEntries.length > 7
        ? sortedEntries.sublist(sortedEntries.length - 7)
        : sortedEntries;

    return last7Days
        .map((e) => {'date': e.key, 'total': e.value.toDouble()})
        .toList();
  }

  Future<Map<String, double>> getSalesStatsForMonth(DateTime month) async {
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

    final salesInMonth = await getSales(start: firstDay, end: lastDay);
    final allProducts = await getProducts();

    double totalOmset = 0;
    double totalProfit = 0;
    int totalTransaksi = salesInMonth.length;

    for (var sale in salesInMonth) {
      final items = await getSaleItems(sale.id!);

      for (var item in items) {
        final product = allProducts.firstWhere(
            (p) => p.id == item.productId,
            orElse: () => Product(
                name: '',
                code: '',
                purchasePrice: 0,
                sellingPrice: 0,
                stock: 0,
                stockAlert: 5,
                category: '',
                createdAt: DateTime.now()));

        int netQuantity = item.quantity - item.returnedQuantity;

        if (netQuantity > 0) {
          double sellingPricePerUnit = item.finalPrice / item.quantity;
          double profitPerUnit = sellingPricePerUnit - product.purchasePrice;
          totalProfit += profitPerUnit * netQuantity;
        }
      }

      totalOmset += sale.finalAmount;
    }

    return {
      'omset': totalOmset,
      'profit': totalProfit,
      'transactions': totalTransaksi.toDouble(),
    };
  }

  Future<List<Map<String, dynamic>>> getTopCategories(int limit) async {
    final data = await supabase
        .rpc('get_top_categories', params: {'limit_count': limit});
    return (data as List).map((item) => item as Map<String, dynamic>).toList();
  }

  Future<List<Map<String, dynamic>>> getTopCustomers(int limit) async {
    final data =
        await supabase.rpc('get_top_customers', params: {'limit_count': limit});
    return (data as List).map((item) => item as Map<String, dynamic>).toList();
  }


  Future<app_user.User?> getCurrentUser() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final data = await supabase
          .from('users')
          .select()
          .eq('id', userId)
          .single();

      return app_user.User.fromMap(data);
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }


  Future<List<app_user.User>> getActiveUsers() async {
    try {
      final data = await supabase
          .from('users')
          .select()
          .eq('is_active', true)
          .order('full_name', ascending: true);

      return data.map((e) => app_user.User.fromMap(e)).toList();
    } catch (e) {
      print('Error getting active users: $e');
      return [];
    }
  }

  Future<List<app_user.User>> getAllUsers() async {
    try {
      final data = await supabase
          .from('users')
          .select()
          .order('is_active', ascending: false)
          .order('full_name', ascending: true);

      return data.map((e) => app_user.User.fromMap(e)).toList();
    } catch (e) {
      print('Error getting all users: $e');
      return [];
    }
  }

  Future<app_user.User?> getUserById(String id) async {
    try {
      final data = await supabase
          .from('users')
          .select()
          .eq('id', id)
          .single();

      return app_user.User.fromMap(data);
    } catch (e) {
      print('Error getting user by ID: $e');
      return null;
    }
  }

  Future<void> upsertUser(app_user.User user) async {
    try {
      final data = user.toMap();
    
      data.remove('created_at');
      data.remove('last_login');
      
      if (_currentUserId != null) {
        data['created_by'] = _currentUserId;
      }

      await supabase.from('users').upsert(data);
    } catch (e) {
      print('Error upserting user: $e');
      rethrow;
    }
  }

  Future<void> updateUserProfile({
    required String userId,
    String? fullName,
    String? phone,
    String? address,
    String? avatarUrl,
  }) async {
    try {
      final updates = <String, dynamic>{};
      
      if (fullName != null) updates['full_name'] = fullName;
      if (phone != null) updates['phone'] = phone;
      if (address != null) updates['address'] = address;
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
      
      if (updates.isNotEmpty) {
        updates['updated_at'] = DateTime.now().toIso8601String();
        
        await supabase
            .from('users')
            .update(updates)
            .eq('id', userId);
      }
    } catch (e) {
      print('Error updating user profile: $e');
      rethrow;
    }
  }

  Future<void> updateUserRole(String userId, String role) async {
    try {
      await supabase
          .from('users')
          .update({
            'role': role,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);
    } catch (e) {
      print('Error updating user role: $e');
      rethrow;
    }
  }

  Future<void> setUserActiveStatus(String userId, bool isActive) async {
    try {
      await supabase
          .from('users')
          .update({
            'is_active': isActive,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);
    } catch (e) {
      print('Error updating user active status: $e');
      rethrow;
    }
  }

  Future<bool> isCurrentUserAdmin() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return false;

      final result = await supabase
          .rpc('is_admin', params: {'user_id': userId});
      
      return result as bool;
    } catch (e) {
      print('Error checking admin status: $e');
      return false;
    }
  }

  Future<bool> isCurrentUserManagerOrAbove() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return false;

      final result = await supabase
          .rpc('is_manager_or_above', params: {'user_id': userId});
      
      return result as bool;
    } catch (e) {
      print('Error checking manager status: $e');
      return false;
    }
  }

  Future<List<app_user.User>> getUsersByRole(String role) async {
    try {
      final data = await supabase
          .from('users')
          .select()
          .eq('role', role)
          .eq('is_active', true)
          .order('full_name', ascending: true);

      return data.map((e) => app_user.User.fromMap(e)).toList();
    } catch (e) {
      print('Error getting users by role: $e');
      return [];
    }
  }

  Future<List<app_user.User>> searchUsers(String query) async {
    try {
      final data = await supabase
          .from('users')
          .select()
          .or('email.ilike.%$query%,full_name.ilike.%$query%,employee_id.ilike.%$query%')
          .eq('is_active', true)
          .order('full_name', ascending: true);

      return data.map((e) => app_user.User.fromMap(e)).toList();
    } catch (e) {
      print('Error searching users: $e');
      return [];
    }
  }
}
