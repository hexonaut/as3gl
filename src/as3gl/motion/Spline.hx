/**
 * Used for providing motion interpolation between two points.
 * @author Sam MacPherson
 */

package as3gl.motion;
import de.polygonal.motor2.geom.math.Vec2;

interface Spline {

	function getPosition (t:Float, out:Vec2):Vec2;
	function getVelocity (t:Float, out:Vec2):Vec2;
	function getTotalTime ():Float;
	
}