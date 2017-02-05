import 'package:edgehead/fractal_stories/action.dart';
import 'package:edgehead/fractal_stories/actor.dart';
import 'package:edgehead/fractal_stories/item.dart';
import 'package:edgehead/fractal_stories/storyline/randomly.dart';
import 'package:edgehead/fractal_stories/storyline/storyline.dart';
import 'package:edgehead/fractal_stories/world.dart';
import 'package:edgehead/src/fight/damage_reports.dart';
import 'package:edgehead/src/fight/fight_situation.dart';
import 'package:edgehead/src/fight/strike_down/strike_down_defense/on_ground_defense_situation.dart';

class OnGroundParry extends EnemyTargetAction {
  @override
  final bool isAggressive = false;

  @override
  final String helpMessage = "You can deal serious damage when countering "
      "because your opponent is often caught off guard. On the other hand, "
      "counters require fast reaction and could throw you out of balance.";

  OnGroundParry(Actor enemy) : super(enemy);

  @override
  String get nameTemplate => "parry it";

  @override
  String get rollReasonTemplate => "will <subject> parry it?";

  @override
  String applyFailure(Actor a, WorldState _, Storyline s) {
    a.report(
        s,
        "<subject> tr<ies> to {parry|deflect it|"
        "stop it{| with <subject's> ${a.currentWeapon.name}}}");
    Randomly.run(
        () => a.report(s, "<subject> {fail<s>|<does>n't succeed}", but: true),
        () => enemy.report(s, "<subject> <is> too quick for <object>",
            object: a, but: true));
    return "${a.name} fails to parry ${enemy.name}";
  }

  @override
  String applySuccess(Actor a, WorldState w, Storyline s) {
    bool extraForce =
        (w.currentSituation as OnGroundDefenseSituation).extraForce;
    if (extraForce) {
      a.report(
          s,
          "<subject> put<s> <subject's> ${a.currentWeapon.name} "
          "in the way");
      s.add("the strike is too powerful", but: true);
      w.updateActorById(enemy.id, (b) => b..hitpoints -= 1);
      bool killed = !w.getActorById(enemy.id).isAlive;
      s.add(
          "<owner's> <subject> still {cuts|slashes} "
          "${killed ? 'across <object\'s> {neck|abdomen}'
              : '<object\'s> {arm|shoulder}'}",
          subject: enemy.currentWeapon,
          owner: enemy,
          object: a);
      if (killed) {
        var groundMaterial = w
            .getSituationByName<FightSituation>("FightSituation")
            .groundMaterial;
        reportDeath(s, a, groundMaterial);
      } else {
        reportPain(s, a);
      }
      w.popSituationsUntil("FightSituation");
      return "${a.name} parries ${enemy.name} but the swing has extra force";
    }
    a.report(
        s,
        "<subject> {parr<ies> it|"
        "stop<s> it with <subject's> ${a.currentWeapon.name}}",
        positive: true);
    w.popSituationsUntil("FightSituation");
    return "${a.name} parries ${enemy.name}";
  }

  @override
  num getSuccessChance(Actor a, WorldState world) {
    if (a.isPlayer) return 0.6;
    return 0.3;
  }

  @override
  bool isApplicable(Actor a, WorldState world) => a.wields(ItemType.sword);

  static EnemyTargetAction builder(Actor enemy) => new OnGroundParry(enemy);
}