import 'dart:convert';
import '../models/purchase_order_model.dart';

class PurchaseOrderRepository {
  static List<PurchaseOrderModel>? _inMemoryPos;
  static List<GrnModel>? _inMemoryGrns;

  static const String _poListJson = '''
{
    "status": "success",
    "message": "Action Successful",
    "data": [
        {
            "id": 133,
            "purchase_order_number": "EFP-PO-10133",
            "status": "approved",
            "expiry_date": null,
            "delivery_date": "2026-07-10",
            "total_units": 24,
            "total_price": "24000.0",
            "final_amount": "24000.0",
            "vendor": {
                "id": 23,
                "firm_name": "New Vendor 202",
                "code": "EFP-VEN-10023",
                "status": "active"
            },
            "shipment": null,
            "line_items": [
                {
                    "id": 104,
                    "product_sku_id": 6,
                    "sku_name": "Commercial Plywood BWR Grade - 6mm 8x4",
                    "sku_code": "10010010001100000",
                    "tracking_type": "serial",
                    "ordered_quantity": 4,
                    "unit_price": "1000.0",
                    "received_quantity": 0
                },
                {
                    "id": 105,
                    "product_sku_id": 11,
                    "sku_name": "Commercial Plywood BWP Grade - 6mm 8x4",
                    "sku_code": "10010010002100000",
                    "tracking_type": "untracked",
                    "ordered_quantity": 10,
                    "unit_price": "1000.0",
                    "received_quantity": 0
                },
                {
                    "id": 106,
                    "product_sku_id": 1,
                    "sku_name": "Commercial Plywood MR Grade - 6mm 8x4",
                    "sku_code": "10010010000100000",
                    "tracking_type": "batch",
                    "ordered_quantity": 10,
                    "unit_price": "1000.0",
                    "received_quantity": 0
                }
            ]
        },
        {
            "id": 132,
            "purchase_order_number": "EFP-PO-10132",
            "status": "approved",
            "expiry_date": null,
            "delivery_date": "2026-07-09",
            "total_units": 399,
            "total_price": "399000.0",
            "final_amount": "399000.0",
            "vendor": {
                "id": 23,
                "firm_name": "New Vendor 202",
                "code": "EFP-VEN-10023",
                "status": "active"
            },
            "shipment": null,
            "line_items": [
                {
                    "id": 101,
                    "product_sku_id": 11,
                    "sku_name": "Commercial Plywood BWP Grade - 6mm 8x4",
                    "sku_code": "10010010002100000",
                    "tracking_type": "untracked",
                    "ordered_quantity": 10,
                    "unit_price": "1000.0",
                    "received_quantity": 0
                },
                {
                    "id": 102,
                    "product_sku_id": 6,
                    "sku_name": "Commercial Plywood BWR Grade - 6mm 8x4",
                    "sku_code": "10010010001100000",
                    "tracking_type": "serial",
                    "ordered_quantity": 10,
                    "unit_price": "1000.0",
                    "received_quantity": 0
                },
                {
                    "id": 103,
                    "product_sku_id": 1,
                    "sku_name": "Commercial Plywood MR Grade - 6mm 8x4",
                    "sku_code": "10010010000100000",
                    "tracking_type": "batch",
                    "ordered_quantity": 10,
                    "unit_price": "1000.0",
                    "received_quantity": 0
                }
            ]
        },
        {
            "id": 131,
            "purchase_order_number": "EFP-PO-10131",
            "status": "completed",
            "expiry_date": null,
            "delivery_date": "2026-06-26",
            "total_units": 1,
            "total_price": "35.0",
            "final_amount": "35.0",
            "vendor": {
                "id": 24,
                "firm_name": "Prince Manufacturers",
                "code": "EFP-VEN-10024",
                "status": "active"
            },
            "shipment": {
                "id": 386,
                "shipment_number": "EFP-S-10386",
                "status": "delivered",
                "order_id": 250
            }
        },
        {
            "id": 130,
            "purchase_order_number": "EFP-PO-10130",
            "status": "completed",
            "expiry_date": "2026-06-27",
            "delivery_date": "2026-06-26",
            "total_units": 1,
            "total_price": "35.0",
            "final_amount": "35.0",
            "vendor": {
                "id": 24,
                "firm_name": "Prince Manufacturers",
                "code": "EFP-VEN-10024",
                "status": "active"
            },
            "shipment": {
                "id": 384,
                "shipment_number": "EFP-S-10384",
                "status": "delivered",
                "order_id": 250
            }
        },
        {
            "id": 129,
            "purchase_order_number": "EFP-PO-10129",
            "status": "completed",
            "expiry_date": null,
            "delivery_date": "2026-06-25",
            "total_units": 10,
            "total_price": "4000.0",
            "final_amount": "4000.0",
            "vendor": {
                "id": 22,
                "firm_name": "prince_2",
                "code": "EXP-VEN-10022",
                "status": "active"
            },
            "shipment": null
        },
        {
            "id": 128,
            "purchase_order_number": "EFP-PO-10128",
            "status": "approved",
            "expiry_date": "2026-06-01",
            "delivery_date": "2026-06-03",
            "total_units": 100,
            "total_price": "9000.0",
            "final_amount": "9000.0",
            "vendor": {
                "id": 24,
                "firm_name": "Prince Manufacturers",
                "code": "EFP-VEN-10024",
                "status": "active"
            },
            "shipment": null
        },
        {
            "id": 127,
            "purchase_order_number": "EFP-PO-10127",
            "status": "completed",
            "expiry_date": "2026-06-24",
            "delivery_date": "2026-06-23",
            "total_units": 1,
            "total_price": "2000.0",
            "final_amount": "2000.0",
            "vendor": {
                "id": 23,
                "firm_name": "New Vendor 202",
                "code": "EFP-VEN-10023",
                "status": "active"
            },
            "shipment": {
                "id": 368,
                "shipment_number": "EFP-S-10368",
                "status": "delivered",
                "order_id": 227
            }
        },
        {
            "id": 126,
            "purchase_order_number": "EFP-PO-10126",
            "status": "completed",
            "expiry_date": "2026-06-27",
            "delivery_date": "2026-06-17",
            "total_units": 1,
            "total_price": "2000.0",
            "final_amount": "2000.0",
            "vendor": {
                "id": 23,
                "firm_name": "New Vendor 202",
                "code": "EFP-VEN-10023",
                "status": "active"
            },
            "shipment": {
                "id": 359,
                "shipment_number": "EFP-S-10359",
                "status": "delivered",
                "order_id": 160
            }
        },
        {
            "id": 125,
            "purchase_order_number": "EFP-PO-10125",
            "status": "completed",
            "expiry_date": null,
            "delivery_date": "2026-06-11",
            "total_units": 30,
            "total_price": "3000.0",
            "final_amount": "3000.0",
            "vendor": {
                "id": 22,
                "firm_name": "prince_2",
                "code": "EXP-VEN-10022",
                "status": "active"
            },
            "shipment": null
        },
        {
            "id": 124,
            "purchase_order_number": "EFP-PO-10124",
            "status": "completed",
            "expiry_date": null,
            "delivery_date": "2026-06-11",
            "total_units": 40,
            "total_price": "20000.0",
            "final_amount": "20000.0",
            "vendor": {
                "id": 22,
                "firm_name": "prince_2",
                "code": "EXP-VEN-10022",
                "status": "active"
            },
            "shipment": null
        },
        {
            "id": 123,
            "purchase_order_number": "EFP-PO-10123",
            "status": "completed",
            "expiry_date": null,
            "delivery_date": "2026-06-10",
            "total_units": 1,
            "total_price": "3.0",
            "final_amount": "3.0",
            "vendor": {
                "id": 22,
                "firm_name": "prince_2",
                "code": "EXP-VEN-10022",
                "status": "active"
            },
            "shipment": null
        },
        {
            "id": 122,
            "purchase_order_number": "EFP-PO-10122",
            "status": "completed",
            "expiry_date": null,
            "delivery_date": "2026-06-10",
            "total_units": 4,
            "total_price": "2415.0",
            "final_amount": "2415.0",
            "vendor": {
                "id": 22,
                "firm_name": "prince_2",
                "code": "EXP-VEN-10022",
                "status": "active"
            },
            "shipment": null
        },
        {
            "id": 121,
            "purchase_order_number": "EFP-PO-10121",
            "status": "completed",
            "expiry_date": null,
            "delivery_date": "2026-06-10",
            "total_units": 2,
            "total_price": "820.0",
            "final_amount": "820.0",
            "vendor": {
                "id": 22,
                "firm_name": "prince_2",
                "code": "EXP-VEN-10022",
                "status": "active"
            },
            "shipment": null
        },
        {
            "id": 120,
            "purchase_order_number": "EFP-PO-10120",
            "status": "approved",
            "expiry_date": "2026-05-29",
            "delivery_date": "2026-05-29",
            "total_units": 2,
            "total_price": "222.0",
            "final_amount": "222.0",
            "vendor": {
                "id": 22,
                "firm_name": "prince_2",
                "code": "EXP-VEN-10022",
                "status": "active"
            },
            "shipment": null
        },
        {
            "id": 119,
            "purchase_order_number": "EFP-PO-10119",
            "status": "completed",
            "expiry_date": null,
            "delivery_date": "2026-05-29",
            "total_units": 2,
            "total_price": "200.0",
            "final_amount": "200.0",
            "vendor": {
                "id": 20,
                "firm_name": "Sainathreddy",
                "code": "EXP-VEN-10020",
                "status": "active"
            },
            "shipment": {
                "id": 348,
                "shipment_number": "EFP-S-10348",
                "status": "delivered",
                "order_id": 136
            }
        },
        {
            "id": 118,
            "purchase_order_number": "EFP-PO-10118",
            "status": "completed",
            "expiry_date": null,
            "delivery_date": "2026-05-29",
            "total_units": 8,
            "total_price": "3800.0",
            "final_amount": "3800.0",
            "vendor": {
                "id": 22,
                "firm_name": "prince_2",
                "code": "EXP-VEN-10022",
                "status": "active"
            },
            "shipment": null
        },
        {
            "id": 117,
            "purchase_order_number": "EFP-PO-10117",
            "status": "waiting_for_approval",
            "expiry_date": null,
            "delivery_date": "2026-05-30",
            "total_units": 1,
            "total_price": "100.0",
            "final_amount": "100.0",
            "vendor": {
                "id": 20,
                "firm_name": "Sainathreddy",
                "code": "EXP-VEN-10020",
                "status": "active"
            },
            "shipment": {
                "id": 344,
                "shipment_number": "EFP-S-10344",
                "status": "created",
                "order_id": 134
            }
        },
        {
            "id": 116,
            "purchase_order_number": "EFP-PO-10116",
            "status": "waiting_for_approval",
            "expiry_date": null,
            "delivery_date": "2026-05-30",
            "total_units": 20,
            "total_price": "20000.0",
            "final_amount": "20000.0",
            "vendor": {
                "id": 23,
                "firm_name": "New Vendor 202",
                "code": "EFP-VEN-10023",
                "status": "active"
            },
            "shipment": null
        },
        {
            "id": 115,
            "purchase_order_number": "EFP-PO-10115",
            "status": "completed",
            "expiry_date": null,
            "delivery_date": "2026-05-30",
            "total_units": 2,
            "total_price": "200.0",
            "final_amount": "200.0",
            "vendor": {
                "id": 20,
                "firm_name": "Sainathreddy",
                "code": "EXP-VEN-10020",
                "status": "active"
            },
            "shipment": {
                "id": 341,
                "shipment_number": "EFP-S-10341",
                "status": "delivered",
                "order_id": 130
            }
        },
        {
            "id": 114,
            "purchase_order_number": "EFP-PO-10114",
            "status": "completed",
            "expiry_date": null,
            "delivery_date": "2026-05-26",
            "total_units": 1,
            "total_price": "1000.0",
            "final_amount": "1000.0",
            "vendor": {
                "id": 22,
                "firm_name": "prince_2",
                "code": "EXP-VEN-10022",
                "status": "active"
            },
            "shipment": null
        },
        {
            "id": 113,
            "purchase_order_number": "EFP-PO-10113",
            "status": "completed",
            "expiry_date": null,
            "delivery_date": "2026-05-26",
            "total_units": 1,
            "total_price": "500.0",
            "final_amount": "500.0",
            "vendor": {
                "id": 22,
                "firm_name": "prince_2",
                "code": "EXP-VEN-10022",
                "status": "active"
            },
            "shipment": null
        }
    ]
}
''';

  static const String _grnListJson = '''
{
    "status": "success",
    "message": "Action Successful",
    "data": [
        {
            "id": 116,
            "grn_number": "EFP-GRN-10116",
            "status": "completed",
            "direct_grn": false,
            "vendor_invoice_date": "2026-07-01",
            "vendor_invoice_no": "jn jn",
            "received_date": "2026-07-02",
            "final_amount": 210000.0,
            "total_received_quantity": 210,
            "total_accepted_quantity": 210,
            "total_rejected_quantity": 0,
            "total_received_amount": "210000.0",
            "total_accepted_amount": "210000.0",
            "total_rejected_amount": "0.0",
            "taxable_amount": "177966.1",
            "tax_amount": "32033.9",
            "cgst_amount": "0.0",
            "sgst_amount": "0.0",
            "igst_amount": "32033.9",
            "vendor_invoice_s3_url": null,
            "vendor": {
                "id": 23,
                "name": "New Vendor 202",
                "vendor_type": "manufacturer"
            },
            "node": {
                "id": 8,
                "name": "Katedhan Warehouse"
            },
            "purchase_order": {
                "id": 132,
                "purchase_order_number": "EFP-PO-10132"
            },
            "created_by": {
                "id": 14,
                "name": "lounghminghsakal",
                "email": "lounghminghsakal@flaerhomes.com"
            },
            "line_items": [
                {
                    "id": 243,
                    "product_sku_id": 1,
                    "sku_name": "Commercial Plywood MR Grade - 6mm 8x4",
                    "sku_code": "10010010000100000",
                    "tracking_type": "batch",
                    "received_quantity": 100,
                    "accepted_quantity": 100,
                    "rejected_quantity": 0,
                    "unit_price": "1000.0",
                    "received_amount": "100000.0",
                    "accepted_amount": "100000.0",
                    "rejected_amount": "0.0",
                    "taxable_amount": "84745.76",
                    "tax_amount": "15254.24",
                    "cgst_amount": "0.0",
                    "sgst_amount": "0.0",
                    "igst_amount": "15254.24",
                    "final_amount": 100000.0,
                    "rejection_reason": null,
                    "received_batches": [
                        {
                            "quantity": 50,
                            "batch_code": "BH-1",
                            "expiry_date": "2026-07-06T18:30:00.000Z",
                            "manufacture_date": "2026-06-29T18:30:00.000Z"
                        },
                        {
                            "quantity": 50,
                            "batch_code": "BH-2",
                            "expiry_date": "2026-07-08T18:30:00.000Z",
                            "manufacture_date": "2026-06-29T18:30:00.000Z"
                        }
                    ],
                    "received_serials": null,
                    "accepted_batches": [
                        {
                            "quantity": 50,
                            "batch_code": "BH-1",
                            "expiry_date": "2026-07-06T18:30:00.000Z",
                            "manufacture_date": "2026-06-29T18:30:00.000Z"
                        },
                        {
                            "quantity": 50,
                            "batch_code": "BH-2",
                            "expiry_date": "2026-07-08T18:30:00.000Z",
                            "manufacture_date": "2026-06-29T18:30:00.000Z"
                        }
                    ],
                    "accepted_serials": null,
                    "rejected_batches": [],
                    "rejected_serials": null
                },
                {
                    "id": 244,
                    "product_sku_id": 6,
                    "sku_name": "Commercial Plywood BWR Grade - 6mm 8x4",
                    "sku_code": "10010010001100000",
                    "tracking_type": "serial",
                    "received_quantity": 10,
                    "accepted_quantity": 10,
                    "rejected_quantity": 0,
                    "unit_price": "1000.0",
                    "received_amount": "10000.0",
                    "accepted_amount": "100000.0",
                    "rejected_amount": "0.0",
                    "taxable_amount": "8474.58",
                    "tax_amount": "1525.42",
                    "cgst_amount": "0.0",
                    "sgst_amount": "0.0",
                    "igst_amount": "1525.42",
                    "final_amount": 10000.0,
                    "rejection_reason": null,
                    "received_batches": null,
                    "received_serials": [
                        "serrr-1",
                        "serr-2",
                        "serr-3",
                        "serr-4",
                        "serr-5",
                        "serr-6",
                        "serr-7",
                        "serr-8",
                        "serr-9",
                        "seerrr-10"
                    ],
                    "accepted_batches": null,
                    "accepted_serials": [
                        "serrr-1",
                        "serr-2",
                        "serr-3",
                        "serr-4",
                        "serr-5",
                        "serr-6",
                        "serr-7",
                        "serr-8",
                        "serr-9",
                        "seerrr-10"
                    ],
                    "rejected_batches": null,
                    "rejected_serials": []
                },
                {
                    "id": 245,
                    "product_sku_id": 11,
                    "sku_name": "Commercial Plywood BWP Grade - 6mm 8x4",
                    "sku_code": "10010010002100000",
                    "tracking_type": "untracked",
                    "received_quantity": 100,
                    "accepted_quantity": 100,
                    "rejected_quantity": 0,
                    "unit_price": "1000.0",
                    "received_amount": "100000.0",
                    "accepted_amount": "100000.0",
                    "rejected_amount": "0.0",
                    "taxable_amount": "84745.76",
                    "tax_amount": "15254.24",
                    "cgst_amount": "0.0",
                    "sgst_amount": "0.0",
                    "igst_amount": "15254.24",
                    "final_amount": 100000.0,
                    "rejection_reason": null,
                    "received_batches": null,
                    "received_serials": null,
                    "accepted_batches": null,
                    "accepted_serials": null,
                    "rejected_batches": null,
                    "rejected_serials": null
                }
            ]
        }
    ]
}
''';

  List<PurchaseOrderModel> get _pos {
    if (_inMemoryPos == null) {
      final map = jsonDecode(_poListJson) as Map<String, dynamic>;
      _inMemoryPos = (map['data'] as List)
          .map((e) => PurchaseOrderModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return _inMemoryPos!;
  }

  List<GrnModel> get _grns {
    if (_inMemoryGrns == null) {
      final map = jsonDecode(_grnListJson) as Map<String, dynamic>;
      _inMemoryGrns = (map['data'] as List)
          .map((e) => GrnModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return _inMemoryGrns!;
  }

  Future<List<PurchaseOrderModel>> getPurchaseOrders() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _pos.where((po) => po.status.toLowerCase() == 'approved').toList();
  }

  Future<List<GrnModel>> getGrnsForPo(int poId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _grns.where((g) => g.purchaseOrderId == poId).toList();
  }

  Future<GrnModel> getGrnDetail(int grnId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      return _grns.firstWhere((g) => g.id == grnId);
    } catch (_) {
      if (_grns.isNotEmpty) return _grns.first;
      throw Exception('GRN not found');
    }
  }

  Future<GrnModel> createGrn({
    required int poId,
    required String vendorInvoiceDate,
    required String vendorInvoiceNo,
    required String receivedDate,
    String? vendorInvoiceS3Url,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final newId = _grns.isEmpty
        ? 117
        : (_grns.map((e) => e.id).reduce((a, b) => a > b ? a : b) + 1);
    final po = _pos.firstWhere((p) => p.id == poId, orElse: () => _pos.first);

    final newGrn = GrnModel(
      id: newId,
      grnNumber: 'EFP-GRN-$newId',
      status: 'created',
      directGrn: false,
      vendorInvoiceDate: vendorInvoiceDate,
      vendorInvoiceNo: vendorInvoiceNo,
      receivedDate: receivedDate,
      finalAmount: 0.0,
      totalReceivedQuantity: 0,
      totalAcceptedQuantity: 0,
      totalRejectedQuantity: 0,
      totalReceivedAmount: '0.0',
      totalAcceptedAmount: '0.0',
      totalRejectedAmount: '0.0',
      taxableAmount: '0.0',
      taxAmount: '0.0',
      cgstAmount: '0.0',
      sgstAmount: '0.0',
      igstAmount: '0.0',
      vendorInvoiceS3Url: vendorInvoiceS3Url,
      vendorId: po.vendor.id,
      vendorName: po.vendor.firmName,
      vendorType: 'manufacturer',
      nodeId: 8,
      nodeName: 'Katedhan Warehouse',
      purchaseOrderId: po.id,
      purchaseOrderNumber: po.purchaseOrderNumber,
      createdById: 14,
      createdByName: 'lounghminghsakal',
      createdByEmail: 'lounghminghsakal@flaerhomes.com',
      lineItems: [],
    );

    _grns.add(newGrn);
    return newGrn;
  }

  Future<GrnModel> updateGrnLineItems(int grnId, List<GrnLineItemModel> newLineItems) async {
    await Future.delayed(const Duration(milliseconds: 200));
    int totRecQty = 0;
    double totRecAmt = 0.0;

    for (final li in newLineItems) {
      totRecQty += li.receivedQuantity;
      final price = double.tryParse(li.unitPrice) ?? 1000.0;
      totRecAmt += li.receivedQuantity * price;
    }

    final index = _grns.indexWhere((g) => g.id == grnId);
    if (index != -1) {
      final old = _grns[index];
      final updated = old.copyWith(
        lineItems: newLineItems,
        totalReceivedQuantity: totRecQty,
        totalAcceptedQuantity: 0,
        totalRejectedQuantity: 0,
        totalReceivedAmount: totRecAmt.toStringAsFixed(1),
        totalAcceptedAmount: '0.0',
        totalRejectedAmount: '0.0',
        finalAmount: 0.0,
      );
      _grns[index] = updated;
      return updated;
    }
    throw Exception('GRN not found');
  }

  Future<GrnModel> updateGrnStatus(int grnId, String newStatus) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _grns.indexWhere((g) => g.id == grnId);
    if (index != -1) {
      final old = _grns[index];
      List<GrnLineItemModel> updatedLi = old.lineItems;
      int totAccQty = old.totalAcceptedQuantity;
      int totRejQty = old.totalRejectedQuantity;
      double totAccAmt = double.tryParse(old.totalAcceptedAmount) ?? 0.0;
      double totRejAmt = double.tryParse(old.totalRejectedAmount) ?? 0.0;
      double finalAmt = old.finalAmount;

      if (newStatus == 'qc_pending' && old.status == 'created') {
        // Initialize accepted = received by default when entering QC
        updatedLi = old.lineItems.map((li) {
          final price = double.tryParse(li.unitPrice) ?? 1000.0;
          final recAmt = li.receivedQuantity * price;
          return li.copyWith(
            acceptedQuantity: li.receivedQuantity,
            rejectedQuantity: 0,
            receivedAmount: recAmt.toStringAsFixed(1),
            acceptedAmount: recAmt.toStringAsFixed(1),
            rejectedAmount: '0.0',
            finalAmount: recAmt,
            acceptedBatches: li.receivedBatches,
            acceptedSerials: li.receivedSerials,
            rejectedBatches: [],
            rejectedSerials: [],
          );
        }).toList();

        totAccQty = old.totalReceivedQuantity;
        totRejQty = 0;
        totAccAmt = double.tryParse(old.totalReceivedAmount) ?? 0.0;
        totRejAmt = 0.0;
        finalAmt = totAccAmt;
       }

      final updated = old.copyWith(
        status: newStatus,
        lineItems: updatedLi,
        totalAcceptedQuantity: totAccQty,
        totalRejectedQuantity: totRejQty,
        totalAcceptedAmount: totAccAmt.toStringAsFixed(1),
        totalRejectedAmount: totRejAmt.toStringAsFixed(1),
        finalAmount: finalAmt,
      );
      _grns[index] = updated;
      return updated;
    }
    throw Exception('GRN not found');
  }

  Future<GrnModel> submitGrnQc(int grnId, List<GrnLineItemModel> qcLineItems) async {
    await Future.delayed(const Duration(milliseconds: 200));
    int totAccQty = 0;
    int totRejQty = 0;
    double totAccAmt = 0.0;
    double totRejAmt = 0.0;
    double totTaxable = 0.0;
    double totTax = 0.0;

    final updatedLi = qcLineItems.map((li) {
      final price = double.tryParse(li.unitPrice) ?? 1000.0;
      final accAmt = li.acceptedQuantity * price;
      final rejAmt = li.rejectedQuantity * price;
      final taxable = accAmt / 1.18;
      final tax = accAmt - taxable;

      totAccQty += li.acceptedQuantity;
      totRejQty += li.rejectedQuantity;
      totAccAmt += accAmt;
      totRejAmt += rejAmt;
      totTaxable += taxable;
      totTax += tax;

      return li.copyWith(
        acceptedAmount: accAmt.toStringAsFixed(1),
        rejectedAmount: rejAmt.toStringAsFixed(1),
        taxableAmount: taxable.toStringAsFixed(2),
        taxAmount: tax.toStringAsFixed(2),
        igstAmount: tax.toStringAsFixed(2),
        cgstAmount: '0.0',
        sgstAmount: '0.0',
        finalAmount: accAmt,
      );
    }).toList();

    final index = _grns.indexWhere((g) => g.id == grnId);
    if (index != -1) {
      final old = _grns[index];
      final updated = old.copyWith(
        lineItems: updatedLi,
        totalAcceptedQuantity: totAccQty,
        totalRejectedQuantity: totRejQty,
        totalAcceptedAmount: totAccAmt.toStringAsFixed(1),
        totalRejectedAmount: totRejAmt.toStringAsFixed(1),
        taxableAmount: totTaxable.toStringAsFixed(1),
        taxAmount: totTax.toStringAsFixed(1),
        igstAmount: totTax.toStringAsFixed(1),
        cgstAmount: '0.0',
        sgstAmount: '0.0',
        finalAmount: totAccAmt,
      );
      _grns[index] = updated;
      return updated;
    }
    throw Exception('GRN not found');
  }

  Future<bool> checkSerialExists(String serialNumber) async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (serialNumber.trim().toUpperCase().startsWith('EXIST')) {
      return true;
    }
    return false;
  }

  Future<List<PoSkuItemModel>> getPurchaseOrderSkuItems(int poId) async {
    // Simulated API call with delay as requested
    await Future.delayed(const Duration(milliseconds: 300));

    return [
      const PoSkuItemModel(
        id: 456,
        productSkuId: 1,
        skuName: "Commercial Plywood MR Grade - 6mm 8x4",
        skuCode: "10010010000100000",
        totalUnits: 50,
        selectionType: "LIFO",
        trackingType: "batch",
        fulfilledQuantity: 10,
        fullyFulfilled: false,
      ),
      const PoSkuItemModel(
        id: 457,
        productSkuId: 6,
        skuName: "Commercial Plywood BWR Grade - 6mm 8x4",
        skuCode: "10010010001100000",
        totalUnits: 20,
        selectionType: "FIFO",
        trackingType: "serial",
        fulfilledQuantity: 5,
        fullyFulfilled: false,
      ),
      const PoSkuItemModel(
        id: 458,
        productSkuId: 11,
        skuName: "Commercial Plywood BWP Grade - 6mm 8x4",
        skuCode: "10010010002100000",
        totalUnits: 100,
        selectionType: "FIFO",
        trackingType: "untracked",
        fulfilledQuantity: 20,
        fullyFulfilled: false,
      ),
      const PoSkuItemModel(
        id: 459,
        productSkuId: 144,
        skuName: "Acrylic Fluted MF 958",
        skuCode: "F0201005060110134025",
        totalUnits: 10,
        selectionType: "LIFO",
        trackingType: "serial",
        fulfilledQuantity: 10,
        fullyFulfilled: true,
      ),
    ];
  }

  Future<bool> validateSerial(String serialNumber) async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (serialNumber.trim().toUpperCase().startsWith('EXIST')) {
      return false; // Invalid or already exists
    }
    return true; // Valid serial
  }
}
