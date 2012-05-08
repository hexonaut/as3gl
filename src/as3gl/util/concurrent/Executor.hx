/**
 * Provides some psuedo-concurrent functionality. Similiar to the java.util.concurrent package.
 * Tasks are removed when complete. To signal a task completion the execute() function must return true.
 * @author Sam MacPherson
 */

package as3gl.util.concurrent;

import as3gl.core.Runnable;
import as3gl.display.Canvas;
import as3gl.event.GroupId;
import as3gl.logging.Logger;
import as3gl.util.concurrent.Job;
import de.polygonal.core.event.Observable;
import flash.events.EventDispatcher;
import flash.errors.Error;
import flash.Lib;

class Executor extends Observable, implements Runnable {
	
	public static var GROUP:Int = GroupId.get();
	public static var EVENT_TASK_COMPLETE:Int = Observable.makeEvent(GROUP, 0);
	
	public static var PRIORITY_LOW:Int = 0;
	public static var PRIORITY_MEDIUM:Int = 1;
	public static var PRIORITY_HIGH:Int = 2;
	
	private var _tasks:de.polygonal.ds.PriorityQueue<TaskData>;
	private var _interval:Float;
	private var _numRuns:Int;
	private var _totalRuntime:Float;

	public function new (interval:Float) {
		super();
		
		_tasks = new de.polygonal.ds.PriorityQueue<TaskData>();
		_interval = interval;
		_numRuns  = 0;
		_totalRuntime = 0;
	}
	
	public function addTask (task:Job, ?priority:Int = 0):Void {
		var td:TaskData = new TaskData(task, priority);
		_tasks.enqueue(td);
		task.init(td.getVars());
	}
	
	public function removeTask (task:Job):Void {
		for (i in _tasks) {
			if (i.getTask() == task) {
				_tasks.remove(i);
			}
		}
	}
	
	public function setInterval (interval:Float):Void {
		_interval = interval;
	}
	
	public function getJobProgress ():Float {
		var total:Float = 0;
		var count:Int = 0;
		for (i in _tasks) {
			total += i.getTask().progress();
			count++;
		}
		return total / count;
	}
	
	public function run ():Void {
		if (!_tasks.isEmpty()) {
			var task:TaskData = _tasks.front();
			while (_totalRuntime +  task.getAverageRuntime() < _interval) {
				try {
					if (task.run()) {
						this.notify(EVENT_TASK_COMPLETE, task.getTask());
						_tasks.remove(task);
					} else {
						_tasks.reprioritize(task, -_numRuns + task.getPriority());
					}
					_totalRuntime += task.getLastRuntime();
				} catch (e:Error) {
					_tasks.remove(task);
					Logger.log(Logger.WARN, "Exception in thread-" + task.getId() + "\n" + e.getStackTrace());
				}
				if (_tasks.isEmpty()) {
					break;
				}
				task = _tasks.front();
			}
		}
		_totalRuntime -= _interval;
		
		_numRuns++;
		if (_numRuns >= 0x7FFFFFFF) {
			for (i in _tasks) {
				_tasks.reprioritize(i, i.priority + _numRuns);
			}
			_numRuns = 0;
		}
	}
	
}

private class TaskData implements de.polygonal.ds.Prioritizable {
	
	private static var _NEXT_ID:Int = 0;
	private static var _mult:Float = 0.25;
	
	public var priority:Int;
	public var position:Int;
	
	private var _id:Int;
	private var _task:Job;
	private var _priority:Int;
	private var _counter:Int;
	private var _vars:Dynamic<Dynamic>;
	private var _averageRuntime:Float;
	private var _lastRuntime:Float;
	private var _numRuns:Int;
	
	public function new (task:Job, priority:Int) {
		this.priority = priority;
		this._id = _NEXT_ID++;
		this._task = task;
		this._priority = priority;
		this._counter = 0;
		this._vars = {};
		this._averageRuntime = 0;
		this._numRuns = 1;
	}
	
	public inline function getTask ():Job {
		return this._task;
	}
	
	public inline function getId ():Int {
		return _id;
	}
	
	public inline function getAverageRuntime ():Float {
		return _averageRuntime;
	}
	
	public inline function getLastRuntime ():Float {
		return _lastRuntime;
	}
	
	public inline function getPriority ():Int {
		return _priority;
	}
	
	public inline function getVars ():Dynamic<Dynamic> {
		return _vars;
	}
	
	public inline function run ():Bool {
		var start:Int = Lib.getTimer();
		var done:Bool = false;
		for (i in 0 ... _numRuns) {
			if (this._task.execute(_vars)) {
				done = true;
				break;
			}
			//Make sure single loop doesnt go too long (Could happen if process was waiting on an event before starting)
			if (Lib.getTimer() - start >= 1 && _numRuns > 1) {
				_numRuns = 1;
			}
		}
		_lastRuntime = Lib.getTimer() - start;
		_averageRuntime = _mult * _lastRuntime + (1 - _mult) * _averageRuntime;
		if (_lastRuntime < 1) {
			//Increase number of runs if the process is fast
			_numRuns <<= 1;
		} else if (_numRuns > 1) {
			//Decrease number of runs if the process has slowed down
			_numRuns >>= 1;
		}
		return done;
	}
	
}