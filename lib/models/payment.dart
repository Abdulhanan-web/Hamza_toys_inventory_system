class Payment {
  final int? id;
  final int clientId;
  final double amount;
  final String date; // Format: yyyy-MM-dd HH:mm:ss
  final String notes;

  Payment({
    this.id,
    required this.clientId,
    required this.amount,
    required this.date,
    this.notes = "",
  });

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "clientId": clientId,
      "amount": amount,
      "date": date,
      "notes": notes,
    };
  }

  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map["id"],
      clientId: map["clientId"],
      amount: (map["amount"] as num).toDouble(),
      date: map["date"],
      notes: map["notes"] ?? "",
    );
  }
}
