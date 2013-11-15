part of egb_scripter;

/**
 * Bit (also known as 'flag') is a variable that has only two states: on or off.
 * There is no [:null:].
 * 
 * This is the easiest way to save state and (more importantly) check for state.
 * For example:
 * 
 *     var gorillaAlive = new Bit(true);
 *     // ...
 *     if (gorillaAlive.isFlagged) { /* ... */ }
 *     if (gorillaAlive.isNotFlagged) { /* ... */ }
 *     
 * Contrast this to a [bool]:
 * 
 *     var gorillaAlive = true;
 *     // ...
 *     if (gorillaAlive != null && gorillaAlive == true) { /* ... */ }
 *     if (gorillaAlive == null || (gorillaAlive != null && 
 *         gorillaAlive == false)) { /* ... */ }
 * 
 * TODO: There is a lot of room for performance/size improvements.
 */
class Bit implements Saveable {
  bool _state;
  Bit([this._state = false]);
  
  void flag() {
    _state = true;
  }
  
  void unflag() {
    _state = false;
  }
  
  void set(bool state) {
    assert(state != null);
    _state = state;
  }
  
  bool get isFlagged => _state;
  bool get isNotFlagged => !_state;
  
  final className = "Bit";
  toMap() {
    return { "_state" : _state };
    // TODO: Optimize (e.g. return empty Map to save a little bit of space).
  }
    
  void updateFromMap(Map map) {
    _state = map["_state"];
  }
}