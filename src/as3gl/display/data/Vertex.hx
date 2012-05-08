/**
 * A float4 vertex.
 * @author Sam MacPherson
 */

package as3gl.display.data;

class Vertex {
	
	public var x:Float;
	public var y:Float;
	public var u:Float;
	public var v:Float;

	public function new (x:Float, y:Float, u:Float, v:Float) {
		this.x = x;
		this.y = y;
		this.u = u;
		this.v = v;
	}
	
}