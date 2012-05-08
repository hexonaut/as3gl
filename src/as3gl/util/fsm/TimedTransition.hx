/**
 * Will execute after a given duration.
 * @author Sam MacPherson
 */

package as3gl.util.fsm;

class TimedTransition extends Transition {
	
	private var _delay:Int;
	private var _counter:Int;

	public function new (targetState:State, delay:Int) {
		super(targetState);
		
		_delay = delay;
	}
	
	public override function enter (fsm:FiniteStateMachine):Void {
		_counter = 0;
	}
	
	public override function evaluate (fsm:FiniteStateMachine):Bool {
		return _counter++ >= _delay;
	}
	
}