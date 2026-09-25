/// Typed reads for API JSON. A wrong type throws [TypeError] and a bad date
/// throws [FormatException]; `runApiCall` maps both to `UnexpectedFailure`.
extension JsonRead on Map<String, dynamic> {
  String str(String key) => this[key] as String;

  String? strOrNull(String key) => this[key] as String?;

  num number(String key) => this[key] as num;

  num? numberOrNull(String key) => this[key] as num?;

  double? decimalOrNull(String key) => (this[key] as num?)?.toDouble();

  int integer(String key) => (this[key] as num).toInt();

  bool flag(String key) => this[key] as bool? ?? false;

  DateTime date(String key) => DateTime.parse(this[key] as String).toLocal();

  Map<String, dynamic> obj(String key) => this[key] as Map<String, dynamic>;

  Map<String, dynamic>? objOrNull(String key) =>
      this[key] as Map<String, dynamic>?;

  List<T> list<T>(String key, T Function(Map<String, dynamic> json) parse) => [
    for (final item in (this[key] as List<dynamic>? ?? const []))
      parse(item as Map<String, dynamic>),
  ];

  List<String> strings(String key) => [
    for (final item in (this[key] as List<dynamic>? ?? const []))
      item as String,
  ];

  List<num> numbers(String key) => [
    for (final item in (this[key] as List<dynamic>? ?? const [])) item as num,
  ];
}

/// Parses a JSON array body.
List<T> parseList<T>(
  List<dynamic> data,
  T Function(Map<String, dynamic> json) parse,
) => [for (final item in data) parse(item as Map<String, dynamic>)];
