/**
 * Represents an available command that the user can type.
 * @author Sam MacPherson
 */

package as3gl.util;

import flash.errors.Error;

class ConsoleCommand {
	
	public static var NUMBER:Int = 0;
	public static var STRING:Int = 1;
	public static var OPTIONAL:Int = 1 << 1;
	
	private static var _num:EReg = ~/^[-]?[0-9]+[\.]?[0-9]*$/;
	
	private var _name:String;
	private var _func:Dynamic;
	private var _opts:Array<Int>;
	
	public function new (name:String, func:Dynamic, options:Array<Int>):Void {
		_name = name;
		_func = func;
		_opts = options;
	}
	
	public function getName ():String {
		return _name;
	}
	
	public function call (args:Array<String>):Void {
		//Console.raw("> " + _name + " " + args.join(" "));
		if (args.length <= _opts.length) {
			for (i in 0 ... args.length) {
				if (_opts[i] & 1 == NUMBER) {
					if (!_num.match(args[i])) {
						Console.error("Expect number for argument " + (i + 1) + ".");
						return;
					}
				}
			}
			for (i in args.length ... _opts.length) {
				if (_opts[i] & OPTIONAL == 0) {
					Console.error("Expected more arguments.");
					return;
				}
			}
			try {
				if (args.length > 0 || _opts.length > 0) {
					_func(args);
				} else {
					_func();
				}
			} catch (e:Error) {
				Console.error(e.getStackTrace());
			}
		} else {
			Console.error("Too many arguments.");
		}
	}

}
