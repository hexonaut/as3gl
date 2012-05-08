/**
 * A canvas sprite.
 * @author Sam MacPherson
 */

package as3gl.display;

class CanvasSprite extends CanvasObject {
	
	public var _ref:FlashDisplayObject;
	
	public function new (ref:FlashDisplayObject) {
		super();
		
		_ref = ref;
	}
	
	public override function getFrame ():SpriteFrame {
		return _ref.get();
	}
	
}
