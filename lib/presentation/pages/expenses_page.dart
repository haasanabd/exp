import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../data/models/app_models.dart';
import '../../data/repositories/app_repository.dart';
import '../../data/datasources/database_helper.dart';

class ExpensesPage extends StatefulWidget {
  const ExpensesPage({super.key});

  @override
  State<ExpensesPage> createState() => _ExpensesPageState();
}

class _ExpensesPageState extends State<ExpensesPage> {
  List<Map<String, dynamic>> _expenses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    final db = await DatabaseHelper.instance.database;
    final expenses = await db.query('Expenses', orderBy: 'date DESC, time DESC');
    if (mounted) {
      setState(() {
        _expenses = expenses;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('المصاريف اليومية')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _expenses.isEmpty
              ? const Center(child: Text('لا توجد مصاريف مسجلة'))
              : ListView.builder(
                  itemCount: _expenses.length,
                  itemBuilder: (context, index) {
                    final expMap = _expenses[index];
                    final exp = Expense.fromMap(expMap);
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.money_off, color: Colors.red)),
                        title: Text(exp.category),
                        subtitle: Text('${exp.date} ${exp.time}\n${exp.notes ?? ""}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('${exp.amount}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red)),
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showExpenseDialog(expense: exp),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _confirmDelete(exp),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showExpenseDialog(),
        label: const Text('إضافة مصروف'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  void _confirmDelete(Expense expense) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف مصروف "${expense.category}" بقيمة ${expense.amount}؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          TextButton(
            onPressed: () async {
              final repo = context.read<AppRepository>();
              await repo.deleteExpense(expense.id!);
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حذف المصروف بنجاح')));
                _loadExpenses();
              }
            },
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showExpenseDialog({Expense? expense}) {
    final repo = context.read<AppRepository>();
    final isEditing = expense != null;
    final amountController = TextEditingController(text: isEditing ? expense.amount.toString() : '');
    final categoryController = TextEditingController(text: isEditing ? expense.category : '');
    final notesController = TextEditingController(text: isEditing ? expense.notes : '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'تعديل مصروف' : 'إضافة مصروف جديد'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: categoryController,
                decoration: const InputDecoration(labelText: 'الفئة (مثلاً: إيجار، كهرباء)')),
            TextField(
                controller: amountController,
                decoration: const InputDecoration(labelText: 'المبلغ'),
                keyboardType: TextInputType.number),
            TextField(controller: notesController, decoration: const InputDecoration(labelText: 'ملاحظات')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(amountController.text) ?? 0.0;
              final category = categoryController.text;
              if (category.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى إدخال فئة المصروف')));
                return;
              }
              if (amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى إدخال مبلغ صحيح')));
                return;
              }

              if (isEditing) {
                final updatedExpense = Expense(
                  id: expense.id,
                  date: expense.date,
                  time: expense.time,
                  category: category,
                  amount: amount,
                  notes: notesController.text,
                );
                await repo.updateExpense(updatedExpense);
              } else {
                final now = DateTime.now();
                final newExpense = Expense(
                  date: DateFormat('yyyy-MM-dd').format(now),
                  time: DateFormat('HH:mm:ss').format(now),
                  category: category,
                  amount: amount,
                  notes: notesController.text,
                );
                await repo.createExpense(newExpense);
              }

              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(isEditing ? 'تم تحديث المصروف' : 'تم حفظ المصروف بنجاح')));
                _loadExpenses();
              }
            },
            child: Text(isEditing ? 'تحديث' : 'حفظ'),
          ),
        ],
      ),
    );
  }
}
