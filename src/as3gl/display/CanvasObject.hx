/**
 * The main canvas display object from which all display objects inherit from.
 * @author Sam MacPherson
 */

package as3gl.display;

import as3gl.core.Runnable;
import as3gl.geom.Geom;
import de.polygonal.core.event.Observable;
import de.polygonal.core.math.Mathematics;
import de.polygonal.ds.Bits;
import de.polygonal.ds.DA;
import de.polygonal.ds.SLL;
import de.polygonal.ds.SLLNode;
import de.polygonal.motor2.geom.intersect.IntersectAABB;
import de.polygonal.motor2.geom.math.Mat22;
import de.polygonal.motor2.geom.math.Vec2;
import de.polygonal.motor2.geom.primitive.AABB2;
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display3D.Context3D;
import flash.display3D.IndexBuffer3D;
import flash.display3D.VertexBuffer3D;
import flash.display3D.textures.Texture;
import flash.geom.Matrix3D;
import flash.geom.Point;
import flash.geom.Rectangle;
import flash.geom.Vector3D;
import flash.geom.ColorTransform;

class CanvasObject extends Observable, implements Runnable {
	
	private static var _TMP_VEC:Vec2 = new Vec2();
	private static var _TMP_VEC3D:Vector3D = new Vector3D();
	private static var _TMP_AABB:AABB2 = new AABB2();
	private static var _TMP_AABB2:AABB2 = new AABB2();
	private static var _TMP_AABB3:AABB2 = new AABB2(0, 0, 1, 1);
	private static var _TMP_MATRIX:Matrix3D = new Matrix3D();
	
	private var _parent:CanvasObject;
	private var _children:Array<CanvasObject>;
	private var _bounds:AABB2;
	private var _boundsChanged:Bool;
	private var _pos:Vec2;
	private var _transform:Matrix3D;
	private var _transformChanged:Bool;
	private var _stageTransform:Matrix3D;
	private var _stageTransformChanged:Bool;
	private var _angle:Float;
	private var _scaleX:Float;
	private var _scaleY:Float;
	private var _alpha:Float;
	private var _stageAlpha:Float;
	private var _alphaChanged:Bool;
	private var _visible:Bool;
	
	public function new () {
		super();
		
		_children = new Array<CanvasObject>();
		_bounds = new AABB2();
		_boundsChanged = true;
		_pos = new Vec2();
		_transform = new Matrix3D();
		_transformChanged = true;
		_stageTransform = new Matrix3D();
		_stageTransformChanged = true;
		_angle = 0;
		_scaleX = 1;
		_scaleY = 1;
		_alpha = 1;
		_stageAlpha = 1;
		_alphaChanged = true;
		_visible = true;
	}
	
	public function getBounds (out:AABB2):AABB2 {
		_rebuildBounds();
		out.xmin = _bounds.xmin + _pos.x;
		out.ymin = _bounds.ymin + _pos.y;
		out.xmax = _bounds.xmax + _pos.x;
		out.ymax = _bounds.ymax + _pos.y;
		return out;
	}
	
	public inline function getXMin ():Float {
		return _bounds.xmin;
	}
	
	public inline function getYMin ():Float {
		return _bounds.ymin;
	}
	
	public inline function getXMax ():Float {
		return _bounds.xmax;
	}
	
	public inline function getYMax ():Float {
		return _bounds.ymax;
	}
	
	public inline function getW ():Float {
		return _bounds.intervalX;
	}
	
	public inline function getH ():Float {
		return _bounds.intervalY;
	}
	
	public function setPosition (x:Float, y:Float):Void {
		if (_pos.x != x || _pos.y != y) {
			_pos.x = x;
			_pos.y = y;
			_setTransformChange();
		}
	}
	
	public inline function movePosition (dx:Float, dy:Float):Void {
		getPosition(_TMP_VEC);
		setPosition(_TMP_VEC.x + dx, _TMP_VEC.y + dy);
	}
	
	public inline function setX (x:Float):Void {
		setPosition(x, getY());
	}
	
	public inline function setY (y:Float):Void {
		setPosition(getX(), y);
	}
	
	public function getPosition (out:Vec2):Vec2 {
		out.x = _pos.x;
		out.y = _pos.y;
		return out;
	}
	
	public inline function getX ():Float {
		return getPosition(_TMP_VEC).x;
	}
	
	public inline function getY ():Float {
		return getPosition(_TMP_VEC).y;
	}
	
	public function setAngle (angle:Float):Void {
		if (_angle != angle) {
			_angle = angle;
			_setTransformChange();
		}
	}
	
	public function getAngle ():Float {
		return _angle;
	}
	
	public inline function deltaAngle (delta:Float):Void {
		setAngle(getAngle() + delta);
	}
	
	public function setAlpha (?alpha:Float = 1):Void {
		if (_alpha != alpha) {
			_alpha = alpha;
			_setAlphaChange();
		}
	}
	
	public function getAlpha ():Float {
		return _alpha;
	}
	
	public inline function deltaAlpha (delta:Float):Void {
		setAlpha(getAlpha() + delta);
	}
	
	public function setScale (?scaleX:Float = 1, ?scaleY:Float = 1):Void {
		if (_scaleX != scaleX || _scaleY != scaleY) {
			_scaleX = scaleX;
			_scaleY = scaleY;
			_setTransformChange();
		}
	}
	
	public function setScaleX (?scaleX:Float = 1):Void {
		if (_scaleX != scaleX) {
			_scaleX = scaleX;
			_setTransformChange();
		}
	}
	
	public function setScaleY (?scaleY:Float = 1):Void {
		if (_scaleY != scaleY) {
			_scaleY = scaleY;
			_setTransformChange();
		}
	}
	
	public function getScaleX ():Float {
		return _scaleX;
	}
	
	public function getScaleY ():Float {
		return _scaleX;
	}
	
	public inline function deltaScale (deltaX:Float, deltaY:Float):Void {
		setScale(getScaleX() + deltaX, getScaleY() + deltaY);
	}
	
	public inline function deltaScaleX (delta:Float):Void {
		setScaleX(getScaleX() + delta);
	}
	
	public inline function deltaScaleY (delta:Float):Void {
		setScaleY(getScaleY() + delta);
	}
	
	public function setVisible (bool:Bool):Void {
		if (_visible != bool) {
			_visible = bool;
		}
	}
	
	public function isVisible ():Bool {
		return _visible;
	}
	
	public function getTransform ():Matrix3D {
		_rebuildTransform();
		return _transform;
	}
	
	public function getStageTransform ():Matrix3D {
		_rebuildStageTransform();
		return _stageTransform;
	}
	
	public function getStageAlpha ():Float {
		_rebuildStageAlpha();
		return _stageAlpha;
	}
	
	private function _setAlphaChange ():Void {
		_alphaChanged = true;
		for (i in _children) {
			i._setAlphaChange();
		}
	}
	
	private function _rebuildStageAlpha ():Void {
		if (_alphaChanged) {
			if (_parent != null) _stageAlpha = _parent.getStageAlpha() * _alpha;
			else _stageAlpha = _alpha;
		}
	}
	
	private function _setTransformChange (?b:Bool = true):Void {
		if (b) _transformChanged = true;
		_stageTransformChanged = true;
		for (i in _children) {
			if (!i._stageTransformChanged) i._setTransformChange(false);
		}
	}
	
	private inline function _rebuildTransform ():Void {
		if (_transformChanged) {
			_transform.identity();
			_transform.appendScale(_scaleX, _scaleY, 1);
			_transform.appendRotation(_angle * Mathematics.RAD_DEG, Vector3D.Z_AXIS);
			_transform.appendTranslation(_pos.x, _pos.y, 0);
			
			_transformChanged = false;
		}
	}
	
	private function _rebuildStageTransform ():Void {
		if (_stageTransformChanged) {
			_rebuildTransform();
			_stageTransform.identity();
			_stageTransform.append(_transform);
			
			if (_parent != null) {
				_parent._rebuildStageTransform();
				_stageTransform.append(_parent._stageTransform);
			}
			
			_stageTransformChanged = false;
		}
	}
	
	public function getAbsolute (input:Vec2, output:Vec2):Vec2 {
		_rebuildStageTransform();
		
		_TMP_VEC3D.x = input.x;
		_TMP_VEC3D.y = input.y;
		var vec:Vector3D = _stageTransform.transformVector(_TMP_VEC3D);
		output.x = vec.x;
		output.y = vec.y;
		
		return output;
	}
	
	private inline function _transformAABB (b:AABB2, out:AABB2, m:Matrix3D, delta:Bool):Void {
		_TMP_VEC.x = b.xmin;
		_TMP_VEC.y = b.ymin;
		_transformVec(_TMP_VEC, m, delta);
		out.set2(_TMP_VEC, _TMP_VEC);
		_TMP_VEC.x = b.xmax;
		_TMP_VEC.y = b.ymin;
		_transformVec(_TMP_VEC, m, delta);
		out.add(_TMP_VEC);
		_TMP_VEC.x = b.xmax;
		_TMP_VEC.y = b.ymax;
		_transformVec(_TMP_VEC, m, delta);
		out.add(_TMP_VEC);
		_TMP_VEC.x = b.xmin;
		_TMP_VEC.y = b.ymax;
		_transformVec(_TMP_VEC, m, delta);
		out.add(_TMP_VEC);
	}
	
	private inline function _transformVec (vec:Vec2, m:Matrix3D, delta:Bool):Void {
		_TMP_VEC3D.x = vec.x;
		_TMP_VEC3D.y = vec.y;
		var v:Vector3D = if (delta) m.deltaTransformVector(_TMP_VEC3D) else m.transformVector(_TMP_VEC3D);
		vec.x = v.x;
		vec.y = v.y;
	}
	
	private function _rebuildBounds ():Void {
		if (_boundsChanged) {
			var frame:SpriteFrame = getFrame();
			if (frame != null) {
				_transformAABB(frame.bounds, _bounds, getTransform(), true);
				for (i in 0 ... _children.length) {
					_transformAABB(_children[i].getBounds(_TMP_AABB), _TMP_AABB2, getTransform(), true);
					_bounds.addAABB(_TMP_AABB2);
				}
			} else {
				if (_children.length > 0) {
					_transformAABB(_children[0].getBounds(_TMP_AABB), _bounds, getTransform(), true);
					for (i in 1 ... _children.length) {
						_transformAABB(_children[i].getBounds(_TMP_AABB), _TMP_AABB2, getTransform(), true);
						_bounds.addAABB(_TMP_AABB2);
					}
				} else {
					_bounds.empty();
				}
			}
			
			_boundsChanged = false;
		}
	}
	
	public function add (obj:CanvasObject):Void {
		_children.push(obj);
		obj._parent = this;
		obj._setTransformChange(false);
	}
	
	public function addAt (obj:CanvasObject, index:Int):Void {
		_children.insert(index, obj);
		obj._parent = this;
		obj._setTransformChange(false);
	}
	
	public function remove (obj:CanvasObject):Void {
		_children.remove(obj);
		obj._parent = null;
	}
	
	public function removeAt (index:Int):CanvasObject {
		var obj:CanvasObject = _children.splice(index, 1)[0];
		obj._parent = null;
		return obj;
	}
	
	public function removeAll ():Void {
		for (i in _children) {
			i._parent = null;
		}
		_children = new Array<CanvasObject>();
	}
	
	public function get (index:Int):CanvasObject {
		return _children[index];
	}
	
	public function has (obj:CanvasObject):Bool {
		for (i in _children) {
			if (i == obj) return true;
		}
		return false;
	}
	
	public function swap (index1:Int, index2:Int):Void {
		var tmp = _children[index1];
		_children[index1] = _children[index2];
		_children[index2] = tmp;
	}
	
	public function getSize ():Int {
		return _children.length;
	}
	
	public function getChildren ():Array<CanvasObject> {
		return _children;
	}
	
	public function run ():Void {
		for (i in _children) {
			i.run();
		}
		this.execute();
	}
	
	public function render (c:Context3D, camera:Matrix3D):Void {
		if (_alpha > 0 && _visible) {
			runShader(c, camera);
			
			for (i in _children) {
				i.render(c, camera);
			}
		}
	}
	
	//Override this if you want to run a custom shader program
	public function runShader (c:Context3D, camera:Matrix3D):Void {
		var frame:SpriteFrame = getFrame();
		if (frame != null) {
			var stageAlpha:Float = getStageAlpha();
			if (stageAlpha < 1) Batcher.get().render(c, camera);
			_TMP_MATRIX.identity();
			_TMP_MATRIX.append(frame.transform);
			_TMP_MATRIX.append(getStageTransform());
			_TMP_VEC3D.x = 1;
			_TMP_VEC3D.y = 1;
			_TMP_VEC3D.z = 1;
			_TMP_VEC3D.w = stageAlpha;
			Batcher.get().batch(c, camera, frame.polygon, _TMP_MATRIX, _TMP_VEC3D);
			if (stageAlpha < 1) Batcher.get().render(c, camera, true);
		}
	}
	
	//Override
	public function execute ():Void {}
	public function getFrame ():SpriteFrame { return null; }
	
}
