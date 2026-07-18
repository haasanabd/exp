import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/app_models.dart';
import '../../data/repositories/app_repository.dart';
import '../../data/datasources/database_helper.dart';

class CustomersPage extends StatefulWidget {
  const CustomersPage({super.key});

  @override
  State<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends State<CustomersPage> {
  List<Customer> _customers = [];
  List<Customer> _filteredCustomers = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCustomers();
    _searchController.addListener(_filterCustomers);
  }

  Future<void> _loadCustomers() async {
    final repo = context.read<AppRepository>();
    final customers = await repo.getAllCustomers();
    if (mounted) {
      setState(() {
        _customers = customers;
        _filteredCustomers = customers;
        _isLoading = false;
      });
    }
  }

  void _filterCustomers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredCustomers = _customers.where((c) => c.name.toLowerCase().contains(query) || (c.phone?.contains(query) ?? false)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إدارة الزبائن')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'بحث عن زبون...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredCustomers.isEmpty
                    ? const Center(child: Text('لا يوجد زبائن حالياً'))
                    : ListView.builder(
                        itemCount: _filteredCustomers.length,
                        itemBuilder: (context, index) {
                          final customer = _filteredCustomers[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            child: ListTile(
                              leading: const CircleAvatar(child: Icon(Icons.person)),
                              title: Text(customer.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(customer.phone ?? 'بدون هاتف'),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text('الرصيد', style: TextStyle(fontSize: 10)),
                                  Text(
                                    '${customer.balance}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: customer.balance > 0 ? Colors.red : (customer.balance < 0 ? Colors.green : Colors.black),
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () => _showCustomerDetails(customer),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddCustomerDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddCustomerDialog({Customer? customer}) {
    final nameController = TextEditingController(text: customer?.name);
    final phoneController = TextEditingController(text: customer?.phone);
    final addressController = TextEditingController(text: customer?.address);
    final notesController = TextEditingController(text: customer?.notes);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(customer == null ? 'إضافة زبون جديد' : 'تعديل بيانات الزبون'),
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
              final newCustomer = Customer(
                id: customer?.id,
                name: nameController.text,
                phone: phoneController.text,
                address: addressController.text,
                balance: customer?.balance ?? 0.0,
                notes: notesController.text,
              );
              if (customer == null) {
                await context.read<AppRepository>().addCustomer(newCustomer);
              } else {
                await context.read<AppRepository>().updateCustomer(newCustomer);
              }
              Navigator.pop(context);
              _loadCustomers();
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _showCustomerDetails(Customer customer) async {
    final db = await DatabaseHelper.instance.database;
    // Load invoices and vouchers for this customer
    final invoices = await db.query('SalesInvoices', where: 'customer_id = ?', whereArgs: [customer.id], orderBy: 'date DESC, time DESC');
    final vouchers = await db.query('ReceiptVouchers', where: 'customer_id = ?', whereArgs: [customer.id], orderBy: 'date DESC, time DESC');

    List<Map<String, dynamic>> statement = [];
    for (var inv in invoices) {
      statement.add({
        'date': inv['date'],
        'time': inv['time'],
        'type': 'فاتورة مبيعات (${inv['sale_type']})',
        'amount': inv['total_amount'],
        'is_debit': true, // Customer owes us
      });
    }
    for (var v in vouchers) {
      statement.add({
        'date': v['date'],
        'time': v['time'],
        'type': 'سند قبض',
        'amount': v['amount'],
        'is_debit': false, // Customer paid us
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
              color: Colors.blueAccent.withOpacity(0.1),
              child: Column(
                children: [
                  Row(
                    children: [
                      const CircleAvatar(radius: 30, child: Icon(Icons.person, size: 40)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(customer.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            Text(customer.phone ?? 'بدون هاتف'),
                          ],
                        ),
                      ),
                      IconButton(icon: const Icon(Icons.edit), onPressed: () {
                        Navigator.pop(context);
                        _showAddCustomerDialog(customer: customer);
                      }),
                    ],
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('الرصيد الحالي:', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('${customer.balance}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: customer.balance > 0 ? Colors.red : Colors.green)),
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
