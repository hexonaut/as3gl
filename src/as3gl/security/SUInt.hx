/**
 * A wrapper class for UInt that implements obfuscation and protection via the default VariableObfuscator.
 * @author Sam MacPherson
 */

package as3gl.security;

class SUInt implements Dynamic {

	public function new (?num:UInt = 0) {
		Security.obfuscator.init(this);
		this.set(num);
	}
	
	public inline function set (num:UInt):Void {
		Security.obfuscator.encrypt(this, num);
	}
	
	public inline function add (num:UInt):Void {
		this.set(this.get() + num);
	}
	
	public inline function subtract (num:UInt):Void {
		this.set(this.get() - num);
	}
	
	public inline function get ():UInt {
		return Security.obfuscator.decrypt(this);
	}
	
}