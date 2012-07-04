/**
 * Similiar to flash.utils.ByteArray, but with more functionality.
 * @author Sam MacPherson
 */

package as3gl.util;

import as3gl.core.Long;
import de.polygonal.ds.BitVector;
import flash.utils.ByteArray;
import haxe.Md5;

class ByteBuffer extends ByteArray {
		
	private static var _KEY:Array<Int>;

	public function new () {
		super();
	}
	
	public static function init (key:Array<Int>):Void {
		_KEY = key;
	}
	
	public function encrypt ():Void {
		var origPos = this.position;
		var check:UInt = 0x7F13D041;
		var index = 0;
		while (this.bytesAvailable > 0) {
			var byte = this.readUnsignedByte();
			check ^= byte << (8*(3 - index%4));
			this.position--;
			this.writeByte(byte ^ _KEY[index % _KEY.length]);
			index++;
		}
		this.writeInt(Std.parseInt("0x" + Md5.encode(String.fromCharCode((0xFF000000 & check) >>> 24) + String.fromCharCode((0x00FF0000 & check) >>> 16) + String.fromCharCode((0x0000FF00 & check) >>> 8) + String.fromCharCode(0x000000FF & check)).substr(0, 8)));
		this.position = origPos;
	}
	
	public function decrypt ():Bool {
		var origPos = this.position;
		var check:UInt = 0x7F13D041;
		var index = 0;
		while (this.bytesAvailable > 4) {
			var byte = (this.readUnsignedByte() ^ _KEY[index % _KEY.length]) & 0xFF;
			check ^= byte << (8*(3 - index%4));
			this.position--;
			this.writeByte(byte);
			index++;
		}
		var message = this.readUnsignedInt();
		this.position = origPos;
		return message == Std.parseInt("0x" + Md5.encode(String.fromCharCode((0xFF000000 & check) >>> 24) + String.fromCharCode((0x00FF0000 & check) >>> 16) + String.fromCharCode((0x0000FF00 & check) >>> 8) + String.fromCharCode(0x000000FF & check)).substr(0, 8));
	}
	
	public function writeLong (val:Long):Void {
		this.writeInt(val.getHigh());
		this.writeInt(val.getLow());
	}
	
	public function readLong ():Long {
		return new Long(this.readInt(), this.readInt());
	}
	
}