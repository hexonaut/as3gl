/**
 * A AABB2 with two additional floor/level properties.
 * @author Sam MacPherson
 */

package as3gl.world;

import de.polygonal.core.fmt.Sprintf;
import de.polygonal.motor2.geom.primitive.AABB2;

class WorldAABB2 extends AABB2 {
	
	public var floor:Int;
	public var level:Int;

	public function new (?xmin:Float = 1.0, ?ymin:Float = 1.0, ?xmax:Float = -1.0, ?ymax:Float = -1.0, ?floor:Int = 0, ?level:Int = 0) {
		super(xmin, ymin, xmax, ymax);
		
		this.floor = floor;
		this.level = level;
	}
	
	public override function toString ():String {
		return Sprintf.format("\n%.3f -> %.3f\n%.3f -> %.3f\nf=%d,l=%d", [xmin, xmax, ymin, ymax, floor, level]);
	}
	
}