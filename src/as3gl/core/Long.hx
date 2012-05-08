/**
 * A wrapper class that allows flash to store Longs.
 * @author Sam MacPherson
 */

package as3gl.core;

class Long {
	
	private var _low:UInt;
	private var _high:UInt;

	public function new (?high:UInt = 0, ?low:UInt = 0) {
		this.set(high, low);
	}
	
	public function set (high:UInt, low:UInt):Void {
		this._high = high;
		this._low = low;
	}
	
	public function setHigh (high:UInt):Void {
		this._high = high;
	}
	
	public function setLow (low:UInt):Void {
		this._low = low;
	}
	
	public function getHigh ():UInt {
		return this._high;
	}
	
	public function getLow ():UInt {
		return this._low;
	}
	
}