import 'package:memo/features/stats/domain/usage.dart';

class FakeUsageRepository implements UsageRepository {
  FakeUsageRepository({this.summary = UsageSummary.empty, this.fail = false});

  final UsageSummary summary;
  final bool fail;
  final recorded = <({int profileId, List<int> ids})>[];

  @override
  Future<void> recordSentence({
    required int profileId,
    required List<int> pictogramIds,
    required DateTime at,
  }) async {
    if (fail) throw StateError('écriture impossible');
    recorded.add((profileId: profileId, ids: pictogramIds));
  }

  @override
  Stream<UsageSummary> watchWeek({
    required int profileId,
    required String lang,
    required DateTime Function() now,
  }) => Stream.value(summary);
}
