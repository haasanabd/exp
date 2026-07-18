import 'package:sqflite/sqflite.dart';
import '../datasources/database_helper.dart';
import '../models/app_models.dart';

class AppRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // --- Customers Operations ---
  Future<int> addCustomer(Customer customer) async {
    final db = await _dbHelper.database;
    return await db.insert('Customers', customer.toMap());
  }

  Future<List<Customer>> getAllCustomers() async {
    final db = await _dbHelper.database;
    final maps = await db.query('Customers', orderBy: 'name ASC');
    return maps.map((e) => Customer.fromMap(e)).toList();
  }

  Future<int> updateCustomer(Customer customer) async {
    final db = await _dbHelper.database;
    return await db.update('Customers', customer.toMap(), where: 'id = ?', whereArgs: [customer.id]);
  }

  // --- Suppliers Operations ---
  Future<int> addSupplier(Supplier supplier) async {
    final db = await _dbHelper.database;
    return await db.insert('Suppliers', supplier.toMap());
  }

  Future<List<Supplier>> getAllSuppliers() async {
    final db = await _dbHelper.database;
    final maps = await db.query('Suppliers', orderBy: 'name ASC');
    return maps.map((e) => Supplier.fromMap(e)).toList();
  }

  Future<int> updateSupplier(Supplier supplier) async {
    final db = await _dbHelper.database;
    return await db.update('Suppliers', supplier.toMap(), where: 'id = ?', whereArgs: [supplier.id]);
  }

  // --- Raw Materials Operations ---
  Future<int> addRawMaterial(RawMaterial material) async {
    final db = await _dbHelper.database;
    return await db.insert('RawMaterials', material.toMap());
  }

  Future<List<RawMaterial>> getAllRawMaterials() async {
    final db = await _dbHelper.database;
    final maps = await db.query('RawMaterials', orderBy: 'name ASC');
    return maps.map((e) => RawMaterial.fromMap(e)).toList();
  }

  Future<int> updateRawMaterial(RawMaterial material) async {
    final db = await _dbHelper.database;
    return await db.update('RawMaterials', material.toMap(), where: 'id = ?', whereArgs: [material.id]);
  }

  // --- Products Operations ---
  Future<int> addProduct(Product product) async {
    final db = await _dbHelper.database;
    return await db.insert('Products', product.toMap());
  }

  Future<List<Product>> getAllProducts() async {
    final db = await _dbHelper.database;
    final maps = await db.query('Products', orderBy: 'name ASC');
    return maps.map((e) => Product.fromMap(e)).toList();
  }

  Future<int> updateProduct(Product product) async {
    final db = await _dbHelper.database;
    return await db.update('Products', product.toMap(), where: 'id = ?', whereArgs: [product.id]);
  }

  // --- Search Operations ---
  Future<List<Customer>> searchCustomers(String query) async {
    final db = await _dbHelper.database;
    final maps = await db.query('Customers', where: 'name LIKE ? OR phone LIKE ?', whereArgs: ['%$query%', '%$query%']);
    return maps.map((e) => Customer.fromMap(e)).toList();
  }

  Future<List<Supplier>> searchSuppliers(String query) async {
    final db = await _dbHelper.database;
    final maps = await db.query('Suppliers', where: 'name LIKE ? OR phone LIKE ?', whereArgs: ['%$query%', '%$query%']);
    return maps.map((e) => Supplier.fromMap(e)).toList();
  }

  Future<List<Product>> searchProducts(String query) async {
    final db = await _dbHelper.database;
    final maps = await db.query('Products', where: 'name LIKE ?', whereArgs: ['%$query%']);
    return maps.map((e) => Product.fromMap(e)).toList();
  }

  Future<List<RawMaterial>> searchRawMaterials(String query) async {
    final db = await _dbHelper.database;
    final maps = await db.query('RawMaterials', where: 'name LIKE ? OR color LIKE ?', whereArgs: ['%$query%', '%$query%']);
    return maps.map((e) => RawMaterial.fromMap(e)).toList();
  }

  // --- Sales Invoice (Complex Operation) ---
  Future<void> createSalesInvoice(SalesInvoice invoice, List<SaleInvoiceItem> items) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      // Get current cashbox balance before transaction
      final currentCashBoxBalance = await _getCashBoxBalance(txn);

      // 1. Insert Invoice
      final invoiceId = await txn.insert('SalesInvoices', invoice.toMap());

      // 2. Insert Items & Update Stock
      for (var item in items) {
        final itemMap = item.toMap();
        itemMap['invoice_id'] = invoiceId;
        await txn.insert('SaleInvoiceItems', itemMap);

        // Update Product Quantity
        await txn.execute(
          'UPDATE Products SET quantity = quantity - ? WHERE id = ?',
          [item.quantity, item.productId],
        );
      }

      // 3. Update Customer Balance if Credit
      if (invoice.saleType == 'آجل' && invoice.customerId != null) {
        await txn.execute(
          'UPDATE Customers SET balance = balance + ? WHERE id = ?',
          [invoice.totalAmount, invoice.customerId],
        );
      }

      // 4. Update CashBox if Cash
      if (invoice.saleType == 'نقدي') {
        await txn.insert('CashBox', {
          'date': invoice.date,
          'time': invoice.time,
          'type': 'وارد',
          'amount': invoice.totalAmount,
          'description': 'فاتورة مبيعات رقم $invoiceId',
          'entity_type': 'زبون',
          'entity_id': invoice.customerId,
          'opening_balance': currentCashBoxBalance,
        });
        // Update Daily Summary
        await _updateDailySummary(txn, invoice.date, invoice.totalAmount, 0);
      }
    });
  }

  // --- Purchase Invoice (Complex Operation) ---
  Future<void> createPurchaseInvoice(PurchaseInvoice invoice, List<PurchaseInvoiceItem> items) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      // Get current cashbox balance before transaction
      final currentCashBoxBalance = await _getCashBoxBalance(txn);

      // 1. Insert Invoice
      final invoiceId = await txn.insert('PurchaseInvoices', invoice.toMap());

      // 2. Insert Items & Update Stock
      for (var item in items) {
        final itemMap = item.toMap();
        itemMap['invoice_id'] = invoiceId;
        await txn.insert('PurchaseInvoiceItems', itemMap);

        // Update Raw Material Weight
        await txn.execute(
          'UPDATE RawMaterials SET weight_gram = weight_gram + ? WHERE id = ?',
          [item.quantityGram, item.rawMaterialId],
        );
      }

      // 3. Update Supplier Balance if Credit
      if (invoice.purchaseType == 'آجل' && invoice.supplierId != null) {
        await txn.execute(
          'UPDATE Suppliers SET balance = balance + ? WHERE id = ?',
          [invoice.totalAmount, invoice.supplierId],
        );
      }

      // 4. Update CashBox if Cash
      if (invoice.purchaseType == 'نقدي') {
        await txn.insert('CashBox', {
          'date': invoice.date,
          'time': invoice.time,
          'type': 'صادر',
          'amount': invoice.totalAmount,
          'description': 'فاتورة مشتريات رقم $invoiceId',
          'entity_type': 'مورد',
          'entity_id': invoice.supplierId,
          'opening_balance': currentCashBoxBalance,
        });
        // Update Daily Summary
        await _updateDailySummary(txn, invoice.date, 0, invoice.totalAmount);
      }
    });
  }

  // --- Production (Complex Operation) ---
  Future<void> createProduction(Production production) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      // 1. Insert Production Record
      await txn.insert('Production', production.toMap());

      // 2. Deduct Raw Material
      await txn.execute(
        'UPDATE RawMaterials SET weight_gram = weight_gram - ? WHERE id = ?',
        [production.consumedWeightGram, production.rawMaterialId],
      );

      // 3. Add Finished Product (Assume 1 unit per production for simplicity or based on weight)
      // If we produce 1 unit of product per record:
      await txn.execute(
        'UPDATE Products SET quantity = quantity + 1 WHERE id = ?',
        [production.productId],
      );
    });
  }

  // --- Vouchers ---
  Future<void> createReceiptVoucher(ReceiptVoucher voucher) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      // Get current cashbox balance before transaction
      final currentCashBoxBalance = await _getCashBoxBalance(txn);

      final id = await txn.insert('ReceiptVouchers', voucher.toMap());
      // Update Customer Balance (Decrease debt)
      await txn.execute(
        'UPDATE Customers SET balance = balance - ? WHERE id = ?',
        [voucher.amount, voucher.customerId],
      );
      // Update CashBox
      await txn.insert('CashBox', {
        'date': voucher.date,
        'time': voucher.time,
        'type': 'وارد',
        'amount': voucher.amount,
        'description': 'سند قبض رقم $id',
        'entity_type': 'زبون',
        'entity_id': voucher.customerId,
        'opening_balance': currentCashBoxBalance,
      });
      // Update Daily Summary
      await _updateDailySummary(txn, voucher.date, voucher.amount, 0);
    });
  }

  Future<void> updateReceiptVoucher(ReceiptVoucher voucher) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      // 1. Get Old Voucher Data
      final oldVoucherMap = await txn.query('ReceiptVouchers', where: 'id = ?', whereArgs: [voucher.id]);
      if (oldVoucherMap.isEmpty) return;
      final oldVoucher = ReceiptVoucher.fromMap(oldVoucherMap.first);

      // 2. Revert Old Customer Balance
      await txn.execute(
        'UPDATE Customers SET balance = balance + ? WHERE id = ?',
        [oldVoucher.amount, oldVoucher.customerId],
      );

      // 3. Revert Old CashBox entry & Daily Summary
      await txn.delete('CashBox', where: "description = ?", whereArgs: ['سند قبض رقم ${voucher.id}']);
      await _updateDailySummary(txn, oldVoucher.date, -oldVoucher.amount, 0);

      // 4. Update Voucher Main Record
      await txn.update('ReceiptVouchers', voucher.toMap(), where: 'id = ?', whereArgs: [voucher.id]);

      // 5. Apply New Customer Balance
      await txn.execute(
        'UPDATE Customers SET balance = balance - ? WHERE id = ?',
        [voucher.amount, voucher.customerId],
      );

      // 6. Apply New CashBox entry & Daily Summary
      final currentCashBoxBalance = await _getCashBoxBalance(txn);
      await txn.insert('CashBox', {
        'date': voucher.date,
        'time': voucher.time,
        'type': 'وارد',
        'amount': voucher.amount,
        'description': 'سند قبض رقم ${voucher.id}',
        'entity_type': 'زبون',
        'entity_id': voucher.customerId,
        'opening_balance': currentCashBoxBalance,
      });
      await _updateDailySummary(txn, voucher.date, voucher.amount, 0);
    });
  }

  Future<void> deleteReceiptVoucher(int voucherId) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      // 1. Get Voucher Data
      final voucherMap = await txn.query('ReceiptVouchers', where: 'id = ?', whereArgs: [voucherId]);
      if (voucherMap.isEmpty) return;
      final voucher = ReceiptVoucher.fromMap(voucherMap.first);

      // 2. Revert Customer Balance
      await txn.execute(
        'UPDATE Customers SET balance = balance + ? WHERE id = ?',
        [voucher.amount, voucher.customerId],
      );

      // 3. Delete CashBox entry & Update Daily Summary
      await txn.delete('CashBox', where: "description = ?", whereArgs: ['سند قبض رقم $voucherId']);
      await _updateDailySummary(txn, voucher.date, -voucher.amount, 0);

      // 4. Delete Voucher Record
      await txn.delete('ReceiptVouchers', where: 'id = ?', whereArgs: [voucherId]);
    });
  }

  Future<void> createPaymentVoucher(PaymentVoucher voucher) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      // Get current cashbox balance before transaction
      final currentCashBoxBalance = await _getCashBoxBalance(txn);

      final id = await txn.insert('PaymentVouchers', voucher.toMap());
      // Update Supplier Balance (Decrease debt)
      await txn.execute(
        'UPDATE Suppliers SET balance = balance - ? WHERE id = ?',
        [voucher.amount, voucher.supplierId],
      );
      // Update CashBox
      await txn.insert('CashBox', {
        'date': voucher.date,
        'time': voucher.time,
        'type': 'صادر',
        'amount': voucher.amount,
        'description': 'سند صرف رقم $id',
        'entity_type': 'مورد',
        'entity_id': voucher.supplierId,
        'opening_balance': currentCashBoxBalance,
      });
      // Update Daily Summary
      await _updateDailySummary(txn, voucher.date, 0, voucher.amount);
    });
  }

  Future<void> updatePaymentVoucher(PaymentVoucher voucher) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      // 1. Get Old Voucher Data
      final oldVoucherMap = await txn.query('PaymentVouchers', where: 'id = ?', whereArgs: [voucher.id]);
      if (oldVoucherMap.isEmpty) return;
      final oldVoucher = PaymentVoucher.fromMap(oldVoucherMap.first);

      // 2. Revert Old Supplier Balance
      await txn.execute(
        'UPDATE Suppliers SET balance = balance + ? WHERE id = ?',
        [oldVoucher.amount, oldVoucher.supplierId],
      );

      // 3. Revert Old CashBox entry & Daily Summary
      await txn.delete('CashBox', where: "description = ?", whereArgs: ['سند صرف رقم ${voucher.id}']);
      await _updateDailySummary(txn, oldVoucher.date, 0, -oldVoucher.amount);

      // 4. Update Voucher Main Record
      await txn.update('PaymentVouchers', voucher.toMap(), where: 'id = ?', whereArgs: [voucher.id]);

      // 5. Apply New Supplier Balance
      await txn.execute(
        'UPDATE Suppliers SET balance = balance - ? WHERE id = ?',
        [voucher.amount, voucher.supplierId],
      );

      // 6. Apply New CashBox entry & Daily Summary
      final currentCashBoxBalance = await _getCashBoxBalance(txn);
      await txn.insert('CashBox', {
        'date': voucher.date,
        'time': voucher.time,
        'type': 'صادر',
        'amount': voucher.amount,
        'description': 'سند صرف رقم ${voucher.id}',
        'entity_type': 'مورد',
        'entity_id': voucher.supplierId,
        'opening_balance': currentCashBoxBalance,
      });
      await _updateDailySummary(txn, voucher.date, 0, voucher.amount);
    });
  }

  Future<void> deletePaymentVoucher(int voucherId) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      // 1. Get Voucher Data
      final voucherMap = await txn.query('PaymentVouchers', where: 'id = ?', whereArgs: [voucherId]);
      if (voucherMap.isEmpty) return;
      final voucher = PaymentVoucher.fromMap(voucherMap.first);

      // 2. Revert Supplier Balance
      await txn.execute(
        'UPDATE Suppliers SET balance = balance + ? WHERE id = ?',
        [voucher.amount, voucher.supplierId],
      );

      // 3. Delete CashBox entry & Update Daily Summary
      await txn.delete('CashBox', where: "description = ?", whereArgs: ['سند صرف رقم $voucherId']);
      await _updateDailySummary(txn, voucher.date, 0, -voucher.amount);

      // 4. Delete Voucher Record
      await txn.delete('PaymentVouchers', where: 'id = ?', whereArgs: [voucherId]);
    });
  }

  // --- Expenses ---
  Future<void> createExpense(Expense expense) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      // Get current cashbox balance before transaction
      final currentCashBoxBalance = await _getCashBoxBalance(txn);

      final id = await txn.insert('Expenses', expense.toMap());
      // Update CashBox
      await txn.insert('CashBox', {
        'date': expense.date,
        'time': expense.time,
        'type': 'مصروف',
        'amount': expense.amount,
        'description': 'مصروف رقم $id: ${expense.category}',
        'opening_balance': currentCashBoxBalance,
      });
      // Update Daily Summary
      await _updateDailySummary(txn, expense.date, 0, expense.amount);
    });
  }

  Future<void> updateExpense(Expense expense) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      // 1. Get Old Expense Data
      final oldExpenseMap = await txn.query('Expenses', where: 'id = ?', whereArgs: [expense.id]);
      if (oldExpenseMap.isEmpty) return;
      final oldExpense = Expense.fromMap(oldExpenseMap.first);

      // 2. Revert Old CashBox entry & Daily Summary
      await txn.delete('CashBox', where: "description LIKE ?", whereArgs: ['مصروف رقم ${expense.id}:%']);
      await _updateDailySummary(txn, oldExpense.date, 0, -oldExpense.amount);

      // 3. Update Expense Main Record
      await txn.update('Expenses', expense.toMap(), where: 'id = ?', whereArgs: [expense.id]);

      // 4. Apply New CashBox entry & Daily Summary
      final currentCashBoxBalance = await _getCashBoxBalance(txn);
      await txn.insert('CashBox', {
        'date': expense.date,
        'time': expense.time,
        'type': 'مصروف',
        'amount': expense.amount,
        'description': 'مصروف رقم ${expense.id}: ${expense.category}',
        'opening_balance': currentCashBoxBalance,
      });
      await _updateDailySummary(txn, expense.date, 0, expense.amount);
    });
  }

  Future<void> deleteExpense(int expenseId) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      // 1. Get Expense Data
      final expenseMap = await txn.query('Expenses', where: 'id = ?', whereArgs: [expenseId]);
      if (expenseMap.isEmpty) return;
      final expense = Expense.fromMap(expenseMap.first);

      // 2. Delete CashBox entry & Update Daily Summary
      await txn.delete('CashBox', where: "description LIKE ?", whereArgs: ['مصروف رقم $expenseId:%']);
      await _updateDailySummary(txn, expense.date, 0, -expense.amount);

      // 3. Delete Expense Record
      await txn.delete('Expenses', where: 'id = ?', whereArgs: [expenseId]);
    });
  }

  // --- Dashboard Data ---
  Future<Map<String, dynamic>> getDashboardData() async {
    final db = await _dbHelper.database;
    
    final cashResult = await db.rawQuery("SELECT SUM(CASE WHEN type='وارد' THEN amount ELSE -amount END) as total FROM CashBox");
    final productsCount = await db.rawQuery("SELECT COUNT(*) as count FROM Products");
    final materialsCount = await db.rawQuery("SELECT COUNT(*) as count FROM RawMaterials");
    final customersCount = await db.rawQuery("SELECT COUNT(*) as count FROM Customers");
    final suppliersCount = await db.rawQuery("SELECT COUNT(*) as count FROM Suppliers");
    final salesTotal = await db.rawQuery("SELECT SUM(total_amount) as total FROM SalesInvoices");
    final purchasesTotal = await db.rawQuery("SELECT SUM(total_amount) as total FROM PurchaseInvoices");

    // Manufacturing Profit Calculation:
    // Net Profit = (Total Production Value) - (Total Cost of Consumed Raw Materials) - (Total Expenses)
    final productionValue = await db.rawQuery("SELECT SUM(selling_price) as total FROM Production");
    final rawMaterialCost = await db.rawQuery('''
      SELECT SUM(Production.consumed_weight_gram * (RawMaterials.price_per_kg / 1000)) as total 
      FROM Production 
      JOIN RawMaterials ON Production.raw_material_id = RawMaterials.id
    ''');
    final expensesTotal = await db.rawQuery("SELECT SUM(amount) as total FROM Expenses");

    final prodValue = (productionValue.first['total'] as num?) ?? 0.0;
    final matCost = (rawMaterialCost.first['total'] as num?) ?? 0.0;
    final expTotal = (expensesTotal.first['total'] as num?) ?? 0.0;

    return {
      'cash_balance': cashResult.first['total'] ?? 0.0,
      'products_count': productsCount.first['count'] ?? 0,
      'materials_count': materialsCount.first['count'] ?? 0,
      'customers_count': customersCount.first['count'] ?? 0,
      'suppliers_count': suppliersCount.first['count'] ?? 0,
      'sales_total': salesTotal.first['total'] ?? 0.0,
      'purchases_total': purchasesTotal.first['total'] ?? 0.0,
      'profit_total': prodValue - matCost - expTotal,
    };
  }

  // --- Reports ---
  Future<List<Map<String, dynamic>>> getSalesInvoicesWithCustomer() async {
    final db = await _dbHelper.database;
    return await db.rawQuery('''
      SELECT SalesInvoices.*, Customers.name as customer_name 
      FROM SalesInvoices 
      LEFT JOIN Customers ON SalesInvoices.customer_id = Customers.id
      ORDER BY date DESC, time DESC
    ''');
  }

  Future<List<SaleInvoiceItem>> getSaleInvoiceItems(int invoiceId) async {
    final db = await _dbHelper.database;
    final maps = await db.query('SaleInvoiceItems', where: 'invoice_id = ?', whereArgs: [invoiceId]);
    return maps.map((e) => SaleInvoiceItem.fromMap(e)).toList();
  }

  Future<void> updateSalesInvoice(SalesInvoice invoice, List<SaleInvoiceItem> newItems) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      // 1. Get Old Invoice Data
      final oldInvoiceMap = await txn.query('SalesInvoices', where: 'id = ?', whereArgs: [invoice.id]);
      if (oldInvoiceMap.isEmpty) return;
      final oldInvoice = SalesInvoice.fromMap(oldInvoiceMap.first);

      // 2. Revert Old Items & Stock
      final oldItemsMaps = await txn.query('SaleInvoiceItems', where: 'invoice_id = ?', whereArgs: [invoice.id]);
      for (var itemMap in oldItemsMaps) {
        final item = SaleInvoiceItem.fromMap(itemMap);
        await txn.execute(
          'UPDATE Products SET quantity = quantity + ? WHERE id = ?',
          [item.quantity, item.productId],
        );
      }

      // 3. Revert Old Customer Balance if Credit
      if (oldInvoice.saleType == 'آجل' && oldInvoice.customerId != null) {
        await txn.execute(
          'UPDATE Customers SET balance = balance - ? WHERE id = ?',
          [oldInvoice.totalAmount, oldInvoice.customerId],
        );
      }

      // 4. Delete Old CashBox entry if Cash
      if (oldInvoice.saleType == 'نقدي') {
        await txn.delete('CashBox', where: "description = ?", whereArgs: ['فاتورة مبيعات رقم ${invoice.id}']);
        await _updateDailySummary(txn, oldInvoice.date, -oldInvoice.totalAmount, 0);
      }

      // 5. Update Invoice Main Record
      await txn.update('SalesInvoices', invoice.toMap(), where: 'id = ?', whereArgs: [invoice.id]);

      // 6. Delete Old Items and Insert New Items
      await txn.delete('SaleInvoiceItems', where: 'invoice_id = ?', whereArgs: [invoice.id]);
      for (var item in newItems) {
        final itemMap = item.toMap();
        itemMap['invoice_id'] = invoice.id;
        itemMap.remove('id'); // Ensure new ID is generated
        await txn.insert('SaleInvoiceItems', itemMap);

        // Update Stock with New Quantities
        await txn.execute(
          'UPDATE Products SET quantity = quantity - ? WHERE id = ?',
          [item.quantity, item.productId],
        );
      }

      // 7. Apply New Customer Balance if Credit
      if (invoice.saleType == 'آجل' && invoice.customerId != null) {
        await txn.execute(
          'UPDATE Customers SET balance = balance + ? WHERE id = ?',
          [invoice.totalAmount, invoice.customerId],
        );
      }

      // 8. Apply New CashBox entry if Cash
      if (invoice.saleType == 'نقدي') {
        final currentCashBoxBalance = await _getCashBoxBalance(txn);
        await txn.insert('CashBox', {
          'date': invoice.date,
          'time': invoice.time,
          'type': 'وارد',
          'amount': invoice.totalAmount,
          'description': 'فاتورة مبيعات رقم ${invoice.id}',
          'entity_type': 'زبون',
          'entity_id': invoice.customerId,
          'opening_balance': currentCashBoxBalance,
        });
        await _updateDailySummary(txn, invoice.date, invoice.totalAmount, 0);
      }
    });
  }

  Future<List<Map<String, dynamic>>> getCashBoxRecords({String? date}) async {
    final db = await _dbHelper.database;
    if (date != null) {
      return await db.query('CashBox', where: 'date = ?', whereArgs: [date], orderBy: 'time DESC');
    }
    return await db.query('CashBox', orderBy: 'date DESC, time DESC');
  }

  Future<ReceiptVoucher?> getReceiptVoucherById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query('ReceiptVouchers', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) return ReceiptVoucher.fromMap(maps.first);
    return null;
  }

  Future<PaymentVoucher?> getPaymentVoucherById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query('PaymentVouchers', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) return PaymentVoucher.fromMap(maps.first);
    return null;
  }

  Future<Expense?> getExpenseById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query('Expenses', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) return Expense.fromMap(maps.first);
    return null;
  }

  Future<List<PurchaseInvoiceItem>> getPurchaseInvoiceItems(int invoiceId) async {
    final db = await _dbHelper.database;
    final maps = await db.query('PurchaseInvoiceItems', where: 'invoice_id = ?', whereArgs: [invoiceId]);
    return maps.map((e) => PurchaseInvoiceItem.fromMap(e)).toList();
  }

  Future<void> updatePurchaseInvoice(PurchaseInvoice invoice, List<PurchaseInvoiceItem> newItems) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      // 1. Get Old Invoice Data
      final oldInvoiceMap = await txn.query('PurchaseInvoices', where: 'id = ?', whereArgs: [invoice.id]);
      if (oldInvoiceMap.isEmpty) return;
      final oldInvoice = PurchaseInvoice.fromMap(oldInvoiceMap.first);

      // 2. Revert Old Items & Stock
      final oldItemsMaps = await txn.query('PurchaseInvoiceItems', where: 'invoice_id = ?', whereArgs: [invoice.id]);
      for (var itemMap in oldItemsMaps) {
        final item = PurchaseInvoiceItem.fromMap(itemMap);
        await txn.execute(
          'UPDATE RawMaterials SET weight_gram = weight_gram - ? WHERE id = ?',
          [item.quantityGram, item.rawMaterialId],
        );
      }

      // 3. Revert Old Supplier Balance if Credit
      if (oldInvoice.purchaseType == 'آجل' && oldInvoice.supplierId != null) {
        await txn.execute(
          'UPDATE Suppliers SET balance = balance - ? WHERE id = ?',
          [oldInvoice.totalAmount, oldInvoice.supplierId],
        );
      }

      // 4. Delete Old CashBox entry if Cash
      if (oldInvoice.purchaseType == 'نقدي') {
        await txn.delete('CashBox', where: "description = ?", whereArgs: ['فاتورة مشتريات رقم ${invoice.id}']);
        await _updateDailySummary(txn, oldInvoice.date, 0, -oldInvoice.totalAmount);
      }

      // 5. Update Invoice Main Record
      await txn.update('PurchaseInvoices', invoice.toMap(), where: 'id = ?', whereArgs: [invoice.id]);

      // 6. Delete Old Items and Insert New Items
      await txn.delete('PurchaseInvoiceItems', where: 'invoice_id = ?', whereArgs: [invoice.id]);
      for (var item in newItems) {
        final itemMap = item.toMap();
        itemMap['invoice_id'] = invoice.id;
        itemMap.remove('id');
        await txn.insert('PurchaseInvoiceItems', itemMap);

        // Update Stock with New Quantities
        await txn.execute(
          'UPDATE RawMaterials SET weight_gram = weight_gram + ? WHERE id = ?',
          [item.quantityGram, item.rawMaterialId],
        );
      }

      // 7. Apply New Supplier Balance if Credit
      if (invoice.purchaseType == 'آجل' && invoice.supplierId != null) {
        await txn.execute(
          'UPDATE Suppliers SET balance = balance + ? WHERE id = ?',
          [invoice.totalAmount, invoice.supplierId],
        );
      }

      // 8. Apply New CashBox entry if Cash
      if (invoice.purchaseType == 'نقدي') {
        final currentCashBoxBalance = await _getCashBoxBalance(txn);
        await txn.insert('CashBox', {
          'date': invoice.date,
          'time': invoice.time,
          'type': 'صادر',
          'amount': invoice.totalAmount,
          'description': 'فاتورة مشتريات رقم ${invoice.id}',
          'entity_type': 'مورد',
          'entity_id': invoice.supplierId,
          'opening_balance': currentCashBoxBalance,
        });
        await _updateDailySummary(txn, invoice.date, 0, invoice.totalAmount);
      }
    });
  }

  // --- Edit & Delete Operations ---
  Future<void> deleteSalesInvoice(int invoiceId) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      // 1. Get Invoice Data
      final invoiceMap = await txn.query('SalesInvoices', where: 'id = ?', whereArgs: [invoiceId]);
      if (invoiceMap.isEmpty) return;
      final invoice = SalesInvoice.fromMap(invoiceMap.first);

      // 2. Get Items to revert stock
      final items = await txn.query('SaleInvoiceItems', where: 'invoice_id = ?', whereArgs: [invoiceId]);
      for (var item in items) {
        await txn.execute(
          'UPDATE Products SET quantity = quantity + ? WHERE id = ?',
          [item['quantity'], item['product_id']],
        );
      }

      // 3. Revert Customer Balance if Credit
      if (invoice.saleType == 'آجل' && invoice.customerId != null) {
        await txn.execute(
          'UPDATE Customers SET balance = balance - ? WHERE id = ?',
          [invoice.totalAmount, invoice.customerId],
        );
      }

      // 4. Delete CashBox entry if Cash
      if (invoice.saleType == 'نقدي') {
        await txn.delete('CashBox', where: "description = ?", whereArgs: ['فاتورة مبيعات رقم $invoiceId']);
        await _updateDailySummary(txn, invoice.date, -invoice.totalAmount, 0);
      }

      // 5. Delete Invoice and Items
      await txn.delete('SaleInvoiceItems', where: 'invoice_id = ?', whereArgs: [invoiceId]);
      await txn.delete('SalesInvoices', where: 'id = ?', whereArgs: [invoiceId]);
    });
  }

  Future<void> deletePurchaseInvoice(int invoiceId) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      // 1. Get Invoice Data
      final invoiceMap = await txn.query('PurchaseInvoices', where: 'id = ?', whereArgs: [invoiceId]);
      if (invoiceMap.isEmpty) return;
      final invoice = PurchaseInvoice.fromMap(invoiceMap.first);

      // 2. Get Items to revert stock
      final items = await txn.query('PurchaseInvoiceItems', where: 'invoice_id = ?', whereArgs: [invoiceId]);
      for (var item in items) {
        await txn.execute(
          'UPDATE RawMaterials SET weight_gram = weight_gram - ? WHERE id = ?',
          [item['quantity_gram'], item['raw_material_id']],
        );
      }

      // 3. Revert Supplier Balance if Credit
      if (invoice.purchaseType == 'آجل' && invoice.supplierId != null) {
        await txn.execute(
          'UPDATE Suppliers SET balance = balance - ? WHERE id = ?',
          [invoice.totalAmount, invoice.supplierId],
        );
      }

      // 4. Delete CashBox entry if Cash
      if (invoice.purchaseType == 'نقدي') {
        await txn.delete('CashBox', where: "description = ?", whereArgs: ['فاتورة مشتريات رقم $invoiceId']);
        await _updateDailySummary(txn, invoice.date, 0, -invoice.totalAmount);
      }

      // 5. Delete Invoice and Items
      await txn.delete('PurchaseInvoiceItems', where: 'invoice_id = ?', whereArgs: [invoiceId]);
      await txn.delete('PurchaseInvoices', where: 'id = ?', whereArgs: [invoiceId]);
    });
  }

  // Helper to get current cashbox balance
  Future<double> _getCashBoxBalance(Transaction txn) async {
    final cashResult = await txn.rawQuery("SELECT SUM(CASE WHEN type='وارد' THEN amount ELSE -amount END) as total FROM CashBox");
    return (cashResult.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  // Helper to update daily summary
  Future<void> _updateDailySummary(Transaction txn, String date, double income, double expense) async {
    final maps = await txn.query('DailyCashBoxSummary', where: 'date = ?', whereArgs: [date]);
    if (maps.isNotEmpty) {
      await txn.execute(
        'UPDATE DailyCashBoxSummary SET income = income + ?, expense = expense + ?, closing_balance = closing_balance + ? - ? WHERE date = ?',
        [income, expense, income, expense, date],
      );
    } else {
      final prevBalance = await _getCashBoxBalance(txn) - income + expense;
      await txn.insert('DailyCashBoxSummary', {
        'date': date,
        'opening_balance': prevBalance,
        'income': income,
        'expense': expense,
        'closing_balance': prevBalance + income - expense,
      });
    }
  }

  // --- Daily CashBox Summary Operations ---
  Future<int> addDailyCashBoxSummary(DailyCashBoxSummary summary) async {
    final db = await _dbHelper.database;
    return await db.insert('DailyCashBoxSummary', summary.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<DailyCashBoxSummary?> getDailyCashBoxSummary(String date) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'DailyCashBoxSummary',
      where: 'date = ?',
      whereArgs: [date],
    );
    if (maps.isNotEmpty) {
      return DailyCashBoxSummary.fromMap(maps.first);
    } else {
      return null;
    }
  }

  Future<List<DailyCashBoxSummary>> getAllDailyCashBoxSummaries() async {
    final db = await _dbHelper.database;
    final maps = await db.query('DailyCashBoxSummary', orderBy: 'date DESC');
    return maps.map((e) => DailyCashBoxSummary.fromMap(e)).toList();
  }

  // --- Settings Operations ---
  Future<void> saveSetting(String key, String value) async {
    final db = await _dbHelper.database;
    await db.insert(
      'Settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getSetting(String key) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'Settings',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
    );
    if (maps.isNotEmpty) {
      return maps.first['value'] as String?;
    } else {
      return null;
    }
  }
}
