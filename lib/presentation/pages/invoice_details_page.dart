import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/app_models.dart';

class InvoiceDetailsPage extends StatelessWidget {
  final dynamic invoice;
  final List<dynamic> items;
  final String entityName;
  final List<Product>? products;
  final List<RawMaterial>? materials;

  const InvoiceDetailsPage({
    super.key,
    required this.invoice,
    required this.items,
    required this.entityName,
    this.products,
    this.materials,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSales = invoice is SalesInvoice;
    final String title = isSales ? 'تفاصيل فاتورة مبيعات' : 'تفاصيل فاتورة مشتريات';
    final String entityLabel = isSales ? 'الزبون' : 'المورد';
    final String invoiceNo = isSales ? (invoice as SalesInvoice).invoiceNumber : (invoice as PurchaseInvoice).invoiceNumber;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('رقم الفاتورة:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(invoiceNo, style: TextStyle(fontSize: 16, color: Colors.blue, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const Divider(),
                    _buildInfoRow('التاريخ:', '${invoice.date} ${invoice.time}'),
                    _buildInfoRow(entityLabel + ':', entityName),
                    _buildInfoRow('النوع:', invoice is SalesInvoice ? (invoice as SalesInvoice).saleType : (invoice as PurchaseInvoice).purchaseType),
                    if (isSales && (invoice as SalesInvoice).discount > 0)
                      _buildInfoRow('الخصم:', (invoice as SalesInvoice).discount.toStringAsFixed(2)),
                    _buildInfoRow('الإجمالي:', invoice.totalAmount.toStringAsFixed(2), isTotal: true),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('الأصناف:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Table(
              border: TableBorder.all(color: Colors.grey.shade300),
              columnWidths: const {
                0: FlexColumnWidth(3),
                1: FlexColumnWidth(1),
                2: FlexColumnWidth(1.5),
                3: FlexColumnWidth(1.5),
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(color: Colors.grey.shade100),
                  children: const [
                    Padding(padding: EdgeInsets.all(8.0), child: Text('الصنف', style: TextStyle(fontWeight: FontWeight.bold))),
                    Padding(padding: EdgeInsets.all(8.0), child: Text('الكمية', style: TextStyle(fontWeight: FontWeight.bold))),
                    Padding(padding: EdgeInsets.all(8.0), child: Text('السعر', style: TextStyle(fontWeight: FontWeight.bold))),
                    Padding(padding: EdgeInsets.all(8.0), child: Text('المجموع', style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                ),
                ...items.map((item) {
                  String name = '';
                  if (isSales) {
                    final pId = (item as SaleInvoiceItem).productId;
                    name = products?.firstWhere((p) => p.id == pId).name ?? 'منتج #$pId';
                  } else {
                    final mId = (item as PurchaseInvoiceItem).rawMaterialId;
                    name = materials?.firstWhere((m) => m.id == mId).name ?? 'مادة #$mId';
                  }

                  return TableRow(
                    children: [
                      Padding(padding: const EdgeInsets.all(8.0), child: Text(name)),
                      Padding(padding: const EdgeInsets.all(8.0), child: Text(isSales ? (item as SaleInvoiceItem).quantity.toString() : (item as PurchaseInvoiceItem).quantityGram.toString())),
                      Padding(padding: const EdgeInsets.all(8.0), child: Text(isSales ? (item as SaleInvoiceItem).price.toStringAsFixed(2) : (item as PurchaseInvoiceItem).pricePerGram.toStringAsFixed(2))),
                      Padding(padding: const EdgeInsets.all(8.0), child: Text(item.subtotal.toStringAsFixed(2))),
                    ],
                  );
                }).toList(),
              ],
            ),
            if (invoice.notes != null && invoice.notes!.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text('ملاحظات:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              Text(invoice.notes!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: isTotal ? FontWeight.bold : FontWeight.normal, fontSize: isTotal ? 18 : 14)),
          Text(value, style: TextStyle(fontWeight: isTotal ? FontWeight.bold : FontWeight.normal, fontSize: isTotal ? 18 : 14, color: isTotal ? Colors.red : Colors.black)),
        ],
      ),
    );
  }
}
