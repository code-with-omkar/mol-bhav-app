import 'package:flutter/widgets.dart';

import '../../../core/di/injection.dart';
import '../../../core/error/result.dart';
import '../domain/catalog.dart';

/// Shows [child] only while the catalog has the category [code]. Used for
/// entries that belong to one category (Suppliers belong to Construction), so
/// they disappear when it is removed and return when it is added again.
class WhenCategory extends StatefulWidget {
  const WhenCategory({super.key, required this.code, required this.child});

  final String code;
  final Widget child;

  @override
  State<WhenCategory> createState() => _WhenCategoryState();
}

class _WhenCategoryState extends State<WhenCategory> {
  late final Future<bool> _present = _check();

  Future<bool> _check() async {
    if (!getIt.isRegistered<CatalogRepository>()) return false;
    final result = await getIt<CatalogRepository>().getCategories();
    return switch (result) {
      Ok(:final value) => value.any((c) => c.code == widget.code),
      Err() => false,
    };
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<bool>(
    future: _present,
    builder: (context, snapshot) =>
        snapshot.data ?? false ? widget.child : const SizedBox.shrink(),
  );
}
