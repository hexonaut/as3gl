/**
 * Will evaluate to true when the given condition function returns true.
 * @author Sam MacPherson
 */

package as3gl.util.fsm;

class ConditionalTransition extends Transition {
	
	private var _cond:Dynamic;

	public function new (targetState:State, cond:Dynamic) {
		super(targetState);
		
		_cond = cond;
	}
	
	public override function evaluate (fsm:FiniteStateMachine):Bool {
		return _cond();
	}
	
}