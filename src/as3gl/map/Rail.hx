/**
 * An image which scales along one axis (Used for walls, etc)
 * @author Sam MacPherson
 */

package as3gl.map;

import as3gl.display.Canvas;
import as3gl.display.SpriteFrame;
import as3gl.display.data.Vertex;
import as3gl.geom.Geom;
import as3gl.util.Asset;
import as3gl.util.Molehill;
import de.polygonal.motor2.geom.primitive.AABB2;
import flash.display3D.IndexBuffer3D;
import flash.display3D.VertexBuffer3D;
import flash.display3D.textures.Texture;
import flash.geom.Matrix3D;
import flash.geom.Vector3D;

class Rail extends as3gl.map.Texture {
	
	private var _length:Float;
	private var _frame:SpriteFrame;
	
	public function new (asset:Asset, image:Asset, depth:Int, length:Float, m:Matrix3D) {
		super(asset, image, depth);
		
		_length = length;
		_frame = image.get().get().clone();
		var scaleX:Float = length / _frame.bitmap.width;
		_frame.transform.appendTranslation(0, -_frame.bitmap.height*0.5, 0);
		_frame.transform.appendScale(scaleX, 1, 1);
		_frame.transform.append(m);
		_frame.bounds = Geom.transformAABB(new AABB2(0, 0, 1, 1), new AABB2(), _frame.transform);
		for (i in _frame.polygon.verticies) {
			if (i.u == 1) i.u = scaleX;
		}
	}
	
	public inline function getLength ():Float {
		return _length;
	}
	
	public override function getFrame ():SpriteFrame {
		return _frame;
	}
	
}
