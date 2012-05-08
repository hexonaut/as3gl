/**
 * Will pack multiple smaller images into one big one.
 * @author Sam MacPherson
 */

package as3gl.display;

import as3gl.display.data.Quad;
import de.polygonal.motor2.geom.intersect.IntersectAABB;
import de.polygonal.motor2.geom.primitive.AABB2;
import flash.display.BitmapData;
import flash.geom.Point;

class TextureAtlas {
	
	private var _root:Node;
	private var _tid:Int;
	private var _dedicated:Bool;
	private var _bitmap:BitmapData;
	private var _bounds:List<AABB2>;

	public function new (tid:Int, dedicated:Bool, w:Int, h:Int) {
		_bitmap = new BitmapData(w, h, true, 0x00000000);
		_root = new Node(0, 0, w, h);
		_bounds = new List<AABB2>();
		_tid = tid;
		_dedicated = dedicated;
	}
	
	private inline function _normalize (xmin:Int, ymin:Int, xmax:Int, ymax:Int):AABB2 {
		return new AABB2(xmin / _bitmap.width, ymin / _bitmap.height, xmax / _bitmap.width, ymax / _bitmap.height);
	}
	
	public function add (bmd:BitmapData):Quad {
		var node:Node = _root.insert(bmd);
		if (node != null) {
			_bitmap.copyPixels(bmd, bmd.rect, new Point(node.xmin, node.ymin));
			return new Quad(_tid, _dedicated, _normalize(node.xmin, node.ymin, node.xmax, node.ymax));
		} else {
			return null;
		}
	}
	
	public function get ():BitmapData {
		return _bitmap;
	}
	
}

private class Node {
	
	public var left:Node;
	public var right:Node;
	public var occupied:Bool;
	public var xmin:Int;
	public var ymin:Int;
	public var xmax:Int;
	public var ymax:Int;
	public var w:Int;
	public var h:Int;
	
	public function new (xmin:Int, ymin:Int, xmax:Int, ymax:Int) {
		this.occupied = false;
		this.xmin = xmin;
		this.ymin = ymin;
		this.xmax = xmax;
		this.ymax = ymax;
		this.w = xmax - xmin;
		this.h = ymax - ymin;
	}
	
	public function insert (bmd:BitmapData):Node {
		var node:Node;
		if (!isLeaf()) {
			node = left.insert(bmd);
			if (node != null) return node;
			return right.insert(bmd);
		} else {
			if (occupied) return null;
			if (bmd.width > w || bmd.height > h) return null;
			if (bmd.width == w && bmd.height == h) {
				occupied = true;
				return this;
			}
			
			var dw:Int = w - bmd.width;
			var dh:Int = h - bmd.height;
			
			if (dw > dh) {
				left = new Node(xmin, ymin, xmin + bmd.width, ymax);
				right = new Node(xmin + bmd.width, ymin, xmax, ymax);
			} else {
				left = new Node(xmin, ymin, xmax, ymin + bmd.height);
				right = new Node(xmin, ymin + bmd.height, xmax, ymax);
			}
			
			return left.insert(bmd);
		}
	}
	
	public inline function isLeaf ():Bool {
		return left == null && right == null;
	}
	
}