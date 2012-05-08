/**
 * A wrapper class for Boolean/Bool that implements obfuscation and protection via the default VariableObfuscator.
 * @author Sam MacPherson
 */

package as3gl.security;

class SBoolean implements Dynamic {

	public function new (?bool:Bool = false) {
		Security.obfuscator.init(this);
		this.set(bool);
	}
	
	public function set (bool:Bool):Void {
		Security.obfuscator.encrypt(this, bool);
	}
	
	public function get ():Bool {
		return Security.obfuscator.decrypt(this);
	}
	
}