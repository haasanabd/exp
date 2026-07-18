import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../data/models/app_models.dart';
import '../../data/repositories/app_repository.dart';

class CashBoxPage extends StatefulWidget {
  const CashBoxPage({super.key});

  @override
  State<CashBoxPage> createState() => _CashBoxPageState();
}

class _CashBoxPageState extends State<CashBoxPage> {
  List<Map<String, dynamic>> _records = [];
  bool _isLoading = true;
  DateTime _selectedDate = DateTime.now();
  DailyCashBoxSummary? _dailySummary;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final repo = context.read<AppRepository>();
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final records = await repo.getCashBoxRecords(date: dateStr);
    final summary = await repo.getDailyCashBoxSummary(dateStr);
    
    if (mounted) {
      setState(() {
        _records = records;
        _dailySummary = summary;
        _isLoading = false;
      });
    }
  }

  void _changeDate(int days) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: days));
    });
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الصندوق اليومي'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
              );
              if (picked != null && picked != _selectedDate) {
                setState(() => _selectedDate = picked);
                _loadData();
              }
            },
          )
        ],
      ),
      body: Column(
        children: [
          _buildDateNavigator(),
          _buildDailySummaryCard(),
          const Divider(height: 1),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _records.isEmpty
                    ? const Center(child: Text('لا توجد معاملات لهذا اليوم'))
                    : ListView.builder(
                        itemCount: _records.length,
                        itemBuilder: (context, index) {
                          final rec = _records[index];
                          final type = rec['type'];
                          final isIncoming = type == 'وارد';
                          final isExpense = type == 'مصروف';
                          
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            child: ListTile(
                              leading: Icon(
                                isIncoming ? Icons.add_circle : Icons.remove_circle,
                                color: isIncoming ? Colors.green : (isExpense ? Colors.orange : Colors.red),
                              ),
                              title: Text(rec['description'] ?? 'بدون وصف'),
                              subtitle: Text(rec['time']),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${rec['amount']}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isIncoming ? Colors.green : (isExpense ? Colors.orange : Colors.red),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  _buildActionButtons(rec),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              onPressed: () => _showVoucherDialog(isReceipt: true),
              icon: const Icon(Icons.download),
              label: const Text('سند قبض'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            ),
            ElevatedButton.icon(
              onPressed: () => _showVoucherDialog(isReceipt: false),
              icon: const Icon(Icons.upload),
              label: const Text('سند صرف'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateNavigator() {
    return Container(
      color: Colors.blue.shade50,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => _changeDate(-1)),
          Text(
            DateFormat('yyyy-MM-dd').format(_selectedDate),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => _changeDate(1)),
        ],
      ),
    );
  }

  Widget _buildDailySummaryCard() {
    if (_dailySummary == null && _records.isEmpty) return const SizedBox.shrink();
    
    final income = _dailySummary?.income ?? 0.0;
    final expense = _dailySummary?.expense ?? 0.0;
    final opening = _dailySummary?.openingBalance ?? 0.0;
    final closing = _dailySummary?.closingBalance ?? (opening + income - expense);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem('الرصيد الافتتاحي', opening, Colors.blueGrey),
              _buildSummaryItem('إجمالي الوارد', income, Colors.green),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem('إجمالي الصادر', expense, Colors.red),
              _buildSummaryItem('الرصيد الختامي', closing, Colors.blue, isBold: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, double value, Color color, {bool isBold = false}) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(
          value.toStringAsFixed(2),
          style: TextStyle(
            fontSize: 16,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(Map<String, dynamic> record) {
    final description = record['description'] as String? ?? "";
    
    // Determine if it's a voucher or expense from description
    if (description.startsWith('سند قبض رقم ')) {
      final id = int.tryParse(description.replaceFirst('سند قبض رقم ', ''));
      if (id != null) {
        return Row(
          children: [
            IconButton(
              icon: const Icon(Icons.edit, size: 20, color: Colors.blue),
              onPressed: () => _editVoucher(id, isReceipt: true),
            ),
            IconButton(
              icon: const Icon(Icons.delete, size: 20, color: Colors.red),
              onPressed: () => _confirmDeleteVoucher(id, isReceipt: true),
            ),
          ],
        );
      }
    } else if (description.startsWith('سند صرف رقم ')) {
      final id = int.tryParse(description.replaceFirst('سند صرف رقم ', ''));
      if (id != null) {
        return Row(
          children: [
            IconButton(
              icon: const Icon(Icons.edit, size: 20, color: Colors.blue),
              onPressed: () => _editVoucher(id, isReceipt: false),
            ),
            IconButton(
              icon: const Icon(Icons.delete, size: 20, color: Colors.red),
              onPressed: () => _confirmDeleteVoucher(id, isReceipt: false),
            ),
          ],
        );
      }
    }
    return const SizedBox.shrink();
  }

  Future<void> _editVoucher(int id, {required bool isReceipt}) async {
    final repo = context.read<AppRepository>();
    if (isReceipt) {
      final voucher = await repo.getReceiptVoucherById(id);
      if (voucher != null) _showVoucherDialog(isReceipt: true, voucher: voucher);
    } else {
      final voucher = await repo.getPaymentVoucherById(id);
      if (voucher != null) _showVoucherDialog(isReceipt: false, voucher: voucher);
    }
  }

  void _confirmDeleteVoucher(int id, {required bool isReceipt}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف ${isReceipt ? "سند القبض" : "سند الصرف"} رقم $id؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          TextButton(
            onPressed: () async {
              final repo = context.read<AppRepository>();
              if (isReceipt) {
                await repo.deleteReceiptVoucher(id);
              } else {
                await repo.deletePaymentVoucher(id);
              }
              if (mounted) {
                Navigator.pop(context);
                _loadData();
              }
            },
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showVoucherDialog({required bool isReceipt, dynamic voucher}) async {
    final repo = context.read<AppRepository>();
    final isEditing = voucher != null;
    
    List<dynamic> entities = [];
    if (isReceipt) {
      entities = await repo.getAllCustomers();
    } else {
      entities = await repo.getAllSuppliers();
    }
    
    if (!mounted) return;

    dynamic selectedEntity;
    if (isEditing) {
      final entityId = isReceipt ? (voucher as ReceiptVoucher).customerId : (voucher as PaymentVoucher).supplierId;
      selectedEntity = entities.firstWhere((e) => e.id == entityId, orElse: () => null);
    }

    final amountController = TextEditingController(text: isEditing ? voucher.amount.toString() : '');
    final descController = TextEditingController(text: isEditing ? voucher.description : '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? (isReceipt ? 'تعديل سند قبض' : 'تعديل سند صرف') : (isReceipt ? 'إنشاء سند قبض' : 'إنشاء سند صرف')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<dynamic>(
                value: selectedEntity,
                decoration: InputDecoration(labelText: isReceipt ? 'الزبون' : 'المورد'),
                items: entities.map((e) => DropdownMenuItem(value: e, child: Text('${e.name} (الرصيد: ${e.balance})'))).toList(),
                onChanged: (v) => selectedEntity = v,
              ),
              TextField(controller: amountController, decoration: const InputDecoration(labelText: 'المبلغ'), keyboardType: TextInputType.number),
              TextField(controller: descController, decoration: const InputDecoration(labelText: 'الوصف')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              if (selectedEntity == null) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isReceipt ? 'يرجى اختيار الزبون' : 'يرجى اختيار المورد')));
                return;
              }
              final amount = double.tryParse(amountController.text) ?? 0.0;
              if (amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى إدخال مبلغ صحيح')));
                return;
              }

              final now = DateTime.now();
              if (isReceipt) {
                final v = ReceiptVoucher(
                  id: isEditing ? voucher.id : null,
                  date: isEditing ? voucher.date : DateFormat('yyyy-MM-dd').format(now),
                  time: isEditing ? voucher.time : DateFormat('HH:mm:ss').format(now),
                  customerId: selectedEntity.id,
                  amount: amount,
                  description: descController.text,
                );
                isEditing ? await repo.updateReceiptVoucher(v) : await repo.createReceiptVoucher(v);
              } else {
                final v = PaymentVoucher(
                  id: isEditing ? voucher.id : null,
                  date: isEditing ? voucher.date : DateFormat('yyyy-MM-dd').format(now),
                  time: isEditing ? voucher.time : DateFormat('HH:mm:ss').format(now),
                  supplierId: selectedEntity.id,
                  amount: amount,
                  description: descController.text,
                );
                isEditing ? await repo.updatePaymentVoucher(v) : await repo.createPaymentVoucher(v);
              }

              if (mounted) {
                Navigator.pop(context);
                _loadData();
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }
}
