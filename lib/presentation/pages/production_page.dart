import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../data/models/app_models.dart';
import '../../data/repositories/app_repository.dart';
import '../../data/datasources/database_helper.dart';

class ProductionPage extends StatefulWidget {
  const ProductionPage({super.key});

  @override
  State<ProductionPage> createState() => _ProductionPageState();
}

class _ProductionPageState extends State<ProductionPage> {
  List<Map<String, dynamic>> _productions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProductions();
  }

  Future<void> _loadProductions() async {
    final db = await DatabaseHelper.instance.database;
    final productions = await db.rawQuery('''
      SELECT Production.*, Products.name as product_name, RawMaterials.name as material_name 
      FROM Production 
      LEFT JOIN Products ON Production.product_id = Products.id
      LEFT JOIN RawMaterials ON Production.raw_material_id = RawMaterials.id
      ORDER BY date DESC
    ''');
    if (mounted) {
      setState(() {
        _productions = productions;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('عمليات الإنتاج')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _productions.isEmpty
              ? const Center(child: Text('لا توجد عمليات إنتاج مسجلة'))
              : ListView.builder(
                  itemCount: _productions.length,
                  itemBuilder: (context, index) {
                    final prod = _productions[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        title: Text('${prod['product_name']} من ${prod['material_name']}'),
                        subtitle: Text('التاريخ: ${prod['date']}\nالهالك: ${prod['waste_percentage'].toStringAsFixed(2)}% | التكلفة: ${prod['production_cost']}'),
                        trailing: Text('${prod['produced_weight_gram']} جم', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddProductionDialog,
        label: const Text('إنتاج جديد'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  void _showAddProductionDialog() async {
    final repo = context.read<AppRepository>();
    final products = await repo.getAllProducts();
    final materials = await repo.getAllRawMaterials();

    if (!mounted) return;

    Product? selectedProduct;
    RawMaterial? selectedMaterial;
    final consumedWeightController = TextEditingController();
    final producedWeightController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تسجيل عملية إنتاج'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<Product>(
                decoration: const InputDecoration(labelText: 'المنتج الناتج'),
                items: products.map((p) => DropdownMenuItem(value: p, child: Text(p.name))).toList(),
                onChanged: (v) => selectedProduct = v,
              ),
              DropdownButtonFormField<RawMaterial>(
                decoration: const InputDecoration(labelText: 'المادة الخام المستخدمة'),
                items: materials.map((m) => DropdownMenuItem(value: m, child: Text('${m.name} (متوفر: ${m.weightGram} جم)'))).toList(),
                onChanged: (v) => selectedMaterial = v,
              ),
              TextField(controller: consumedWeightController, decoration: const InputDecoration(labelText: 'الوزن المصروف (غ)'), keyboardType: TextInputType.number),
              TextField(controller: producedWeightController, decoration: const InputDecoration(labelText: 'الوزن الناتج (غ)'), keyboardType: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              if (selectedProduct == null || selectedMaterial == null) return;
              final consumed = double.tryParse(consumedWeightController.text) ?? 0.0;
              final produced = double.tryParse(producedWeightController.text) ?? 0.0;

              if (consumed <= 0 || produced <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء إدخال أوزان صحيحة')));
                return;
              }

              if (consumed > selectedMaterial!.weightGram) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الكمية المتوفرة من المادة الخام غير كافية')));
                return;
              }

              // Calculate production cost based on material price per gram
              final costPerGram = selectedMaterial!.pricePerKg / 1000;
              final productionCost = consumed * costPerGram;

              final production = Production(
                date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
                productId: selectedProduct!.id!,
                rawMaterialId: selectedMaterial!.id!,
                consumedWeightGram: consumed,
                producedWeightGram: produced,
                wastePercentage: ((consumed - produced) / consumed) * 100,
                productionCost: double.parse(productionCost.toStringAsFixed(2)),
                sellingPrice: selectedProduct!.price,
              );

              await repo.createProduction(production);
              Navigator.pop(context);
              _loadProductions();
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }
}
