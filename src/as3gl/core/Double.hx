/**
 * A wrapper class that allows bitwise operations on IEEE double precision floats.
 * @author Sam MacPherson
 */

package as3gl.core;
import de.polygonal.ds.mem.MemoryManager;
import flash.Memory;

class Double {
	
	private var _low:UInt;
	private var _high:UInt;

	public function new (?num:Float = 0) {
		this.set(num);
	}
	
	public function set (num:Float) {
		Memory.setDouble(0, num);
		_high = Memory.getI32(4);
		_low = Memory.getI32(0);
	}
	
	public function get ():Float {
		Memory.setI32(0, _low);
		Memory.setI32(4, _high);
		return Memory.getDouble(0);
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
	
	public function and (high:UInt, low:UInt):Void {
		this._high &= high;
		this._low &= low;
	}
	
	public function or (high:UInt, low:UInt):Void {
		this._high |= high;
		this._low |= low;
	}
	
	public function not ():Void {
		this._high = ~this._high;
		this._low = ~this._low;
	}
	
	public function xor (high:UInt, low:UInt):Void {
		this._high ^= high;
		this._low ^= low;
	}
	
	public function equals (other:Double):Bool {
		return other._high == this._high && other._low == this._low;
	}
	
}