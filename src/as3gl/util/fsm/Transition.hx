/**
 * A transition between two states. Will be taken if evaluate() returns true.
 * @author Sam MacPherson
 */

package as3gl.util.fsm;

class Transition {
	
	private var _targetState:State;

	public function new (targetState:State) {
		this._targetState = targetState;
	}
	
	public function getTargetState ():State {
		return this._targetState;
	}
	
	//Override
	public function enter (fsm:FiniteStateMachine):Void {
	}
	public function evaluate (fsm:FiniteStateMachine):Bool {
		return true;
	}
	public function exit (fsm:FiniteStateMachine):Void {
	}
	
}