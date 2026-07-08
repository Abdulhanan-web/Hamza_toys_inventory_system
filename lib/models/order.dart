class Order {
  final int? id;
  final String orderNo;
  final int clientId;
  final String orderDate;
  final double grandTotal;
  final double paidAmount;
  final double remainingAmount;
  final String status;
  final String remarks;

  Order({
    this.id,
    required this.orderNo,
    required this.clientId,
    required this.orderDate,
    required this.grandTotal,
    required this.paidAmount,
    required this.remainingAmount,
    required this.status,
    required this.remarks,
  });

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "orderNo": orderNo,
      "clientId": clientId,
      "orderDate": orderDate,
      "grandTotal": grandTotal,
      "paidAmount": paidAmount,
      "remainingAmount": remainingAmount,
      "status": status,
      "remarks": remarks,
    };
  }

  factory Order.fromMap(Map<String, dynamic> map) {
    return Order(
      id: map["id"],
      orderNo: map["orderNo"],
      clientId: map["clientId"],
      orderDate: map["orderDate"],
      grandTotal: (map["grandTotal"] as num).toDouble(),
      paidAmount: (map["paidAmount"] as num).toDouble(),
      remainingAmount: (map["remainingAmount"] as num).toDouble(),
      status: map["status"],
      remarks: map["remarks"],
    );
  }

  Order copyWith({
    int? id,
    String? orderNo,
    int? clientId,
    String? orderDate,
    double? grandTotal,
    double? paidAmount,
    double? remainingAmount,
    String? status,
    String? remarks,
  }) {
    return Order(
      id: id ?? this.id,
      orderNo: orderNo ?? this.orderNo,
      clientId: clientId ?? this.clientId,
      orderDate: orderDate ?? this.orderDate,
      grandTotal: grandTotal ?? this.grandTotal,
      paidAmount: paidAmount ?? this.paidAmount,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      status: status ?? this.status,
      remarks: remarks ?? this.remarks,
    );
  }
}