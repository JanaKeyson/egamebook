part of zil;

abstract class Located {
  /// Location of the entity in game. It is set to [:null:] for objects/actors 
  /// that are 'nowhere'.
  Room get location;
  
  bool isIn(Room room) => location == room;
  bool isInSameRoomAs(ZilActor actor) => location == actor.location;
}

/**
 *     var captainsGun = new Item("captains {gun|pistol}", 
          [
           new Action("check the gun", 
              () => echo("You check the gun. It's okay."))
           ],
        count: 1,  // can be >1 for things like bullets
        container: true,
        contents: NO_ITEMS,
        takeable: true,
        visible: true
      );
 */
class Item extends Entity implements Located {
  final Iterable<Action> actions;
  bool takeable;
  bool visible;
  final bool container;
  final bool plural;
  int count;
  
  Set<Item> contents = new Set<Item>();
  
  Item(String name, this.actions, {
      this.takeable: true, this.visible: true, this.container: false,
      this.plural: false, this.count: 1,
      Iterable<Item> contents: const [],
      Pronoun pronoun: Pronoun.IT}) : super(name, pronoun: pronoun) {
        
    actions.forEach((action) => action.item = this);
    if (!container) {
      assert(contents.isEmpty);
    } else {
      this.contents.addAll(contents);
    }
    if (!plural) assert(count == 1);
  }
  
  Room _location;
  ZilActor carrier;
  
  bool get isBeingCarried => carrier != null;
  bool isCarriedBy(ZilActor actor) => carrier == actor;
  bool isInRoomFreeStanding(Room room) => carrier == null && _location == room;
  
  Room get location {
    if (carrier != null) return carrier.location;
    return _location;
  }
  
  bool isIn(Room room) => location == room;
  bool isInSameRoomAs(ZilActor actor) => location == actor.location;
  
  // TODO: droppable - some items just shouldn't be even giving the option to be dropped
  // TODO: get inspiration from item.dart
  
  // TODO: containers ?
}