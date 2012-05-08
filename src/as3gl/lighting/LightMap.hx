/**
 * Renders a lighting mask which can be added to the display list via Bitmap.
 * @author Sam MacPherson
 */

package as3gl.lighting;

import as3gl.core.Destroyable;
import as3gl.core.Runnable;
import as3gl.display.Batcher;
import as3gl.display.Canvas;
import as3gl.display.CanvasObject;
import as3gl.geom.Geom;
import as3gl.util.Molehill;
import as3gl.util.Shaders;
import as3gl.world.WorldAABB2;
import de.polygonal.core.math.Mathematics;
import de.polygonal.ds.mem.BitMemory;
import de.polygonal.ds.mem.IntMemory;
import de.polygonal.ds.mem.MemoryAccess;
import de.polygonal.ds.mem.MemoryManager;
import de.polygonal.ds.Bits;
import de.polygonal.ds.HashMap;
import de.polygonal.ds.SLL;
import de.polygonal.motor2.geom.primitive.AABB2;
import de.polygonal.motor2.geom.math.Vec2;
import flash.display.BitmapData;
import flash.display3D.Context3D;
import flash.display3D.Context3DBlendFactor;
import flash.display3D.Context3DClearMask;
import flash.display3D.Context3DCompareMode;
import flash.display3D.Context3DTextureFormat;
import flash.display3D.IndexBuffer3D;
import flash.display3D.VertexBuffer3D;
import flash.display3D.textures.Texture;
import flash.filters.BlurFilter;
import flash.geom.Matrix3D;
import flash.geom.Point;
import flash.geom.Rectangle;
import flash.geom.Vector3D;
import flash.utils.ByteArray;

@:shader({
	var input:{
		pos:Float2
	};
	function vertex (mpos:M44, mproj:M44) {
		out = pos.xyzw * mpos * mproj;
	}
	function fragment () {
		out = [1, 1, 1, 1];
	}
}) class ObjectShader extends format.hxsl.Shader {
}

@:shader({
	var input:{
		pos:Float2,
		uv:Float2
	};
	var tuv:Float2;
	function vertex (mproj:M44) {
		out = pos.xyzw * mproj;
		tuv = uv;
	}
	function fragment (t:Texture) {
		var dx:Float = tuv.x - 0.5;
		var dy:Float = tuv.y - 0.5;
		out = if (t.get(tuv, nearest).x > 0) sqrt(dx*dx + dy*dy).xxxx else 1.xxxx;
	}
}) class DistanceShader extends format.hxsl.Shader {
}

@:shader({
	var input:{
		pos:Float2,
		uv:Float2
	};
	var tuv:Float2;
	function vertex (mproj:M44) {
		out = pos.xyzw * mproj;
		tuv = uv;
	}
	function fragment (t:Texture) {
		var u0 = tuv.x * 2 - 1;
		var v0 = tuv.y * 2 - 1;
		v0 = v0 * abs(u0);
		v0 = (v0 + 1) / 2;
		out = [t.get([tuv.x, v0], nearest).x, t.get([v0, tuv.x], nearest).x, 0, 1];
	}
}) class DistortionShader extends format.hxsl.Shader {
}

@:shader({
	var input:{
		pos:Float2,
		uv:Float2
	};
	var tuv:Float2;
	var dx:Float;
	function vertex (mproj:M44, pixel:Float) {
		out = pos.xyzw * mproj;
		tuv = uv;
		dx = pixel;
	}
	function fragment (t:Texture) {
		out = min(t.get(tuv + [-dx, 0], nearest), t.get(tuv + [0, 0], nearest));
	}
}) class MinDistanceShader extends format.hxsl.Shader {
}

@:shader({
	var input:{
		pos:Float2,
		uv:Float2
	};
	function getShadowDistanceH (t:Texture, pos:Float2):Float {
		var u:Float = pos.x;
		var v:Float = pos.y;
		
		u = abs(u-0.5) * 2;
		v = v * 2 - 1;
		var v0:Float = v/u;
		v0 = (v0 + 1) / 2;
		
		return t.get([pos.x, v0], nearest).x;
	}
	function getShadowDistanceV (t:Texture, pos:Float2):Float {
		var u:Float = pos.y;
		var v:Float = pos.x;
		
		u = abs(u-0.5) * 2;
		v = v * 2 - 1;
		var v0:Float = v/u;
		v0 = (v0 + 1) / 2;
		
		return t.get([pos.y, v0], nearest).y;
	}
	var tuv:Float2;
	function vertex (mproj:M44) {
		out = pos.xyzw * mproj;
		tuv = uv;
	}
	function fragment (t:Texture, shadowColor:Float4, v1:Float2, v2:Float2, v3:Float2) {
		var duv:Float3 = tuv.xyz - [0.5, 0.5, 0];
		var dx:Float = tuv.x - 0.5;
		var dy:Float = tuv.y - 0.5;
		var d:Float = sqrt(dx*dx + dy*dy);
		//var d:Float = len(tuv - [0.5, 0.5]);
		var a:Float = min(d*2, 1);
		var sd:Float = if (abs(duv.y) < abs(duv.x)) getShadowDistanceH(t, tuv) else getShadowDistanceV(t, tuv);
		out = if (d < 0.5) if (d < sd) if (crs([v2.x, v2.y, 0], duv).z >= 0) if (crs(duv, [v1.x, v1.y, 0]).z >= 0) shadowColor*a else shadowColor else if (crs([v3.x, v3.y, 0], duv).z >= 0) shadowColor*a else shadowColor else shadowColor else shadowColor;
	}
}) class ShadowMapShader extends format.hxsl.Shader {
}

@:shader({
	var input:{
		pos:Float2,
		uv:Float2
	};
	function getShadowDistanceH (t:Texture, pos:Float2):Float {
		var u:Float = pos.x;
		var v:Float = pos.y;
		
		u = abs(u-0.5) * 2;
		v = v * 2 - 1;
		var v0:Float = v/u;
		v0 = (v0 + 1) / 2;
		
		return t.get([pos.x, v0], nearest).x;
	}
	function getShadowDistanceV (t:Texture, pos:Float2):Float {
		var u:Float = pos.y;
		var v:Float = pos.x;
		
		u = abs(u-0.5) * 2;
		v = v * 2 - 1;
		var v0:Float = v/u;
		v0 = (v0 + 1) / 2;
		
		return t.get([pos.y, v0], nearest).y;
	}
	var tuv:Float2;
	function vertex (mproj:M44) {
		out = pos.xyzw * mproj;
		tuv = uv;
	}
	function fragment (t:Texture, color:Float4, v1:Float2, v2:Float2, v3:Float2) {
		var duv:Float3 = tuv.xyz - [0.5, 0.5, 0];
		var dx:Float = tuv.x - 0.5;
		var dy:Float = tuv.y - 0.5;
		var d:Float = sqrt(dx*dx + dy*dy);
		//var d:Float = len(tuv - [0.5, 0.5]);
		var sd:Float = if (abs(duv.y) < abs(duv.x)) getShadowDistanceH(t, tuv) else getShadowDistanceV(t, tuv);
		var a:Float = min((0.5 - d)*2, 1);
		out = if (d < 0.5) if (d < sd) if (crs([v2.x, v2.y, 0], duv).z >= 0) if (crs(duv, [v1.x, v1.y, 0]).z >= 0) color*a else [0, 0, 0, 0] else if (crs([v3.x, v3.y, 0], duv).z >= 0) color*a else [0, 0, 0, 0] else [0, 0, 0, 0] else [0, 0, 0, 0];
	}
}) class LightShader extends format.hxsl.Shader {
}

@:shader({
	var input:{
		pos:Float2,
		uv:Float2,
		copy:Float,
		suv:Float2
	};
	var tuv:Float2;
	var tcopy:Float;
	var stuv:Float2;
	function vertex (mproj:M44) {
		out = pos.xyzw * mproj;
		tuv = uv;
		tcopy = copy;
		stuv = suv;
	}
	function fragment (t:Texture, sm:Texture, baseShadow:Float) {
		out = if (tcopy > 0) sm.get(tuv) else [0, 0, 0, sm.get(stuv).w + t.get(tuv).w - baseShadow];
	}
}) class ShadowMergeShader extends format.hxsl.Shader {
}

@:shader({
	var input:{
		pos:Float2,
		uv:Float2
	};
	var tuv:Float2;
	var dx:Float;
	function vertex (mproj:M44, pixelX:Float) {
		out = pos.xyzw * mproj;
		tuv = uv;
		dx = pixelX;
	}
	function fragment (t:Texture, mult:Float) {
		//Due to temp register limit of 8 some samples need to be done multiple times
		var s1:Float4 = t.get(tuv + [-dx * 4, 0], clamp);
		var s2:Float4 = t.get(tuv + [-dx * 3, 0], clamp);
		var s3:Float4 = t.get(tuv + [-dx * 2, 0], clamp);
		var s7:Float4 = t.get(tuv + [dx * 2, 0], clamp);
		var s8:Float4 = t.get(tuv + [dx * 3, 0], clamp);
		var s9:Float4 = t.get(tuv + [dx * 4, 0], clamp);
		var avgw:Float = (s1.w + s2.w + s3.w + t.get(tuv + [-dx, 0], clamp).w + t.get(tuv, clamp).w + t.get(tuv + [dx, 0], clamp).w + s7.w + s8.w + s9.w) / 9;
		var sum:Float4 = [0, 0, 0, 0];
		
		sum += s1 * 0.05 * ((avgw - s1.w)*mult + 1);
		sum += s2 * 0.09 * ((avgw - s2.w)*mult + 1);
		sum += s3 * 0.12 * ((avgw - s3.w)*mult + 1);
		sum += t.get(tuv + [-dx, 0], clamp) * 0.15 * ((avgw - t.get(tuv + [-dx, 0], clamp).w)*mult + 1);
		sum += t.get(tuv, clamp) * 0.18 * ((avgw - t.get(tuv, clamp).w)*mult + 1);
		sum += t.get(tuv + [dx, 0], clamp) * 0.15 * ((avgw - t.get(tuv + [dx, 0], clamp).w)*mult + 1);
		sum += s7 * 0.12 * ((avgw - s7.w)*mult + 1);
		sum += s8 * 0.09 * ((avgw - s8.w)*mult + 1);
		sum += s9 * 0.05 * ((avgw - s9.w)*mult + 1);
		
		out = sum;
	}
}) class HorizontalBlurShader extends format.hxsl.Shader {
}

@:shader({
	var input:{
		pos:Float2,
		uv:Float2
	};
	var tuv:Float2;
	var dy:Float;
	function vertex (mpos:M44, mproj:M44, pixelY:Float) {
		out = pos.xyzw * mpos * mproj;
		tuv = uv;
		dy = pixelY;
	}
	function fragment (t:Texture, mult:Float) {
		var s1:Float4 = t.get(tuv + [0, -dy * 4], clamp);
		var s2:Float4 = t.get(tuv + [0, -dy * 3], clamp);
		var s3:Float4 = t.get(tuv + [0, -dy * 2], clamp);
		var s7:Float4 = t.get(tuv + [0, dy * 2], clamp);
		var s8:Float4 = t.get(tuv + [0, dy * 3], clamp);
		var s9:Float4 = t.get(tuv + [0, dy * 4], clamp);
		var avgw:Float = (s1.w + s2.w + s3.w + t.get(tuv + [0, -dy], clamp).w + t.get(tuv, clamp).w + t.get(tuv + [0, dy], clamp).w + s7.w + s8.w + s9.w) / 9;
		var sum:Float4 = [0, 0, 0, 0];
		
		sum += s1 * 0.05 * ((avgw - s1.w)*mult + 1);
		sum += s2 * 0.09 * ((avgw - s2.w)*mult + 1);
		sum += s3 * 0.12 * ((avgw - s3.w)*mult + 1);
		sum += t.get(tuv + [0, -dy], clamp) * 0.15 * ((avgw - t.get(tuv + [0, -dy], clamp).w)*mult + 1);
		sum += t.get(tuv, clamp) * 0.18 * ((avgw - t.get(tuv, clamp).w)*mult + 1);
		sum += t.get(tuv + [0, dy], clamp) * 0.15 * ((avgw - t.get(tuv + [0, dy], clamp).w)*mult + 1);
		sum += s7 * 0.12 * ((avgw - s7.w)*mult + 1);
		sum += s8 * 0.09 * ((avgw - s8.w)*mult + 1);
		sum += s9 * 0.05 * ((avgw - s9.w)*mult + 1);
		
		out = sum;
	}
}) class VerticalBlurShader extends format.hxsl.Shader {
}

class LightMap extends CanvasObject, implements Destroyable {
	
	public static var QUALITY_VERY_LOW:Int = 64;
	public static var QUALITY_LOW:Int = 128;
	public static var QUALITY_MEDIUM:Int = 256;
	public static var QUALITY_HIGH:Int = 512;
	public static var QUALITY_VERY_HIGH:Int = 1024;
	public static var QUALITY_BEST:Int = 2048;
	
	private var _w:Int;
	private var _h:Int;
	private var _mapW:Int;
	private var _mapH:Int;
	private var _x:Int;
	private var _y:Int;
	private var _floor:Int;
	private var _lightSources:SLL<LightSource>;
	private var _floors:Int;
	private var _vbufs:Array<VertexBuffer3D>;
	private var _ibufs:Array<IndexBuffer3D>;
	private var _tbuf1:Texture;
	private var _tbuf2:Texture;
	private var _distBufs:Array<Texture>;
	private var _sbuf1:Texture;
	private var _sbuf2:Texture;
	private var _lightQuality:Int;
	private var _baseAlpha:Float;
	private var _lightCache:HashMap<LightSource, CachedTexture>;
	private var _cachedTextures:SLL<CachedTexture>;
	private var _cacheExpiry:Int;
	
	private var _objectShader:ObjectShader;
	private var _distanceShader:DistanceShader;
	private var _distortionShader:DistortionShader;
	private var _minDistanceShader:MinDistanceShader;
	private var _shadowMapShader:ShadowMapShader;
	private var _lightShader:LightShader;
	private var _shadowMergeShader:ShadowMergeShader;
	private var _horBlurShader:HorizontalBlurShader;
	private var _vertBlurShader:VerticalBlurShader;
	
	public function new (scrWidth:Int, scrHeight:Int, mapWidth:Int, mapHeight:Int, obstructions:Array<WorldAABB2>, lightQuality:Int, baseAlpha:Float, ?cacheExpiry:Int = 300) {
		super();
		
		_w = scrWidth;
		_h = scrHeight;
		_mapW = mapWidth;
		_mapH = mapHeight;
		_lightSources = new SLL<LightSource>();
		_lightQuality = lightQuality;
		_baseAlpha = baseAlpha;
		_cachedTextures = new SLL<CachedTexture>();
		_lightCache = new HashMap<LightSource, CachedTexture>();
		_cacheExpiry = cacheExpiry;
		_tbuf1 = Canvas.getContext().createTexture(_lightQuality, _lightQuality, Context3DTextureFormat.BGRA, true);
		_tbuf2 = Canvas.getContext().createTexture(_lightQuality, _lightQuality, Context3DTextureFormat.BGRA, true);
		_sbuf1 = Canvas.getContext().createTexture(_lightQuality, _lightQuality, Context3DTextureFormat.BGRA, true);
		_sbuf2 = Canvas.getContext().createTexture(_lightQuality, _lightQuality, Context3DTextureFormat.BGRA, true);
		_distBufs = new Array<Texture>();
		var dim:Int = lightQuality >> 1;
		while (dim > 1) {
			_distBufs.push(Canvas.getContext().createTexture(dim, _lightQuality, Context3DTextureFormat.BGRA, true));
			dim >>= 1;
		}
		
		_floors = 1;
		for (i in obstructions) {
			if (i.floor + 1 > _floors) {
				_floors = i.floor + 1;
			}
		}
		
		var obsCpy:Array<WorldAABB2> = new Array<WorldAABB2>();
		for (i in obstructions) {
			obsCpy.push(i);
		}
		obstructions = obsCpy;
		for (i in 0 ... _floors) {
			var found:Bool = false;
			for (o in obstructions) {
				if (o.floor == i) {
					found = true;
					break;
				}
			}
			if (!found) {
				obstructions.push(new WorldAABB2(-1, -1, 0, 0, i));
			}
		}
		
		_genBuffers(obstructions);
		_initShaders();
	}
	
	public function destroy ():Void {
		_tbuf1.dispose();
		_tbuf2.dispose();
		_sbuf1.dispose();
		_sbuf2.dispose();
		for (i in _distBufs) {
			i.dispose();
		}
	}
	
	private inline function _genBuffers (rects:Array<WorldAABB2>):Void {
		_vbufs = new Array<VertexBuffer3D>();
		_ibufs = new Array<IndexBuffer3D>();
		
		var vpts:Array<flash.Vector<Float>> = new Array<flash.Vector<Float>>();
		for (i in 0 ... _floors) {
			vpts[i] = new flash.Vector<Float>();
		}
		var ipts:Array<flash.Vector<UInt>> = new Array<flash.Vector<UInt>>();
		for (i in 0 ... _floors) {
			ipts[i] = new flash.Vector<UInt>();
		}
		
		for (i in rects) {
			var index:Int = Std.int(vpts[i.floor].length / 2);
			
			//Vertex buffer
			vpts[i.floor].push(i.xmin);
			vpts[i.floor].push(i.ymin);
			
			vpts[i.floor].push(i.xmax);
			vpts[i.floor].push(i.ymin);
			
			vpts[i.floor].push(i.xmin);
			vpts[i.floor].push(i.ymax);
			
			vpts[i.floor].push(i.xmax);
			vpts[i.floor].push(i.ymax);
			
			//Index buffer
			ipts[i.floor].push(index);
			ipts[i.floor].push(index + 1);
			ipts[i.floor].push(index + 3);
			
			ipts[i.floor].push(index);
			ipts[i.floor].push(index + 3);
			ipts[i.floor].push(index + 2);
		}
		
		for (i in 0 ... _floors) {
			_vbufs[i] = Canvas.getContext().createVertexBuffer(Std.int(vpts[i].length / 2), 2);
			_vbufs[i].uploadFromVector(vpts[i], 0, Std.int(vpts[i].length / 2));
			_ibufs[i] = Canvas.getContext().createIndexBuffer(ipts[i].length);
			_ibufs[i].uploadFromVector(ipts[i], 0, ipts[i].length);
		}
	}
	
	private inline function _initShaders ():Void {
		_objectShader = new ObjectShader(Canvas.getContext());
		_distanceShader = new DistanceShader(Canvas.getContext());
		_distortionShader = new DistortionShader(Canvas.getContext());
		_minDistanceShader = new MinDistanceShader(Canvas.getContext());
		_shadowMapShader = new ShadowMapShader(Canvas.getContext());
		_lightShader = new LightShader(Canvas.getContext());
		_shadowMergeShader = new ShadowMergeShader(Canvas.getContext());
		_horBlurShader = new HorizontalBlurShader(Canvas.getContext());
		_vertBlurShader = new VerticalBlurShader(Canvas.getContext());
	}
	
	public inline function setLocation (x:Int, y:Int, floor:Int):Void {
		_x = x;
		_y = y;
		_floor = floor;
	}
	
	public inline function moveLocation (dx:Int, dy:Int, df:Int):Void {
		setLocation(_x + dx, _y + dy, _floor + df);
	}
	
	private inline function _getCachedTexture ():CachedTexture {
		if (!_cachedTextures.isEmpty()) {
			var t:CachedTexture = _cachedTextures.removeHead();
			t.unused = 0;
			return t;
		} else {
			return new CachedTexture(Canvas.getContext().createTexture(_lightQuality, _lightQuality, Context3DTextureFormat.BGRA, true), Canvas.getContext().createTexture(_lightQuality, _lightQuality, Context3DTextureFormat.BGRA, true));
		}
	}
	
	private inline function _putCachedTexture (t:CachedTexture):Void {
		_cachedTextures.append(t);
	}
	
	public override function runShader (c:Context3D, camera:Matrix3D):Void {
		//Custom shader need to flush batcher
		Batcher.get().render(c, camera);
		
		//Find active lights and their bounding boxes
		var activeLights:Array<BoundingLight> = new Array<BoundingLight>();
		for (i in _lightSources) {
			if (i.isLightOn() && i.getLightRange() > 0 && i.getLightFloor() == _floor) {
				var bb:AABB2 = _getLightBoundingBox(i);
				if (Geom.intersectsAABBvsAABB8(_x, _y, _x + _w, _y + _h, bb.xmin, bb.ymin, bb.xmax, bb.ymax)) {
					activeLights.push(new BoundingLight(bb, i));
				} else {
					var cl:CachedTexture = _lightCache.get(i);
					if (cl != null) {
						if (cl.unused++ >= _cacheExpiry) {
							_putCachedTexture(cl);
							_lightCache.clr(i);
						}
					}
				}
			}
		}
		
		var v1:Vector3D = new Vector3D();
		var v2:Vector3D = new Vector3D();
		var v3:Vector3D = new Vector3D();
		var m:Matrix3D = new Matrix3D();
		var unitCam:Matrix3D = Molehill.get2DOrthographicMatrix(1, 1);
		var index:Int = 0;
		c.setRenderToTexture(_sbuf1);
		c.clear(0, 0, 0, _baseAlpha);
		c.setRenderToTexture(_sbuf2);
		c.clear(0, 0, 0, _baseAlpha);
		
		//Draw lights
		for (i in activeLights) {
			//Init vars
			m.identity();
			m.appendTranslation(-i.bounds.xmin, -i.bounds.ymin, 0);
			var angle:Float = i.light.getLightAngle() + Math.PI;
			v1.x = Math.cos(angle - i.light.getLightArc()*0.5);
			v1.y = Math.sin(angle - i.light.getLightArc()*0.5);
			v2.x = Math.cos(angle);
			v2.y = Math.sin(angle);
			v3.x = Math.cos(angle + i.light.getLightArc()*0.5);
			v3.y = Math.sin(angle + i.light.getLightArc()*0.5);
			var texCam:Matrix3D = Molehill.get2DOrthographicMatrix(i.bounds.intervalX, i.bounds.intervalY);
			var vbuf:VertexBuffer3D = Molehill.getRectangularVertexBuffer(c, 0, 0, i.bounds.intervalX, i.bounds.intervalY);
			var ibuf:IndexBuffer3D = Molehill.getTextureIndexBuffer(c);
			c.setBlendFactors(Context3DBlendFactor.ONE, Context3DBlendFactor.ZERO);
			
			//Check if light is cached
			var cl:CachedTexture = _lightCache.get(i.light);
			var shadow:Texture = null;
			var light:Texture = null;
			if (cl == null) {
				//First pass write out objects
				c.setRenderToTexture(_tbuf1);
				c.clear();
				_objectShader.init(
					{ mpos:m, mproj:texCam },
					{ }
				);
				_objectShader.draw(_vbufs[_floor], _ibufs[_floor]);
				
				//Second pass write out distances
				c.setRenderToTexture(_tbuf2);
				c.clear();
				_distanceShader.init(
					{ mproj:texCam },
					{ t:_tbuf1 }
				);
				_distanceShader.draw(vbuf, ibuf);
				
				//Third pass image distortion
				c.setRenderToTexture(_tbuf1);
				c.clear();
				_distortionShader.init(
					{ mproj:texCam },
					{ t:_tbuf2 }
				);
				_distortionShader.draw(vbuf, ibuf);
				
				//Fourth pass calculate minimum distance
				for (i in 0 ... _distBufs.length) {
					c.setRenderToTexture(_distBufs[i]);
					c.clear();
					_minDistanceShader.init(
						{ mproj:texCam, pixel:1/(_lightQuality >> i) },
						{ t:if (i == 0) _tbuf1 else _distBufs[i - 1] }
					);
					_minDistanceShader.draw(vbuf, ibuf);
				}
				
				//Check if we are caching this light
				if (i.light.cacheLight()) {
					cl = _getCachedTexture();
					_lightCache.set(i.light, cl);
					shadow = cl.shadow;
					light = cl.light;
				} else {
					shadow = _tbuf1;
					light = _tbuf2;
				}
				
				//Render light to back buffer after blur filter
				c.setRenderToTexture(_tbuf1);
				c.clear();
				_lightShader.init(
					{ mproj:texCam },
					{ t:_distBufs[_distBufs.length - 1], color:Molehill.getColor(i.light.getLightColor()), v1:v1, v2:v2, v3:v3 }
				);
				_lightShader.draw(vbuf, ibuf);
				
				//Horizontal blur
				c.setRenderToTexture(light);
				c.clear();
				_horBlurShader.init(
					{ mproj:texCam, pixelX:1/_lightQuality },
					{ t:_tbuf1, mult:-1.0 }
				);
				_horBlurShader.draw(vbuf, ibuf);
				
				//Fifth pass draw shadow map
				c.setRenderToTexture(shadow);
				c.clear();
				_shadowMapShader.init(
					{ mproj:texCam },
					{ t:_distBufs[_distBufs.length - 1], shadowColor:new Vector3D(0, 0, 0, _baseAlpha), v1:v1, v2:v2, v3:v3 }
				);
				_shadowMapShader.draw(vbuf, ibuf);
			} else {
				cl.unused = 0;
				shadow = cl.shadow;
				light = cl.light;
			}
			
			//Sixth pass merge to cumulative shadow map
			var svbuf:VertexBuffer3D = _getShadowMapVertexBuffer(i.bounds);
			var sibuf:IndexBuffer3D = _getShadowMapIndexBuffer();
			
			c.setRenderToTexture(if (index % 2 == 0) _sbuf2 else _sbuf1);
			c.clear();
			_shadowMergeShader.init(
				{ mproj:unitCam },
				{ t:shadow, sm:if (index % 2 == 0) _sbuf1 else _sbuf2, baseShadow:_baseAlpha }
			);
			_shadowMergeShader.draw(svbuf, sibuf);
				
			//Draw light
			c.setRenderToBackBuffer();
			c.setDepthTest(false, Context3DCompareMode.ALWAYS);
			c.setBlendFactors(Context3DBlendFactor.SOURCE_ALPHA, Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA);
			m.appendTranslation(i.bounds.xmin * 2 - _x, i.bounds.ymin * 2 - _y, 0);
			m.append(getStageTransform());
			_vertBlurShader.init(
				{ mpos:m, mproj:camera, pixelY:1/_lightQuality },
				{ t:light, mult:-1.0 }
			);
			_vertBlurShader.draw(vbuf, ibuf);
			
			//Increment index to alternate buffers
			index++;
			
			//Cleanup
			svbuf.dispose();
			sibuf.dispose();
			vbuf.dispose();
		}
		
		//Render shadow map after applying a blur effect
		//Horizontal blur
		c.setBlendFactors(Context3DBlendFactor.ONE, Context3DBlendFactor.ZERO);
		c.setRenderToTexture(if (index % 2 == 0) _sbuf2 else _sbuf1);
		c.clear();
		_horBlurShader.init(
			{ mproj:unitCam, pixelX:1/_lightQuality },
			{ t:if (index % 2 == 0) _sbuf1 else _sbuf2, mult:1.0 }
		);
		_horBlurShader.draw(Molehill.getTextureVertexBuffer(c), Molehill.getTextureIndexBuffer(c));
		
		//Vertical blur
		c.setRenderToBackBuffer();
		c.setDepthTest(false, Context3DCompareMode.ALWAYS);
		c.setBlendFactors(Context3DBlendFactor.SOURCE_ALPHA, Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA);
		var screenTransform:Matrix3D = new Matrix3D();
		screenTransform.appendScale(Canvas.SCREEN_WIDTH, Canvas.SCREEN_HEIGHT, 1);
		screenTransform.append(getStageTransform());
		_vertBlurShader.init(
			{ mpos:screenTransform, mproj:camera, pixelY:1/_lightQuality },
			{ t:if (index % 2 == 0) _sbuf2 else _sbuf1, mult:1.0 }
		);
		_vertBlurShader.draw(Molehill.getTextureVertexBuffer(c), Molehill.getTextureIndexBuffer(c));
		
		c.setDepthTest(true, Context3DCompareMode.LESS);
	}
	
	private inline function _getShadowMapVertexBuffer (bounds:AABB2):VertexBuffer3D {
		var vbuf:VertexBuffer3D = Canvas.getContext().createVertexBuffer(8, 7);
		var vpts:flash.Vector<Float> = new flash.Vector<Float>();
		
		vpts.push(0);
		vpts.push(0);
		vpts.push(0);
		vpts.push(0);
		vpts.push(1);
		vpts.push(0);
		vpts.push(0);
		
		vpts.push(1);
		vpts.push(0);
		vpts.push(1);
		vpts.push(0);
		vpts.push(1);
		vpts.push(0);
		vpts.push(0);
		
		vpts.push(0);
		vpts.push(1);
		vpts.push(0);
		vpts.push(1);
		vpts.push(1);
		vpts.push(0);
		vpts.push(0);
		
		vpts.push(1);
		vpts.push(1);
		vpts.push(1);
		vpts.push(1);
		vpts.push(1);
		vpts.push(0);
		vpts.push(0);
		
		vpts.push((bounds.xmin - _x) / Canvas.SCREEN_WIDTH);
		vpts.push((bounds.ymin - _y) / Canvas.SCREEN_HEIGHT);
		vpts.push(0);
		vpts.push(0);
		vpts.push(0);
		vpts.push((bounds.xmin - _x) / Canvas.SCREEN_WIDTH);
		vpts.push((bounds.ymin - _y) / Canvas.SCREEN_HEIGHT);
		
		vpts.push((bounds.xmax - _x) / Canvas.SCREEN_WIDTH);
		vpts.push((bounds.ymin - _y) / Canvas.SCREEN_HEIGHT);
		vpts.push(1);
		vpts.push(0);
		vpts.push(0);
		vpts.push((bounds.xmax - _x) / Canvas.SCREEN_WIDTH);
		vpts.push((bounds.ymin - _y) / Canvas.SCREEN_HEIGHT);
		
		vpts.push((bounds.xmin - _x) / Canvas.SCREEN_WIDTH);
		vpts.push((bounds.ymax - _y) / Canvas.SCREEN_HEIGHT);
		vpts.push(0);
		vpts.push(1);
		vpts.push(0);
		vpts.push((bounds.xmin - _x) / Canvas.SCREEN_WIDTH);
		vpts.push((bounds.ymax - _y) / Canvas.SCREEN_HEIGHT);
		
		vpts.push((bounds.xmax - _x) / Canvas.SCREEN_WIDTH);
		vpts.push((bounds.ymax - _y) / Canvas.SCREEN_HEIGHT);
		vpts.push(1);
		vpts.push(1);
		vpts.push(0);
		vpts.push((bounds.xmax - _x) / Canvas.SCREEN_WIDTH);
		vpts.push((bounds.ymax - _y) / Canvas.SCREEN_HEIGHT);
		
		vbuf.uploadFromVector(vpts, 0, 8);
		return vbuf;
	}
	
	private inline function _getShadowMapIndexBuffer ():IndexBuffer3D {
		var ibuf:IndexBuffer3D = Canvas.getContext().createIndexBuffer(12);
		var ipts:flash.Vector<UInt> = new flash.Vector<UInt>();
		
		ipts.push(0);
		ipts.push(1);
		ipts.push(3);
		
		ipts.push(0);
		ipts.push(3);
		ipts.push(2);
		
		ipts.push(4);
		ipts.push(5);
		ipts.push(7);
		
		ipts.push(4);
		ipts.push(7);
		ipts.push(6);
		
		ibuf.uploadFromVector(ipts, 0, 12);
		return ibuf;
	}
	
	private inline function _getLightBoundingBox (source:LightSource):AABB2 {
		return new AABB2(source.getLightX() - source.getLightRange(), source.getLightY() - source.getLightRange(), source.getLightX() + source.getLightRange(), source.getLightY() + source.getLightRange());
	}
	
	public inline function addLightSource (source:LightSource):Void {
		removeLightSource(source);
		_lightSources.append(source);
	}
	
	public inline function removeLightSource (source:LightSource):Void {
		_lightSources.remove(source);
	}
	
}

private class BoundingLight {
	
	public var bounds:AABB2;
	public var light:LightSource;
	
	public function new (bounds:AABB2, light:LightSource) {
		this.bounds = bounds;
		this.light = light;
	}
	
}

private class CachedTexture {
	
	public var shadow:Texture;
	public var light:Texture;
	public var unused:Int;
	
	public function new (shadow:Texture, light:Texture) {
		this.shadow = shadow;
		this.light = light;
		this.unused = 0;
	}
	
}
