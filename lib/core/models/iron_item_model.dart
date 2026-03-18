class IronItem {
  final String clothType;
  final int quantity;
  final int pricePerUnit;

  IronItem({
    required this.clothType,
    required this.quantity,
    required this.pricePerUnit,
  });

  factory IronItem.fromJson(Map<String, dynamic> json) {
    return IronItem(
      clothType: json["clothType"],
      quantity: json["quantity"],
      pricePerUnit: json["pricePerUnit"],
    );
  }
}