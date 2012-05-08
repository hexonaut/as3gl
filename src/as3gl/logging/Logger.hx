/**
 * A top-level manager for logging.
 * @author Sam MacPherson
 */

package as3gl.logging;

class Logger {
	
	public static inline var DEBUG:Int = 0;
	public static inline var INFO:Int = 1;
	public static inline var WARN:Int = 2;
	public static inline var ERROR:Int = 3;
	
	private static var _logHandler:LogHandler = new NullHandler();
	private static var _filter:Int = 0;
	
	public static inline function set (logHandler:LogHandler):Void {
		_logHandler = logHandler;
	}
	
	public static inline function log (level:Int, msg:Dynamic):Void {
		if (level >= _filter) {
			_logHandler.log(level, msg);
		}
	}
	
	public static inline function setFilter (level:Int):Void {
		_filter = level;
	}

}
