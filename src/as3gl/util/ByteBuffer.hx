/**
 * Similiar to flash.utils.ByteArray, but with more functionality.
 * @author Sam MacPherson
 */

package as3gl.util;
import as3gl.core.Long;
import de.polygonal.ds.BitVector;
import flash.utils.ByteArray;

class ByteBuffer extends ByteArray {

	public function new () {
		super();
	}
	
	public function encrypt (securityId:Int, id:Int):Void {
		this.addChecksum();
		this.encryptData(securityId, id);
	}
	
	public function decrypt ():Int {
		var userId:Int = this.decryptData();
		if (this.verifyChecksum()) {
			return userId;
		} else {
			return -1;
		}
	}
	
	public function writeLong (val:Long):Void {
		this.writeInt(val.getHigh());
		this.writeInt(val.getLow());
	}
	
	public function readLong ():Long {
		return new Long(this.readInt(), this.readInt());
	}
	
	//Call after writing all data
	private function addChecksum ():Void {
		var checksum:Int = 0x829EED31;
		var start:Int = this.position;
		var pos:Int = 0;
		while (this.bytesAvailable > 0) {
			var byte:Int = this.readByte();
			checksum ^= byte << (pos++ % 25);
		}
		this.writeInt(checksum);
		this.position = start;
	}
	
	//Call before reading data
	private function verifyChecksum ():Bool {
		var checksum:Int = 0x829EED31;
		var start:Int = this.position;
		var pos:Int = 0;
		while (this.bytesAvailable > 4) {
			var byte:Int = this.readByte();
			checksum ^= byte << (pos++ % 25);
		}
		var givenChecksum:Int = this.readInt();
		this.position = start;
		this.length = this.length - 4;
		
		return givenChecksum == checksum;
	}
	
	//Call after addChecksum
	private function encryptData (securitySeed:Int, id:Int):Void {
		var start:Int = this.position;
		while (this.bytesAvailable >= 4) {
			var num:Int = this.readInt();
			this.position -= 4;
			this.writeInt(num ^ securitySeed ^ id);
		}
		while (this.bytesAvailable > 0) {
			var byte:Int = this.readByte();
			this.position -= 1;
			this.writeByte(byte ^ securitySeed ^ id);
		}
		this.writeInt(securitySeed);
		this.position = start;
	}
	
	//Call before verifyChecksum
	private function decryptData ():Int {
		var start:Int = this.position;
		var senderId:Int = this.readInt();
		this.position = this.length - 4;
		var securitySeed:Int = this.readInt();
		this.length -= 4;
		this.position = start + 4;
		while (this.bytesAvailable >= 4) {
			var num:Int = this.readInt();
			this.position -= 4;
			this.writeInt(num ^ senderId ^ securitySeed);
		}
		while (this.bytesAvailable > 0) {
			var byte:Int = this.readByte();
			this.position -= 1;
			this.writeByte(byte ^ senderId ^ securitySeed);
		}
		this.position = start + 4;
		
		return senderId;
	}
	
}