/**
 * Useful for generating unique group ids for events.
 * @author Sam MacPherson
 */

package as3gl.event;

import de.polygonal.core.event.Observable;
import flash.errors.Error;

class GroupId {
	
	private static var _NEXT_ID:Int = 0;
	
	public inline static function get ():Int {
		if (_NEXT_ID == 1 << Observable.NUM_GROUP_BITS) throw new Error("All available group ids have been used. Increase group id space.");
		return _NEXT_ID++;
	}
	
}
