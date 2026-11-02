import 'package:supabase_flutter/supabase_flutter.dart';

import 'report_service.dart';
import 'report_summary.dart';

class SupabaseReportService implements ReportService {
  SupabaseReportService(this._client);
  final SupabaseClient _client;

  String _dateStr(DateTime d) => d.toIso8601String().substring(0, 10);

  @override
  Future<ReportSummary> reportSummary({
    required String businessId,
    required DateTime from,
    required DateTime to,
  }) async {
    final json = await _client.rpc(
      'report_summary',
      params: {
        'p_business_id': businessId,
        'p_from': _dateStr(from),
        'p_to': _dateStr(to),
      },
    );
    return ReportSummary.fromJson(json as Map<String, dynamic>);
  }
}
