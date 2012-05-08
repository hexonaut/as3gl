/**
 * Used in the SimpleParticleSystem.
 * @author Sam MacPherson
 */

package as3gl.particle;

import flash.geom.Matrix3D;
import flash.geom.Vector3D;

class SimpleParticle {
	
	//Physical Transformations
	public var transform:Array<Vector3D>;
	
	//Color Transformations
	public var color:Vector3D;
	public var velColor:Vector3D;
	public var accelColor:Vector3D;
	
	//Time offset
	public var timeOffset:Float;

	public function new (?timeOffset:Float = 0) {
		transform = new Array<Vector3D>();
		for (i in 0 ... 4) {
			transform[i] = new Vector3D();
		}
		transform[0].w = 1;
		transform[1].x = 1;
		transform[3].w = 0;
		
		color = new Vector3D(1, 1, 1, 1);
		velColor = new Vector3D();
		accelColor = new Vector3D();
		
		this.timeOffset = timeOffset;
	}
	
	public function setTransform (x:Float, y:Float, angle:Float, scaleX:Float, scaleY:Float):Void {
		transform[0].x = x;
		transform[0].y = y;
		transform[0].z = angle;
		transform[0].w = scaleX;
		transform[1].x = scaleY;
	}
	
	public function setVelocityTransform (x:Float, y:Float, angle:Float, scaleX:Float, scaleY:Float):Void {
		transform[1].y = x;
		transform[1].z = y;
		transform[1].w = angle;
		transform[2].x = scaleX;
		transform[2].y = scaleY;
	}
	
	public function setAccelerationTransform (x:Float, y:Float, angle:Float, scaleX:Float, scaleY:Float):Void {
		transform[2].z = x;
		transform[2].w = y;
		transform[3].x = angle;
		transform[3].y = scaleX;
		transform[3].z = scaleY;
	}
	
	public function setColor (r:Float, g:Float, b:Float, a:Float):Void {
		color.x = r;
		color.y = g;
		color.z = b;
		color.w = a;
	}
	
	public function setColorVelocity (r:Float, g:Float, b:Float, a:Float):Void {
		velColor.x = r;
		velColor.y = g;
		velColor.z = b;
		velColor.w = a;
	}
	
	public function setColorAcceleration (r:Float, g:Float, b:Float, a:Float):Void {
		accelColor.x = r;
		accelColor.y = g;
		accelColor.z = b;
		accelColor.w = a;
	}
	
}