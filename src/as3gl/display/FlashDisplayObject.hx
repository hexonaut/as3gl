/**
 * Represents a traditional flash display object. Used to convert flash display objects to as3gl display objects.
 * @author Sam MacPherson
 */

package as3gl.display;

import de.polygonal.motor2.geom.primitive.AABB2;
import de.polygonal.ds.HashMap;
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.FrameLabel;
import flash.display.MovieClip;
import flash.display.Sprite;
import flash.geom.Rectangle;
import flash.geom.Matrix;
import flash.errors.Error;

class FlashDisplayObject {
	
	private var _frames:Array<SpriteFrame>;
	private var _frameLookup:HashMap<String, SpriteFrame>;
	
	public function new (obj:Dynamic) {
		_frames = new Array<SpriteFrame>();
		_frameLookup = new HashMap<String, SpriteFrame>();
		
		if (Std.is(obj, BitmapData)) {
			_loadFromBitmapData(cast(obj, BitmapData));
		} else if (Std.is(obj, Bitmap)) {
			_loadFromBitmap(cast(obj, Bitmap));
		} else if (Std.is(obj, MovieClip)) {
			_loadFromMovieClip(cast(obj, MovieClip));
		} else if (Std.is(obj, Sprite)) {
			_loadFromSprite(cast(obj, Sprite));
		} else {
			throw new Error("Unknown DisplayObject " + obj + ". Only Bitmap, Sprite and MovieClip are supported.");
		}
	}
	
	private function _loadFromBitmapData (bmd:BitmapData):Void {
		_frames.push(new SpriteFrame(0, bmd, new AABB2(0, 0, bmd.width, bmd.height)));
	}
	
	private function _loadFromBitmap (bm:Bitmap):Void {
		var bounds:Rectangle = bm.getBounds(bm);
		var bmd:BitmapData = new BitmapData(Math.ceil(Math.max(bounds.width, 1)), Math.ceil(Math.max(bounds.height, 1)), true, 0x00000000);
		var m:Matrix = new Matrix();
		m.translate(-bounds.x, -bounds.y);
		bmd.draw(bm, m);
		_frames.push(new SpriteFrame(0, bmd, AABB2.ofRectangle(bounds, new AABB2())));
	}
	
	private function _loadFromSprite (sprite:Sprite):Void {
		var bounds:Rectangle = sprite.getBounds(sprite);
		var bmd:BitmapData = new BitmapData(Math.ceil(Math.max(bounds.width, 1)), Math.ceil(Math.max(bounds.height, 1)), true, 0x00000000);
		var m:Matrix = new Matrix();
		m.translate(-bounds.x, -bounds.y);
		bmd.draw(sprite, m);
		_frames.push(new SpriteFrame(0, bmd, AABB2.ofRectangle(bounds, new AABB2())));
	}
	
	private function _loadFromMovieClip (mc:MovieClip):Void {
		for (i in 1 ... mc.totalFrames + 1) {
			mc.gotoAndStop(i);
			var bounds:Rectangle = mc.getBounds(mc);
			var bmd:BitmapData = new BitmapData(Math.ceil(Math.max(bounds.width, 1)), Math.ceil(Math.max(bounds.height, 1)), true, 0x00000000);
			var m:Matrix = new Matrix();
			m.translate(-bounds.x, -bounds.y);
			bmd.draw(mc, m);
			_frames.push(new SpriteFrame(i - 1, bmd, AABB2.ofRectangle(bounds, new AABB2())));
		}
		
		var frameLabels:Array<FrameLabel> = mc.currentLabels;
		for (i in frameLabels) {
			this._frames[i.frame - 1].label = i.name;
			this._frameLookup.set(i.name, this._frames[i.frame - 1]);
		}
	}
	
	public inline function get (?frame:Int = 0):SpriteFrame {
		return _frames[frame];
	}
	
	public inline function getFromLabel (label:String):SpriteFrame {
		return _frameLookup.get(label);
	}
	
	public inline function size ():Int {
		return _frames.length;
	}
	
	public inline function newInstance ():CanvasObject {
		if (size() == 1) {
			return new CanvasSprite(this);
		} else {
			return new CanvasSpriteSheet(this);
		}
	}
	
}
