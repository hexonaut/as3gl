package as3gl.util;

import de.polygonal.ds.HashMap;

class Locale {
	
	private static var _lang:String = "en";
	private static var _t:HashMap<String, String> = new HashMap<String, String>();
	
	public static function setLanguage (lang:String):Void {
		_lang = lang;
	}
	
	public static function getLanguage ():String {
		return _lang;
	}
	
	public static function setTranslation (translation:HashMap<String, String>):Void {
		_t = translation;
	}
	
	public static function t (strId:String):String {
		var str:String = _t.get(strId);
		if (str != null) {
			return str;
		} else {
			return strId;
		}
	}
	
}
