/**
 * A canvas sprite sheet.
 * @author Sam MacPherson
 */

package as3gl.display;

import de.polygonal.core.math.Mathematics;
import de.polygonal.motor2.geom.math.Vec2;
import flash.errors.Error;
import flash.geom.Point;
import flash.geom.Rectangle;

class CanvasSpriteSheet extends CanvasSprite {
	
	private static var _TMP_PT:Point = new Point();
	private static var _TMP_VEC:Vec2 = new Vec2();
	private static var _TMP_RECT:Rectangle = new Rectangle();
	
	private var _currFrame:Int;
	private var _running:Bool;
	private var _internalFrameRateRatio:Float;
	private var _frameCounter:Float;
	
	public function new (ref:FlashDisplayObject) {
		super(ref);
		
		_currFrame = 0;
		_running = true;
		setAnimationSpeed();
	}
	
	public override function getFrame ():SpriteFrame {
		return _ref.get(_currFrame);
	}
	
	public function setAnimationSpeed (?speed:Float = 1):Void {
		if (speed == 0 || speed == Mathematics.NaN || speed == Mathematics.POSITIVE_INFINITY || speed == Mathematics.NEGATIVE_INFINITY) {
			throw new Error("Attemped to set CanvasSpriteSheet play speed to INFINITY.");
		} else {
			this._internalFrameRateRatio = speed;
			this._frameCounter = 0;
		}
	}
	
	public function getAnimationSpeed ():Float {
		return this._internalFrameRateRatio;
	}
	
	public function play ():Void {
		_running = true;
	}
	
	public function stop ():Void {
		_running = false;
	}
	
	public function getCurrentFrame ():Int {
		return this._currFrame;
	}
	
	public function getTotalFrames ():Int {
		return this._ref.size();
	}
	
	public function gotoAndPlay (frame:Dynamic):Void {
		if (Std.is(frame, String)) {
			_currFrame = this._ref.getFromLabel(cast(frame, String)).frameNum % getTotalFrames();
		} else if (Std.is(frame, Int)) {
			_currFrame = cast(frame, Int) % getTotalFrames();
		} else if (Std.is(frame, Float)) {
			_currFrame = Std.int(cast(frame, Float)) % getTotalFrames();
		}
		this.play();
	}
	
	public function gotoAndStop (frame:Dynamic):Void {
		if (Std.is(frame, String)) {
			_currFrame = this._ref.getFromLabel(cast(frame, String)).frameNum % getTotalFrames();
		} else if (Std.is(frame, Int)) {
			_currFrame = cast(frame, Int) % getTotalFrames();
		} else if (Std.is(frame, Float)) {
			_currFrame = Std.int(cast(frame, Float)) % getTotalFrames();
		}
		this.stop();
	}
	
	public function nextFrame ():Void {
		if (this._currFrame + 1 == this.getTotalFrames()) {
			this._currFrame = 0;
		} else {
			this._currFrame++;
		}
	}
	
	public function prevFrame ():Void {
		if (this._currFrame == 0) {
			this._currFrame = this.getTotalFrames() - 1;
		} else {
			this._currFrame--;
		}
	}
	
	public function getCurrentFrameLabel ():String {
		return _ref.get(_currFrame).label;
	}
	
	public function getFrameFromLabel (label:String):Int {
		var frame:SpriteFrame = _ref.getFromLabel(label);
		if (frame != null) {
			return frame.frameNum;
		} else {
			return -1;
		}
	}
	
	public function getLabelFromFrame (frame:Int):String {
		return _ref.get(frame).label;
	}
	
	public override function run ():Void {
		for (i in _children) {
			i.run();
		}
		
		this._frameCounter += this._internalFrameRateRatio;
		var positive:Bool = this._frameCounter >= 0;
		
		while ((positive ? this._frameCounter : -this._frameCounter) >= 1) {
			if (_running) {
				positive ? this.nextFrame() : this.prevFrame();
			}
			
			this.execute();
			
			positive ? this._frameCounter-- : this._frameCounter++;
		}
	}

}
