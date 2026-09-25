import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/result.dart';
import '../../../core/network/api_call.dart';
import '../../../core/network/json.dart';
import '../domain/tools.dart';

/// Tools endpoints:
///
/// - `GET /estimator/options` → `{ categories: [{ id, name }],
///   materials: [{ id, name, categoryCode, units: [{ id, name }] }],
///   locations: [{ id, name }] }`
/// - `POST /estimator/estimate` with `{ materialId, quantity, unitId,
///   locationId }` → `{ estimatedCost, quantity, unitName, priceUnit,
///   lowestPrice, lowestSourceName, averagePrice, savings, source, updatedAt,
///   benchmarks: [{ name, meta, price, isLowest }] }`
/// - `POST /estimator/estimates` with the same body saves it.
/// - `GET /reports` → `{ currentWeek: { start, end, potentialSavings,
///   watchlistCount, alertCount, opportunityCount, language } | null,
///   weekly: [{ id, start, end, language, pages }],
///   exports: [{ id, title, subtitle, isLocked }] }`
abstract interface class ToolsRemoteDataSource {
  Future<Map<String, dynamic>> getEstimatorOptions();

  Future<Map<String, dynamic>> estimate(Map<String, dynamic> body);

  Future<void> saveEstimate(Map<String, dynamic> body);

  Future<Map<String, dynamic>> getReports();
}

@LazySingleton(as: ToolsRemoteDataSource)
class DioToolsRemoteDataSource implements ToolsRemoteDataSource {
  DioToolsRemoteDataSource(this._dio);

  final Dio _dio;

  @override
  Future<Map<String, dynamic>> getEstimatorOptions() async =>
      (await _dio.get<Map<String, dynamic>>('/estimator/options')).data!;

  @override
  Future<Map<String, dynamic>> estimate(Map<String, dynamic> body) async =>
      (await _dio.post<Map<String, dynamic>>(
        '/estimator/estimate',
        data: body,
      )).data!;

  @override
  Future<void> saveEstimate(Map<String, dynamic> body) =>
      _dio.post<void>('/estimator/estimates', data: body);

  @override
  Future<Map<String, dynamic>> getReports() async =>
      (await _dio.get<Map<String, dynamic>>('/reports')).data!;
}

@LazySingleton(as: ToolsRepository)
class ToolsRepositoryImpl implements ToolsRepository {
  ToolsRepositoryImpl(this._remote);

  final ToolsRemoteDataSource _remote;

  static NamedOption _option(Map<String, dynamic> j) =>
      NamedOption(id: j.str('id'), name: j.str('name'));

  static Map<String, dynamic> _body(EstimateRequest r) => {
    'materialId': r.materialId,
    'quantity': r.quantity,
    'unitId': r.unitId,
    'locationId': r.locationId,
  };

  @override
  Future<Result<EstimatorOptions>> getEstimatorOptions() =>
      runApiCall(() async {
        final j = await _remote.getEstimatorOptions();
        return EstimatorOptions(
          categories: j.list('categories', _option),
          materials: j.list(
            'materials',
            (m) => EstimatorMaterial(
              id: m.str('id'),
              name: m.str('name'),
              categoryCode: m.str('categoryCode'),
              units: m.list('units', _option),
            ),
          ),
          locations: j.list('locations', _option),
        );
      });

  @override
  Future<Result<Estimate>> estimate(EstimateRequest request) =>
      runApiCall(() async {
        final j = await _remote.estimate(_body(request));
        return Estimate(
          estimatedCost: j.number('estimatedCost'),
          quantity: j.number('quantity'),
          unitName: j.str('unitName'),
          priceUnit: j.str('priceUnit'),
          lowestPrice: j.number('lowestPrice'),
          lowestSourceName: j.str('lowestSourceName'),
          averagePrice: j.number('averagePrice'),
          savings: j.number('savings'),
          benchmarks: j.list(
            'benchmarks',
            (b) => Benchmark(
              name: b.str('name'),
              meta: b.strOrNull('meta'),
              price: b.number('price'),
              isLowest: b.flag('isLowest'),
            ),
          ),
          source: j.str('source'),
          updatedAt: j.date('updatedAt'),
        );
      });

  @override
  Future<Result<void>> saveEstimate(EstimateRequest request) =>
      runApiCall(() => _remote.saveEstimate(_body(request)));

  @override
  Future<Result<ReportsOverview>> getReports() => runApiCall(() async {
    final j = await _remote.getReports();
    final week = j.objOrNull('currentWeek');
    return ReportsOverview(
      currentWeek: week == null
          ? null
          : WeekSummary(
              start: week.date('start'),
              end: week.date('end'),
              potentialSavings: week.number('potentialSavings'),
              watchlistCount: week.integer('watchlistCount'),
              alertCount: week.integer('alertCount'),
              opportunityCount: week.integer('opportunityCount'),
              language: week.str('language'),
            ),
      weekly: j.list(
        'weekly',
        (w) => WeeklyReport(
          id: w.str('id'),
          start: w.date('start'),
          end: w.date('end'),
          language: w.str('language'),
          pages: w.integer('pages'),
        ),
      ),
      exports: j.list(
        'exports',
        (e) => ExportItem(
          id: e.str('id'),
          title: e.str('title'),
          subtitle: e.strOrNull('subtitle'),
          isLocked: e.flag('isLocked'),
        ),
      ),
    );
  });
}
