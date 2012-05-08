/**
 * A Vec2 with two additional floor/level properties.
 * @author Sam MacPherson
 */

package as3gl.world;

import de.polygonal.core.fmt.Sprintf;
import de.polygonal.motor2.geom.math.Vec2;

class WorldVec2 extends Vec2 {
	
	public var floor:Int;
	public var level:Int;

	public function new (?x:Float = 0.0, ?y:Float = 0.0, ?floor:Int = 0, ?level:Int = 0) {
		super(x, y);
		
		this.floor = floor;
		this.level = level;
	}
	
	public override function toString ():String {
		return Sprintf.format("[%.3f,%.3f,f=%d,l=%d]", [x, y, floor, level]);
	}
	
}