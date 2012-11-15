/**
 * An implementation of the flash Socket class using a prefixed length protocol.
 * @author Sam MacPherson
 */

package as3gl.net;
import as3gl.core.Destroyable;
import as3gl.event.SocketEvent;
import as3gl.util.ByteBuffer;
import flash.Lib;
import flash.net.Socket;
import flash.events.ProgressEvent;

class SocketConnection extends Socket, implements Destroyable {
	
	private var _len:Int;
	private var _readBuf:ByteBuffer;
	private var _lastInbound:Int;
	private var _in:Int;
	private var _lastOutbound:Int;
	private var _out:Int;

	public function new (?host:String = null, ?port:Int = 0) {
		super(host, port);
		
		_len = -1;
		_readBuf = new ByteBuffer();
		
		this.addEventListener(ProgressEvent.SOCKET_DATA, onData);
	}
	
	public function destroy ():Void {
		this.removeEventListener(ProgressEvent.SOCKET_DATA, onData);
	}
	
	public function getInboundDataRate ():Float {
		var dur:Float = (Lib.getTimer() - _lastInbound) / 1000;
		if (dur == 0) return 0;
		var rate:Float = _in / dur;
		_in = 0;
		_lastInbound = Lib.getTimer();
		return rate;
	}
	
	public function getOutboundDataRate ():Float {
		var dur:Float = (Lib.getTimer() - _lastOutbound) / 1000;
		if (dur == 0) return 0;
		var rate:Float = _out / dur + 40;
		_out = 0;
		_lastOutbound = Lib.getTimer();
		return rate;
	}
	
	public override function flush ():Void {
		_out += this.bytesPending;
		super.flush();
	}
	
	public function onData (event:ProgressEvent = null):Void {
		if (_len == -1) {
			if (this.bytesAvailable >= 2) {
				_len = this.readShort();
			} else {
				return;
			}
		}
		
		while (this.bytesAvailable > 0 && _len > 0) {
			_readBuf.writeByte(this.readByte());
			_len--;
		}
		if (_len == 0) {
			var buf:ByteBuffer = new ByteBuffer();
			this._readBuf.position = 0;
			_readBuf.readBytes(buf);
			buf.position = 0;
			
			_in += buf.bytesAvailable;
			
			this.dispatchEvent(new SocketEvent(SocketEvent.DATA, buf));
			
			_len = -1;
			this._readBuf.position = 0;
			this._readBuf.length = 0;
			
			onData();
		}
	}
	
}