/**
 * Same as TimedTransition but will only increment the counter if the given function evaluates to true.
 * @author Sam MacPherson
 */

package as3gl.util.fsm;

class ConditionalTimedTransition extends TimedTransition {
	
	private var _cond:Dynamic;

	public function new (targetState:State, delay:Int, cond:Dynamic) {
		super(targetState, delay);
		
		_cond = cond;
	}
	
	public override function evaluate (fsm:FiniteStateMachine):Bool {
		if (_cond()) {
			return _counter++ >= _delay;
		} else {
			return false;
		}
	}
	
}