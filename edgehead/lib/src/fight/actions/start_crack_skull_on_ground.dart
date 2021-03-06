import 'package:edgehead/fractal_stories/action.dart';
import 'package:edgehead/fractal_stories/actor.dart';
import 'package:edgehead/fractal_stories/pose.dart';
import 'package:edgehead/fractal_stories/simulation.dart';
import 'package:edgehead/fractal_stories/situation.dart';
import 'package:edgehead/fractal_stories/storyline/storyline.dart';
import 'package:edgehead/fractal_stories/world_state.dart';
import 'package:edgehead/src/fight/common/combat_command_path.dart';
import 'package:edgehead/src/fight/common/conflict_chance.dart';
import 'package:edgehead/src/fight/common/start_defensible_action.dart';
import 'package:edgehead/src/fight/fatality_on_ground/fatality_on_ground.dart';
import 'package:edgehead/src/fight/fatality_on_ground/wrestle_defense/wrestle_defense_situation.dart';

const String startCrackSkullOnGroundHelpMessage =
    "Puts a quick stop to the fight. Requires a blunt weapon and positional "
    "superiority.";

ReasonedSuccessChance computeCrackSkullOnGroundChance(
        Actor a, Simulation sim, WorldState w, Actor enemy) =>
    getCombatMoveChance(a, enemy, 0.6, [
      const Modifier(50, CombatReason.dexterity),
      const Bonus(20, CombatReason.targetHasSecondaryArmDisabled),
      const Bonus(50, CombatReason.targetHasPrimaryArmDisabled),
      const Bonus(50, CombatReason.targetHasOneEyeDisabled),
      const Bonus(100, CombatReason.targetHasAllEyesDisabled),
    ]);

EnemyTargetAction startCrackSkullOnGroundBuilder() => StartDefensibleAction(
      name: "StartCrackSkullOnGround",
      combatCommandType: CombatCommandType.body,
      commandPathTail: "crack skull",
      helpMessage: startCrackSkullOnGroundHelpMessage,
      isApplicable: (a, sim, w, enemy) =>
          (a.currentWeaponOrBodyPart?.damageCapability?.isBlunt ?? false) &&
          !a.anatomy.isBlind &&
          enemy.isOnGround &&
          enemy.holdsNoWeapon,
      applyStart: startBreakNeckOnGroundReportStart,
      mainSituationBuilder: createFatalityOnGroundSituation,
      defenseSituationBuilder: createOnGroundWrestleDefenseSituation,
      successChanceGetter: computeCrackSkullOnGroundChance,
      rerollable: true,
      rerollResource: Resource.stamina,
      rollReasonTemplate: "will <subject> succeed?",
    );

void startBreakNeckOnGroundReportStart(Actor a, Simulation sim,
    WorldStateBuilder w, Storyline s, Actor enemy, Situation mainSituation) {
  final weapon = a.currentWeaponOrBodyPart;
  a.report(
      s,
      "<subject> throw<s> <subjectPronounSelf> {on|upon} <object> "
      "with <object2> held high",
      object: enemy,
      object2: weapon,
      positive: true,
      endSentence: true);
  w.updateActorById(a.id, (b) => b..pose = Pose.onGround);
}
