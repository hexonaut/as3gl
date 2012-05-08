/**
 * A cubic implementation of the Spline interface.
 * @author Sam MacPherson
 */

package as3gl.motion;
import de.polygonal.motor2.geom.math.Vec2;

class CubicSpline implements Spline {
	
	private var _a:Float;
	private var _b:Float;
	private var _c:Float;
	private var _d:Float;
	
	private var _e:Float;
	private var _f:Float;
	private var _g:Float;
	private var _h:Float;
	
	private var _t:Float;
	private var _t2:Float;
	private var _t3:Float;

	public function new (x1:Float, y1:Float, vx1:Float, vy1:Float, x2:Float, y2:Float, vx2:Float, vy2:Float, t:Float) {
		_t = t;
		_t2 = _t * _t;
		_t3 = _t2 * t;
		
		var invt2:Float = 1 / _t2;
		var invt3:Float = 1 / _t3;
		
		if (t > 0) {
			_a = ((2 * x1) - (2 * x2) + (vx1 * t) + (vx2 * t)) * invt3;
			_b = ((3 * x2) - (3 * x1) - (2 * vx1 * t) - (vx2 * t)) * invt2;
		} else {
			_a = 0;
			_b = 0;
		}
		_c = vx1;
		_d = x1;
		
		if (t > 0) {
			_e = ((2 * y1) - (2 * y2) + (vy1 * t) + (vy2 * t)) * invt3;
			_f = ((3 * y2) - (3 * y1) - (2 * vy1 * t) - (vy2 * t)) * invt2;
		} else {
			_e = 0;
			_f = 0;
		}
		_g = vy1;
		_h = y1;
	}
	
	public inline function getPosition (t:Float, out:Vec2):Vec2 {
		var t2:Float = t*t;
		var t3:Float = t2*t;
		out.x = _a*t3 + _b*t2 + _c*t + _d;
		out.y = _e*t3 + _f*t2 + _g*t + _h;
		return out;
	}
	
	public inline function getVelocity (t:Float, out:Vec2):Vec2 {
		var t2:Float = t*t;
		out.x = 3*_a*t2 + 2*_b*t + _c;
		out.y = 3*_e*t2 + 2*_f*t + _g;
		return out;
	}
	
	public inline function getTotalTime ():Float {
		return _t;
	}
	
}