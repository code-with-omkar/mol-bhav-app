import 'mb_category_card.dart';
import 'mb_icons.dart';
import 'mb_price.dart';

/// Line icon for a procurement category, keyed by its stable API `code`.
MbIcons categoryIcon(String code) => switch (code) {
  'agriculture' => MbIcons.agriculture,
  'construction' => MbIcons.construction,
  'manufacturing' => MbIcons.manufacturing,
  'hospitality' => MbIcons.hospitality,
  'pharma' => MbIcons.pharma,
  'retail' => MbIcons.retail,
  _ => MbIcons.others,
};

/// Agriculture green, Construction amber, other live categories navy;
/// not-yet-launched categories grey.
MbCategoryTone categoryTone(String code, {bool available = true}) {
  if (!available) return MbCategoryTone.grey;
  return switch (code) {
    'agriculture' => MbCategoryTone.green,
    'construction' => MbCategoryTone.amber,
    _ => MbCategoryTone.navy,
  };
}

/// Thumb tint for a category: Agriculture green, Construction amber.
MbTone categoryTint(String code) => switch (code) {
  'agriculture' => MbTone.green,
  'construction' => MbTone.amber,
  _ => MbTone.neutral,
};
