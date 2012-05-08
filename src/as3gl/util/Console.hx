/**
 * Handles input/output from user as well as rendering to the screen.
 * @author Sam MacPherson
 */

package as3gl.util;

import as3gl.logging.Logger;
import as3gl.logging.LogHandler;
import hsl.haxe.data.mathematics.Point;

class Console implements LogHandler {
	
	private static var _instance:Console;
	
	private var _console:mlc.haxe.Console;
	
	private function new ():Void {
		_instance = this;
		
		_console = new mlc.avm2.AVM2Console();
	}
	
	private static inline function _get ():Console {
		if (_instance == null) {
			_instance = new Console();
		}
		return _instance;
	}
	
	public static inline function getLogger ():LogHandler {
		return _get();
	}
	
	public static inline function isActive ():Bool {
		var console:mlc.avm2.AVM2Console = cast(_get()._console, mlc.avm2.AVM2Console);
		return console.visualizer != null && console.visualizer.view != null && console.visualizer.view.handleKeyPressedDownBond != null && !console.visualizer.view.handleKeyPressedDownBond.halted;
	}
	
	public static inline function addCommand (cmd:ConsoleCommand) {
		_get()._console.addRawCommand(cmd.getName(), cmd.call);
	}
	
	public inline function log (level:Int, msg:Dynamic):Void {
		if (level == Logger.DEBUG) {
			debug(msg);
		} else if (level == Logger.INFO) {
			print(msg);
		} else if (level == Logger.WARN) {
			warn(msg);
		} else if (level == Logger.ERROR) {
			error(msg);
		}
	}
	
	public static inline function raw (obj:Dynamic):Void {
		_get()._console.write(obj, 0xFFFFFF, true);
	}
	
	public static inline function debug (obj:Dynamic):Void {
		_get()._console.write("[Debug] " + obj, 0xFFFFFF, true);
	}
	
	public static inline function print (obj:Dynamic):Void {
		_get()._console.write("[Info] " + obj, 0xFFFFFF, true);
	}
	
	public static inline function warn (obj:Dynamic):Void {
		_get()._console.write("[Warning] " + obj, 0xF95A61, true);
	}
	
	public static inline function error (obj:Dynamic):Void {
		_get()._console.write("[Error] " + obj, 0xF95A61, true);
	}
	
}
