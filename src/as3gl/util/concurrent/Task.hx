/**
 * A simple implementation of the Runnable interface which allows for running user defined functions through an Executor.
 * @author Sam MacPherson
 */

package as3gl.util.concurrent;
import as3gl.core.Runnable;

class Task implements Runnable {
	
	private var _func:Dynamic;
	private var _delay:Int;
	private var _count:Int;

	public function new (func:Dynamic, ?delay:Int = 0) {
		this._func = func;
		this._delay = delay;
		this._count = delay;
	}
	
	public function run ():Void {
		if (_count++ >= _delay) {
			_count = 0;
			_func();
		}
	}
	
}