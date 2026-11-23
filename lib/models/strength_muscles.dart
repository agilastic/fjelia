/// Muscle groups a built-in exercise trains, shown in the exercise details.
/// Coarse on purpose: the groups a coach would name, not single muscles.
enum StrengthMuscle {
  quads,
  hamstrings,
  glutes,
  calves,
  adductors,
  core,
  obliques,
  lowerBack,
  lats,
  upperBack,
  chest,
  shoulders,
  triceps,
  biceps,
  forearms,
}

typedef StrengthMuscles = ({
  List<StrengthMuscle> primary,
  List<StrengthMuscle> secondary,
});

const _q = StrengthMuscle.quads, _h = StrengthMuscle.hamstrings;
const _g = StrengthMuscle.glutes, _ca = StrengthMuscle.calves;
const _ad = StrengthMuscle.adductors, _co = StrengthMuscle.core;
const _ob = StrengthMuscle.obliques, _lb = StrengthMuscle.lowerBack;
const _la = StrengthMuscle.lats, _ub = StrengthMuscle.upperBack;
const _ch = StrengthMuscle.chest, _sh = StrengthMuscle.shoulders;
const _tr = StrengthMuscle.triceps, _bi = StrengthMuscle.biceps;
const _fa = StrengthMuscle.forearms;

/// Per built-in variant id (`builtInStrengthVariants`). The athlete's own
/// exercises have none: nothing is guessed from a name.
const _muscles = <String, StrengthMuscles>{
  'back_squat': (primary: [_q, _g], secondary: [_ad, _lb, _co]),
  'front_squat': (primary: [_q], secondary: [_g, _co, _ub]),
  'goblet_squat': (primary: [_q, _g], secondary: [_co]),
  'deadlift': (primary: [_g, _h, _lb], secondary: [_q, _ub, _fa]),
  'romanian_deadlift': (primary: [_h, _g], secondary: [_lb, _fa]),
  'bench_press': (primary: [_ch], secondary: [_tr, _sh]),
  'db_bench_press': (primary: [_ch], secondary: [_tr, _sh]),
  'overhead_press': (primary: [_sh], secondary: [_tr, _ub, _co]),
  'barbell_row': (primary: [_ub, _la], secondary: [_bi, _lb]),
  'db_row': (primary: [_la, _ub], secondary: [_bi]),
  'pull_up': (primary: [_la], secondary: [_bi, _ub, _fa]),
  'push_up': (primary: [_ch], secondary: [_tr, _sh, _co]),
  'walking_lunge': (primary: [_q, _g], secondary: [_h, _ad, _ca]),
  'split_squat': (primary: [_q, _g], secondary: [_h, _ad]),
  'calf_raise': (primary: [_ca], secondary: []),
  'leg_press': (primary: [_q, _g], secondary: [_h]),
  'barbell_curl': (primary: [_bi], secondary: [_fa]),
  'hip_thrust': (primary: [_g], secondary: [_h]),
  'step_up': (primary: [_q, _g], secondary: [_ca]),
  'single_leg_rdl': (primary: [_h, _g], secondary: [_lb, _co]),
  'step_down': (primary: [_q], secondary: [_g]),
  'leg_curl': (primary: [_h], secondary: [_ca]),
  'lat_pulldown': (primary: [_la], secondary: [_bi, _ub]),
  'jump_squat': (primary: [_q, _g], secondary: [_ca]),
  'plank': (primary: [_co], secondary: [_sh, _g]),
  'side_plank': (primary: [_ob], secondary: [_co, _g]),
  'dead_bug': (primary: [_co], secondary: [_ob]),
  'bird_dog': (primary: [_co, _lb], secondary: [_g, _sh]),
  'pallof_press': (primary: [_ob, _co], secondary: [_sh]),
};

/// The muscles [variantId] trains, or null for an exercise without data.
StrengthMuscles? strengthMusclesOf(String variantId) => _muscles[variantId];
