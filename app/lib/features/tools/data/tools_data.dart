import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/result.dart';
import '../../../core/network/api_call.dart';
import '../../../core/network/json.dart';
import '../domain/tools.dart';

/// Cost estimates on the Procurement module:
///
/// - `POST /procurement/requirements` `{ productId, quantity, unitId, targetDistrictId? }` → `{ id }`
/// - `POST /procurement/requirements/{id}/opportunities` → cheapest-first
///   `[{ locationKind, locationName, unitPrice, estimatedCost, priceRecordDate, … }]`
/// - `GET /procurement/requirements` → saved requirements
/// - `DELETE /procurement/requirements/{id}`
@LazySingleton(as: EstimatorRepository)
class EstimatorRepositoryImpl implements EstimatorRepository {
  EstimatorRepositoryImpl(this._dio);

  final Dio _dio;

  static const _path = '/procurement/requirements';

  @override
  Future<Result<Estimate>> estimate(EstimateRequest request) async {
    final created = await runApiCall(() async {
      final body = (await _dio.post<Map<String, dynamic>>(
        _path,
        data: {
          'productId': request.materialId,
          'quantity': request.quantity,
          'unitId': request.unitId,
          'targetDistrictId': request.districtId,
        },
      )).data!;
      return body.str('id');
    });
    return switch (created) {
      Ok(value: final id) => _price(id),
      Err(:final failure) => Err(failure),
    };
  }

  @override
  Future<Result<Estimate>> reprice(SavedEstimate saved) => _price(saved.id);

  /// Prices [requirementId]; a requirement no location can price is deleted
  /// again so it doesn't linger as a saved estimate.
  Future<Result<Estimate>> _price(String requirementId) async {
    final result = await runApiCall(() async {
      final rows = parseList(
        (await _dio.post<List<dynamic>>(
              '$_path/${Uri.encodeComponent(requirementId)}/opportunities',
            )).data ??
            const [],
        (j) => j,
      );
      return rows.isEmpty ? null : _estimate(requirementId, rows);
    });
    return switch (result) {
      Ok(value: final Estimate estimate) => Ok(estimate),
      Ok() => await _deleteThen(requirementId, const NoPricesFailure()),
      Err(:final failure) => Err(failure),
    };
  }

  Future<Result<Estimate>> _deleteThen(
    String id,
    NoPricesFailure failure,
  ) async {
    await delete(id);
    return Err(failure);
  }

  static Estimate _estimate(String id, List<Map<String, dynamic>> rows) {
    final best = rows.first;
    final prices = [for (final r in rows) r.number('unitPrice')];
    final average = prices.reduce((a, b) => a + b) / prices.length;
    final quantity = best.number('quantity');
    return Estimate(
      requirementId: id,
      estimatedCost: best.number('estimatedCost'),
      quantity: quantity,
      lowestPrice: best.number('unitPrice'),
      lowestSourceName: best.str('locationName'),
      averagePrice: average,
      savings: (average - best.number('unitPrice')) * quantity,
      benchmarks: [
        for (final (i, r) in rows.indexed)
          Benchmark(
            name: r.str('locationName'),
            price: r.number('unitPrice'),
            isLowest: i == 0,
            recordDate: DateTime.parse(r.str('priceRecordDate')),
          ),
      ],
      updatedAt: DateTime.parse(best.str('priceRecordDate')),
    );
  }

  @override
  Future<Result<List<SavedEstimate>>> getSaved() => runApiCall(
    () async =>
        parseList((await _dio.get<List<dynamic>>(_path)).data ?? const [], (j) {
          final product = j.obj('product');
          final variant = j.strOrNull('variantName');
          return SavedEstimate(
            id: j.str('id'),
            productId: product.str('id'),
            productName: variant == null
                ? product.str('name')
                : '${product.str('name')} · $variant',
            quantity: j.number('quantity'),
            unitSymbol: j.obj('unit').str('symbol'),
            districtName: j.strOrNull('targetDistrictName'),
            createdAt: j.date('createdAtUtc'),
          );
        }),
  );

  @override
  Future<Result<void>> delete(String requirementId) => runApiCall(
    () => _dio.delete<void>('$_path/${Uri.encodeComponent(requirementId)}'),
  );
}

/// Reports:
///
/// - `GET /reports?pageSize=` → `[ReportResponse]`
/// - `POST /reports` `{ reportType, format, parameters }` → `{ id }`; 403 `Report.ProRequired`
/// - `GET /reports/{id}` → status
/// - `GET /reports/{id}/download` → the file
@LazySingleton(as: ReportsRepository)
class ReportsRepositoryImpl implements ReportsRepository {
  ReportsRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Result<List<GeneratedReport>>> getReports() => runApiCall(
    () async => parseList(
      (await _dio.get<List<dynamic>>(
            '/reports',
            queryParameters: {'pageSize': 50},
          )).data ??
          const [],
      _report,
    ),
  );

  @override
  Future<Result<String>> request(ReportRequest request) => runApiCall(
    () async {
      final (type, format) = switch (request.kind) {
        ReportKind.weeklySummary => ('WeeklySummary', 'Pdf'),
        ReportKind.priceHistoryCsv => ('PriceHistory', 'Csv'),
      };
      final body = (await _dio.post<Map<String, dynamic>>(
        '/reports',
        data: {
          'reportType': type,
          'format': format,
          'parameters': {
            'fromDate': _day(request.from),
            'toDate': _day(request.to),
            'language': request.language,
            'productId': ?request.productId,
            'mandiId': ?request.mandiId,
          },
        },
      )).data!;
      return body.str('id');
    },
    mapError: (e) =>
        e.response?.statusCode == 403 ? const ProRequiredFailure() : null,
  );

  @override
  Future<Result<GeneratedReport>> getReport(String id) => runApiCall(
    () async => _report(
      (await _dio.get<Map<String, dynamic>>(
        '/reports/${Uri.encodeComponent(id)}',
      )).data!,
    ),
  );

  @override
  Future<Result<DownloadedFile>> download(String id) => runApiCall(() async {
    final response = await _dio.get<List<int>>(
      '/reports/${Uri.encodeComponent(id)}/download',
      options: Options(responseType: ResponseType.bytes),
    );
    final mimeType =
        response.headers.value(Headers.contentTypeHeader) ??
        'application/octet-stream';
    return DownloadedFile(
      name:
          _fileName(response.headers.value('content-disposition')) ??
          'molbhav-report-$id${mimeType.contains('csv') ? '.csv' : '.pdf'}',
      mimeType: mimeType.split(';').first.trim(),
      bytes: Uint8List.fromList(response.data!),
    );
  });

  static GeneratedReport _report(Map<String, dynamic> j) => GeneratedReport(
    id: j.str('id'),
    kind: switch ((j.str('reportType'), j.str('format'))) {
      ('WeeklySummary', 'Pdf') => ReportKind.weeklySummary,
      ('PriceHistory', 'Csv') => ReportKind.priceHistoryCsv,
      _ => null,
    },
    status: switch (j.str('status')) {
      'Ready' => ReportStatus.ready,
      'Failed' => ReportStatus.failed,
      _ => ReportStatus.pending,
    },
    requestedAt: j.date('requestedAtUtc'),
    completedAt: j.dateOrNull('completedAtUtc'),
    lastDownloadedAt: j.dateOrNull('lastDownloadedAtUtc'),
    failureReason: j.strOrNull('failureReason'),
  );

  /// `attachment; filename=a.pdf; filename*=UTF-8''a.pdf` → `a.pdf`.
  static String? _fileName(String? disposition) {
    if (disposition == null) return null;
    final encoded = RegExp(
      r"filename\*=UTF-8''([^;]+)",
      caseSensitive: false,
    ).firstMatch(disposition);
    if (encoded != null) return Uri.decodeComponent(encoded.group(1)!);
    final plain = RegExp(
      r'filename="?([^";]+)"?',
      caseSensitive: false,
    ).firstMatch(disposition);
    return plain?.group(1);
  }

  static String _day(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
