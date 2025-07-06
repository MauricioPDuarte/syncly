import '../entities/sync_error.dart';
import '../entities/sync_error_report_result.dart';

/// Interface para envio de erros para o backend
abstract class ISyncErrorReporter {
  Future<SyncErrorReportResult> sendPendingErrors();
  Future<SyncErrorReportResult> sendError(SyncError error);
  Future<SyncErrorReportResult> sendErrors(List<SyncError> errors);
  Future<void> scheduleErrorReporting();
}