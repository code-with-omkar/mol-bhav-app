import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../cache/response_cache.dart';
import 'app_language.dart';
import 'locale_repository.dart';

/// App-wide UI language. Changing it rebuilds the app in that locale.
@lazySingleton
class LocaleCubit extends Cubit<AppLanguage> {
  LocaleCubit(this._repository, this._cache) : super(_repository.current);

  final LocaleRepository _repository;
  final ResponseCache _cache;

  Future<void> select(AppLanguage language) async {
    if (language == state) return;
    // Saved before emitting: listeners refetch at once, and requests read
    // the language for `Accept-Language` from the repository.
    await _repository.save(language);
    // The API localises names, so cached bodies are for the old language.
    await _cache.clear();
    emit(language);
  }
}
