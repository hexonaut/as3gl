/**
 * Provides molehill-specific helper functions.
 * @author Sam MacPherson
 */
 
package as3gl.util;

import de.polygonal.ds.Bits;
import de.polygonal.motor2.geom.primitive.AABB2;
import flash.display.BitmapData;
import flash.display3D.Context3D;
import flash.display3D.IndexBuffer3D;
import flash.display3D.VertexBuffer3D;
import flash.display3D.textures.Texture;
import flash.geom.Matrix;
import flash.geom.Matrix3D;
import flash.geom.Vector3D;

class Molehill {
	
	private static var _vpts:flash.Vector<Float>;
	private static var _vbuf:VertexBuffer3D;
	private static var _ibuf:IndexBuffer3D;
	
	public static inline function getTextureDimension (dim:Int):Int {
		if (dim > 1) {
			return Bits.msb(dim - 1) << 1;
		} else {
			return 1;
		}
	}
	
	public static inline function getTexture (c:Context3D, bmd:BitmapData):Texture {
		var bmdCpy:BitmapData = new BitmapData(Molehill.getTextureDimension(bmd.width), Molehill.getTextureDimension(bmd.height), true, 0x00000000);
		var m:Matrix = new Matrix();
		m.scale(bmdCpy.width / bmd.width, bmdCpy.height / bmd.height);
		bmdCpy.draw(bmd, m);
		var t:Texture = c.createTexture(bmdCpy.width, bmdCpy.height, flash.display3D.Context3DTextureFormat.BGRA, false);
		t.uploadFromBitmapData(bmdCpy);
		
		return t;
	}
	
	public static inline function getRectangularVertexBuffer (c:Context3D, xmin:Float, ymin:Float, xmax:Float, ymax:Float, ?texW:Float = 1, ?texH:Float = 1):VertexBuffer3D {
		if (_vpts == null) _vpts = new flash.Vector<Float>(16, true);
		var vbuf:VertexBuffer3D = c.createVertexBuffer(4, 4);
		_vpts[0] = xmin;
		_vpts[1] = ymin;
		_vpts[2] = 0;
		_vpts[3] = 0;
		
		_vpts[4] = xmax;
		_vpts[5] = ymin;
		_vpts[6] = texW;
		_vpts[7] = 0;
		
		_vpts[8] = xmin;
		_vpts[9] = ymax;
		_vpts[10] = 0;
		_vpts[11] = texH;
		
		_vpts[12] = xmax;
		_vpts[13] = ymax;
		_vpts[14] = texW;
		_vpts[15] = texH;
		vbuf.uploadFromVector(_vpts, 0, 4);
		
		return vbuf;
	}
	
	public static inline function getTextureVertexBuffer (c:Context3D):VertexBuffer3D {
		if (_vbuf == null) {
			var vpts:flash.Vector<Float> = new flash.Vector<Float>(16, true);
			_vbuf = c.createVertexBuffer(4, 4);
			vpts[0] = 0;
			vpts[1] = 0;
			vpts[2] = 0;
			vpts[3] = 0;
			
			vpts[4] = 1;
			vpts[5] = 0;
			vpts[6] = 1;
			vpts[7] = 0;
			
			vpts[8] = 0;
			vpts[9] = 1;
			vpts[10] = 0;
			vpts[11] = 1;
			
			vpts[12] = 1;
			vpts[13] = 1;
			vpts[14] = 1;
			vpts[15] = 1;
			_vbuf.uploadFromVector(vpts, 0, 4);
		}
		return _vbuf;
	}
	
	public static inline function getTextureIndexBuffer (c:Context3D):IndexBuffer3D {
		if (_ibuf == null) {
			_ibuf = c.createIndexBuffer(6);
			var ipts:flash.Vector<UInt> = new flash.Vector<UInt>(6, true);
			ipts[0] = 0;
			ipts[1] = 1;
			ipts[2] = 3;
			
			ipts[3] = 0;
			ipts[4] = 3;
			ipts[5] = 2;
			_ibuf.uploadFromVector(ipts, 0, 6);
		}
		return _ibuf;
	}
	
	public static inline function get2DOrthographicMatrix (w:Float, h:Float, ?n:Float = 1, ?f:Float = 0):Matrix3D {
		return getOrthographicMatrix(0, w, h, 0, n, f);
	}
	
	public static inline function getOrthographicMatrix (l:Float, r:Float, b:Float, t:Float, n:Float, f:Float):Matrix3D {
		var v:flash.Vector<Float> = new flash.Vector<Float>(16, true);
		//First col
		v[0] = 2 / (r - l);
		v[1] = 0;
		v[2] = 0;
		v[3] = 0;
		
		//Second col
		v[4] = 0;
		v[5] = 2 / (t - b);
		v[6] = 0;
		v[7] = 0;
		
		//Third col
		v[8] = 0;
		v[9] = 0;
		v[10] = 2 / (f - n);
		v[11] = 0;
		
		//Fourth col
		v[12] = (r + l) / (l - r);
		v[13] = (t + b) / (b - t);
		v[14] = -n / (f - n);
		v[15] = 1;
		return new Matrix3D(v);
	}
	
	public static inline function getColor (color:UInt):Vector3D {
		return new Vector3D((color & 0x00FF0000) / 0x00FF0000, (color & 0x0000FF00) / 0x0000FF00, (color & 0x000000FF) / 0x000000FF, ((color & 0xFF000000) >>> 24) / 0xFF);
	}
	
	public static inline function addVectorToVertexBuffer (v:Vector3D, vbuf:flash.Vector<Float>):Void {
		vbuf.push(v.x);
		vbuf.push(v.y);
		vbuf.push(v.z);
		vbuf.push(v.w);
	}
	
}
