import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'app_language.dart';
import 'locale_repository.dart';

/// App-wide UI language. Changing it rebuilds the app in that locale.
@lazySingleton
class LocaleCubit extends Cubit<AppLanguage> {
  LocaleCubit(this._repository) : super(_repository.current);

  final LocaleRepository _repository;

  Future<void> select(AppLanguage language) async {
    if (language == state) return;
    emit(language);
    await _repository.save(language);
  }
}
