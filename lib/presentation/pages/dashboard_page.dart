import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/repositories/app_repository.dart';
import 'customers_page.dart';
import 'suppliers_page.dart';
import 'inventory_page.dart';
import 'sales_page.dart';
import 'purchases_page.dart';
import 'production_page.dart';
import 'cashbox_page.dart';
import 'expenses_page.dart';
import 'reports_page.dart';
import 'settings_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  Map<String, dynamic>? _stats;
  bool _isLoading = true;
  String _shopName = 'Haa 3D Management';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final repo = context.read<AppRepository>();
    final stats = await repo.getDashboardData();
    final shopName = await repo.getSetting('shop_name');
    if (mounted) {
      setState(() {
        _stats = stats;
        _shopName = shopName ?? 'Haa 3D Management';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_shopName),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('نظرة عامة'),
                    const SizedBox(height: 16),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.5,
                      children: [
                        _buildStatCard('رصيد القاصة', '${_stats?['cash_balance'] ?? 0}', Colors.green, Icons.account_balance_wallet),
                        _buildStatCard('عدد المنتجات', '${_stats?['products_count'] ?? 0}', Colors.blue, Icons.precision_manufacturing),
                        _buildStatCard('المواد الخام', '${_stats?['materials_count'] ?? 0}', Colors.orange, Icons.category),
                        _buildStatCard('عدد الزبائن', '${_stats?['customers_count'] ?? 0}', Colors.purple, Icons.people),
                        _buildStatCard('عدد الموردين', '${_stats?['suppliers_count'] ?? 0}', Colors.teal, Icons.local_shipping),
                        _buildStatCard('إجمالي المبيعات', '${_stats?['sales_total'] ?? 0}', Colors.indigo, Icons.sell),
                        _buildStatCard('إجمالي المشتريات', '${_stats?['purchases_total'] ?? 0}', Colors.red, Icons.shopping_cart),
                        _buildStatCard('إجمالي الأرباح', '${_stats?['profit_total'] ?? 0}', Colors.amber, Icons.trending_up),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSectionTitle('الوصول السريع'),
                    const SizedBox(height: 16),
                    _buildQuickActions(context),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
              Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      {'title': 'فاتورة مبيعات', 'icon': Icons.add_shopping_cart, 'color': Colors.blue, 'page': const SalesPage()},
      {'title': 'فاتورة مشتريات', 'icon': Icons.add_business, 'color': Colors.orange, 'page': const PurchasesPage()},
      {'title': 'عملية إنتاج', 'icon': Icons.settings_suggest, 'color': Colors.green, 'page': const ProductionPage()},
      {'title': 'سند قبض', 'icon': Icons.money, 'color': Colors.teal, 'page': const CashBoxPage()},
    ];

    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: actions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final action = actions[index];
          return InkWell(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => action['page'] as Widget)).then((_) => _loadData()),
            child: Container(
              width: 100,
              decoration: BoxDecoration(
                color: (action['color'] as Color).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: (action['color'] as Color).withOpacity(0.3)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(action['icon'] as IconData, color: action['color'] as Color, size: 32),
                  const SizedBox(height: 8),
                  Text(action['title'] as String, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.blueAccent, Colors.blue],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const CircleAvatar(backgroundColor: Colors.white, radius: 30, child: Icon(Icons.print, color: Colors.blueAccent, size: 35)),
                const SizedBox(height: 10),
                Text(_shopName, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const Text('v1.0 - Offline Mode', style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          _buildDrawerItem(Icons.dashboard, 'الرئيسية', () => Navigator.pop(context)),
          _buildDrawerItem(Icons.people, 'الزبائن', () => _navigateTo(context, const CustomersPage())),
          _buildDrawerItem(Icons.local_shipping, 'الموردين', () => _navigateTo(context, const SuppliersPage())),
          _buildDrawerItem(Icons.inventory, 'المخزن', () => _navigateTo(context, const InventoryPage())),
          _buildDrawerItem(Icons.sell, 'المبيعات', () => _navigateTo(context, const SalesPage())),
          _buildDrawerItem(Icons.shopping_cart, 'المشتريات', () => _navigateTo(context, const PurchasesPage())),
          _buildDrawerItem(Icons.precision_manufacturing, 'الإنتاج', () => _navigateTo(context, const ProductionPage())),
          _buildDrawerItem(Icons.account_balance_wallet, 'القاصة', () => _navigateTo(context, const CashBoxPage())),
          _buildDrawerItem(Icons.money_off, 'المصروفات', () => _navigateTo(context, const ExpensesPage())),
          const Divider(),
          _buildDrawerItem(Icons.assessment, 'التقارير', () => _navigateTo(context, const ReportsPage())),
          _buildDrawerItem(Icons.settings, 'الإعدادات', () => _navigateTo(context, const SettingsPage())),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: onTap,
    );
  }

  void _navigateTo(BuildContext context, Widget page) {
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (_) => page)).then((_) => _loadData());
  }
}
