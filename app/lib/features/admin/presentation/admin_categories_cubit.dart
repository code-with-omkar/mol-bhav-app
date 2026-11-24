import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../../../core/utils/data_state.dart';
import '../domain/admin_categories.dart';

/// The catalog's categories and sub-categories: add, rename, show or hide.
@injectable
class AdminCategoriesCubit extends Cubit<DataState<List<AdminCategory>>> {
  AdminCategoriesCubit(this._repository) : super(const DataState());

  final AdminCategoriesRepository _repository;

  Future<void> load() async {
    emit(DataState.loading(data: state.data));
    final result = await _repository.getCategories();
    if (isClosed) return;
    emit(DataState.fromResult(result));
  }

  /// Each save returns null on success (the list is reread), else why not.
  Future<Failure?> createCategory(String code, Map<String, String> names) =>
      _then(() => _repository.createCategory(code: code, names: names));

  Future<Failure?> updateCategory(AdminCategory category) =>
      _then(() => _repository.updateCategory(category));

  Future<Failure?> addSubCategory(
    String categoryId,
    String code,
    Map<String, String> names,
  ) => _then(
    () => _repository.addSubCategory(
      categoryId: categoryId,
      code: code,
      names: names,
    ),
  );

  Future<Failure?> updateSubCategory(
    String categoryId,
    AdminSubCategory subCategory,
  ) => _then(
    () => _repository.updateSubCategory(
      categoryId: categoryId,
      subCategory: subCategory,
    ),
  );

  Future<Failure?> _then(Future<Result<void>> Function() save) async {
    final result = await save();
    if (isClosed) return null;
    switch (result) {
      case Err<void>(:final failure):
        return failure;
      case Ok<void>():
        await load();
        return null;
    }
  }
}
