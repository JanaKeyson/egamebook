import 'package:edgehead/fractal_stories/action.dart';
import 'package:edgehead/fractal_stories/actor.dart';
import 'package:edgehead/fractal_stories/item.dart';
import 'package:edgehead/fractal_stories/storyline/randomly.dart';
import 'package:edgehead/fractal_stories/storyline/storyline.dart';
import 'package:edgehead/fractal_stories/world.dart';
import 'package:edgehead/src/fight/slash/slash_defense/slash_defense_situation.dart';

class DefensiveParrySlash extends EnemyTargetAction {
  @override
  final String helpMessage = "Stepping back is the safest way to get out of "
      "harm's way.";

  @override
  final bool isAggressive = false;

  DefensiveParrySlash(Actor enemy) : super(enemy);

  @override
  String get nameTemplate => "step back and parry";

  @override
  String get rollReasonTemplate => "will <subject> parry it?";

  @override
  String applyFailure(Actor a, WorldState w, Storyline s) {
    final extraForce = (w.currentSituation as SlashDefenseSituation).extraForce;
    a.report(
        s,
        "<subject> tr<ies> to {parry|deflect it|"
        "meet it with <subject's> ${a.currentWeapon.name}|"
        "fend it off}");
    if (a.pose == Pose.offBalance) {
      a.report(s, "<subject> <is> out of balance", but: true);
    } else if (extraForce) {
      a.report(s, "the swing is too {fast|quick}", but: true);
    } else {
      Randomly.run(
          () => a.report(s, "<subject> {fail<s>|<does>n't succeed}", but: true),
          () => enemy.report(s, "<subject> <is> too quick for <object>",
              object: a, but: true));
    }
    w.popSituation();
    return "${a.name} fails to parry ${enemy.name}";
  }

  @override
  String applySuccess(Actor a, WorldState w, Storyline s) {
    if (a.isPlayer) {
      a.report(s, "<subject> {step<s>|take<s> a step} back");
    }
    a.report(
        s,
        "<subject> {parr<ies> it|deflect<s> it|"
        "meet<s> it with <subject's> ${a.currentWeapon.name}|"
        "fend<s> it off}",
        positive: true);

    final extraForce = (w.currentSituation as SlashDefenseSituation).extraForce;

    if (extraForce) {
      if (a.isPlayer) {
        a.report(
            s,
            "<subject> feel<s> the power of the swing through "
            "<subject's> ${a.currentWeapon.name}");
      } else {
        a.report(
            s,
            "<subject> almost drop<s> "
            "<subject's> ${a.currentWeapon.name} in the process",
            but: true);
      }
    }

    if (a.pose != Pose.standing && !extraForce) {
      w.updateActorById(a.id, (b) => b..pose = Pose.standing);
      if (a.isPlayer) {
        a.report(s, "<subject> regain<s> balance");
      }
    }
    w.popSituationsUntil("FightSituation");
    return "${a.name} steps back and parries ${enemy.name}";
  }

  @override
  num getSuccessChance(Actor a, WorldState w) {
    if (a.isPlayer) return 1.0;
    num outOfBalancePenalty = a.pose == Pose.standing ? 0 : 0.2;
    return 0.5 - outOfBalancePenalty;
  }

  @override
  bool isApplicable(Actor a, WorldState w) => a.wields(ItemType.sword);

  static EnemyTargetAction builder(Actor enemy) =>
      new DefensiveParrySlash(enemy);
}