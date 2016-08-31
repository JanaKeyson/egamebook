import 'package:stranded/action.dart';
import 'package:stranded/actor.dart';

var standUp = new ClosureActorAction(
    "Stand up.", (Actor a, w) => a.pose == Pose.onGround, (a, w, s) {
  a.report(s, "<subject> stand<s> up");
  w.updateActorById(a.id, (b) => b.pose = Pose.standing);
  return "${a.name} stands up";
}, (_, __, ___) {}, 1.0);