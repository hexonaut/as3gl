/**
 * A helper class that provides methods for common geometric operations.
 * @author Sam MacPherson
 */

package as3gl.geom;

import de.polygonal.core.math.Mathematics;
import de.polygonal.ds.DLL;
import de.polygonal.motor2.geom.math.Vec2;
import de.polygonal.motor2.geom.inside.PointInsideTriangle;
import de.polygonal.motor2.geom.primitive.AABB2;
import de.polygonal.motor2.geom.primitive.Poly2;
import flash.Memory;
import flash.geom.Matrix3D;
import flash.geom.Vector3D;

class Geom {
	
	private static var _TMP_VEC3D:Vector3D = new Vector3D();
	
	public inline static function intersectsAABBvsAABB (rect1:AABB2, rect2:AABB2):Bool {
		return intersectsAABBvsAABB8(rect1.xmin, rect1.ymin, rect1.xmax, rect1.ymax, rect2.xmin, rect2.ymin, rect2.xmax, rect2.ymax);
	}

	public inline static function intersectsAABBvsAABB8 (x1:Float, y1:Float, x2:Float, y2:Float, x3:Float, y3:Float, x4:Float, y4:Float):Bool {
		var sx:Float = (x2 - x1) + (x4 - x3);
		var sy:Float = (y2 - y1) + (y4 - y3);
		var dx:Float = Mathematics.fabs((x1 + x2) - (x3 + x4));
		var dy:Float = Mathematics.fabs((y1 + y2) - (y3 + y4));
		return dx < sx && dy < sy;
	}
	
	public inline static function containsAABBvsAABB (rect1:AABB2, rect2:AABB2):Bool {
		return containsAABBvsAABB8(rect1.xmin, rect1.ymin, rect1.xmax, rect1.ymax, rect2.xmin, rect2.ymin, rect2.xmax, rect2.ymax);
	}
	
	public inline static function containsAABBvsAABB8 (x1:Float, y1:Float, x2:Float, y2:Float, x3:Float, y3:Float, x4:Float, y4:Float):Bool {
		return x3 >= x1 && y3 >= y1 && x4 <= x2 && y4 <= y2;
	}
	
	public inline static function containsAABBvsVec (rect:AABB2, vec:Vec2):Bool {
		return containsAABBvsAABB8(rect.xmin, rect.ymin, rect.xmax, rect.ymax, vec.x, vec.y, vec.x, vec.y);
	}
	
	public inline static function containsAABBvsVec6 (x1:Float, y1:Float, x2:Float, y2:Float, x3:Float, y3:Float):Bool {
		return containsAABBvsAABB8(x1, y1, x2, y2, x3, y3, x3, y3);
	}
	
	public inline static function areaAABB (rect:AABB2):Float {
		return areaAABB4(rect.xmin, rect.ymin, rect.xmax, rect.ymax);
	}
	
	public inline static function areaAABB4 (x1:Float, y1:Float, x2:Float, y2:Float):Float {
		return (x2 - x1) * (y2 - y1);
	}
	
	public inline static function intersectsLinevsLine (line1:Line, line2:Line):Bool {
		return intersectsLinevsLine8(line1.x1, line1.y1, line1.x2, line1.y2, line2.x1, line2.y1, line2.x2, line2.y2);
	}
	
	public inline static function intersectsLinevsLine8 (x1:Float, y1:Float, x2:Float, y2:Float, x3:Float, y3:Float, x4:Float, y4:Float):Bool {
		var a:Float = x4 - x3;
		var b:Float = y4 - y3;
		var c:Float = x2 - x1;
		var d:Float = y2 - y1;
		
		var den:Float = (a * d - b * c);
		if (den != 0) {
			den = 1 / den;
			var e:Float = (x3 - x1) * den;
			var f:Float = (y3 - y1) * den;
			var g:Float = f*a - e*b;
			var h:Float = f*c - e*d;
			if (g >= 0 && g <= 1 && h >= 0 && h <= 1) {
				return true;
			} else {
				return false;
			}
		} else {
			return false;
		}
	}
	
	public inline static function intersectsAABBvsLine (rect:AABB2, line:Line):Bool {
		return intersectsAABBvsLine8(rect.xmin, rect.ymin, rect.xmax, rect.ymax, line.x1, line.y1, line.x2, line.y2);
	}
	
	public inline static function intersectsAABBvsLine8 (x1:Float, y1:Float, x2:Float, y2:Float, x3:Float, y3:Float, x4:Float, y4:Float):Bool {
		if (containsAABBvsVec6(x1, y1, x2, y2, x3, y3)) {
			return true;
		} else {
			if (intersectsLinevsLine8(x1, y1, x2, y1, x3, y3, x4, y4)) {
				return true;
			} else if (intersectsLinevsLine8(x2, y1, x2, y2, x3, y3, x4, y4)) {
				return true;
			} else if (intersectsLinevsLine8(x1, y1, x1, y2, x3, y3, x4, y4)) {
				return true;
			} else if (intersectsLinevsLine8(x1, y2, x2, y2, x3, y3, x4, y4)) {
				return true;
			} else {
				return false;
			}
		}
	}
	
	public inline static function intersectionAABBvsLine (rect:AABB2, line:Line, out:Vec2):Vec2 {
		return intersectionAABBvsLine8(rect.xmin, rect.ymin, rect.xmax, rect.ymax, line.x1, line.y1, line.x2, line.y2, out);
	}
	
	public inline static function intersectionAABBvsLine8 (x1:Float, y1:Float, x2:Float, y2:Float, x3:Float, y3:Float, x4:Float, y4:Float, out:Vec2):Vec2 {
		out.x = x3;
		out.y = y3;
		if (!containsAABBvsVec6(x1, y1, x2, y2, x3, y3)) {
			var minDist:Float = Mathematics.POSITIVE_INFINITY;
			var x:Float;
			var y:Float;
			var dx:Float;
			var dy:Float;
			var dist:Float;
			if (_memIntersection(x1, y1, x2, y1, x3, y3, x4, y4)) {
				x = Memory.getDouble(0);
				y = Memory.getDouble(8);
				dx = x - x3;
				dy = y - y3;
				dist = dx*dx + dy*dy;
				if (dist < minDist) {
					out.x = x;
					out.y = y;
					minDist = dist;
				}
			}
			if (_memIntersection(x2, y1, x2, y2, x3, y3, x4, y4)) {
				x = Memory.getDouble(0);
				y = Memory.getDouble(8);
				dx = x - x3;
				dy = y - y3;
				dist = dx*dx + dy*dy;
				if (dist < minDist) {
					out.x = x;
					out.y = y;
					minDist = dist;
				}
			}
			if (_memIntersection(x1, y1, x1, y2, x3, y3, x4, y4)) {
				x = Memory.getDouble(0);
				y = Memory.getDouble(8);
				dx = x - x3;
				dy = y - y3;
				dist = dx*dx + dy*dy;
				if (dist < minDist) {
					out.x = x;
					out.y = y;
					minDist = dist;
				}
			}
			if (_memIntersection(x1, y2, x2, y2, x3, y3, x4, y4)) {
				x = Memory.getDouble(0);
				y = Memory.getDouble(8);
				dx = x - x3;
				dy = y - y3;
				dist = dx*dx + dy*dy;
				if (dist < minDist) {
					out.x = x;
					out.y = y;
					minDist = dist;
				}
			}
			if (minDist == Mathematics.POSITIVE_INFINITY) {
				return null;
			} else {
				return out;
			}
		} else {
			return out;
		}
	}
	
	private inline static function _memIntersection (x1:Float, y1:Float, x2:Float, y2:Float, x3:Float, y3:Float, x4:Float, y4:Float):Bool {
		var a:Float = x2 - x1;
		var b:Float = y2 - y1;
		var c:Float = x4 - x3;
		var d:Float = y4 - y3;
		
		var den:Float = (a * d - b * c);
		if (den != 0) {
			den = 1 / den;
			var e:Float = (x1 - x3) * den;
			var f:Float = (y1 - y3) * den;
			var g:Float = f*a - e*b;
			var h:Float = f*c - e*d;
			if (g >= 0 && g <= 1 && h >= 0 && h <= 1) {
				Memory.setDouble(0, x1 + h*a);
				Memory.setDouble(8, y1 + h*b);
				return true;
			} else {
				return false;
			}
		} else {
			return false;
		}
	}
	
	public inline static function intersectionLinevsLine (line1:Line, line2:Line, out:Vec2):Vec2 {
		return intersectionLinevsLine8(line1.x1, line1.y1, line1.x2, line1.y2, line2.x1, line2.y1, line2.x2, line2.y2, out);
	}
	
	public inline static function intersectionLinevsLine8 (x1:Float, y1:Float, x2:Float, y2:Float, x3:Float, y3:Float, x4:Float, y4:Float, out:Vec2):Vec2 {
		var a:Float = x2 - x1;
		var b:Float = y2 - y1;
		var c:Float = x4 - x3;
		var d:Float = y4 - y3;
		
		var den:Float = (a * d - b * c);
		if (den != 0) {
			den = 1 / den;
			var e:Float = (x1 - x3) * den;
			var f:Float = (y1 - y3) * den;
			var g:Float = f*a - e*b;
			var h:Float = f*c - e*d;
			if (g >= 0 && g <= 1 && h >= 0 && h <= 1) {
				out.x = x1 + h*a;
				out.y = y1 + h*b;
				return out;
			} else {
				return null;
			}
		} else {
			return null;
		}
	}
	
	public inline static function triangulate (pts:Array<Vec2>):Array<Vec2> {
		//Verticies are assumed to be oriented clock-wise
		var t:Array<Vec2> = new Array<Vec2>();
		var c:DLL<Vertex> = new DLL<Vertex>();
		var r:DLL<Vertex> = new DLL<Vertex>();
		var e:DLL<Vertex> = new DLL<Vertex>();
		var curr:Vec2;
		var prev:Vec2;
		var next:Vec2;
		var left:Float;
		var v:Vertex;
		var lastVertex:Vertex = null;
		var firstVertex:Vertex = null;
		
		//Init lists
		for (i in 0 ... pts.length) {
			curr = pts[i];
			v = new Vertex(curr);
			if (i == 0) {
				firstVertex = v;
			} else if (i == pts.length - 1) {
				firstVertex.prev = v;
				v.next = firstVertex;
			}
			if (lastVertex != null) {
				v.prev = lastVertex;
				lastVertex.next = v;
			}
			
			if (i == 0) prev = pts[pts.length - 1];
			else prev = pts[i - 1];
			if (i == pts.length - 1) next = pts[0];
			else next = pts[i + 1];
			
			left = Vec2.isLeft3(prev, curr, next);
			if (left < 0) {
				v.type = Vertex.REFLEX;
				r.append(v);
			} else {
				v.type = Vertex.CONVEX;
				c.append(v);
			}
			
			lastVertex = v;
		}
		
		//Init ears
		for (i in c) {
			if (_isEar(i)) {
				i.type = Vertex.EAR;
				c.remove(i);
				e.append(i);
			}
		}
		
		//Do ear clipping algorithm
		while (!e.isEmpty() && e.size() + r.size() + c.size() > 2) {
			//Remove ear
			v = e.removeHead();
			
			//Add triangle to list and update references
			t.push(v.prev.pt);
			t.push(v.pt);
			t.push(v.next.pt);
			v.prev.next = v.next;
			v.next.prev = v.prev;
			
			//Test ears to make sure they are still ears
			for (i in e) {
				if (!_isEar(i)) {
					e.remove(i);
					c.append(i);
				}
			}
			
			//Test convex angles to see if they are now ears
			for (i in c) {
				if (_isEar(i)) {
					c.remove(i);
					e.append(i);
				}
			}
			
			//Test reflex angles to see if they have become convex or ears
			for (i in r) {
				left = Vec2.isLeft3(i.prev.pt, i.pt, i.next.pt);
				if (left >= 0) {
					r.remove(i);
					if (_isEar(i)) {
						e.append(i);
					} else {
						c.append(i);
					}
				}
			}
			
		}
		
		return t;
	}
	
	private inline static function _isEar (v:Vertex):Bool {
		var ear:Bool = true;
		var prev:Vertex = v.prev;
		var next:Vertex = v.next;
		var curr:Vertex = next.next;
		while (curr != prev) {
			if (PointInsideTriangle.test4(curr.pt, prev.pt, v.pt, next.pt)) {
				ear = false;
				break;
			}
			curr = curr.next;
		}
		return ear;
	}
	
	public static inline function transformAABB (input:AABB2, output:AABB2, m:Matrix3D):AABB2 {
		var result:Vector3D;
		_TMP_VEC3D.z = 0;
		_TMP_VEC3D.x = input.xmin;
		_TMP_VEC3D.y = input.ymin;
		result = m.transformVector(_TMP_VEC3D);
		output.set4(result.x, result.y, result.x, result.y);
		_TMP_VEC3D.x = input.xmax;
		_TMP_VEC3D.y = input.ymin;
		result = m.transformVector(_TMP_VEC3D);
		output.add2(result.x, result.y);
		_TMP_VEC3D.x = input.xmin;
		_TMP_VEC3D.y = input.ymax;
		result = m.transformVector(_TMP_VEC3D);
		output.add2(result.x, result.y);
		_TMP_VEC3D.x = input.xmax;
		_TMP_VEC3D.y = input.ymax;
		result = m.transformVector(_TMP_VEC3D);
		output.add2(result.x, result.y);
		return output;
	}
	
}

private class Vertex {
	
	public static var CONVEX:Int = 0;
	public static var REFLEX:Int = 1;
	public static var EAR:Int = 2;
	
	public var pt:Vec2;
	public var prev:Vertex;
	public var next:Vertex;
	public var type:Int;
	
	public function new (pt:Vec2) {
		this.pt = pt;
	}
	
}