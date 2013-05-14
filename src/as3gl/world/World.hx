/**
 * A 2D axis-aligned scrolling world that supports multiple floors and levels.
 * An example of the hierarchy follows:
 * 
 * World -> 	Floor0 -> 	Level0
 * 							Level1
 * 							Level2
 * 				Floor1 ->	Level0
 * 							Level1
 * 							Level2
 * 				...
 * 				etc
 * 
 * @author Sam MacPherson
 */

package as3gl.world;

import as3gl.core.Dimension;
import as3gl.display.CanvasObject;
import as3gl.geom.Geom;
import as3gl.geom.Line;
import as3gl.util.Molehill;
import de.polygonal.motor2.geom.distance.DistancePoint;
import de.polygonal.motor2.geom.math.Vec2;
import de.polygonal.motor2.geom.primitive.AABB2;
import de.polygonal.core.event.IObserver;
import de.polygonal.core.event.Observable;
import de.polygonal.core.math.Mathematics;
import de.polygonal.ds.ArrayedStack;
import flash.display.DisplayObject;
import flash.display3D.Context3D;
import flash.geom.Matrix3D;
import flash.Vector;

class World extends CanvasObject, implements IObserver {
	
	private static var _TMP_AABB:AABB2 = new AABB2();
	private static var _TMP_VEC:Vec2 = new Vec2();
	private static var _TMP_STACK:ArrayedStack<WorldObject> = new ArrayedStack<WorldObject>();
	
	private var _floors:Vector<WorldFloor>;
	
	private var _dim:Dimension;
	public var _screenDim:Dimension;
	private var _numFloors:Int;
	private var _levelsPerFloor:Int;
	
	public var _posX:Int;
	public var _posY:Int;
	
	private var _minPosX:Int;
	private var _minPosY:Int;
	private var _maxPosX:Int;
	private var _maxPosY:Int;

	public function new (bounds:Dimension, screenDimensions:Dimension, ?numFloors:Int = 1, ?levelsPerFloor:Int = 1, ?collTreeDepth:Int = 5) {
		super();
		
		this._dim = bounds;
		this._screenDim = screenDimensions;
		this._numFloors = numFloors;
		this._levelsPerFloor = levelsPerFloor;
		
		this._minPosX = this._posX = 0;
		this._minPosY = this._posY = 0;
		this._maxPosX = Std.int(bounds.width - screenDimensions.width);
		this._maxPosY = Std.int(bounds.height - screenDimensions.height);
		
		this._floors = new Vector<WorldFloor>(numFloors);
		for (i in 0 ... numFloors) {
			_floors[i] = new WorldFloor(this, levelsPerFloor, Std.int(bounds.width), Std.int(bounds.height), collTreeDepth);
			this.add(_floors[i]);
		}
	}
	
	public function getPosX ():Int {
		return _posX;
	}
	
	public function getPosY ():Int {
		return _posY;
	}
	
	public function move (x:Int, y:Int):Void {
		if (x < 0) {
			x = 0;
		} else if (x > _maxPosX) {
			x = _maxPosX;
		}
		if (y < 0) {
			y = 0;
		} else if (y > _maxPosY) {
			y = _maxPosY;
		}
		
		this._posX = x;
		this._posY = y;
	}
	
	public function scroll (dx:Int, dy:Int):Void {
		this.move(_posX + dx, _posY + dy);
	}
	
	public inline function getRelativePosition (out:Vec2, ?x:Float = 0, ?y:Float = 0):Vec2 {
		out.x = x - _posX;
		out.y = y - _posY;
		return out;
	}
	
	public inline function getAbsolutePosition (out:Vec2, ?x:Float = 0, ?y:Float = 0):Vec2 {
		out.x = x + _posX;
		out.y = y + _posY;
		return out;
	}
	
	public inline function addObject (obj:WorldObject):Void {
		_floors[obj.getFloor()].addObject(obj);
		obj.attach(this, WorldObject.EVENT_FLOOR_CHANGE);
	}
	
	public inline function removeObject (obj:WorldObject):Void {
		_floors[obj.getFloor()].removeObject(obj);
		obj.detach(this, WorldObject.EVENT_FLOOR_CHANGE);
	}
	
	public inline function update (type:Int, source:Observable, data:Dynamic):Void {
		if (type == WorldObject.EVENT_FLOOR_CHANGE) {
			var obj:WorldObject = cast(source, WorldObject);
			_floors[data].removeObject(obj);
			_floors[obj.getFloor()].addObject(obj);
		}
	}
	
	public inline function getFloor (floor:Int):CanvasObject {
		return _floors[floor];
	}
	
	public inline function queryAABB (b:AABB2, floor:Int, out:Array<WorldObject>, ?filter:Dynamic = null, ?limit:Int = Mathematics.INT32_MAX):Array<WorldObject> {
		return _floors[floor].getQuadTree().queryAABB(b, out, filter, limit);
	}
	
	public inline function queryVec (v:Vec2, floor:Int, out:Array<WorldObject>, ?filter:Dynamic = null, ?limit:Int = Mathematics.INT32_MAX):Array<WorldObject> {
		return _floors[floor].getQuadTree().queryVec(v, out, filter, limit);
	}
	
	public inline function queryLine (l:Line, floor:Int, out:Array<WorldObject>, ?filter:Dynamic = null, ?limit:Int = Mathematics.INT32_MAX):Array<WorldObject> {
		return _floors[floor].getQuadTree().queryLine(l, out, filter, limit);
	}
	
	public inline function queryLineClosest (l:Line, floor:Int, out:Array<WorldObject>, ?filter:Dynamic = null):WorldObject {
		var a:Array<WorldObject> = _floors[floor].getQuadTree().queryLine(l, out, filter, Mathematics.INT32_MAX);
		var minDist:Float = -1;
		var minObj:WorldObject = null;
		for (i in a) {
			Geom.intersectionAABBvsLine(i.getBounds(_TMP_AABB), l, _TMP_VEC);
			var dx:Float = _TMP_VEC.x - l.x1;
			var dy:Float = _TMP_VEC.y - l.y1;
			var d:Float = dx * dx + dy * dy;
			if (d < minDist || minObj == null) {
				minDist = d;
				minObj = i;
			}
		}
		return minObj;
	}
	
	public inline function getWidth ():Float {
		return _dim.width;
	}
	
	public inline function getHeight ():Float {
		return _dim.height;
	}
	
}

private class WorldFloor extends CanvasObject, implements IObserver {
	
	private var _quadTree:WorldQuadTree;
	private var _levels:Vector<WorldLevel>;
	
	public function new (world:World, numLevels:Int, mapW:Int, mapH:Int, collTreeDepth:Int) {
		super();
		
		_levels = new Vector<WorldLevel>(numLevels);
		for (i in 0 ... numLevels) {
			_levels[i] = new WorldLevel(world);
			this.add(_levels[i]);
		}
		
		_quadTree = new WorldQuadTree(collTreeDepth, mapW, mapH);
	}
	
	public inline function addObject (obj:WorldObject):Void {
		_levels[obj.getLevel()].addObject(obj);
		obj.attach(this, WorldObject.EVENT_LEVEL_CHANGE);
		obj.attach(this, WorldObject.EVENT_COLLISION_CHANGE);
		if (obj.isCollidable()) _quadTree.add(obj);
	}
	
	public inline function removeObject (obj:WorldObject):Void {
		_levels[obj.getLevel()].removeObject(obj);
		obj.detach(this, WorldObject.EVENT_LEVEL_CHANGE);
		obj.detach(this, WorldObject.EVENT_COLLISION_CHANGE);
		if (obj.isCollidable()) _quadTree.remove(obj);
	}
	
	public inline function update (type:Int, source:Observable, data:Dynamic):Void {
		if (type == WorldObject.EVENT_LEVEL_CHANGE) {
			var obj:WorldObject = cast(source, WorldObject);
			_levels[data].removeObject(obj);
			_levels[obj.getLevel()].addObject(obj);
		} else if (type == WorldObject.EVENT_COLLISION_CHANGE) {
			var obj:WorldObject = cast(source, WorldObject);
			if (obj.isCollidable()) _quadTree.add(obj) else _quadTree.remove(obj);
		}
	}
	
	public inline function getLevel (level:Int):WorldLevel {
		return _levels[level];
	}
	
	public inline function getQuadTree ():WorldQuadTree {
		return _quadTree;
	}
	
}

private class WorldLevel extends CanvasObject {
	
	private static var _TMP_AABB2:AABB2 = new AABB2();
	
	private var world:World;
	
	public function new (world:World) {
		super();
		
		this.world = world;
	}
	
	public inline function addObject (obj:WorldObject):Void {
		this.add(obj);
	}
	
	public inline function removeObject (obj:WorldObject):Void {
		this.remove(obj);
	}
	
	public override function render(c:Context3D, camera:Matrix3D):Void {
		if (_alpha > 0 && _visible) {
			runShader(c, camera);
			
			for (i in _children) {
				i.getBounds(_TMP_AABB2);
				if (_TMP_AABB2.xmax >= world.getPosX() && _TMP_AABB2.xmin < world.getPosX() + world._screenDim.width && _TMP_AABB2.ymax >= world.getPosY() && _TMP_AABB2.ymin < world.getPosY() + world._screenDim.height) i.render(c, camera);
			}
		}
	}
	
}