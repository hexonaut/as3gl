/**
 * The FiniteStateMachine acts as the "overseer" for the various states contained.
 * @author Sam MacPherson
 */

package as3gl.util.fsm;

interface FiniteStateMachine {

	function addState (state:State):Void;
	function getState (name:String):State;
	function removeState (name:String):State;
	function clearStates ():Void;
	function setCurrentState (state:State):Void;
	
}