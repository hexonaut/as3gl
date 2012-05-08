package as3gl.logging;

class TraceHandler {
	
	public function new () {
	}
	
	public function log (level:Int, msg:Dynamic):Void {
		if (level == Logger.DEBUG) {
			flash.Lib.trace("[Debug] " + msg);
		} else if (level == Logger.INFO) {
			flash.Lib.trace("[Info] " + msg);
		} else if (level == Logger.WARN) {
			flash.Lib.trace("[Warning] " + msg);
		} else if (level == Logger.ERROR) {
			flash.Lib.trace("[Error] " + msg);
		}
	}

}
