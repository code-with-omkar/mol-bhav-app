import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mol_bhav/core/error/failure.dart';
import 'package:mol_bhav/core/error/result.dart';
import 'package:mol_bhav/core/session/session_manager.dart';
import 'package:mol_bhav/features/watchlist/domain/watchlist.dart';
import 'package:mol_bhav/features/watchlist/presentation/watchlist_cubit.dart';

class _MockRepository extends Mock implements WatchlistRepository {}

class _MockSession extends Mock implements SessionManager {}

/// The star answers the tap at once; the server's answer confirms or undoes it.
void main() {
  late _MockRepository repository;
  late WatchlistCubit cubit;
  late Completer<Result<void>> saving;

  setUp(() {
    repository = _MockRepository();
    saving = Completer<Result<void>>();
    final session = _MockSession();
    when(() => session.hasSession).thenReturn(false);
    when(() => repository.add('p1')).thenAnswer((_) => saving.future);
    cubit = WatchlistCubit(
      WatchWatchlist(repository),
      AddToWatchlist(repository),
      RemoveFromWatchlist(repository),
      session,
    );
  });

  tearDown(() => cubit.close());

  test('the star is filled while the item is being saved', () async {
    final adding = cubit.add('p1');

    expect(cubit.state.isWatched('p1'), isTrue);
    expect(cubit.state.isWatched('p1', variantId: 'v1'), isFalse);

    saving.complete(const Ok<void>(null));
    await adding;
    expect(cubit.state.adding, isEmpty);
  });

  test('a failed save empties the star again', () async {
    final adding = cubit.add('p1');
    saving.complete(const Err<void>(NetworkFailure()));
    await adding;

    expect(cubit.state.isWatched('p1'), isFalse);
  });
}
