/**
 * Implement this interface to obfuscate and protect data.
 * @author Sam MacPherson
 */

package as3gl.security;

interface VariableObfuscator {

	function init (obj:Dynamic):Void;
	function encrypt (obj:Dynamic, val:Dynamic):Void;
	function decrypt (obj:Dynamic):Dynamic;
	
}