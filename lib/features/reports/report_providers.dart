import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import 'report_service.dart';
import 'export_service.dart';
import 'report_summary.dart';

final reportServiceProvider = Provider<ReportService>((ref) {
  throw UnimplementedError('reportServiceProvider belum di-override');
});

final reportSummaryProvider =
    FutureProvider.family<ReportSummary, ({DateTime from, DateTime to})>((
      ref,
      range,
    ) async {
      final biz = await ref.watch(currentBusinessProvider.future);
      if (biz == null) {
        return ReportSummary.empty(from: range.from, to: range.to);
      }
      return ref
          .watch(reportServiceProvider)
          .reportSummary(businessId: biz.id, from: range.from, to: range.to);
    });

final exportServiceProvider = Provider<ExportService>(
  (ref) => const DefaultExportService(),
);
