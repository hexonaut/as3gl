/**
 * An abstract asset (Sound/Animation/Image/etc)
 * @author Sam MacPherson
 */

package as3gl.util;

import as3gl.logging.Logger;
import de.polygonal.ds.ArrayedQueue;
import de.polygonal.ds.HashMap;
import flash.errors.Error;

class Asset {
	
	private static var _TMP_QUEUE:ArrayedQueue<Asset> = new ArrayedQueue<Asset>(1);
	
	private var _path:String;
	private var _parent:Asset;
	public var _gapId:Int;
	public var _libId:Int;
	private var _props:HashMap<String, String>;
	private var _assets:HashMap<String, Asset>;
	
	public function new (path:String, ?parent:Asset = null) {
		this._path = path;
		this._parent = parent;
		this._props = new HashMap<String, String>();
		this._assets = new HashMap<String, Asset>();
	}
	
	public function get ():Dynamic {
		return Assets._libraryAssets[_gapId].get(_libId);
	}
	
	public function _setPath (path:String):Void {
		this._path = path;
	}
	
	public function getPath ():String {
		return _path;
	}
	
	public function getName ():String {
		return _path.substr(_path.lastIndexOf('.') + 1);
	}
	
	public function setProperty (name:String, value:String):Void {
		_props.set(name, value);
	}
	
	public function getProperty (name:String, ?defaultValue:String = null):String {
		var val:String = _props.get(name);
		if (val == null || val == "") {
			val = defaultValue;
		}
		return val;
	}
	
	public function requireProperty (name:String):String {
		var val:String = _props.get(name);
		if (val == null || val == "") {
			Logger.log(Logger.WARN, "Missing required property '" + name + "' on directory '" + getPath() + "'.");
			throw new Error("Missing required property '" + name + "' on directory '" + getPath() + "'.");
		}
		return val;
	}
	
	public function hasProperty (name:String):Bool {
		return _props.hasKey(name);
	}
	
	public function getProperties ():HashMap<String, String> {
		return _props;
	}
	
	public function addAsset (name:String, value:Asset):Void {
		_assets.set(name, value);
	}
	
	public function getAsset (name:String):Asset {
		if (_props.hasKey(name)) {
			return _assets.get(name);
		} else {
			throw new Error("Sub-asset '" + name + "' not found on asset '" + getPath() + "'");
		}
	}
	
	public function removeAsset (asset:Asset):Void {
		_assets.remove(asset);
	}
	
	public function getAssets (?recursive:Bool = false):HashMap<String, Asset> {
		if (recursive) {
			var list:HashMap<String, Asset> = new HashMap<String, Asset>();
			_TMP_QUEUE.clear();
			_TMP_QUEUE.enqueue(this);
			while (!_TMP_QUEUE.isEmpty()) {
				var asset:Asset = _TMP_QUEUE.dequeue();
				if (asset != this) list.set(asset.getPath().substr(this.getPath().length + 1), asset);
				for (i in asset._assets) {
					_TMP_QUEUE.enqueue(i);
				}
			}
			return list;
		} else {
			return _assets;
		}
	}
	
	public function getParent ():Asset {
		return _parent;
	}
	
}
