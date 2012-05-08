/**
 * A valid state in the Finite State Machine.
 * @author Sam MacPherson
 */

package as3gl.util.fsm;
import de.polygonal.ds.SLL;

class State {
	
	private var _name:String;
	private var _trans:SLL<Transition>;

	public function new (name:String) {
		this._name = name;
		this._trans = new SLL<Transition>();
	}
	
	public function addTransition (trans:Transition):Void {
		_trans.append(trans);
	}
	
	public function getName ():String {
		return this._name;
	}
	
	//Override
	public function enter (fsm:FiniteStateMachine):Void {
		for (i in _trans) {
			i.enter(fsm);
		}
	}
	public function tick (fsm:FiniteStateMachine):Void {
		for (i in _trans) {
			if (i.evaluate(fsm)) {
				fsm.setCurrentState(i.getTargetState());
			}
		}
	}
	public function exit (fsm:FiniteStateMachine):Void {
		for (i in _trans) {
			i.exit(fsm);
		}
	}
	
}