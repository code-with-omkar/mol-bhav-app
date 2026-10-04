import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mol_bhav/features/monetization/presentation/ads/ad_interleave.dart';

class _Group extends StatelessWidget {
  const _Group(this.rows);

  final List<Widget> rows;

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class _Ad extends StatelessWidget {
  const _Ad(this.index);

  final int index;

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

List<Widget> _rows(int n) => [for (var i = 0; i < n; i++) Text('$i')];

List<Widget> _layout(int rows) =>
    interleaveAds(rows: _rows(rows), every: 8, group: _Group.new, ad: _Ad.new);

void main() {
  test('a short list gets no ad', () {
    final out = _layout(8);

    expect(out.whereType<_Ad>(), isEmpty);
    expect(out.single, isA<_Group>());
  });

  test('one ad between two groups', () {
    final out = _layout(9).where((w) => w is _Group || w is _Ad).toList();

    expect(out.map((w) => w.runtimeType), [_Group, _Ad, _Group]);
    expect((out.first as _Group).rows, hasLength(8));
    expect((out.last as _Group).rows, hasLength(1));
  });

  test('one ad per 8 rows, never after the last group', () {
    final ads = _layout(24).whereType<_Ad>().toList();

    expect(ads.map((a) => a.index), [0, 1]);
  });

  test('an empty list yields nothing', () {
    expect(_layout(0), isEmpty);
  });

  test('caps the ads in a long list', () {
    final ads = _layout(100).whereType<_Ad>().toList();

    expect(ads, hasLength(2));
    // Groups still split every 8 rows; only the ads stop.
    expect(_layout(100).whereType<_Group>(), hasLength(13));
  });
}
