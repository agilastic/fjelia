import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fjelia_service_api/fjelia_service_api.dart';
import '../services/blood_pressure_chart_data.dart';
import 'database_provider.dart';
import 'day_data_provider.dart';

final bloodPressureInsightsProvider=FutureProvider.family<
  ({DailyBpSummary? summary,List<BpVariationBucket> buckets}),
  ({DateTime start,DateTime end,BpPeriod period})>((ref,request) async {
  if(request.period==BpPeriod.day) ref.watch(bpSummaryForDateProvider(request.start));
  final rows=request.period==BpPeriod.day
    ? await ref.watch(bpForDateProvider(request.start).future)
    : await ref.watch(bpPeriodReadingsProvider((start:request.start,end:request.end)).future);
  final buckets=bpVariationBuckets(rows,request.start,request.end,request.period);
  if(request.period==BpPeriod.day){
    final workouts=await ref.watch(databaseProvider).getActivitiesForDate(request.start);
    markBpDayBuckets(buckets,[
      for(final a in workouts) (start:a.startDate.toLocal(),duration:Duration(seconds:a.durationSeconds)),
    ],DateTime.now());
  }
  return (summary:buildBpSummaryFromRecords(request.start,rows),buckets:buckets);
});
