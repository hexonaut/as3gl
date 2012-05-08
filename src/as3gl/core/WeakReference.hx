package as3gl.core;

import flash.utils.Dictionary;

class WeakReference<T> {
    
	private var _dic:Dictionary;
	
	public function new (obj:T) {
		_dic = new Dictionary(true);
		untyped _dic[obj] = null;
	}
	
	public inline function get ():T {
		var a:Array<Dynamic> = untyped __keys__(_dic);
		var key:T = null;
		for (i in a) key = i;
		return key;
	}
	
	public inline function exists ():Bool {
		return get() != null;
	}
	
}