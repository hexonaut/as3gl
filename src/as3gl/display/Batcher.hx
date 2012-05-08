/**
 * Prepares a batch of quads for a draw call.
 * @author Sam MacPherson
 */

package as3gl.display;

import as3gl.core.Destroyable;
import as3gl.display.data.Polygon;
import as3gl.display.data.Quad;
import as3gl.display.data.Vertex;
import as3gl.util.Molehill;
import flash.display.BitmapData;
import flash.display3D.Context3D;
import flash.display3D.VertexBuffer3D;
import flash.display3D.IndexBuffer3D;
import flash.display3D.textures.Texture;
import flash.geom.Matrix;
import flash.geom.Matrix3D;
import flash.geom.Vector3D;
import flash.errors.Error;

@:shader({
	var input:{
		pos:Float3,
		uv:Float2,
		filter:Float4
	};
	var tuv:Float2;
	var color:Float4;
	function vertex (mproj:M44) {
		out = pos.xyzw * mproj;
		tuv = uv;
		color = filter;
	}
	function fragment (t:Texture) {
		var s = t.get(tuv, wrap, nearest) * color;
		kill(s.w - 0.8);
		out = s;
	}
}) class Shader extends format.hxsl.Shader {
}

@:shader({
	var input:{
		pos:Float3,
		uv:Float2,
		filter:Float4
	};
	var tuv:Float2;
	var color:Float4;
	function vertex (mproj:M44) {
		out = pos.xyzw * mproj;
		tuv = uv;
		color = filter;
	}
	function fragment (t:Texture) {
		var s = t.get(tuv, wrap, nearest) * color;
		out = s;
	}
}) class TransparencyShader extends format.hxsl.Shader {
}

class Batcher implements Destroyable {
	
	private static var _EMPTY_TRANSFORM:Matrix3D = new Matrix3D();
	private static var _EMPTY_FILTER:Vector3D = new Vector3D(1, 1, 1, 1);
	
	private static var _instance:Batcher;

	private var _bmds:Array<TextureAtlas>;
	private var _textures:Array<Texture>;
	private var _shader:Shader;
	private var _transparencyShader:TransparencyShader;
	private var _unusedBuffers:List<BufferSet>;
	private var _bufs:IntHash<BufferSet>;
	private var _lastIndex:Int;
	private var _processed:Int;
	
	public function new () {
		_bmds = new Array<TextureAtlas>();
		_textures = new Array<Texture>();
		_bufs = new IntHash<BufferSet>();
		_unusedBuffers = new List<BufferSet>();
		_lastIndex = 0;
		_processed = 0;
		
		_instance = this;
	}
	
	public function destroy ():Void {
		for (i in _textures) {
			i.dispose();
		}
		for (i in _bmds) {
			i.get().dispose();
		}
	}
	
	public inline static function get ():Batcher {
		if (_instance == null) new Batcher();
		return _instance;
	}
	
	public function add (bmd:BitmapData, ?dedicatedTexture:Bool = false):Quad {
		var quad:Quad;
		if (!dedicatedTexture) {
			if (_bmds.length == _processed) _bmds.push(new TextureAtlas(_lastIndex, false, 2048, 2048));
			
			var last:TextureAtlas = _bmds[_lastIndex];
			quad = last.add(bmd);
			if (quad == null) {
				//Last texture is full -- make new one
				_lastIndex = _bmds.length;
				last = new TextureAtlas(_lastIndex, false, 2048, 2048);
				_bmds.push(last);
				quad = last.add(bmd);
			}
		} else {
			var w:Int = Molehill.getTextureDimension(bmd.width);
			var h:Int = Molehill.getTextureDimension(bmd.height);
			var bmdCpy:BitmapData = new BitmapData(w, h, true, 0x00000000);
			var m:Matrix = new Matrix();
			m.scale(w / bmd.width, h / bmd.height);
			bmdCpy.draw(bmd, m);
			var ta:TextureAtlas = new TextureAtlas(_bmds.length, true, w, h);
			quad = ta.add(bmdCpy);
			_bmds.push(ta);
		}
		return quad;
	}
	
	public function build (c:Context3D):Void {
		for (i in _processed ... _bmds.length) {
			var bmd:BitmapData = _bmds[i].get();
			var t:Texture = c.createTexture(bmd.width, bmd.height, flash.display3D.Context3DTextureFormat.BGRA, false);
			t.uploadFromBitmapData(bmd);
			bmd.dispose();
			_textures.push(t);
		}
		_processed = _bmds.length;
		_lastIndex = _bmds.length;
		if (_shader == null) _shader = new Shader(c);
		if (_transparencyShader == null) _transparencyShader = new TransparencyShader(c);
	}
	
	public function batch (c:Context3D, camera:Matrix3D, polygon:Polygon, ?transform:Matrix3D = null, ?filter:Vector3D = null):Void {
		if (_bmds.length > 0) build(c);
		
		if (transform == null) transform = _EMPTY_TRANSFORM;
		if (filter == null) filter = _EMPTY_FILTER;
		
		var depth:Float = Canvas.getNextDepth();
		var bufs:BufferSet = _bufs.get(polygon.tid);
		if (bufs == null) {
			if (_unusedBuffers.isEmpty()) bufs = new BufferSet();
			else bufs = _unusedBuffers.pop();
			_bufs.set(polygon.tid, bufs);
		}
		var baseIndex:Int = bufs.getVertexBufferSize();
		if (baseIndex + polygon.verticies.length >= (1 << 16)) {
			//Too many verticies -- need to flush buffer
			render(c, camera);
			baseIndex = 0;
		}
		for (i in polygon.verticies) {
			bufs.addVertex(i, depth, transform, filter);
		}
		for (i in polygon.indicies) {
			bufs.addIndex(i + baseIndex);
		}
	}
	
	public function render (c:Context3D, camera:Matrix3D, ?useTransparencyShader:Bool = false):Void {
		for (i in _bufs.keys()) {
			var bufs:BufferSet = _bufs.get(i);
			var vertexSize:Int = bufs.getVertexBufferSize();
			var vbuf:VertexBuffer3D = c.createVertexBuffer(vertexSize, 9);
			vbuf.uploadFromVector(bufs.vbuf, 0, vertexSize);
			var ibuf:IndexBuffer3D = c.createIndexBuffer(bufs.getIndexBufferSize());
			ibuf.uploadFromVector(bufs.ibuf, 0, bufs.getIndexBufferSize());
			
			if (useTransparencyShader) {
				_transparencyShader.init(
					{ mproj:camera },
					{ t:_textures[i] }
				);
				_transparencyShader.draw(vbuf, ibuf);
			} else {
				_shader.init(
					{ mproj:camera },
					{ t:_textures[i] }
				);
				_shader.draw(vbuf, ibuf);
			}
			
			vbuf.dispose();
			ibuf.dispose();
			bufs.reset();
			_unusedBuffers.push(bufs);
		}
		_bufs = new IntHash<BufferSet>();
	}
	
	public inline function getTexture (tid:Int):Texture {
		return _textures[tid];
	}
	
}

private class BufferSet {
	
	public var vbuf:flash.Vector<Float>;
	public var vbufi:Int;
	public var ibuf:flash.Vector<UInt>;
	public var ibufi:Int;
	
	public function new () {
		vbuf = new flash.Vector<Float>(1 << 16, true);
		ibuf = new flash.Vector<UInt>(1 << 16, true);
		reset();
	}
	
	public inline function reset ():Void {
		vbufi = 0;
		ibufi = 0;
	}
	
	public inline function addVertex (v:Vertex, depth:Float, transform:Matrix3D, filter:Vector3D):Void {
		var m:flash.Vector<Float> = transform.rawData;
		vbuf[vbufi++] = v.x*m[0] + v.y*m[4] + m[12];
		vbuf[vbufi++] = v.x*m[1] + v.y*m[5] + m[13];
		vbuf[vbufi++] = depth;
		vbuf[vbufi++] = v.u;
		vbuf[vbufi++] = v.v;
		vbuf[vbufi++] = filter.x;
		vbuf[vbufi++] = filter.y;
		vbuf[vbufi++] = filter.z;
		vbuf[vbufi++] = filter.w;
	}
	
	public inline function addIndex (i:UInt):Void {
		ibuf[ibufi++] = i;
	}
	
	public inline function getVertexBufferSize ():Int {
		return Std.int(vbufi / 9);
	}
	
	public inline function getIndexBufferSize ():Int {
		return ibufi;
	}
	
}