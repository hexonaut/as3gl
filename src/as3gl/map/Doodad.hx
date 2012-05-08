/**
 * A fixed doodad.
 * @author Sam MacPherson
 */

package as3gl.map;

import as3gl.display.Canvas;
import as3gl.display.SpriteFrame;
import as3gl.geom.Geom;
import as3gl.util.Asset;
import as3gl.util.Molehill;
import de.polygonal.motor2.geom.primitive.AABB2;
import flash.display3D.IndexBuffer3D;
import flash.display3D.VertexBuffer3D;
import flash.display3D.textures.Texture;
import flash.geom.Matrix3D;
import flash.geom.Vector3D;

class Doodad extends as3gl.map.Texture {
	
	private var _frame:SpriteFrame;
	
	public function new (asset:Asset, image:Asset, depth:Int, m:Matrix3D) {
		super(asset, image, depth);
		
		_frame = image.get().get().clone();
		_frame.transform.appendTranslation(-_frame.bounds.intervalX*0.5, -_frame.bounds.intervalY*0.5, 0);
		_frame.transform.append(m);
		_frame.bounds = Geom.transformAABB(new AABB2(0, 0, 1, 1), new AABB2(), _frame.transform);
	}
	
	public override function getFrame ():SpriteFrame {
		return _frame;
	}
	
}
