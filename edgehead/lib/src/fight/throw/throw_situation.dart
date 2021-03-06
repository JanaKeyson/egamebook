library stranded.fight.thrust_situation;

import 'package:edgehead/fractal_stories/actor.dart';
import 'package:edgehead/fractal_stories/situation.dart';
import 'package:edgehead/src/fight/common/attacker_situation.dart';
import 'package:edgehead/src/fight/throw/actions/finish_throw_blunt.dart';
import 'package:edgehead/src/fight/throw/actions/finish_throw_thrusting.dart';

const String throwSituationName = "ThrowSituation";

Situation createThrowSituation(int id, Actor attacker, Actor target) {
  return AttackerSituation.initialized(
    id,
    throwSituationName,
    [
      FinishThrowBlunt.singleton,
      FinishThrowThrusting.singleton,
    ],
    [],
    attacker,
    target,
    "throw",
  );
}
