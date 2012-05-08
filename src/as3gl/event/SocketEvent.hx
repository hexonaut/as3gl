/**
 * Represents socket events.
 * @author Sam MacPherson
 */

package as3gl.event;
import as3gl.util.ByteBuffer;
import flash.events.Event;

class SocketEvent extends Event {
	
	public static var DATA:String = "SOCKET_DATA";
	
	public var data:ByteBuffer;

	public function new (type:String, data:ByteBuffer) {
		super(type);
		
		this.data = data;
	}
	
}