/**
 * Represents a light source which can be added to a LightMap.
 * @author Sam MacPherson
 */

package as3gl.lighting;

import de.polygonal.motor2.geom.math.Vec2;

interface LightSource {
	
	function getLightX ():Int;
	function getLightY ():Int;
	function getLightFloor ():Int;
	function getLightArc ():Float;
	function getLightAngle ():Float;
	function getLightRange ():Float;
	function getLightColor ():UInt;
	function isLightOn ():Bool;
	function cacheLight ():Bool;
	
}
