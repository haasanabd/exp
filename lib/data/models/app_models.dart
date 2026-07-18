import 'package:equatable/equatable.dart';

class Customer extends Equatable {
  final int? id;
  final String name;
  final String? phone;
  final String? address;
  final double balance;
  final String? notes;

  const Customer({
    this.id,
    required this.name,
    this.phone,
    this.address,
    this.balance = 0.0,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'address': address,
      'balance': balance,
      'notes': notes,
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'],
      name: map['name'],
      phone: map['phone'],
      address: map['address'],
      balance: map['balance'],
      notes: map['notes'],
    );
  }

  @override
  List<Object?> get props => [id, name, phone, address, balance, notes];
}

class Supplier extends Equatable {
  final int? id;
  final String name;
  final String? phone;
  final String? address;
  final double balance;
  final String? notes;

  const Supplier({
    this.id,
    required this.name,
    this.phone,
    this.address,
    this.balance = 0.0,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'address': address,
      'balance': balance,
      'notes': notes,
    };
  }

  factory Supplier.fromMap(Map<String, dynamic> map) {
    return Supplier(
      id: map['id'],
      name: map['name'],
      phone: map['phone'],
      address: map['address'],
      balance: map['balance'],
      notes: map['notes'],
    );
  }

  @override
  List<Object?> get props => [id, name, phone, address, balance, notes];
}

class RawMaterial extends Equatable {
  final int? id;
  final String name;
  final String? color;
  final double weightGram;
  final double pricePerKg;
  final double minQuantityGram;
  final String? notes;

  const RawMaterial({
    this.id,
    required this.name,
    this.color,
    this.weightGram = 0.0,
    this.pricePerKg = 0.0,
    this.minQuantityGram = 0.0,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'color': color,
      'weight_gram': weightGram,
      'price_per_kg': pricePerKg,
      'min_quantity_gram': minQuantityGram,
      'notes': notes,
    };
  }

  factory RawMaterial.fromMap(Map<String, dynamic> map) {
    return RawMaterial(
      id: map['id'],
      name: map['name'],
      color: map['color'],
      weightGram: map['weight_gram'],
      pricePerKg: map['price_per_kg'],
      minQuantityGram: map['min_quantity_gram'],
      notes: map['notes'],
    );
  }

  @override
  List<Object?> get props => [id, name, color, weightGram, pricePerKg, minQuantityGram, notes];
}

class Product extends Equatable {
  final int? id;
  final String name;
  final String? imagePath;
  final int quantity;
  final double price;
  final double weightGram;
  final int? rawMaterialId;

  const Product({
    this.id,
    required this.name,
    this.imagePath,
    this.quantity = 0,
    required this.price,
    required this.weightGram,
    this.rawMaterialId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'image_path': imagePath,
      'quantity': quantity,
      'price': price,
      'weight_gram': weightGram,
      'raw_material_id': rawMaterialId,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      name: map['name'],
      imagePath: map['image_path'],
      quantity: map['quantity'],
      price: map['price'],
      weightGram: map['weight_gram'],
      rawMaterialId: map['raw_material_id'],
    );
  }

  @override
  List<Object?> get props => [id, name, imagePath, quantity, price, weightGram, rawMaterialId];
}

class SalesInvoice extends Equatable {
  final int? id;
  final String date;
  final String time;
  final int? customerId;
  final String saleType; // 'نقدي' or 'آجل'
  final double discount;
  final double totalAmount;
  final String? notes;

  const SalesInvoice({
    this.id,
    required this.date,
    required this.time,
    this.customerId,
    required this.saleType,
    this.discount = 0.0,
    required this.totalAmount,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'time': time,
      'customer_id': customerId,
      'sale_type': saleType,
      'discount': discount,
      'total_amount': totalAmount,
      'notes': notes,
    };
  }

  factory SalesInvoice.fromMap(Map<String, dynamic> map) {
    return SalesInvoice(
      id: map['id'],
      date: map['date'],
      time: map['time'],
      customerId: map['customer_id'],
      saleType: map['sale_type'],
      discount: map['discount'],
      totalAmount: map['total_amount'],
      notes: map['notes'],
    );
  }

  String get invoiceNumber => id != null ? 'S-${id.toString().padLeft(6, '0')}' : 'S-000000';

  @override
  List<Object?> get props => [id, date, time, customerId, saleType, discount, totalAmount, notes];
}

class SaleInvoiceItem extends Equatable {
  final int? id;
  final int invoiceId;
  final int productId;
  final int quantity;
  final double price;
  final double subtotal;

  const SaleInvoiceItem({
    this.id,
    required this.invoiceId,
    required this.productId,
    required this.quantity,
    required this.price,
    required this.subtotal,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoice_id': invoiceId,
      'product_id': productId,
      'quantity': quantity,
      'price': price,
      'subtotal': subtotal,
    };
  }

  factory SaleInvoiceItem.fromMap(Map<String, dynamic> map) {
    return SaleInvoiceItem(
      id: map['id'],
      invoiceId: map['invoice_id'],
      productId: map['product_id'],
      quantity: map['quantity'],
      price: map['price'],
      subtotal: map['subtotal'],
     );
  }

  @override
  List<Object?> get props => [id, invoiceId, productId, quantity, price, subtotal];
}

class PurchaseInvoice extends Equatable {
  final int? id;
  final String date;
  final String time;
  final int? supplierId;
  final String purchaseType; // 'نقدي' or 'آجل'
  final double totalAmount;
  final String? notes;

  const PurchaseInvoice({
    this.id,
    required this.date,
    required this.time,
    this.supplierId,
    required this.purchaseType,
    required this.totalAmount,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'time': time,
      'supplier_id': supplierId,
      'purchase_type': purchaseType,
      'total_amount': totalAmount,
      'notes': notes,
    };
  }

  factory PurchaseInvoice.fromMap(Map<String, dynamic> map) {
    return PurchaseInvoice(
      id: map['id'],
      date: map['date'],
      time: map['time'],
      supplierId: map['supplier_id'],
      purchaseType: map['purchase_type'],
      totalAmount: map['total_amount'],
      notes: map['notes'],
    );
  }

  String get invoiceNumber => id != null ? 'P-${id.toString().padLeft(6, '0')}' : 'P-000000';

  @override
  List<Object?> get props => [id, date, time, supplierId, purchaseType, totalAmount, notes];
}

class PurchaseInvoiceItem extends Equatable {
  final int? id;
  final int invoiceId;
  final int rawMaterialId;
  final double quantityGram;
  final double pricePerGram;
  final double subtotal;

  const PurchaseInvoiceItem({
    this.id,
    required this.invoiceId,
    required this.rawMaterialId,
    required this.quantityGram,
    required this.pricePerGram,
    required this.subtotal,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoice_id': invoiceId,
      'raw_material_id': rawMaterialId,
      'quantity_gram': quantityGram,
      'price_per_gram': pricePerGram,
      'subtotal': subtotal,
    };
  }

  factory PurchaseInvoiceItem.fromMap(Map<String, dynamic> map) {
    return PurchaseInvoiceItem(
      id: map['id'],
      invoiceId: map['invoice_id'],
      rawMaterialId: map['raw_material_id'],
      quantityGram: map['quantity_gram'],
      pricePerGram: map['price_per_gram'],
      subtotal: map['subtotal'],
    );
  }

  @override
  List<Object?> get props => [id, invoiceId, rawMaterialId, quantityGram, pricePerGram, subtotal];
}

class Production extends Equatable {
  final int? id;
  final String date;
  final int productId;
  final int rawMaterialId;
  final double consumedWeightGram;
  final double producedWeightGram;
  final double wastePercentage;
  final double productionCost;
  final double sellingPrice;
  final String? notes;

  const Production({
    this.id,
    required this.date,
    required this.productId,
    required this.rawMaterialId,
    required this.consumedWeightGram,
    required this.producedWeightGram,
    required this.wastePercentage,
    required this.productionCost,
    required this.sellingPrice,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'product_id': productId,
      'raw_material_id': rawMaterialId,
      'consumed_weight_gram': consumedWeightGram,
      'produced_weight_gram': producedWeightGram,
      'waste_percentage': wastePercentage,
      'production_cost': productionCost,
      'selling_price': sellingPrice,
      'notes': notes,
    };
  }

  factory Production.fromMap(Map<String, dynamic> map) {
    return Production(
      id: map['id'],
      date: map['date'],
      productId: map['product_id'],
      rawMaterialId: map['raw_material_id'],
      consumedWeightGram: map['consumed_weight_gram'],
      producedWeightGram: map['produced_weight_gram'],
      wastePercentage: map['waste_percentage'],
      productionCost: map['production_cost'],
      sellingPrice: map['selling_price'],
      notes: map['notes'],
    );
  }

  @override
  List<Object?> get props => [
        id,
        date,
        productId,
        rawMaterialId,
        consumedWeightGram,
        producedWeightGram,
        wastePercentage,
        productionCost,
        sellingPrice,
        notes
      ];
}

class CashBoxAction extends Equatable {
  final int? id;
  final String date;
  final String time;
  final String type; // 'وارد', 'صادر', 'مصروف'
  final double amount;
  final String? description;
  final String? entityType; // 'زبون', 'مورد'
  final int? entityId;

  const CashBoxAction({
    this.id,
    required this.date,
    required this.time,
    required this.type,
    required this.amount,
    this.description,
    this.entityType,
    this.entityId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'time': time,
      'type': type,
      'amount': amount,
      'description': description,
      'entity_type': entityType,
      'entity_id': entityId,
    };
  }

  factory CashBoxAction.fromMap(Map<String, dynamic> map) {
    return CashBoxAction(
      id: map['id'],
      date: map['date'],
      time: map['time'],
      type: map['type'],
      amount: map['amount'],
      description: map['description'],
      entityType: map['entity_type'],
      entityId: map['entity_id'],
    );
  }

  @override
  List<Object?> get props => [id, date, time, type, amount, description, entityType, entityId];
}

class Expense extends Equatable {
  final int? id;
  final String date;
  final String time;
  final String category;
  final double amount;
  final String? notes;

  const Expense({
    this.id,
    required this.date,
    required this.time,
    required this.category,
    required this.amount,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'time': time,
      'category': category,
      'amount': amount,
      'notes': notes,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'],
      date: map['date'],
      time: map['time'],
      category: map['category'],
      amount: map['amount'],
      notes: map['notes'],
    );
  }

  @override
  List<Object?> get props => [id, date, time, category, amount, notes];
}

class ReceiptVoucher extends Equatable {
  final int? id;
  final String date;
  final String time;
  final int customerId;
  final double amount;
  final String? description;

  const ReceiptVoucher({
    this.id,
    required this.date,
    required this.time,
    required this.customerId,
    required this.amount,
    this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'time': time,
      'customer_id': customerId,
      'amount': amount,
      'description': description,
    };
  }

  factory ReceiptVoucher.fromMap(Map<String, dynamic> map) {
    return ReceiptVoucher(
      id: map['id'],
      date: map['date'],
      time: map['time'],
      customerId: map['customer_id'],
      amount: map['amount'],
      description: map['description'],
    );
  }

  @override
  List<Object?> get props => [id, date, time, customerId, amount, description];
}

class PaymentVoucher extends Equatable {
  final int? id;
  final String date;
  final String time;
  final int supplierId;
  final double amount;
  final String? description;

  const PaymentVoucher({
    this.id,
    required this.date,
    required this.time,
    required this.supplierId,
    required this.amount,
    this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'time': time,
      'supplier_id': supplierId,
      'amount': amount,
      'description': description,
    };
  }

  factory PaymentVoucher.fromMap(Map<String, dynamic> map) {
    return PaymentVoucher(
      id: map['id'],
      date: map['date'],
      time: map['time'],
      supplierId: map['supplier_id'],
      amount: map['amount'],
      description: map['description'],
    );
  }

  @override
  List<Object?> get props => [id, date, time, supplierId, amount, description];
}

class Settings extends Equatable {
  final String key;
  final String value;

  const Settings({
    required this.key,
    required this.value,
  });

  Map<String, dynamic> toMap() {
    return {
      'key': key,
      'value': value,
    };
  }

  factory Settings.fromMap(Map<String, dynamic> map) {
    return Settings(
      key: map['key'],
      value: map['value'],
    );
  }

  @override
  List<Object?> get props => [key, value];
}

class DailyCashBoxSummary extends Equatable {
  final int? id;
  final String date;
  final double openingBalance;
  final double income;
  final double expense;
  final double closingBalance;

  const DailyCashBoxSummary({
    this.id,
    required this.date,
    required this.openingBalance,
    required this.income,
    required this.expense,
    required this.closingBalance,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'opening_balance': openingBalance,
      'income': income,
      'expense': expense,
      'closing_balance': closingBalance,
    };
  }

  factory DailyCashBoxSummary.fromMap(Map<String, dynamic> map) {
    return DailyCashBoxSummary(
      id: map['id'],
      date: map['date'],
      openingBalance: map['opening_balance'],
      income: map['income'],
      expense: map['expense'],
      closingBalance: map['closing_balance'],
    );
  }

  @override
  List<Object?> get props => [id, date, openingBalance, income, expense, closingBalance];
}
