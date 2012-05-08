/**
 * A Quad Tree data structure which supports WorldObjects which can be queried by Points, Lines and other AABB.
 * @author Sam MacPherson
 */

package as3gl.world;

import as3gl.core.Destroyable;
import as3gl.geom.Geom;
import as3gl.geom.Line;
import de.polygonal.core.event.IObserver;
import de.polygonal.core.event.Observable;
import de.polygonal.core.math.Mathematics;
import de.polygonal.ds.ArrayedQueue;
import de.polygonal.ds.IntHashTable;
import de.polygonal.ds.LinkedQueue;
import de.polygonal.ds.SLL;
import de.polygonal.motor2.geom.inside.PointInsideAABB;
import de.polygonal.motor2.geom.intersect.IntersectAABB;
import de.polygonal.motor2.geom.intersect.IntersectSegmentAABB;
import de.polygonal.motor2.geom.math.Vec2;
import de.polygonal.motor2.geom.primitive.AABB2;

class WorldQuadTree implements Destroyable, implements IObserver {
	
	private static var _TMP_AABB:AABB2 = new AABB2();
	private static var _TMP_QUEUE:ArrayedQueue<QuadTreeNode> = new ArrayedQueue<QuadTreeNode>(1024);
	
	private var _top:QuadTreeNode;
	private var _w:Int;
	private var _h:Int;
	private var _lookup:IntHashTable<QuadTreeNode>;
	private var _maxDepth:Int;

	public function new (depth:Int, width:Int, height:Int, ?lookupTableSize:Int = 8192) {
		_top = new QuadTreeNode(0, 0, 0, width, height);
		_lookup = new IntHashTable<QuadTreeNode>(lookupTableSize);
		_maxDepth = depth;
	}
	
	public function destroy ():Void {
		_lookup.free();
	}
	
	public inline function add (obj:WorldObject):Void {
		obj.getBounds(_TMP_AABB);
		var node:QuadTreeNode = _top;
		while (true) {
			node.objCount++;
			if (node.depth + 1 < _maxDepth) {
				if (node.topLeft == null) {
					var midX:Float = (node.xmin + node.xmax) * 0.5;
					var midY:Float = (node.ymin + node.ymax) * 0.5;
					node.topLeft = new QuadTreeNode(node.depth + 1, node.xmin, node.ymin, midX, midY, node);
					node.topRight = new QuadTreeNode(node.depth + 1, midX, node.ymin, node.xmax, midY, node);
					node.bottomLeft = new QuadTreeNode(node.depth + 1, node.xmin, midY, midX, node.ymax, node);
					node.bottomRight = new QuadTreeNode(node.depth + 1, midX, midY, node.xmax, node.ymax, node);
				}
				if (node.topLeft.contains(_TMP_AABB)) {
					node = node.topLeft;
				} else if (node.topRight.contains(_TMP_AABB)) {
					node = node.topRight;
				} else if (node.bottomLeft.contains(_TMP_AABB)) {
					node = node.bottomLeft;
				} else if (node.bottomRight.contains(_TMP_AABB)) {
					node = node.bottomRight;
				} else {
					_add(node, obj);
					break;
				}
			} else {
				_add(node, obj);
				break;
			}
		}
		obj.attach(this, WorldObject.EVENT_POSITION_CHANGE);
	}
	
	private inline function _add (node:QuadTreeNode, obj:WorldObject):Void {
		node.objs.append(obj);
		if (_lookup.hasKey(obj.getId())) _lookup.clr(obj.getId());
		_lookup.set(obj.getId(), node);
	}
	
	public inline function remove (obj:WorldObject):Void {
		obj.detach(this, WorldObject.EVENT_POSITION_CHANGE);
		var node:QuadTreeNode = _lookup.get(obj.getId());
		_lookup.clr(obj.getId());
		node.objs.remove(obj);
		
		var curr:QuadTreeNode = node;
		while (curr != null) {
			if (--curr.objCount == 0) {
				curr.topLeft = null;
				curr.topRight = null;
				curr.bottomLeft = null;
				curr.bottomRight = null;
			}
			curr = curr.parent;
		}
	}
	
	public inline function update (type:Int, source:Observable, data:Dynamic):Void {
		if (type == WorldObject.EVENT_POSITION_CHANGE) {
			var obj:WorldObject = cast(source, WorldObject);
			obj.getBounds(_TMP_AABB);
			var node:QuadTreeNode = _lookup.get(obj.getId());
			node.objs.remove(obj);
			
			//Decrement counters until container is found
			while (!node.contains(_TMP_AABB) && node != _top) {
				if (--node.objCount == 0) {
					node.topLeft = null;
					node.topRight = null;
					node.bottomLeft = null;
					node.bottomRight = null;
				}
				node = node.parent;
			}
			
			//Find new container for obj
			node.objCount--;
			while (true) {
				node.objCount++;
				if (node.depth + 1 < _maxDepth) {
					if (node.topLeft == null) {
						var midX:Float = (node.xmin + node.xmax) * 0.5;
						var midY:Float = (node.ymin + node.ymax) * 0.5;
						node.topLeft = new QuadTreeNode(node.depth + 1, node.xmin, node.ymin, midX, midY, node);
						node.topRight = new QuadTreeNode(node.depth + 1, midX, node.ymin, node.xmax, midY, node);
						node.bottomLeft = new QuadTreeNode(node.depth + 1, node.xmin, midY, midX, node.ymax, node);
						node.bottomRight = new QuadTreeNode(node.depth + 1, midX, midY, node.xmax, node.ymax, node);
					}
					if (node.topLeft.contains(_TMP_AABB)) {
						node = node.topLeft;
					} else if (node.topRight.contains(_TMP_AABB)) {
						node = node.topRight;
					} else if (node.bottomLeft.contains(_TMP_AABB)) {
						node = node.bottomLeft;
					} else if (node.bottomRight.contains(_TMP_AABB)) {
						node = node.bottomRight;
					} else {
						_add(node, obj);
						break;
					}
				} else {
					_add(node, obj);
					break;
				}
			}
		}
	}
	
	public function queryAABB (b:AABB2, out:Array<WorldObject>, ?filter:Dynamic = null, ?limit:Int = Mathematics.INT32_MAX):Array<WorldObject> {
		if (filter == null) filter = WorldObject;
		_TMP_QUEUE.clear();
		var count:Int = 0;
		if (_top.objCount > 0 && IntersectAABB.test2(b, _top)) _TMP_QUEUE.enqueue(_top);
		while (!_TMP_QUEUE.isEmpty()) {
			var node:QuadTreeNode = _TMP_QUEUE.dequeue();
			for (i in node.objs) {
				if (Std.is(i, filter) && IntersectAABB.test2(b, i.getBounds(_TMP_AABB)) && (count++) < limit) {
					out.push(i);
					if (count >= limit) return out;
				}
			}
			if (node.topLeft != null) {
				if (node.topLeft.objCount > 0 && IntersectAABB.test2(b, node.topLeft)) {
					_TMP_QUEUE.enqueue(node.topLeft);
				}
				if (node.topRight.objCount > 0 && IntersectAABB.test2(b, node.topRight)) {
					_TMP_QUEUE.enqueue(node.topRight);
				}
				if (node.bottomLeft.objCount > 0 && IntersectAABB.test2(b, node.bottomLeft)) {
					_TMP_QUEUE.enqueue(node.bottomLeft);
				}
				if (node.bottomRight.objCount > 0 && IntersectAABB.test2(b, node.bottomRight)) {
					_TMP_QUEUE.enqueue(node.bottomRight);
				}
			}
		}
		return out;
	}
	
	public function queryVec (v:Vec2, out:Array<WorldObject>, ?filter:Dynamic = null, ?limit:Int = Mathematics.INT32_MAX):Array<WorldObject> {
		if (filter == null) filter = WorldObject;
		var node:QuadTreeNode = null;
		var count:Int = 0;
		if (_top.objCount > 0 && PointInsideAABB.test2(v, _top)) node = _top;
		while (node != null) {
			for (i in node.objs) {
				if (Std.is(i, filter) && PointInsideAABB.test2(v, i.getBounds(_TMP_AABB)) && (count++) < limit) {
					out.push(i);
					if (count >= limit) return out;
				}
			}
			if (node.topLeft != null) {
				if (PointInsideAABB.test2(v, node.topLeft)) {
					if (node.topLeft.objCount > 0) node = node.topLeft else break;
				} else if (PointInsideAABB.test2(v, node.topRight)) {
					if (node.topRight.objCount > 0) node = node.topRight else break;
				} else if (PointInsideAABB.test2(v, node.bottomLeft)) {
					if (node.bottomLeft.objCount > 0) node = node.bottomLeft else break;
				} else if (PointInsideAABB.test2(v, node.bottomRight)) {
					if (node.bottomRight.objCount > 0) node = node.bottomRight else break;
				}
			} else {
				break;
			}
		}
		return out;
	}
	
	public function queryLine (l:Line, out:Array<WorldObject>, ?filter:Dynamic = null, ?limit:Int = Mathematics.INT32_MAX):Array<WorldObject> {
		if (filter == null) filter = WorldObject;
		_TMP_QUEUE.clear();
		var count:Int = 0;
		if (_top.objCount > 0 && IntersectSegmentAABB.test5(l.x1, l.y1, l.x2, l.y2, _top)) _TMP_QUEUE.enqueue(_top);
		while (!_TMP_QUEUE.isEmpty()) {
			var node:QuadTreeNode = _TMP_QUEUE.dequeue();
			for (i in node.objs) {
				if (Std.is(i, filter) && Geom.intersectsAABBvsLine(i.getBounds(_TMP_AABB), l) && (count++) < limit) {
					out.push(i);
					if (count >= limit) return out;
				}
			}
			if (node.topLeft != null) {
				if (node.topLeft.objCount > 0 && IntersectSegmentAABB.test5(l.x1, l.y1, l.x2, l.y2, node.topLeft)) {
					_TMP_QUEUE.enqueue(node.topLeft);
				}
				if (node.topRight.objCount > 0 && IntersectSegmentAABB.test5(l.x1, l.y1, l.x2, l.y2, node.topRight)) {
					_TMP_QUEUE.enqueue(node.topRight);
				}
				if (node.bottomLeft.objCount > 0 && IntersectSegmentAABB.test5(l.x1, l.y1, l.x2, l.y2, node.bottomLeft)) {
					_TMP_QUEUE.enqueue(node.bottomLeft);
				}
				if (node.bottomRight.objCount > 0 && IntersectSegmentAABB.test5(l.x1, l.y1, l.x2, l.y2, node.bottomRight)) {
					_TMP_QUEUE.enqueue(node.bottomRight);
				}
			}
		}
		return out;
	}
	
}

private class QuadTreeNode extends AABB2 {
	
	public var depth:Int;
	public var topLeft:QuadTreeNode;
	public var topRight:QuadTreeNode;
	public var bottomLeft:QuadTreeNode;
	public var bottomRight:QuadTreeNode;
	public var parent:QuadTreeNode;
	public var objs:SLL<WorldObject>;
	public var objCount:Int;
	
	public function new (depth:Int, xmin:Float, ymin:Float, xmax:Float, ymax:Float, ?parent:QuadTreeNode = null) {
		super(xmin, ymin, xmax, ymax);
		
		this.depth = depth;
		this.objs = new SLL<WorldObject>();
		this.objCount = 0;
		this.parent = parent;
	}
	
}