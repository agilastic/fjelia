# Activity input for the biological-age estimate

The activity factor uses the seven calendar dates ending today. Each date
contributes one input:

1. A reported moderate-minutes value takes priority, including an explicit zero.
2. If minutes are absent, a non-negative step count substitutes an **estimated
   walking duration**: steps / 100.
3. If neither exists, that date is unknown. The activity factor is omitted until
   all seven dates have an input; missing days are never treated as zero activity
   or extrapolated into a full week.

Daily step estimates are not added to reported minutes from the same date.
Training durations and vigorous minutes are not added by this change. The
existing activity curve and its 600-minute reference are retained.

The card distinguishes reported minutes, estimated walking minutes and coverage.
An activity contribution using step estimates has an approximation mark. The
estimated walking minutes only inform this activity factor; they do not also
feed the non-exercise VO2max estimate, and are not written back as recorded
wellness minutes.

The 100-steps/minute assumption is informed by the
[CADENCE-Adults study](https://pubmed.ncbi.nlm.nih.gov/33168018/), which studied
actual walking cadence and intensity. **A daily step total does not measure
cadence or establish moderate intensity.** Applying the assumption to a total is
a fallback heuristic, not a validated conversion of arbitrary daily steps into
moderate minutes or personal life expectancy. It does not validate the existing
biological-age model or its conversion to years.
