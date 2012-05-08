/**
 * Common shaders.
 * @author Sam MacPherson
 */
 
package as3gl.util;

import flash.display3D.Context3D;

@:shader({
	var input:{
		pos:Float2,
		uv:Float2
	};
	var tuv:Float2;
	var dx:Float;
	var dy:Float;
	function vertex (mpos:M44, mproj:M44, pixelX:Float, pixelY:Float) {
		out = pos.xyzw * mpos * mproj;
		tuv = uv;
		dx = pixelX;
		dy = pixelY;
	}
	function fragment (t:Texture) {
		out = (t.get(tuv, clamp) + t.get(tuv + [-dx, 0], clamp) + t.get(tuv + [dx, 0], clamp) + t.get(tuv + [0, -dy], clamp) + t.get(tuv + [0, dy], clamp)) * 0.2;
	}
}) class BlurShader extends format.hxsl.Shader {
}

class Shaders {
	
	private static var _blurShader:BlurShader;
	
	public static function getBlurShader (c:Context3D):BlurShader {
		if (_blurShader == null) _blurShader = new BlurShader(c);
		return _blurShader;
	}
	
}
