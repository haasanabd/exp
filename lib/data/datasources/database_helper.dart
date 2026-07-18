import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('haa_3d_management.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2, // Increment version for migration
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _createDB(Database db, int version) async {
    await _createTables(db);
  }

  Future _createTables(Database db) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const textTypeNullable = 'TEXT';
    const realType = 'REAL NOT NULL DEFAULT 0.0';
    const integerType = 'INTEGER NOT NULL DEFAULT 0';

    // Customers Table
    await db.execute('''
      CREATE TABLE Customers (
        id $idType,
        name $textType,
        phone $textTypeNullable,
        address $textTypeNullable,
        balance $realType,
        notes $textTypeNullable
      )
    ''');

    // Suppliers Table
    await db.execute('''
      CREATE TABLE Suppliers (
        id $idType,
        name $textType,
        phone $textTypeNullable,
        address $textTypeNullable,
        balance $realType,
        notes $textTypeNullable
      )
    ''');

    // RawMaterials Table
    await db.execute('''
      CREATE TABLE RawMaterials (
        id $idType,
        name $textType,
        color $textTypeNullable,
        weight_gram $realType,
        price_per_kg $realType,
        min_quantity_gram $realType,
        notes $textTypeNullable
      )
    ''');

    // Products Table
    await db.execute('''
      CREATE TABLE Products (
        id $idType,
        name $textType,
        image_path $textTypeNullable,
        quantity $integerType,
        price $realType,
        weight_gram $realType,
        raw_material_id INTEGER,
        FOREIGN KEY (raw_material_id) REFERENCES RawMaterials (id)
      )
    ''');

    // SalesInvoices Table
    await db.execute('''
      CREATE TABLE SalesInvoices (
        id $idType,
        date $textType,
        time $textType,
        customer_id INTEGER,
        sale_type $textType,
        discount $realType,
        total_amount $realType,
        notes $textTypeNullable,
        FOREIGN KEY (customer_id) REFERENCES Customers (id)
      )
    ''');

    // SaleInvoiceItems Table
    await db.execute('''
      CREATE TABLE SaleInvoiceItems (
        id $idType,
        invoice_id INTEGER,
        product_id INTEGER,
        quantity $integerType,
        price $realType,
        subtotal $realType,
        FOREIGN KEY (invoice_id) REFERENCES SalesInvoices (id),
        FOREIGN KEY (product_id) REFERENCES Products (id)
      )
    ''');

    // PurchaseInvoices Table
    await db.execute('''
      CREATE TABLE PurchaseInvoices (
        id $idType,
        date $textType,
        time $textType,
        supplier_id INTEGER,
        purchase_type $textType,
        total_amount $realType,
        notes $textTypeNullable,
        FOREIGN KEY (supplier_id) REFERENCES Suppliers (id)
      )
    ''');

    // PurchaseInvoiceItems Table
    await db.execute('''
      CREATE TABLE PurchaseInvoiceItems (
        id $idType,
        invoice_id INTEGER,
        raw_material_id INTEGER,
        quantity_gram $realType,
        price_per_gram $realType,
        subtotal $realType,
        FOREIGN KEY (invoice_id) REFERENCES PurchaseInvoices (id),
        FOREIGN KEY (raw_material_id) REFERENCES RawMaterials (id)
      )
    ''');

    // Production Table
    await db.execute('''
      CREATE TABLE Production (
        id $idType,
        date $textType,
        product_id INTEGER,
        raw_material_id INTEGER,
        consumed_weight_gram $realType,
        produced_weight_gram $realType,
        waste_percentage $realType,
        production_cost $realType,
        selling_price $realType,
        notes $textTypeNullable,
        FOREIGN KEY (product_id) REFERENCES Products (id),
        FOREIGN KEY (raw_material_id) REFERENCES RawMaterials (id)
      )
    ''');

    // CashBox Table
    await db.execute('''
      CREATE TABLE CashBox (
        id $idType,
        date $textType,
        time $textType,
        type $textType,
        amount $realType,
        description $textTypeNullable,
        entity_type $textTypeNullable,
        entity_id INTEGER,
        opening_balance $realType
      )
    ''');

    // Add a table for daily cashbox summary
    await db.execute('''
      CREATE TABLE DailyCashBoxSummary (
        id $idType,
        date TEXT NOT NULL UNIQUE,
        opening_balance $realType,
        income $realType,
        expense $realType,
        closing_balance $realType
      )
    ''');

    // Expenses Table
    await db.execute('''
      CREATE TABLE Expenses (
        id $idType,
        date $textType,
        time $textType,
        category $textType,
        amount $realType,
        notes $textTypeNullable
      )
    ''');

    // ReceiptVouchers Table
    await db.execute('''
      CREATE TABLE ReceiptVouchers (
        id $idType,
        date $textType,
        time $textType,
        customer_id INTEGER,
        amount $realType,
        description $textTypeNullable,
        FOREIGN KEY (customer_id) REFERENCES Customers (id)
      )
    ''');

    // PaymentVouchers Table
    await db.execute('''
      CREATE TABLE PaymentVouchers (
        id $idType,
        date $textType,
        time $textType,
        supplier_id INTEGER,
        amount $realType,
        description $textTypeNullable,
        FOREIGN KEY (supplier_id) REFERENCES Suppliers (id)
      )
    ''');

    // Settings Table
    await db.execute('''
      CREATE TABLE Settings (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');

    // Optimization: Add indexes for frequently queried columns
    await db.execute('CREATE INDEX idx_sales_date ON SalesInvoices(date)');
    await db.execute('CREATE INDEX idx_purchases_date ON PurchaseInvoices(date)');
    await db.execute('CREATE INDEX idx_cashbox_date ON CashBox(date)');
    await db.execute('CREATE INDEX idx_expenses_date ON Expenses(date)');
    await db.execute('CREATE INDEX idx_production_date ON Production(date)');
    await db.execute('CREATE INDEX idx_customers_name ON Customers(name)');
    await db.execute('CREATE INDEX idx_suppliers_name ON Suppliers(name)');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Migration from version 1 to 2
      // Add any new tables or alter existing ones here
      // For example, adding an 'opening_balance' to CashBox
      await db.execute(
        'ALTER TABLE CashBox ADD COLUMN opening_balance REAL NOT NULL DEFAULT 0.0;'
      );
      // Add a table for daily cashbox summary
      await db.execute(
        'CREATE TABLE DailyCashBoxSummary ('
        'id INTEGER PRIMARY KEY AUTOINCREMENT,'
        'date TEXT NOT NULL UNIQUE,'
        'opening_balance REAL NOT NULL,'
        'income REAL NOT NULL,'
        'expense REAL NOT NULL,'
        'closing_balance REAL NOT NULL'
        ');'
      );
    }
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
