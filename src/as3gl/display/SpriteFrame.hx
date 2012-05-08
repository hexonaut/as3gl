/**
 * A grouping of properties that represents a SpriteSheet Frame. Can only be instantiated after Canvas has been initialized.
 * @author Sam MacPherson
 */

package as3gl.display;

import as3gl.display.data.Polygon;
import de.polygonal.motor2.geom.math.Vec2;
import de.polygonal.motor2.geom.primitive.AABB2;
import flash.display.BitmapData;
import flash.geom.Matrix3D;

class SpriteFrame {
	
	public var bounds:AABB2;
	public var transform:Matrix3D;
	public var bitmap:BitmapData;
	public var frameNum:Int;
	public var label:String;
	public var polygon:Polygon;
	
	public function new (frameNum:Int, bmd:BitmapData, bounds:AABB2, ?label:String = null, ?buildQuad:Bool = true) {
		this.bitmap = bmd;
		this.frameNum = frameNum;
		this.bounds = bounds;
		this.label = label;
		this.transform = new Matrix3D();
		
		if (bounds.intervalX > 0 && bounds.intervalY > 0) {
			this.transform.appendScale(bounds.intervalX, bounds.intervalY, 1);
			this.transform.appendTranslation(bounds.xmin, bounds.ymin, 0);
		}
		
		if (buildQuad && bmd.width <= 2048 && bmd.height <= 2048) {
			this.polygon = Batcher.get().add(bmd);
		}
	}
	
	public function clone ():SpriteFrame {
		var sf:SpriteFrame = new SpriteFrame(frameNum, bitmap, bounds.clone(), label, false);
		sf.polygon = polygon.clone();
		return sf;
	}
	
}
