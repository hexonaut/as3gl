/**
 * A Line with two additional floor/level properties.
 * @author Sam MacPherson
 */

package as3gl.world;

import de.polygonal.core.fmt.Sprintf;
import as3gl.geom.Line;

class WorldLine extends Line {
	
	public var floor:Int;
	public var level:Int;

	public function new (?x1:Float = 0, ?y1:Float = 0, ?x2:Float = 0, ?y2:Float = 0, ?floor:Int = 0, ?level:Int = 0) {
		super(x1, y1, x2, y2);
		
		this.floor = floor;
		this.level = level;
	}
	
	public override function toString ():String {
		return Sprintf.format("[%.3f,%.3f,%.3f,%.3f,f=%d,l=%d]", [x1, y1, x2, y2, floor, level]);
	}
	
}