/**
 * A linear implementation of the Spline interface.
 * @author Sam MacPherson
 */

package as3gl.motion;
import de.polygonal.motor2.geom.math.Vec2;

class LinearSpline implements Spline {
	
	private var _a:Float;
	private var _b:Float;
	
	private var _c:Float;
	private var _d:Float;
	
	private var _t:Float;

	public function new (x1:Float, y1:Float, x2:Float, y2:Float, t:Float) {
		_t = t;
		
		var invt:Float = 1 / t;
		
		if (t > 0) {
			_a = (x2 - x1) * invt;
		} else {
			_a = 0;
		}
		_b = x1;
		
		if (t > 0) {
			_c = (y2 - y1) * invt;
		} else {
			_c = 0;
		}
		_d = y1;
	}
	
	public inline function getPosition (t:Float, out:Vec2):Vec2 {
		out.x = _a*t + _b;
		out.y = _c*t + _d;
		return out;
	}
	
	public inline function getVelocity (t:Float, out:Vec2):Vec2 {
		out.x = _a;
		out.y = _c;
		return out;
	}
	
	public inline function getTotalTime ():Float {
		return _t;
	}
	
}