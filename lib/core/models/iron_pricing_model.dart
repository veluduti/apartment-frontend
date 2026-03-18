class IronPricing {
  final String clothType;
  final int price;

  IronPricing({
    required this.clothType,
    required this.price,
  });

  factory IronPricing.fromJson(Map<String, dynamic> json) {
    return IronPricing(
      clothType: json["clothType"],
      price: json["price"],
    );
  }
}