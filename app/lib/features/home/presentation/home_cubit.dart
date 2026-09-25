import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../core/utils/data_state.dart';
import '../domain/home_entities.dart';
import '../domain/home_repository.dart';

@injectable
class HomeCubit extends Cubit<DataState<HomeDashboard>> {
  HomeCubit(this._getDashboard) : super(const DataState());

  final GetHomeDashboard _getDashboard;

  Future<void> load() async {
    emit(DataState.loading(data: state.data));
    emit(DataState.fromResult(await _getDashboard()));
  }
}
