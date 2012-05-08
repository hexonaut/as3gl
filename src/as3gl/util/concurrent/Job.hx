/**
 * A Job is a Runnable that has methods for determining the status of the task.
 * @author Sam MacPherson
 */

package as3gl.util.concurrent;

interface Job {
	
	function init (vars:Dynamic<Dynamic>):Void;
	function execute (vars:Dynamic<Dynamic>):Bool;
	function progress ():Float;
	function isComplete ():Bool;
	
}
