import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/app_models.dart';
import '../../data/repositories/app_repository.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<RawMaterial> _materials = [];
  List<Product> _products = [];
  List<RawMaterial> _filteredMaterials = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = true;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
    _searchController.addListener(_filterData);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final repo = context.read<AppRepository>();
    final materials = await repo.getAllRawMaterials();
    final products = await repo.getAllProducts();
    if (mounted) {
      setState(() {
        _materials = materials;
        _products = products;
        _filterData();
        _isLoading = false;
      });
    }
  }

  void _filterData() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredMaterials = _materials.where((m) => m.name.toLowerCase().contains(query) || (m.color?.toLowerCase().contains(query) ?? false)).toList();
      _filteredProducts = _products.where((p) => p.name.toLowerCase().contains(query)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة المخزن'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'بحث...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'المواد الخام', icon: Icon(Icons.category)),
                  Tab(text: 'المنتجات الجاهزة', icon: Icon(Icons.precision_manufacturing)),
                ],
              ),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildMaterialsList(),
                _buildProductsList(),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _tabController.index == 0 ? _showAddMaterialDialog() : _showAddProductDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildMaterialsList() {
    return ListView.builder(
      itemCount: _filteredMaterials.length,
      itemBuilder: (context, index) {
        final m = _filteredMaterials[index];
        return Card(
          margin: const EdgeInsets.all(8),
          child: ListTile(
            onTap: () => _showAddMaterialDialog(material: m),
            title: Text(m.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('اللون: ${m.color ?? "-"} | سعر الكيلو: ${m.pricePerKg}'),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('الوزن (غ)', style: TextStyle(fontSize: 10)),
                Text('${m.weightGram}', style: TextStyle(fontWeight: FontWeight.bold, color: m.weightGram <= m.minQuantityGram ? Colors.red : Colors.green)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProductsList() {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.8),
      itemCount: _filteredProducts.length,
      itemBuilder: (context, index) {
        final p = _filteredProducts[index];
        return Card(
          child: InkWell(
            onTap: () => _showAddProductDialog(product: p),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.image, size: 50, color: Colors.grey),
                const SizedBox(height: 8),
                Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('السعر: ${p.price}'),
                Text('الكمية: ${p.quantity}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddMaterialDialog({RawMaterial? material}) {
    final nameController = TextEditingController(text: material?.name);
    final colorController = TextEditingController(text: material?.color);
    final priceController = TextEditingController(text: material?.pricePerKg.toString());
    final minQtyController = TextEditingController(text: material?.minQuantityGram.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(material == null ? 'إضافة مادة خام' : 'تعديل مادة خام'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'الاسم *')),
            TextField(controller: colorController, decoration: const InputDecoration(labelText: 'اللون')),
            TextField(controller: priceController, decoration: const InputDecoration(labelText: 'سعر الكيلو'), keyboardType: TextInputType.number),
            TextField(controller: minQtyController, decoration: const InputDecoration(labelText: 'أقل كمية تنبيه'), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty) return;
              final m = RawMaterial(
                id: material?.id,
                name: nameController.text,
                color: colorController.text,
                weightGram: material?.weightGram ?? 0.0,
                pricePerKg: double.tryParse(priceController.text) ?? 0.0,
                minQuantityGram: double.tryParse(minQtyController.text) ?? 0.0,
                notes: material?.notes,
              );
              if (material == null) {
                await context.read<AppRepository>().addRawMaterial(m);
              } else {
                await context.read<AppRepository>().updateRawMaterial(m);
              }
              Navigator.pop(context);
              _loadData();
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _showAddProductDialog({Product? product}) {
    final nameController = TextEditingController(text: product?.name);
    final priceController = TextEditingController(text: product?.price.toString());
    final weightController = TextEditingController(text: product?.weightGram.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(product == null ? 'إضافة منتج جديد' : 'تعديل منتج'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'الاسم *')),
            TextField(controller: priceController, decoration: const InputDecoration(labelText: 'سعر البيع'), keyboardType: TextInputType.number),
            TextField(controller: weightController, decoration: const InputDecoration(labelText: 'الوزن (غ)'), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty) return;
              final p = Product(
                id: product?.id,
                name: nameController.text,
                imagePath: product?.imagePath,
                quantity: product?.quantity ?? 0,
                price: double.tryParse(priceController.text) ?? 0.0,
                weightGram: double.tryParse(weightController.text) ?? 0.0,
                rawMaterialId: product?.rawMaterialId,
              );
              if (product == null) {
                await context.read<AppRepository>().addProduct(p);
              } else {
                await context.read<AppRepository>().updateProduct(p);
              }
              Navigator.pop(context);
              _loadData();
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }
}
