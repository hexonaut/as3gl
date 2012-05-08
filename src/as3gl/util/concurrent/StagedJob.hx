package as3gl.util.concurrent;

class StagedJob implements Job {
	
	private var _funcList:Array<Dynamic>;
	private var _stage:Int;
	
	public function new (funcList:Array<Dynamic>) {
		_funcList = funcList;
		_stage = 0;
	}
	
	public function init (vars:Dynamic<Dynamic>):Void {
	}
	
	public function isComplete ():Bool {
		return _stage == _funcList.length;
	}
	
	public function progress ():Float {
		return _stage / _funcList.length;
	}
	
	public function execute (vars:Dynamic<Dynamic>):Bool {
		if (_funcList[_stage](vars)) {
			_stage++;
			if (_stage == _funcList.length) {
				return true;
			}
		}
		
		return false;
	}
	
	public inline function getStageCount ():Int {
		return _funcList.length;
	}
	
}
