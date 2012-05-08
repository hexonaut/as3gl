/**
 * A batchable rectangle.
 * @author Sam MacPherson
 */

package as3gl.display.data;

import de.polygonal.motor2.geom.primitive.AABB2;
import flash.geom.Matrix3D;
import flash.geom.Vector3D;

class Quad extends Polygon {
	
	public var umin:Float;
	public var vmin:Float;
	public var umax:Float;
	public var vmax:Float;

	public function new (tid:Int, dedicated:Bool, tcoords:AABB2) {
		super(tid, dedicated);
		
		this.addVertex(new Vertex(0, 0, tcoords.xmin, tcoords.ymin));
		this.addVertex(new Vertex(1, 0, tcoords.xmax, tcoords.ymin));
		this.addVertex(new Vertex(0, 1, tcoords.xmin, tcoords.ymax));
		this.addVertex(new Vertex(1, 1, tcoords.xmax, tcoords.ymax));
		
		this.addTriangle(0, 1, 3);
		this.addTriangle(0, 3, 2);
		
		umin = tcoords.xmin;
		vmin = tcoords.ymin;
		umax = tcoords.xmax;
		vmax = tcoords.ymax;
	}
	
}