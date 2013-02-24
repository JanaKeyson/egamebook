library spaceship;

import '../../lib/src/book/scripter.dart';
import '../../lib/src/shared/user_interaction.dart';
import 'numscale.dart';
import 'actor.dart';
import 'storyline.dart';
import 'timeline.dart';
import 'randomly.dart';

part 'combatmove.dart';
part 'shipsystem.dart';
part 'pilot.dart';


class Spaceship extends Actor /*TODO: implements Saveable*/ {
  Spaceship(String name, {this.shield, this.engine, this.hull,
             this.thrusters: const [], this.weapons: const[],
             this.systems: const [], this.pilot}) : super(name: name) {
    if (pilot == null) pilot = new Pilot.ai(this);
    pilot.spaceship = this;
    team = pilot.team;
    // Assing this as all of this ship's system's spaceship. 
    allSystems.forEach((system) {
      system.spaceship = this;
      system.team = team;
    });
  }
  
  bool get isAlive => hull.hp.value > 0;
  Pilot pilot;
  
  /// The ship that this spaceship is focused on. Doesn't prevent a weapon 
  /// from targeting a different ship.
  Spaceship targetShip;
  
  final Hull hull;
  final Shield shield;
  final Engine engine;
  
  final List<Thruster> thrusters;
  final List<Weapon> weapons;
  
  /// Life support, mining equipment, hyperdrive ...
  final List<SpecialSystems> systems;
  
  /// Return the list of all the ship's systems, including engine, weapons, etc.
  Iterable<ShipSystem> get allSystems => new Iterable.generate(
      systems.length + weapons.length + thrusters.length + 3, /* shield + engine + hull */
      (int i) {
        if (i < systems.length) {
          return systems[i];
        }
        if (i < systems.length + weapons.length) {
          return weapons[i - systems.length];
        }
        if (i < systems.length + weapons.length + thrusters.length) {
          return thrusters[i - systems.length - weapons.length];
        }
        if (i == systems.length + weapons.length + thrusters.length) {
          return shield;
        }
        if (i == systems.length + weapons.length + thrusters.length + 1) {
          return engine;
        }
        if (i == systems.length + weapons.length + thrusters.length + 2) {
          return hull;
        }
      }
  ).where((system) => system != null);
  
  /// The current combined maneuverability of the ship's thrusters.
  int get maneuverability =>
    thrusters.reduce(0, 
        (num prevValue, thruster) => prevValue + thruster.maneuverability)
        .toInt();
  
  void update() {
    allSystems.forEach((system) => system.update());
    pilot.update();
  }
  
  List<CombatMove> getAvailableMoves() {
    List<CombatMove> moves = [];
    allSystems.forEach((system) {
      if (system.currentMove == null) {
        system.availableMoves.forEach((move) {
          if (move.isEligible(targetShip: targetShip)) {
            moves.add(move);
          }
        });
      } else if (system.currentMove.autoRepeat) {
        // add autoRepeating currentMoves so pilot can choose to stop them
        moves.add(system.currentMove);   
      }
    });
    return moves;
  }
  
  /*
   * TODO: saveable only primitives, rest should be remembered by Combat
   */
}





