/**
 * Security is a global class responsible for data encryption and protection.
 * @author Sam MacPherson
 */

package as3gl.security;

class Security {

	public static var obfuscator:VariableObfuscator;
	
	public static function setDefaultObfuscator (obf:VariableObfuscator):Void {
		obfuscator = obf;
	}
	
}