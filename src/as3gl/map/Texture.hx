/**
 * A piece of map terrain. Do not instantiate directly.
 * @author Sam MacPherson
 */

package as3gl.map;

import as3gl.display.Batcher;
import as3gl.display.SpriteFrame;
import as3gl.util.Asset;
import as3gl.util.Assets;
import as3gl.world.WorldObject;
import de.polygonal.motor2.geom.math.Vec2;
import flash.errors.Error;
import flash.geom.Matrix3D;

class Texture extends WorldObject {
	
	public var _asset:Asset;
	public var _image:Asset;
	public var _depth:Int;
	
	public function new (asset:Asset, image:Asset, depth:Int) {
		super();
		
		_asset = asset;
		_image = image;
		_depth = depth;
	}
	
	public inline static function loadFromAsset (asset:Asset):Texture {
		var t:Texture = null;
		var ref:Asset = null;
		var m:Matrix3D = _getBaseTransform(Std.parseFloat(asset.requireProperty("m00")), Std.parseFloat(asset.requireProperty("m10")), Std.parseFloat(asset.requireProperty("m01")), Std.parseFloat(asset.requireProperty("m11")), Std.parseFloat(asset.requireProperty("m02")), Std.parseFloat(asset.requireProperty("m12")));
		if (asset.requireProperty("t") == "d") {
			t = new Doodad(asset, Assets.get(asset.requireProperty("r")), Std.parseInt(asset.requireProperty("d")), m);
		} else if (asset.requireProperty("t") == "r") {
			ref = Assets.get(asset.requireProperty("r"));
			_setupFrame(ref);
			t = new Rail(asset, ref, Std.parseInt(asset.requireProperty("d")), Std.parseFloat(asset.requireProperty("l")), m);
		} else if (asset.requireProperty("t") == "s") {
			ref = Assets.get(asset.requireProperty("r"));
			_setupFrame(ref);
			var pts:Array<Vec2> = new Array<Vec2>();
			var index:Int = 0;
			while (asset.getProperty("p" + index) != null) {
				pts.push(new Vec2(Std.parseFloat(asset.getProperty("p" + index)), Std.parseFloat(asset.getProperty("p" + (index + 1)))));
				index += 2;
			}
			t = new Surface(asset, ref, Std.parseInt(asset.requireProperty("d")), pts, m);
		} else {
			throw new Error("Asset is not a texture.");
		}
		t.setPosition(Std.parseInt(asset.requireProperty("x")), Std.parseInt(asset.requireProperty("y")));
		return t;
	}
	
	private inline static function _setupFrame (asset:Asset):Void {
		var sf:SpriteFrame = asset.get().get();
		if (!sf.polygon.dedicated) {
			sf.polygon = Batcher.get().add(sf.bitmap, true);
		}
	}
	
	private inline static function _getBaseTransform (m00:Float, m10:Float, m01:Float, m11:Float, m02:Float, m12:Float):Matrix3D {
		var data:flash.Vector<Float> = new flash.Vector<Float>(16, true);
		
		//First col
		data[0] = m00;
		data[1] = m10;
		data[2] = 0;
		data[3] = 0;
		
		//Second col
		data[4] = m01;
		data[5] = m11;
		data[6] = 0;
		data[7] = 0;
		
		//Third col
		data[8] = 0;
		data[9] = 0;
		data[10] = 1;
		data[11] = 0;
		
		//Fourth col
		data[12] = m02;
		data[13] = m12;
		data[14] = 0;
		data[15] = 1;
		
		return new Matrix3D(data);
	}
	
	public inline function getAsset ():Asset {
		return _asset;
	}
	
	public inline function getImageAsset ():Asset {
		return _image;
	}
	
	public inline function getDepth ():Int {
		return _depth;
	}

}
