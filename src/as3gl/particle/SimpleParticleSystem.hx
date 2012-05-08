/**
 * A particle system that involves n particle quads with pre-defined positions, velocities and accelerations.
 * Linear color and scale transformations are also provided.
 * A time value is provided to the shader which cycles between 0 to 1 in the given interval.
 * @author Sam MacPherson
 */

package as3gl.particle;

import as3gl.core.Destroyable;
import as3gl.display.Batcher;
import as3gl.display.Canvas;
import as3gl.display.CanvasObject;
import as3gl.display.data.Quad;
import as3gl.util.Molehill;
import flash.display3D.Context3D;
import flash.display3D.IndexBuffer3D;
import flash.display3D.VertexBuffer3D;
import flash.display3D.textures.Texture;
import flash.geom.Matrix3D;

@:shader({
	var input:{
		pos:Float3,
		t0:Float4,
		t1:Float4,
		t2:Float4,
		t3:Float4,
		color:Float4,
		velColor:Float4,
		accelColor:Float4
	};
	var tuv:Float2;
	var tcolor:Float4;
	function vertex (mproj:M44, mpos:M44, t:Float, depth:Float) {
		var dt:Float = frac(pos.z + t);
		var a:Float = 0.5*dt*dt;
		var scale:Float2 = [t0.w + t2.x*dt + t3.y*a, t1.x + t2.y*dt + t3.z*a];
		var angle:Float = t0.z + t1.w*dt + t3.x*a;
		var rot:Float2 = [cos(angle), sin(angle)];
		var endPos:Float4;
		endPos.x = pos.x*scale.x*rot.x - pos.y*scale.y*rot.y + t0.x + t1.y*dt + t2.z*a;
		endPos.y = pos.x*scale.x*rot.y + pos.y*scale.y*rot.x + t0.y + t1.z*dt + t2.w*a;
		endPos.z = depth;
		endPos.w = 1;
		out = endPos.xyzw * mpos * mproj;
		tuv = [pos.x, pos.y];
		tcolor = color + 0.5*velColor + a*accelColor;
	}
	function fragment () {
		kill(0.5 - sqrt(tuv.x*tuv.x + tuv.y*tuv.y));
		out = tcolor;
	}
}) class Shader extends format.hxsl.Shader {
}

class SimpleParticleSystem extends CanvasObject, implements Destroyable {
	
	private var _vpts:flash.Vector<Float>;
	private var _vbuf:VertexBuffer3D;
	private var _ipts:flash.Vector<UInt>;
	private var _ibuf:IndexBuffer3D;
	private var _cyclelen:Int;
	private var _currTime:Int;
	private var _shader:Shader;

	public function new (cyclelen:Int) {
		super();
		
		_cyclelen = cyclelen;
		_currTime = 0;
		_vpts = new flash.Vector<Float>();
		_ipts = new flash.Vector<UInt>();
	}
	
	public function destroy ():Void {
		if (_vbuf != null) _vbuf.dispose();
		if (_ibuf != null) _ibuf.dispose();
	}
	
	public function addParticle (particle:SimpleParticle):Void {
		var baseIndex:Int = Std.int(_vpts.length / 31);
		
		_vpts.push(-0.5);
		_vpts.push(-0.5);
		_vpts.push(particle.timeOffset);
		Molehill.addVectorToVertexBuffer(particle.transform[0], _vpts);
		Molehill.addVectorToVertexBuffer(particle.transform[1], _vpts);
		Molehill.addVectorToVertexBuffer(particle.transform[2], _vpts);
		Molehill.addVectorToVertexBuffer(particle.transform[3], _vpts);
		Molehill.addVectorToVertexBuffer(particle.color, _vpts);
		Molehill.addVectorToVertexBuffer(particle.velColor, _vpts);
		Molehill.addVectorToVertexBuffer(particle.accelColor, _vpts);
		
		_vpts.push(0.5);
		_vpts.push(-0.5);
		_vpts.push(particle.timeOffset);
		Molehill.addVectorToVertexBuffer(particle.transform[0], _vpts);
		Molehill.addVectorToVertexBuffer(particle.transform[1], _vpts);
		Molehill.addVectorToVertexBuffer(particle.transform[2], _vpts);
		Molehill.addVectorToVertexBuffer(particle.transform[3], _vpts);
		Molehill.addVectorToVertexBuffer(particle.color, _vpts);
		Molehill.addVectorToVertexBuffer(particle.velColor, _vpts);
		Molehill.addVectorToVertexBuffer(particle.accelColor, _vpts);
		
		_vpts.push(-0.5);
		_vpts.push(0.5);
		_vpts.push(particle.timeOffset);
		Molehill.addVectorToVertexBuffer(particle.transform[0], _vpts);
		Molehill.addVectorToVertexBuffer(particle.transform[1], _vpts);
		Molehill.addVectorToVertexBuffer(particle.transform[2], _vpts);
		Molehill.addVectorToVertexBuffer(particle.transform[3], _vpts);
		Molehill.addVectorToVertexBuffer(particle.color, _vpts);
		Molehill.addVectorToVertexBuffer(particle.velColor, _vpts);
		Molehill.addVectorToVertexBuffer(particle.accelColor, _vpts);
		
		_vpts.push(0.5);
		_vpts.push(0.5);
		_vpts.push(particle.timeOffset);
		Molehill.addVectorToVertexBuffer(particle.transform[0], _vpts);
		Molehill.addVectorToVertexBuffer(particle.transform[1], _vpts);
		Molehill.addVectorToVertexBuffer(particle.transform[2], _vpts);
		Molehill.addVectorToVertexBuffer(particle.transform[3], _vpts);
		Molehill.addVectorToVertexBuffer(particle.color, _vpts);
		Molehill.addVectorToVertexBuffer(particle.velColor, _vpts);
		Molehill.addVectorToVertexBuffer(particle.accelColor, _vpts);
		
		_ipts.push(baseIndex);
		_ipts.push(baseIndex + 1);
		_ipts.push(baseIndex + 3);
		
		_ipts.push(baseIndex);
		_ipts.push(baseIndex + 3);
		_ipts.push(baseIndex + 2);
	}
	
	public function finished (c:Context3D):Void {
		_shader = new Shader(c);
		_vbuf = c.createVertexBuffer(Std.int(_vpts.length / 31), 31);
		_vbuf.uploadFromVector(_vpts, 0, Std.int(_vpts.length / 31));
		_ibuf = c.createIndexBuffer(_ipts.length);
		_ibuf.uploadFromVector(_ipts, 0, _ipts.length);
		_vpts = null;
		_ipts = null;
	}
	
	public override function runShader (c:Context3D, camera:Matrix3D):Void {
		_shader.init(
			{ mproj:camera, mpos:getStageTransform(), t:(_currTime / _cyclelen), depth:Canvas.getNextDepth() },
			{ }
		);
		_shader.draw(_vbuf, _ibuf);
		
		if (_currTime++ >= _cyclelen) {
			_currTime = 0;
		}
	}
	
}