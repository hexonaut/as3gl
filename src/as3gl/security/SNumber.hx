/**
 * A wrapper class for Number/Float that implements obfuscation and protection via the default VariableObfuscator.
 * @author Sam MacPherson
 */

package as3gl.security;

class SNumber implements Dynamic {

	public function new (?num:Float = 0) {
		Security.obfuscator.init(this);
		this.set(num);
	}
	
	public inline function set (num:Float):Void {
		Security.obfuscator.encrypt(this, num);
	}
	
	public inline function add (num:Float):Void {
		this.set(this.get() + num);
	}
	
	public inline function subtract (num:Float):Void {
		this.set(this.get() - num);
	}
	
	public inline function get ():Float {
		return Security.obfuscator.decrypt(this);
	}
	
}