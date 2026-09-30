import 'package:equatable/equatable.dart';

/// Everything one shared price card shows, gathered by the screen that shares
/// it so the card widget and the message text stay in step.
class PriceShareData extends Equatable {
  const PriceShareData({
    required this.productName,
    required this.mandiName,
    required this.modalPrice,
    required this.unitSymbol,
    required this.recordDate,
    required this.source,
    required this.link,
    this.variantName,
    this.minPrice,
    this.maxPrice,
  });

  final String productName;

  /// Variety, when the price is for one.
  final String? variantName;
  final String mandiName;

  /// Null when the source reported only a modal price.
  final num? minPrice;
  final num? maxPrice;
  final num modalPrice;
  final String unitSymbol;
  final DateTime recordDate;
  final String source;

  /// Deep link to this product/mandi, or the store link while deep linking
  /// is off (see `DeepLinkConfig`).
  final String link;

  /// `Onion · Nashik Red` — the heading on the card and in the message.
  String get title =>
      variantName == null ? productName : '$productName · $variantName';

  bool get hasRange => minPrice != null && maxPrice != null;

  @override
  List<Object?> get props => [
    productName,
    variantName,
    mandiName,
    minPrice,
    maxPrice,
    modalPrice,
    unitSymbol,
    recordDate,
    source,
    link,
  ];
}
