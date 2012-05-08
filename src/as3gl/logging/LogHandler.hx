/**
 * Represents an object capable of recieving print/error messages.
 * @author Sam MacPherson
 */

package as3gl.logging;

interface LogHandler {
	
	function log (level:Int, msg:Dynamic):Void;

}
