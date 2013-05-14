/**
 * Gives low level control over the flash player's execute/render cycle.
 * Canvas is a singleton accessed through the static get() method.
 * @author Sam MacPherson
 */

package as3gl.display;

import as3gl.core.Runnable;
import as3gl.event.GroupId;
import as3gl.logging.Logger;
import as3gl.util.Molehill;
import de.polygonal.core.event.Observable;
import de.polygonal.ds.SLL;
import de.polygonal.motor2.geom.primitive.AABB2;
import flash.display.BitmapData;
import flash.display.Stage3D;
import flash.display3D.Context3D;
import flash.display3D.Context3DBlendFactor;
import flash.display3D.Context3DCompareMode;
import flash.display3D.Context3DTriangleFace;
import flash.display3D.IndexBuffer3D;
import flash.display3D.VertexBuffer3D;
import flash.geom.Matrix3D;
import flash.geom.Rectangle;
import flash.geom.Vector3D;
import flash.errors.Error;
import flash.events.Event;
import flash.events.TimerEvent;
import flash.Lib;
import flash.utils.Timer;

class Canvas extends CanvasObject {
	
	public static var GROUP:Int = GroupId.get();
	public static var EVENT_READY:Int = Observable.makeEvent(GROUP, 0);
	
	public static var ANTI_ALIAS_NONE:Int = 0;
	public static var ANTI_ALIAS_NORMAL:Int = 2;
	public static var ANTI_ALIAS_HIGH:Int = 4;
	public static var ANTI_ALIAS_BEST:Int = 16;
	
	public static var FRAME_RATE:Int = 30;
	public static var SCREEN_WIDTH:Int = 800;
	public static var SCREEN_HEIGHT:Int = 600;
	public static var ANTI_ALIAS:Int = ANTI_ALIAS_NONE;
	public static var ERROR_CHECKING:Bool = false;
	
	private static var _instance:Canvas;
	
	private var _listeners:SLL<Runnable>;
	
	private var _s:Stage3D;
	private var _c:Context3D;
	private var _mproj:Matrix3D;
	private var _ready:Bool;
	private var _depth:Float;
	
	private var _frameRate:Int;
	private var _frameTimer:Timer;
	private var _fps:Float;
	private var _executeDur:Float;
	private var _renderDur:Float;
	private var _dur:Float;
	
	private var _mult:Float;
	private var _period:Float;
	private var _beforeTime:Float;
	private var _afterTime:Float;
	private var _timeDiff:Float;
	private var _sleepTime:Float;
	private var _overSleepTime:Float;
	private var _excess:Float;

	private function new (frameRate:Int) {
		super();
		
		_instance = this;
		
		_listeners = new SLL<Runnable>();
		_dur = Lib.getTimer();
		_executeDur = 0;
		_renderDur = 0;
		_setFrameRate(frameRate);
		_ready = false;
		
		_initFrame();
	}
	
	private function _initFrame ():Void {
		_s = flash.Lib.current.stage.stage3Ds[0];
		_s.addEventListener(Event.CONTEXT3D_CREATE, _onReady);
		_s.requestContext3D();
	}
	
	private function _onReady (e:Event):Void {
		_c = _s.context3D;
		_c.configureBackBuffer(SCREEN_WIDTH, SCREEN_HEIGHT, ANTI_ALIAS, true);
		_c.enableErrorChecking = ERROR_CHECKING;
		
		//Setup camera
		_setCamera(0, 0);
		
		_ready = true;
		this.notify(EVENT_READY, null);
	}
	
	public static inline function get ():Canvas {
		if (_instance == null) {
			_instance = new Canvas(FRAME_RATE);
		}
		return _instance;
	}
	
	private inline function __hook (obj:Runnable):Void {
		_listeners.append(obj);
	}
	
	public static inline function hook (obj:Runnable):Void {
		get().__hook(obj);
	}
	
	private inline function __unhook (obj:Runnable):Void {
		_listeners.remove(obj);
	}
	
	public static inline function unhook (obj:Runnable):Void {
		get().__unhook(obj);
	}
	
	private inline function _clear ():Void {
		_listeners.clear();
	}
	
	public static inline function clear ():Void {
		get()._clear();
	}
	
	private inline function _start ():Void {
		if (!_frameTimer.running) {
			_frameTimer.start();
		}
	}
	
	public static inline function start ():Void {
		get()._start();
	}
	
	private inline function _stop ():Void {
		if (_frameTimer.running) {
			_frameTimer.stop();
			_frameTimer.reset();
		}
	}
	
	public static inline function stop ():Void {
		get()._stop();
	}
	
	public static inline function isRunning ():Bool {
		return get()._frameTimer.running;
	}
	
	private inline function _setFrameRate (frameRate:Int):Void {
		var running:Bool = false;
		
		_frameRate = frameRate;
		
		_period = 1000 / frameRate;
		_mult = 1 / frameRate;
		_fps = frameRate;
		
		if (_frameTimer == null) {
			_frameTimer = new Timer(_period);
			_frameTimer.addEventListener(TimerEvent.TIMER, _tick);
		} else {
			_frameTimer.delay = _period;
			if (_frameTimer.running) {
				_frameTimer.stop();
				_frameTimer.reset();
				_frameTimer.start();
				running = true;
			}
		}
		
		if (running) {
			_start();
		}
	}
	
	public static inline function setFrameRate (frameRate:Int):Void {
		get()._setFrameRate(frameRate);
	}
	
	public static inline function getFrameRate ():Int {
		return get()._frameRate;
	}
	
	public static inline function getFPS ():Int {
		return Std.int(get()._fps);
	}
	
	private inline function _getLoad ():Float {
		return _executeDur + _renderDur;
	}
	
	public static inline function getLoad ():Float {
		return get()._getLoad();
	}
	
	public static inline function getExecuteTime ():Float {
		return get()._executeDur;
	}
	
	public static inline function getRenderTime ():Float {
		return get()._renderDur;
	}
	
	public static inline function getContext ():Context3D {
		return get()._c;
	}
	
	public static inline function isReady ():Bool {
		return get()._ready;
	}
	
	public static inline function getDriverInfo ():String {
		return get()._c.driverInfo;
	}
	
	public static inline function getNextDepth ():Float {
		return _instance._depth++;
	}
	
	public static function setCamera (x:Int, y:Int):Void {
		get()._setCamera(x, y);
	}
	
	private function _setCamera (x:Int, y:Int):Void {
		_mproj = Molehill.getOrthographicMatrix(x, x + SCREEN_WIDTH, y + SCREEN_HEIGHT, y, 1 << 20, 0);
	}
	
	private function _tick (event:TimerEvent):Void {
		if (_ready) {
			_beforeTime = Lib.getTimer();
			if (_beforeTime - _dur > 0) _fps = _mult * (1000 / (_beforeTime - _dur)) + (1 - _mult) * _fps;
			_dur = _beforeTime;
			_overSleepTime = (_beforeTime - _afterTime) - _sleepTime;
			
			_notify();
			
			_afterTime = Lib.getTimer();
			_timeDiff = _afterTime - _beforeTime;
			_sleepTime = (_period - _timeDiff) - _overSleepTime;
			if (_sleepTime <= 0) {
				_excess -= _sleepTime;
				_sleepTime = 5;
			}
			
			if (_excess > 100) {
				_excess = 100;
			}
			
			while (_excess > _period) {
				_notify();
				_excess -= _period;
			}
			
			_render();
		}
	}
	
	private function _notify ():Void {
		var time:Int = Lib.getTimer();
		for (i in _listeners) {
			try {
				i.run();
			} catch (e:Error) {
				Logger.log(Logger.WARN, e.getStackTrace());
				__unhook(i);
			}
		}
		run();
		_executeDur = _mult * ((Lib.getTimer() - time) / _period) + (1 - _mult) * _executeDur;
	}
	
	private inline function _render ():Void {
		var time:Int = Lib.getTimer();
		
		//Clear last render and setup next one
		_c.clear();
		_c.setDepthTest(true, Context3DCompareMode.LESS);
		_c.setCulling(Context3DTriangleFace.BACK);
		_c.setBlendFactors(Context3DBlendFactor.SOURCE_ALPHA, Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA);
		
		//Make sure batcher is ready
		var b:Batcher = Batcher.get();
		if (b.isReady()) b.build(_c);
		
		//Render children and display
		_depth = 1;
		this.render(_c, _mproj);
		b.render(_c, _mproj);
		_c.present();
		
		_renderDur = _mult * ((Lib.getTimer() - time) / _period) + (1 - _mult) * _renderDur;
	}
	
}