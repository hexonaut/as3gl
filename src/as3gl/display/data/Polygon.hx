/**
 * A batchable polygon.
 * @author Sam MacPherson
 */

package as3gl.display.data;

import de.polygonal.motor2.geom.primitive.AABB2;
import flash.geom.Matrix3D;
import flash.geom.Vector3D;

class Polygon {
	
	public var tid:Int;
	public var dedicated:Bool;
	public var verticies:Array<Vertex>;
	public var indicies:Array<UInt>;

	public function new (tid:Int, ?dedicated:Bool) {
		this.tid = tid;
		this.dedicated = dedicated;
		this.verticies = new Array<Vertex>();
		this.indicies = new Array<UInt>();
	}
	
	public inline function addVertex (vertex:Vertex):Void {
		this.verticies.push(vertex);
	}
	
	public inline function addTriangle (v1:UInt, v2:UInt, v3:UInt):Void {
		this.indicies.push(v1);
		this.indicies.push(v2);
		this.indicies.push(v3);
	}
	
	public function clone ():Polygon {
		var p:Polygon = new Polygon(tid, dedicated);
		for (i in verticies) {
			p.addVertex(new Vertex(i.x, i.y, i.u, i.v));
		}
		for (i in indicies) {
			p.indicies.push(i);
		}
		return p;
	}
	
}