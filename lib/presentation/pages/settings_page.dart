import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../../data/repositories/app_repository.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _shopNameController = TextEditingController();
  final _shopPhoneController = TextEditingController();
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final repo = context.read<AppRepository>();
    final shopName = await repo.getSetting('shop_name');
    final shopPhone = await repo.getSetting('shop_phone');
    final darkMode = await repo.getSetting('dark_mode');

    setState(() {
      _shopNameController.text = shopName ?? 'Haa 3D Management';
      _shopPhoneController.text = shopPhone ?? '';
      _isDarkMode = darkMode == 'true';
    });
  }

  Future<void> _saveShopInfo() async {
    final repo = context.read<AppRepository>();
    await repo.saveSetting('shop_name', _shopNameController.text);
    await repo.saveSetting('shop_phone', _shopPhoneController.text);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ معلومات المحل')));
    }
  }

  Future<void> _backupDatabase() async {
    try {
      final dbPath = await getDatabasesPath();
      final sourcePath = p.join(dbPath, 'haa_3d_management.db');
      final sourceFile = File(sourcePath);

      if (await sourceFile.exists()) {
        String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
        if (selectedDirectory != null) {
          final backupPath = p.join(selectedDirectory, 'haa_3d_backup_${DateTime.now().millisecondsSinceEpoch}.db');
          await sourceFile.copy(backupPath);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم النسخ الاحتياطي بنجاح إلى: $backupPath')));
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل النسخ الاحتياطي: $e')));
      }
    }
  }

  Future<void> _restoreDatabase() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();
      if (result != null) {
        final backupFile = File(result.files.single.path!);
        final dbPath = await getDatabasesPath();
        final destinationPath = p.join(dbPath, 'haa_3d_management.db');
        
        await backupFile.copy(destinationPath);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم استعادة البيانات بنجاح. يرجى إعادة تشغيل التطبيق.')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل استعادة البيانات: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('معلومات المحل', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          TextField(controller: _shopNameController, decoration: const InputDecoration(labelText: 'اسم المحل', border: OutlineInputBorder())),
          const SizedBox(height: 10),
          TextField(controller: _shopPhoneController, decoration: const InputDecoration(labelText: 'رقم الهاتف', border: OutlineInputBorder()), keyboardType: TextInputType.phone),
          const SizedBox(height: 10),
          ElevatedButton(onPressed: _saveShopInfo, child: const Text('حفظ المعلومات')),
          const Divider(height: 32),
          const Text('المظهر', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SwitchListTile(
            title: const Text('الوضع الداكن'),
            value: _isDarkMode,
            onChanged: (v) async {
              setState(() => _isDarkMode = v);
              await context.read<AppRepository>().saveSetting('dark_mode', v.toString());
              // Note: Theme change will require a provider or global state update
            },
          ),
          const Divider(height: 32),
          const Text('البيانات والنسخ الاحتياطي', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ListTile(
            leading: const Icon(Icons.backup, color: Colors.blue),
            title: const Text('نسخ احتياطي'),
            subtitle: const Text('حفظ نسخة من قاعدة البيانات'),
            onTap: _backupDatabase,
          ),
          ListTile(
            leading: const Icon(Icons.restore, color: Colors.orange),
            title: const Text('استعادة نسخة'),
            subtitle: const Text('استبدال البيانات الحالية بنسخة سابقة'),
            onTap: _restoreDatabase,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('إعادة ضبط المصنع', style: TextStyle(color: Colors.red)),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('تحذير'),
                  content: const Text('سيتم حذف جميع البيانات نهائياً. هل أنت متأكد؟'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
                    TextButton(
                      onPressed: () async {
                        final dbPath = await getDatabasesPath();
                        final path = p.join(dbPath, 'haa_3d_management.db');
                        await deleteDatabase(path);
                        Navigator.pop(context);
                        exit(0);
                      },
                      child: const Text('حذف الكل', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          const Center(child: Text('Haa 3D Management v1.0', style: TextStyle(color: Colors.grey))),
        ],
      ),
    );
  }
}
