import 'package:injectable/injectable.dart';

import '../../../core/error/result.dart';
import 'home_entities.dart';

abstract interface class HomeRepository {
  Future<Result<HomeDashboard>> getDashboard();
}

@injectable
class GetHomeDashboard {
  const GetHomeDashboard(this._repository);

  final HomeRepository _repository;

  Future<Result<HomeDashboard>> call() => _repository.getDashboard();
}
