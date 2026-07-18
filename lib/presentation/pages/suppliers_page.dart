import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/app_models.dart';
import '../../data/repositories/app_repository.dart';
import '../../data/datasources/database_helper.dart';

class SuppliersPage extends StatefulWidget {
  const SuppliersPage({super.key});

  @override
  State<SuppliersPage> createState() => _SuppliersPageState();
}

class _SuppliersPageState extends State<SuppliersPage> {
  List<Supplier> _suppliers = [];
  List<Supplier> _filteredSuppliers = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSuppliers();
    _searchController.addListener(_filterSuppliers);
  }

  Future<void> _loadSuppliers() async {
    final repo = context.read<AppRepository>();
    final suppliers = await repo.getAllSuppliers();
    if (mounted) {
      setState(() {
        _suppliers = suppliers;
        _filteredSuppliers = suppliers;
        _isLoading = false;
      });
    }
  }

  void _filterSuppliers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredSuppliers = _suppliers.where((s) => s.name.toLowerCase().contains(query) || (s.phone?.contains(query) ?? false)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إدارة الموردين')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'بحث عن مورد...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredSuppliers.isEmpty
                    ? const Center(child: Text('لا يوجد موردين حالياً'))
                    : ListView.builder(
                        itemCount: _filteredSuppliers.length,
                        itemBuilder: (context, index) {
                          final supplier = _filteredSuppliers[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            child: ListTile(
                              leading: const CircleAvatar(backgroundColor: Colors.teal, child: Icon(Icons.local_shipping, color: Colors.white)),
                              title: Text(supplier.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(supplier.phone ?? 'بدون هاتف'),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text('الرصيد', style: TextStyle(fontSize: 10)),
                                  Text(
                                    '${supplier.balance}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: supplier.balance > 0 ? Colors.red : (supplier.balance < 0 ? Colors.green : Colors.black),
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () => _showSupplierDetails(supplier),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSupplierDialog(),
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showAddSupplierDialog({Supplier? supplier}) {
    final nameController = TextEditingController(text: supplier?.name);
    final phoneController = TextEditingController(text: supplier?.phone);
    final addressController = TextEditingController(text: supplier?.address);
    final notesController = TextEditingController(text: supplier?.notes);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(supplier == null ? 'إضافة مورد جديد' : 'تعديل بيانات المورد'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'الاسم *')),
              TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'الهاتف'), keyboardType: TextInputType.phone),
              TextField(controller: addressController, decoration: const InputDecoration(labelText: 'العنوان')),
              TextField(controller: notesController, decoration: const InputDecoration(labelText: 'ملاحظات')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty) return;
              final newSupplier = Supplier(
                id: supplier?.id,
                name: nameController.text,
                phone: phoneController.text,
                address: addressController.text,
                balance: supplier?.balance ?? 0.0,
                notes: notesController.text,
              );
              if (supplier == null) {
                await context.read<AppRepository>().addSupplier(newSupplier);
              } else {
                await context.read<AppRepository>().updateSupplier(newSupplier);
              }
              Navigator.pop(context);
              _loadSuppliers();
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _showSupplierDetails(Supplier supplier) async {
    final db = await DatabaseHelper.instance.database;
    // Load invoices and vouchers for this supplier
    final invoices = await db.query('PurchaseInvoices', where: 'supplier_id = ?', whereArgs: [supplier.id], orderBy: 'date DESC, time DESC');
    final vouchers = await db.query('PaymentVouchers', where: 'supplier_id = ?', whereArgs: [supplier.id], orderBy: 'date DESC, time DESC');

    List<Map<String, dynamic>> statement = [];
    for (var inv in invoices) {
      statement.add({
        'date': inv['date'],
        'time': inv['time'],
        'type': 'فاتورة مشتريات (${inv['purchase_type']})',
        'amount': inv['total_amount'],
        'is_debit': true, // We owe supplier
      });
    }
    for (var v in vouchers) {
      statement.add({
        'date': v['date'],
        'time': v['time'],
        'type': 'سند صرف',
        'amount': v['amount'],
        'is_debit': false, // We paid supplier
      });
    }
    statement.sort((a, b) => (b['date'] + b['time']).compareTo(a['date'] + a['time']));

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.teal.withOpacity(0.1),
              child: Column(
                children: [
                  Row(
                    children: [
                      const CircleAvatar(radius: 30, backgroundColor: Colors.teal, child: Icon(Icons.local_shipping, size: 40, color: Colors.white)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(supplier.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            Text(supplier.phone ?? 'بدون هاتف'),
                          ],
                        ),
                      ),
                      IconButton(icon: const Icon(Icons.edit), onPressed: () {
                        Navigator.pop(context);
                        _showAddSupplierDialog(supplier: supplier);
                      }),
                    ],
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('الرصيد الحالي:', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('${supplier.balance}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: supplier.balance > 0 ? Colors.red : Colors.green)),
                    ],
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('كشف الحساب', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: statement.isEmpty
                  ? const Center(child: Text('لا توجد حركات مالية مسجلة'))
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: statement.length,
                      itemBuilder: (context, index) {
                        final item = statement[index];
                        final isDebit = item['is_debit'];
                        return ListTile(
                          leading: Icon(isDebit ? Icons.arrow_upward : Icons.arrow_downward, color: isDebit ? Colors.red : Colors.green),
                          title: Text(item['type']),
                          subtitle: Text('${item['date']} ${item['time']}'),
                          trailing: Text('${item['amount']}', style: TextStyle(fontWeight: FontWeight.bold, color: isDebit ? Colors.red : Colors.green)),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
