/**
 * An image which scales along both axis's (Used for grass, pavement, etc)
 * Points are assumed to be quadratic bezier curves alternating between control points and verticies in that order.
 * The points are also assumed to be oriented clock-wise and must form a closed simple shape.
 * @author Sam MacPherson
 */

package as3gl.map;

import as3gl.display.data.Polygon;
import as3gl.display.data.Vertex;
import as3gl.display.Canvas;
import as3gl.display.SpriteFrame;
import as3gl.geom.Geom;
import as3gl.util.Asset;
import de.polygonal.motor2.geom.math.Vec2;
import de.polygonal.motor2.geom.math.XY;
import de.polygonal.motor2.geom.bv.MinimumAreaRectangle;
import de.polygonal.motor2.geom.primitive.AABB2;
import de.polygonal.motor2.geom.primitive.OBB2;
import flash.display3D.Context3D;
import flash.display3D.IndexBuffer3D;
import flash.display3D.VertexBuffer3D;
import flash.display3D.textures.Texture;
import flash.geom.Matrix3D;
import flash.geom.Vector3D;

@:shader({
	var input:{
		pos:Float2,
		uv:Float2,
		cts:Float2
	};
	var tuv:Float2;
	var ss:Float2;
	function vertex (mpos:M44, mproj:M44) {
		out = pos.xyzw * mpos * mproj;
		tuv = uv;
		ss = cts;
	}
	function fragment (t:Texture, alpha:Float) {
		out = t.get(tuv, wrap) * [1, 1, 1, alpha*lte(ss.x*ss.x - ss.y, 0)];
	}
}) class CurveShader extends format.hxsl.Shader {
}

class Surface extends as3gl.map.Texture {
	
	private static var _SHADER:CurveShader;
	
	private var _cpts:Array<Vec2>;
	private var _pts:Array<Vec2>;
	private var _frame:SpriteFrame;
	
	public function new (asset:Asset, image:Asset, depth:Int, pts:Array<Vec2>, m:Matrix3D) {
		super(asset, image, depth);
		
		_cpts = new Array<Vec2>();
		_pts = new Array<Vec2>();
		for (i in 0 ... pts.length) {
			if (i % 2 == 0) _cpts.push(pts[i]);
			else _pts.push(pts[i]);
		}
		
		//Init frame
		_frame = image.get().get().clone();
		_frame.transform = m;
		var a:Dynamic = pts;
		var bb:OBB2 = new OBB2();
		MinimumAreaRectangle.find(a, bb);
		var v:Array<XY> = new Array<XY>();
		for (i in 0 ... 4) {
			v.push(new Vec2());
		}
		bb.getVertexList(v);
		var pt:Vector3D = m.transformVector(new Vector3D(v[0].x, v[0].y, 0));
		_frame.bounds.set4(pt.x, pt.y, pt.x, pt.y);
		pt = m.transformVector(new Vector3D(v[1].x, v[1].y, 0));
		_frame.bounds.add2(pt.x, pt.y);
		pt = m.transformVector(new Vector3D(v[2].x, v[2].y, 0));
		_frame.bounds.add2(pt.x, pt.y);
		pt = m.transformVector(new Vector3D(v[3].x, v[3].y, 0));
		_frame.bounds.add2(pt.x, pt.y);
		
		_frame.polygon = new Polygon(_frame.polygon.tid);
		
		//Add verticies
		var triangles:Array<Vec2> = Geom.triangulate(pts);
		var index:Int = 0;
		for (i in triangles) {
			var u:Float = i.x / _frame.bitmap.width;
			var v:Float = i.y / _frame.bitmap.height;
			_frame.polygon.addVertex(new Vertex(i.x, i.y, u, v));
			_frame.polygon.indicies.push(index);
			index++;
		}
	}
	
	public inline function getPoints ():Array<Vec2> {
		return _pts;
	}
	
	public override function getFrame ():SpriteFrame {
		return _frame;
	}
	
	public static inline function _getShader (c:Context3D):CurveShader {
		if (_SHADER == null) _SHADER = new CurveShader(c);
		return _SHADER;
	}
	
	public override function runShader (c:Context3D, camera:Matrix3D):Void {
		//Shade inside
		super.runShader(c, camera);
		
		//Shade quadratic curves
		/*Batcher.get().render(c, camera);
		var shader:CurveShader = _getShader(c);
		shader.init(
			{ mpos:getStageTransform(), mproj:camera },
			{ t:_frame.texture, alpha:getStageAlpha() }
		);
		shader.draw(_frame.qvbuf, _frame.qibuf);*/
	}
	
}

/*class SurfaceFrame extends TextureFrame {
	
	public var qvbuf:VertexBuffer3D;
	public var qibuf:IndexBuffer3D;
	
	public function new (frame:SpriteFrame, pts:Array<Vec2>, cpts:Array<Vec2>, m:Matrix3D) {
		var a:Dynamic = pts;
		var bb:OBB2 = new OBB2();
		MinimumAreaRectangle.find(a, bb);
		var v:Array<XY> = new Array<XY>();
		for (i in 0 ... 4) {
			v.push(new Vec2());
		}
		bb.getVertexList(v);
		var pt:Vector3D = m.transformVector(new Vector3D(v[0].x, v[0].y, 0));
		bounds = new AABB2();
		bounds.set4(pt.x, pt.y, pt.x, pt.y);
		pt = m.transformVector(new Vector3D(v[1].x, v[1].y, 0));
		bounds.add2(pt.x, pt.y);
		pt = m.transformVector(new Vector3D(v[2].x, v[2].y, 0));
		bounds.add2(pt.x, pt.y);
		pt = m.transformVector(new Vector3D(v[3].x, v[3].y, 0));
		bounds.add2(pt.x, pt.y);
		texture = frame.texture;
		transform = m;
		this.u = 1;
		this.v = 1;
		
		//Setup vertex buffer
		var triangles:Array<Vec2> = Geom.triangulate(pts);
		vbuf = Canvas.getContext().createVertexBuffer(triangles.length, 4);
		var vpts:flash.Vector<Float> = new flash.Vector<Float>();
		for (i in triangles) {
			vpts.push(i.x);
			vpts.push(i.y);
			vpts.push(i.x / frame.bounds.intervalX);
			vpts.push(i.y / frame.bounds.intervalY);
		}
		vbuf.uploadFromVector(vpts, 0, triangles.length);
		
		//Setup index buffer
		ibuf = Canvas.getContext().createIndexBuffer(triangles.length);
		var ipts:flash.Vector<UInt> = new flash.Vector<UInt>();
		for (i in 0 ... triangles.length) {
			ipts.push(i);
		}
		ibuf.uploadFromVector(ipts, 0, triangles.length);
		
		//Do quadratic bezier curves
		var lastVec:Vec2 = new Vec2();
		qvbuf = Canvas.getContext().createVertexBuffer(pts.length * 3, 6);
		vpts = new flash.Vector<Float>();
		for (i in 0 ... pts.length) {
			vpts.push(lastVec.x);
			vpts.push(lastVec.y);
			vpts.push(lastVec.x / frame.bounds.intervalX);
			vpts.push(lastVec.y / frame.bounds.intervalY);
			vpts.push(0);
			vpts.push(0);
			
			vpts.push(cpts[i].x);
			vpts.push(cpts[i].y);
			vpts.push(cpts[i].x / frame.bounds.intervalX);
			vpts.push(cpts[i].y / frame.bounds.intervalY);
			vpts.push(0.5);
			vpts.push(0);
			
			vpts.push(pts[i].x);
			vpts.push(pts[i].y);
			vpts.push(pts[i].x / frame.bounds.intervalX);
			vpts.push(pts[i].y / frame.bounds.intervalY);
			vpts.push(1);
			vpts.push(1);
			
			lastVec = pts[i];
		}
		qvbuf.uploadFromVector(vpts, 0, pts.length * 3);
		
		qibuf = Canvas.getContext().createIndexBuffer(pts.length * 3);
		ipts = new flash.Vector<UInt>();
		for (i in 0 ... (pts.length * 3)) {
			ipts.push(i);
		}
		qibuf.uploadFromVector(ipts, 0, pts.length * 3);
	}
	
	public function getBounds ():AABB2 {
		return bounds;
	}
	
	public function getTransform ():Matrix3D {
		return transform;
	}
	
}*/
