/**
 * Represents a 2D line segment.
 * @author Sam MacPherson
 */

package as3gl.geom;
import de.polygonal.core.fmt.Sprintf;
import de.polygonal.core.math.Mathematics;
import de.polygonal.motor2.geom.math.Vec2;
import de.polygonal.motor2.geom.primitive.AABB2;
import flash.Memory;

class Line {
	
	public var x1:Float;
	public var y1:Float;
	public var x2:Float;
	public var y2:Float;

	public function new (?x1:Float = 0, ?y1:Float = 0, ?x2:Float = 0, ?y2:Float = 0) {
		this.x1 = x1;
		this.y1 = y1;
		this.x2 = x2;
		this.y2 = y2;
	}
	
	public inline function getVector (output:Vec2):Vec2 {
		output.x = x2 - x1;
		output.y = y2 - y1;
		return output;
	}
	
	public inline function length ():Float {
		var x:Float = x2 - x1;
		var y:Float = y2 - y1;
		return Math.sqrt(x*x + y*y);
	}
	
	public inline function interpolate (f:Float, out:Vec2):Vec2 {
		out.x = x1 + (f * (x2 - x1));
		out.y = y1 + (f * (y2 - y1));
		return out;
	}
	
	public inline function middle (out:Vec2):Vec2 {
		return this.interpolate(0.5, out);
	}
	
	public inline function bounds (out:AABB2):AABB2 {
		if (x1 < x2) {
			out.xmin = x1;
			out.xmax = x2;
		} else {
			out.xmin = x2;
			out.xmax = x1;
		}
		
		if (y1 < y2) {
			out.ymin = y1;
			out.ymax = y2;
		} else {
			out.ymin = y2;
			out.ymax = y1;
		}
		
		return out;
	}
	
	public inline function project (vec:Vec2, out:Vec2):Vec2 {
		if (x1 == x2 && y1 == y2) {
			out.x = x1;
			out.y = y1;
		} else {
			var a:Float = x2 - x1;
			var b:Float = y2 - y1;
			var c:Float = vec.x - x1;
			var d:Float = vec.y - y1;
			var e:Float = (a*c + b*d) / (a*a + b*b);
			if (e < 0) {
				e = 0;
			} else if (e > 1) {
				e = 1;
			}
			out.x = x1 + e*a;
			out.y = y1 + e*b;
		}
		
		return out;
	}
	
	public function toString ():String {
		return Sprintf.format("[%.3f,%.3f,%.3f,%.3f]", [x1, y1, x2, y2]);
	}
	
}