import 'report_summary.dart';

abstract class ReportService {
  Future<ReportSummary> reportSummary({
    required String businessId,
    required DateTime from,
    required DateTime to,
  });
}
