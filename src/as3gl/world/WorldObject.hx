/**
 * Any object found in the World.
 * @author Sam MacPherson
 */

package as3gl.world;
import as3gl.core.Dimension;
import as3gl.display.CanvasObject;
import as3gl.display.CanvasSprite;
import as3gl.event.GroupId;
import de.polygonal.core.math.Mathematics;
import de.polygonal.core.event.Observable;
import de.polygonal.motor2.geom.math.Mat32;
import de.polygonal.motor2.geom.math.Vec2;
import de.polygonal.motor2.geom.primitive.AABB2;
import de.polygonal.ds.SLLNode;
import de.polygonal.ds.SLL;

class WorldObject extends CanvasObject {
	
	public static var GROUP:Int = GroupId.get();
	public static var EVENT_LEVEL_CHANGE:Int = Observable.makeEvent(GROUP, 0);
	public static var EVENT_FLOOR_CHANGE:Int = Observable.makeEvent(GROUP, 1);
	public static var EVENT_POSITION_CHANGE:Int = Observable.makeEvent(GROUP, 2);
	public static var EVENT_COLLISION_CHANGE:Int = Observable.makeEvent(GROUP, 3);
	
	private static var _TMP_VEC:Vec2 = new Vec2();
	
	private static var _NEXT_ID:Int = 0;
	
	private var _wid:Int;
	private var _floor:Int;
	private var _level:Int;
	private var _collidable:Bool;

	public function new () {
		super();
		
		_wid = _NEXT_ID++;
		_collidable = false;
		_floor = 0;
		_level = 0;
	}
	
	public inline function getId ():Int {
		return _wid;
	}
	
	public override function setPosition (x:Float, y:Float):Void {
		getPosition(_TMP_VEC);
		if (x != _TMP_VEC.x || y != _TMP_VEC.y) {
			super.setPosition(x, y);
			this.notify(EVENT_POSITION_CHANGE, new Vec2(_TMP_VEC.x, _TMP_VEC.y));
		}
	}
	
	public inline function getLevel ():Int {
		return _level;
	}
	
	public inline function setLevel (level:Int):Void {
		if (level != _level) {
			var lastLevel:Int = _level;
			this._level = level;
			this.notify(EVENT_LEVEL_CHANGE, lastLevel);
		}
	}
	
	public inline function getFloor ():Int {
		return _floor;
	}
	
	public inline function setFloor (floor:Int):Void {
		if (floor != _floor) {
			var lastFloor:Int = _floor;
			this._floor = floor;
			this.notify(EVENT_FLOOR_CHANGE, lastFloor);
		}
	}
	
	public inline function setCollidable (bool:Bool):Void {
		if (_collidable != bool) {
			_collidable = bool;
			this.notify(EVENT_COLLISION_CHANGE, !bool);
		}
	}
	
	public inline function isCollidable ():Bool {
		return _collidable;
	}
	
}