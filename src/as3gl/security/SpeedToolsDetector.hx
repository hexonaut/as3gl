/**
 * Detects tools that make the game timers run faster.
 * @author Sam MacPherson
 */

package as3gl.security;
import as3gl.core.Runnable;
import as3gl.event.GroupId;
import de.polygonal.core.event.Observable;
import flash.events.EventDispatcher;

class SpeedToolsDetector extends Observable, implements Runnable {
	
	public static var GROUP:Int = GroupId.get();
	public static var EVENT_SPEED:Int = Observable.makeEvent(GROUP, 0);
	
	private var _limit:Float;
	private var _init:Bool;
	private var _mark:Float;

	public function new (interval:Int, tollerance:Float) {
		super();
		this._limit = interval * (1 - tollerance);
		this._init = true;
	}
	
	public function run ():Void {
		if (_init) {
			_mark = Date.now().getTime();
			_init = false;
		} else {
			var now:Float = Date.now().getTime();
			if (now - _mark < _limit) {
				this.notify(EVENT_SPEED, null);
			}
			_mark = now;
		}
	}
	
}