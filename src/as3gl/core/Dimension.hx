/**
 * Specifies width and height properties of a 2D object.
 * @author Sam MacPherson
 */

package as3gl.core;
import flash.geom.Point;

class Dimension {
	
	public var width:Float;
	public var height:Float;

	public function new (?width:Float = 0, ?height:Float = 0) {
		this.width = width;
		this.height = height;
	}
	
	public function clone ():Dimension {
		return new Dimension(width, height);
	}
	
	public function equals (other:Dimension):Bool {
		return width == other.width && height == other.height;
	}
	
	public function toString ():String {
		return "(w=" + width + ", h=" + height + ")";
	}
	
	public function contains (x:Float, y:Float):Bool {
		return x >= 0 && x < width && y >= 0 && y < height;
	}
	
	public function containsPoint (pt:Point):Bool {
		return pt.x >= 0 && pt.x < width && pt.y >= 0 && pt.y < height;
	}
	
}