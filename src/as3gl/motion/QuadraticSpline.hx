/**
 * A quadratic implementation of the Spline interface.
 * @author Sam MacPherson
 */

package as3gl.motion;
import de.polygonal.motor2.geom.math.Vec2;

class QuadraticSpline implements Spline {
	
	private var _a:Float;
	private var _b:Float;
	private var _c:Float;
	
	private var _d:Float;
	private var _e:Float;
	private var _f:Float;
	
	private var _t:Float;
	private var _t2:Float;

	public function new (x1:Float, y1:Float, vx:Float, vy:Float, x2:Float, y2:Float, t:Float) {
		_t = t;
		_t2 = _t * _t;
		
		var invt2:Float = 1 / _t2;
		
		if (t > 0) {
			_a = (x2 - (vx * t) - x1) * invt2;
		} else {
			_a = 0;
		}
		_b = vx;
		_c = x1;
		
		if (t > 0) {
			_d = (y2 - (vy * t) - y1) * invt2;
		} else {
			_d = 0;
		}
		_e = vy;
		_f = y1;
	}
	
	public inline function getPosition (t:Float, out:Vec2):Vec2 {
		var t2:Float = t * t;
		out.x = _a*t2 + _b*t + _c;
		out.y = _d*t2 + _e*t + _f;
		return out;
	}
	
	public inline function getVelocity (t:Float, out:Vec2):Vec2 {
		out.x = 2*_a*t + _b;
		out.y = 2*_d*t + _e;
		return out;
	}
	
	public inline function getTotalTime ():Float {
		return _t;
	}
	
}