package as3gl.core;

import de.polygonal.ds.SLL;

class GC implements Runnable {
	
	private static var _INSTANCE:GC;
	
	private var _monitors:SLL<Monitor>;
	
	private function new () {
		_monitors = new SLL<Monitor>();
	}
	
	public inline function monitor (monitorObj:Dynamic, obj:Destroyable):Void {
		_monitors.append(new Monitor(monitorObj, obj));
	}
	
	public inline function run ():Void {
		for (i in _monitors) {
			if (i.check()) {
				_monitors.remove(i);
			}
		}
	}
	
	public inline static function instance ():GC {
		if (_INSTANCE == null) {
			_INSTANCE = new GC();
		}
		return _INSTANCE;
	}
	
}

class Monitor {
	
	public var monitorObj:WeakReference<Dynamic>;
	public var obj:Destroyable;
	
	public function new (monitorObj:Dynamic, obj:Destroyable) {
		this.monitorObj = new WeakReference<Dynamic>(monitorObj);
		this.obj = obj;
	}
	
	public inline function check ():Bool {
		if (monitorObj.exists()) {
			return false;
		} else {
			obj.destroy();
			return true;
		}
	}
	
}