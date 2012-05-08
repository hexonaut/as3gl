/**
 * A wrapper class for Int that implements obfuscation and protection via the default VariableObfuscator.
 * @author Sam MacPherson
 */

package as3gl.security;

class SInt implements Dynamic {

	public function new (?num:Int = 0) {
		Security.obfuscator.init(this);
		this.set(num);
	}
	
	public inline function set (num:Int):Void {
		Security.obfuscator.encrypt(this, num);
	}
	
	public inline function add (num:Int):Void {
		this.set(this.get() + num);
	}
	
	public inline function subtract (num:Int):Void {
		this.set(this.get() - num);
	}
	
	public inline function get ():Int {
		return Security.obfuscator.decrypt(this);
	}
	
}