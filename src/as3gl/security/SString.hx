/**
 * A wrapper class for String that implements obfuscation and protection via the default VariableObfuscator.
 * @author Sam MacPherson
 */

package as3gl.security;

class SString implements Dynamic {

	public function new (?str:String = null) {
		Security.obfuscator.init(this);
		this.set(str);
	}
	
	public function set (str:String):Void {
		Security.obfuscator.encrypt(this, str);
	}
	
	public function get ():String {
		return Security.obfuscator.decrypt(this);
	}
	
}