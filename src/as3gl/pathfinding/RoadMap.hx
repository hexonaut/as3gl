/**
 * Provides O(1) lookups for paths in AABB maps that are static.
 * Be sure to call destroy after usage as this class uses alchemy memory.
 * @author Sam MacPherson
 */

package as3gl.pathfinding;

import as3gl.core.Destroyable;
import as3gl.core.Dimension;
import as3gl.geom.Geom;
import as3gl.geom.Line;
import as3gl.logging.Logger;
import as3gl.util.concurrent.StagedJob;
import as3gl.world.WorldAABB2;
import as3gl.world.WorldVec2;
import de.polygonal.core.math.Mathematics;
import de.polygonal.ds.Bits;
import de.polygonal.motor2.geom.math.Vec2;
import de.polygonal.motor2.geom.primitive.AABB2;
import de.polygonal.motor2.geom.intersect.IntersectAABB;

class RoadMap extends StagedJob, implements Destroyable {
	
	private var _xLookup:de.polygonal.ds.mem.ShortMemory;
	private var _yLookup:de.polygonal.ds.mem.ShortMemory;
	private var _roads:de.polygonal.ds.Map<Int, Road>;
	private var _roadList:de.polygonal.ds.SLL<Road>;
	private var _graph:de.polygonal.ds.Graph<Road>;
	private var _cache:de.polygonal.ds.IntHashTable<WorldVec2>;
	
	private var _mapWidth:Int;
	private var _mapHeight:Int;
	private var _collWidth:Int;
	private var _collHeight:Int;
	private var _collWidthHalf:Int;
	private var _collHeightHalf:Int;
	private var _collRects:Array<WorldAABB2>;
	private var _connPts:Array<WorldVec2>;
	private var _cacheSize:Int;
	private var _cacheRes:Float;
	private var _filterPts:Array<WorldVec2>;
	private var _preprocess:Bool;
	private var _maxResolution:Float;
	private var _floors:Int;
	private var _running:Bool;
	private var _progress:Float;
	private var _floorDims:flash.Vector<Dimension>;
	
	public function new (collWidth:Int, collHeight:Int, mapWidth:Int, mapHeight:Int, collRects:Array<WorldAABB2>, connPts:Array<WorldVec2>, ?cacheSize:Int = -1, ?cacheResolution:Float = -1, ?filterPts:Array<WorldVec2> = null, ?preprocess:Bool = false, ?maxResolution:Float = Mathematics.FLOAT_MAX) {
		super([_buildRectLines, _enforceMaxResolution, _buildRects, _mergeRects, _buildLookups, _buildGraphArcs, _joinFloors, _filterInaccessableRoads, _buildRouteLookups]);
		_running = true;
		_mapWidth = mapWidth;
		_mapHeight = mapHeight;
		_collWidth = collWidth;
		_collHeight = collHeight;
		_collWidthHalf = Std.int(collWidth * 0.5);
		_collHeightHalf = Std.int(collHeight * 0.5);
		_collRects = collRects;
		_connPts = connPts;
		if (cacheSize != -1) {
			_cache = new de.polygonal.ds.IntHashTable<WorldVec2>(cacheSize);
		}
		_cacheSize = cacheSize;
		_cacheRes = 1 / cacheResolution;
		_yMul = Math.ceil(_mapWidth * _cacheRes);
		_floorMul = _yMul * Math.ceil(_mapHeight * _cacheRes);
		_idMul = _floorMul * _floors;
		_filterPts = filterPts;
		_preprocess = preprocess;
		_maxResolution = maxResolution;
		_progress = 0;
		
		_floors = 1;
		for (i in connPts) {
			if (i.floor + 2 > _floors) {
				_floors = i.floor + 2;
			}
		}
		
		_xLookup = new de.polygonal.ds.mem.ShortMemory(_floors * mapWidth);
		_yLookup = new de.polygonal.ds.mem.ShortMemory(_floors * mapHeight);
		_roadList = new de.polygonal.ds.SLL<Road>();
	}
	
	public function destroy ():Void {
		_roads.free();
		_xLookup.free();
		_yLookup.free();
	}
	
	public override function init (vars:Dynamic<Dynamic>):Void {
		vars.stage = 0;
		vars.itr = 0 ... _collRects.length;
		
		//Set first cell in each floor to a grid line
		for (i in 0 ... _floors) {
			_setX(i, 0, 0);
		}
		for (i in 0 ... _floors) {
			_setY(i, 0, 0);
		}
		
		//Init floor dimensions
		_floorDims = new flash.Vector<Dimension>(_floors);
		for (i in 0 ... _floorDims.length) {
			_floorDims[i] = new Dimension(1, 1);
		}
	}
	
	public override function progress ():Float {
		return _progress;
	}
	
	public override function isComplete ():Bool {
		return !_running;
	}
	
	private function _buildRectLines (vars:Dynamic<Dynamic>):Bool {
		//Build all rectangle lines
		var val:Int;
		if (vars.itr.hasNext()) {
			var i:WorldAABB2 = _collRects[vars.itr.next()];
			val = Std.int(i.xmin - _collWidthHalf);
			if (val >= 0 && val < _mapWidth) {
				if (this._getX(i.floor, val) != val) {
					this._setX(i.floor, val, val);
					_floorDims[i.floor].width++;
				}
			}
			val = Std.int(i.xmax + _collWidthHalf);
			if (val >= 0 && val < _mapWidth) {
				if (this._getX(i.floor, val) != val) {
					this._setX(i.floor, val, val);
					_floorDims[i.floor].width++;
				}
			}
			val = Std.int(i.ymin - _collHeightHalf);
			if (val >= 0 && val < _mapHeight) {
				if (this._getY(i.floor, val) != val) {
					this._setY(i.floor, val, val);
					_floorDims[i.floor].height++;
				}
			}
			val = Std.int(i.ymax + _collHeightHalf);
			if (val >= 0 && val < _mapHeight) {
				if (this._getY(i.floor, val) != val) {
					this._setY(i.floor, val, val);
					_floorDims[i.floor].height++;
				}
			}
			_progress += 1 / _collRects.length / getStageCount();
		} else {
			vars.itr = 0 ... _floors;
			return true;
		}
		
		return false;
	}
	
	private function _enforceMaxResolution (vars:Dynamic<Dynamic>):Bool {
		//Make sure maximum distance between collision areas is less than the maximum resolution
		var val:Int;
		if (vars.itr.hasNext()) {
			var i:Int = vars.itr.next();
			var count:Int = 0;
			for (o in 1 ... _mapWidth) {
				if (this._getX(i, o) == 0) {
					count++;
				} else {
					count = 0;
				}
				if (count >= _maxResolution) {
					count = 0;
					this._setX(i, o, o);
					_floorDims[i].width++;
				}
			}
			
			count = 0;
			for (o in 1 ... _mapHeight) {
				if (this._getY(i, o) == 0) {
					count++;
				} else {
					count = 0;
				}
				if (count >= _maxResolution) {
					count = 0;
					this._setY(i, o, o);
					_floorDims[i].height++;
				}
			}
			
			_progress += 1 / _floors / getStageCount();
		} else {
			vars.itr = 0 ... _floors;
			vars.gridRects = new flash.Vector<de.polygonal.ds.Array2<WorldAABB2>>(_floors);
			vars.totalGridRects = 0;
			for (i in 0 ... _floors) {
				vars.gridRects[i] = new de.polygonal.ds.Array2<WorldAABB2>(Std.int(_floorDims[i].width), Std.int(_floorDims[i].height));
			}
			return true;
		}
		
		return false;
	}
	
	private function _buildRects (vars:Dynamic<Dynamic>):Bool {
		//Create rectangle objects
		var x:Int;
		var y:Int;
		var o:Int;
		var p:Int;
		var xmin:Int;
		var ymin:Int;
		if (vars.itr.hasNext()) {
			var i:Int = vars.itr.next();
			x = 0;
			y = 0;
			o = 0;
			xmin = 0;
			ymin = 0;
			while (o <= _mapWidth) {
				if (o == _mapWidth || _getX(i, o) != 0) {
					p = 0;
					while (p <= _mapHeight) {
						if (p == _mapHeight || _getY(i, p) != 0)  {
							var rect:WorldAABB2 = new WorldAABB2(xmin, ymin, o, p, i);
							vars.totalGridRects++;
							vars.gridRects[i].set(x, y, rect);
							ymin = p;
							y++;
						}
						p++;
					}
					
					ymin = 0;
					y = 0;
					x++;
					xmin = o;
				}
				o++;
			}
			_progress += 1 / _floors / getStageCount();
		} else {
			vars.itr = 0 ... _floors;
			vars.adjRects = new de.polygonal.ds.HashMap<Road, de.polygonal.ds.SLL<WorldVec2>>();
			vars.completed = new flash.Vector<de.polygonal.ds.Array2<Bool>>(_floors);
			vars.roads = new de.polygonal.ds.IntHashTable<Road>(Bits.msb(Std.int(vars.totalGridRects) - 1) << 1);
			vars.graph = new de.polygonal.ds.Graph<Road>();
			_roads = vars.roads;
			return true;
		}
		
		return false;
	}
	
	private function _mergeRects (vars:Dynamic<Dynamic>):Bool {
		//Merge rectangles and build graph nodes
		var gridRects:flash.Vector<de.polygonal.ds.Array2<WorldAABB2>> = vars.gridRects;
		var completed:flash.Vector<de.polygonal.ds.Array2<Bool>> = vars.completed;
		if (vars.itr.hasNext()) {
			var i:Int = vars.itr.next();
			completed[i] = new de.polygonal.ds.Array2<Bool>(gridRects[i].getW(), gridRects[i].getH());
			for (o in 0 ... completed[i].getW()) {
				for (p in 0 ... completed[i].getH()) {
					completed[i].set(o, p, false);
				}
			}
			for (o in 0 ... gridRects[i].getW()) {
				for (p in 0 ... gridRects[i].getH()) {
					if (!completed[i].get(o, p)) {
						var end:WorldVec2 = _expandAABB(gridRects[i], completed[i], o, p, i);
						if (end != null) {
							var r1:WorldAABB2 = gridRects[i].get(o, p);
							var r2:WorldAABB2 = gridRects[i].get(Std.int(end.x), Std.int(end.y));
							var rect:Road = new Road(r1.xmin, r1.ymin, r2.xmax, r2.ymax, i, 0, Std.int(end.x) + 1 - o, Std.int(end.y) + 1 - p);
							var graphNode:de.polygonal.ds.GraphNode<Road> = vars.graph.addNode(rect);
							rect.graphNode = graphNode;
							for (dy in p ... Std.int(end.y) + 1) {
								for (dx in o ... Std.int(end.x) + 1) {
									r1 = gridRects[i].get(dx, dy);
									completed[i].set(dx, dy, true);
									vars.roads.set(_getCoordinateId(i, dx, dy), rect);
								}
							}
							var adjRect:de.polygonal.ds.SLL<WorldVec2> = new de.polygonal.ds.SLL<WorldVec2>();
							if (Std.int(end.x) + 1 < gridRects[i].getW()) {
								for (dy in p ... Std.int(end.y) + 1) {
									r1 = gridRects[i].get(Std.int(end.x) + 1, dy);
									adjRect.append(new WorldVec2(r1.xmin, r1.ymin, i));
								}
							}
							if (Std.int(end.y) + 1 < gridRects[i].getH()) {
								for (dx in o ... Std.int(end.x) + 1) {
									r1 = gridRects[i].get(dx, Std.int(end.y) + 1);
									adjRect.append(new WorldVec2(r1.xmin, r1.ymin, i));
								}
							}
							vars.adjRects.set(rect, adjRect);
						}
					}
				}
			}
			_progress += 1 / vars.gridRects.length / getStageCount();
		} else {
			vars.itr = 0 ... _floors;
			return true;
		}
		
		return false;
	}
	
	private function _buildLookups (vars:Dynamic<Dynamic>):Bool {
		//Fill in lookups
		if (vars.itr.hasNext()) {
			var i:Int = vars.itr.next();
			var count:Int = 0;
			for (o in 0 ... _mapWidth) {
				if (_getX(i, o) != 0) {
					count++;
				}
				_setX(i, o, count);
			}
			count = 0;
			for (o in 0 ... _mapHeight) {
				if (_getY(i, o) != 0) {
					count++;
				}
				_setY(i, o, count);
			}
			_progress += 1 / _floors / getStageCount();
		} else {
			vars.itr = vars.roads.iterator();
			return true;
		}
		
		return false;
	}
	
	private function _buildGraphArcs (vars:Dynamic<Dynamic>):Bool {
		//Connect nodes
		var adjRects:de.polygonal.ds.HashMap<Road, de.polygonal.ds.SLL<WorldVec2>> = vars.adjRects;
		if (vars.itr.hasNext()) {
			var i:Road = vars.itr.next();
			for (o in adjRects.get(i)) {
				var otherRoad:Road = vars.roads.get(_getCoordinateId(o.floor, _getX(o.floor, Std.int(o.x)), _getY(o.floor, Std.int(o.y))));
				if (otherRoad != null && !i.graphNode.isMutuallyConnected(otherRoad.graphNode)) {
					var dx:Float = ((i.xmin + i.xmax) - (otherRoad.xmin + otherRoad.xmax)) / 2;
					var dy:Float = ((i.ymin + i.ymax) - (otherRoad.ymin + otherRoad.ymax)) / 2;
					vars.graph.addMutualArc(i.graphNode, otherRoad.graphNode, Math.sqrt(dx*dx + dy*dy));
				}
			}
			_progress += 1 / vars.roads.size() / getStageCount();
		} else {
			vars.itr = _connPts.iterator();
			return true;
		}
		
		return false;
	}
	
	private function _joinFloors (vars:Dynamic<Dynamic>):Bool {
		//Join floors
		if (vars.itr.hasNext()) {
			var i:WorldVec2 = vars.itr.next();
			var road:Road = _getRoad(i);
			var otherRoad:Road = _getRoad(new WorldVec2(i.x, i.y, i.floor + 1));
			if (road != null && otherRoad != null) {
				var dx:Float = ((road.xmin + road.xmax) - (otherRoad.xmin + otherRoad.xmax)) / 2;
				var dy:Float = ((road.ymin + road.ymax) - (otherRoad.ymin + otherRoad.ymax)) / 2;
				vars.graph.addMutualArc(road.graphNode, otherRoad.graphNode, Math.sqrt(dx*dx + dy*dy));
			} else {
				Logger.log(Logger.WARN, "Failed to join staircase on floor " + i.floor + " to " + (i.floor + 1));
			}
			_progress += 1 / _connPts.length / getStageCount();
		} else {
			if (_filterPts != null) {
				vars.itr = _filterPts.iterator();
				_roads = new de.polygonal.ds.IntHashTable<Road>(vars.totalGridRects);
			} else {
				vars.itr = 0 ... 0;
			}
			return true;
		}
		
		return false;
	}
	
	private function _filterInaccessableRoads (vars:Dynamic<Dynamic>):Bool {
		//Filter out inaccessable roads
		var processed:de.polygonal.ds.HashMap<Road, Bool> = vars.processed;
		if (vars.itr.hasNext()) {
			var filterPt:WorldVec2 = vars.itr.next();
			var filterRoad:Road = vars.roads.get(_getCoordinateId(filterPt.floor, _getX(filterPt.floor, Std.int(filterPt.x)), _getY(filterPt.floor, Std.int(filterPt.y))));
			vars.graph.BFS(false, filterRoad.graphNode, _addAccessableRoad);
			
			_progress += 1 / _filterPts.length / getStageCount();
		} else {
			vars.roads.free();
			vars.roads = null;
			vars.itr = _roads.iterator();
			vars.processed = new de.polygonal.ds.HashMap<Road, Bool>();
			return true;
		}
		
		return false;
	}
	
	private function _addAccessableRoad (node:de.polygonal.ds.GraphNode<Road>, preflight:Bool, userData:Dynamic):Bool {
		if (!_roads.has(node.val)) {
			for (i in 0 ... node.val.lenY) {
				for (o in 0 ... node.val.lenX) {
					_roads.set(_getCoordinateId(node.val.floor, _getX(node.val.floor, Std.int(node.val.xmin)) + o, _getY(node.val.floor, Std.int(node.val.ymin)) + i), node.val);
				}
			}
			_roadList.append(node.val);
		}
		return true;
	}
	
	private function _buildRouteLookups (vars:Dynamic<Dynamic>):Bool {
		//Build route table
		if (_preprocess) {
			var processed:de.polygonal.ds.HashMap<Road, Bool> = vars.processed;
			if (vars.itr.hasNext()) {
				var startingRoad:Road = vars.itr.next();
				if (!processed.hasKey(startingRoad)) {
					var open:de.polygonal.ds.LinkedQueue<Road> = new de.polygonal.ds.LinkedQueue<Road>();
					var openLookup:de.polygonal.ds.Map<Road, Bool> = new de.polygonal.ds.HashMap<Road, Bool>();
					var closed:de.polygonal.ds.Map<Road, Bool> = new de.polygonal.ds.HashMap<Road, Bool>();
					startingRoad.cost = 0;
					startingRoad.parent = null;
					open.enqueue(startingRoad);
					openLookup.set(startingRoad, true);
					
					while (!open.isEmpty()) {
						var road:Road = open.dequeue();
						openLookup.clr(road);
						closed.set(road, true);
						var currRoad:Road = road;
						var lastDir:Int = -1;
						var tempDir:Int = -1;
						var currDir:Int = -1;
						var switched:Bool = false;
						while (currRoad.parent != null && currRoad.parent.parent != null) {
							currRoad = currRoad.parent;
							tempDir = currDir;
							currDir = _getDir(startingRoad, currRoad);
							if (lastDir == -1) {
								lastDir = currDir;
							} else if (((lastDir == 0 || lastDir == 2) && (currDir == 1 || currDir == 3)) || ((lastDir == 1 || lastDir == 3) && (currDir == 0 || currDir == 2))) {
								switched = true;
							} else {
								if (switched) {
									lastDir = tempDir;
								}
							}
						}
						var intersectionLine:Line = _getLineIntersection(startingRoad, currRoad);
						var transferPt:Vec2 = null;
						if (switched) {
							if (currDir == 0 || currDir == 2) {
								if (lastDir == 1) {
									transferPt = intersectionLine.interpolate(1, new Vec2());
								} else if (lastDir == 3) {
									transferPt = intersectionLine.interpolate(0, new Vec2());
								}
							} else if (currDir == 1 || currDir == 3) {
								if (lastDir == 0) {
									transferPt = intersectionLine.interpolate(0, new Vec2());
								} else if (lastDir == 2) {
									transferPt = intersectionLine.interpolate(1, new Vec2());
								}
							}
						}
						if (startingRoad != road) {
							startingRoad.addRoute(road, new RoadRoute(currRoad, intersectionLine, transferPt));
						}
						
						var currArc:de.polygonal.ds.GraphArc<Road> = road.graphNode.arcList;
						while (currArc != null) {
							if (!closed.hasKey(currArc.node.val)) {
								if (openLookup.hasKey(currArc.node.val)) {
									if (road.cost + currArc.cost < currArc.node.val.cost) {
										currArc.node.val.parent = road;
										currArc.node.val.cost = road.cost + currArc.cost;
									}
								} else {
									currArc.node.val.parent = road;
									currArc.node.val.cost = road.cost + currArc.cost;
									open.enqueue(currArc.node.val);
									openLookup.set(currArc.node.val, true);
								}
							}
							currArc = currArc.next;
						}
					}
					
					processed.set(startingRoad, true);
				}
				_progress += 1 / _roads.size() / getStageCount();
			} else {
				_graph = vars.graph;
				_progress = 1;
				_running = false;
				return true;
			}
			
			return false;
		} else {
			_graph = vars.graph;
			_progress = 1;
			_running = false;
			return true;
		}
	}
	
	private inline function _getCoordinateId (floor:Int, x:Int, y:Int):Int {
		if (floor < 0 || floor >= _floors || x < 0 || x >= _floorDims[floor].width || y < 0 || y >= _floorDims[floor].height) {
			return -1;
		} else {
			var id:Int = 0;
			for (i in 0 ... floor) {
				id += Std.int(_floorDims[i].width) * Std.int(_floorDims[i].height);
			}
			id += (y * Std.int(_floorDims[floor].width)) + x;
			return id;
		}
	}
	
	private inline function _getLineIntersection (rect1:AABB2, rect2:AABB2):Line {
		var sx:Float = 0;
		var sy:Float = 0;
		var ex:Float = 0;
		var ey:Float = 0;
		
		if (rect1.xmax == rect2.xmin) {
			sx = ex = rect1.xmax;
			if (rect1.ymin >= rect2.ymin) {
				sy = rect1.ymin;
			} else {
				sy = rect2.ymin;
			}
			if (rect1.ymax <= rect2.ymax) {
				ey = rect1.ymax;
			} else {
				ey = rect2.ymax;
			}
		} else if (rect1.xmin == rect2.xmax) {
			sx = ex = rect1.xmin;
			if (rect1.ymin >= rect2.ymin) {
				sy = rect1.ymin;
			} else {
				sy = rect2.ymin;
			}
			if (rect1.ymax <= rect2.ymax) {
				ey = rect1.ymax;
			} else {
				ey = rect2.ymax;
			}
		} else if (rect1.ymax == rect2.ymin) {
			sy = ey = rect1.ymax;
			if (rect1.xmin >= rect2.xmin) {
				sx = rect1.xmin;
			} else {
				sx = rect2.xmin;
			}
			if (rect1.xmax <= rect2.xmax) {
				ex = rect1.xmax;
			} else {
				ex = rect2.xmax;
			}
		} else if (rect1.ymin == rect2.ymax) {
			sy = ey = rect1.ymin;
			if (rect1.xmin >= rect2.xmin) {
				sx = rect1.xmin;
			} else {
				sx = rect2.xmin;
			}
			if (rect1.xmax <= rect2.xmax) {
				ex = rect1.xmax;
			} else {
				ex = rect2.xmax;
			}
		}
		
		return new Line(sx, sy, ex, ey);
	}
	
	private inline function _getDir (rect1:Road, rect2:Road):Int {
		var dir:Int = -1;
		
		if (rect1.xmax == rect2.xmin) {
			dir = 1;	//East
		} else if (rect1.xmin == rect2.xmax) {
			dir = 3;	//West
		} else if (rect1.ymax == rect2.ymin) {
			dir = 2;	//South
		} else if (rect1.ymin == rect2.ymax) {
			dir = 0;	//North
		}
		
		return dir;
	}
	
	private inline function _checkCollision (rect:WorldAABB2):Bool {
		var adjustedRect:WorldAABB2 = new WorldAABB2(rect.xmin - _collWidthHalf + 1, rect.ymin - _collHeightHalf + 1, rect.xmax + _collWidthHalf - 1, rect.ymax + _collHeightHalf - 1);
		var coll:Bool = false;
		
		for (i in _collRects) {
			if (i.floor == rect.floor && IntersectAABB.test2(adjustedRect, i)) {
				coll = true;
				break;
			}
		}
		
		return coll;
	}
	
	private inline function _expandAABB (gridRects:de.polygonal.ds.Array2<WorldAABB2>, completed:de.polygonal.ds.Array2<Bool>, sx:Int, sy:Int, floor:Int):WorldVec2 {
		var successX:Bool = true;
		var successY:Bool = true;
		var ex:Int = sx;
		var ey:Int = sy;
		var gridRect:WorldAABB2 = gridRects.get(sx, sy);
		if (_checkCollision(gridRect) || completed.get(sx, sy)) {
			return null;
		} else {
			var rect:WorldAABB2 = new WorldAABB2(gridRect.xmin, gridRect.ymin, gridRect.xmax, gridRect.ymax, floor);
			var potRect:WorldAABB2 = new WorldAABB2(gridRect.xmin, gridRect.ymin, gridRect.xmax, gridRect.ymax, floor);
			
			while (successX || successY) {
				if (successX && ex + 1 < gridRects.getW()) {
					for (i in sy ... ey + 1) {
						if (completed.get(ex + 1, i)) {
							successX = false;
							break;
						}
					}
					if (successX) {
						gridRect = gridRects.get(ex + 1, ey);
						potRect.xmax = gridRect.xmax;
						potRect.ymax = gridRect.ymax;
						if (potRect.intervalX <= _maxResolution && !_checkCollision(potRect)) {
							rect.xmax = potRect.xmax;
							rect.ymax = potRect.ymax;
							ex++;
						} else {
							successX = false;
						}
					}
				} else {
					successX = false;
				}
				if (successY && ey + 1 < gridRects.getH()) {
					for (i in sx ... ex + 1) {
						if (completed.get(i, ey + 1)) {
							successY = false;
							break;
						}
					}
					if (successY) {
						gridRect = gridRects.get(ex, ey + 1);
						potRect.xmax = gridRect.xmax;
						potRect.ymax = gridRect.ymax;
						if (potRect.intervalY <= _maxResolution && !_checkCollision(potRect)) {
							rect.xmax = potRect.xmax;
							rect.ymax = potRect.ymax;
							ey++;
						} else {
							successY = false;
						}
					}
				} else {
					successY = false;
				}
			}
			
			return new WorldVec2(ex, ey, floor);
		}
	}
	
	private inline function _getRoad (pt:WorldVec2):Road {
		if (pt.x >= 0 && pt.x < _mapWidth && pt.y >= 0 && pt.y < _mapHeight) {
			var road:Road = this._roads.get(_getCoordinateId(pt.floor, this._getX(pt.floor, Std.int(pt.x)), this._getY(pt.floor, Std.int(pt.y))));
			if (road == null) {
				road = this._roads.get(_getCoordinateId(pt.floor, this._getX(pt.floor, Std.int(pt.x) - 1), this._getY(pt.floor, Std.int(pt.y))));
			}
			if (road == null) {
				road = this._roads.get(_getCoordinateId(pt.floor, this._getX(pt.floor, Std.int(pt.x)), this._getY(pt.floor, Std.int(pt.y) - 1)));
			}
			if (road == null) {
				road = this._roads.get(_getCoordinateId(pt.floor, this._getX(pt.floor, Std.int(pt.x) - 1), this._getY(pt.floor, Std.int(pt.y) - 1)));
			}
			return road;
		} else {
			return null;
		}
	}
	
	public function getRoute (start:WorldVec2, end:WorldVec2, out:WorldVec2, ?usePreprocess:Bool = false):WorldVec2 {
		var sr:Road = _getRoad(start);
		var er:Road = _getRoad(end);
		if (sr != null && er != null) {
			if (usePreprocess && _preprocess) {
				var nr:RoadRoute = sr.getRoute(er);
				if (nr != null) {
					if (Geom.containsAABBvsVec(nr.road, start)) {
						if (er == nr.road) {
							return null;
						}
						nr = nr.road.getRoute(er);
					}
					if (Geom.containsAABBvsVec(nr.road, start)) {
						if (er == nr.road) {
							return null;
						}
						nr = nr.road.getRoute(er);
					}
					if (nr != null) {
						if (nr.pt != null) {
							out.x = nr.pt.x;
							out.y = nr.pt.y;
							out.floor = nr.road.floor;
							return out;
						} else {
							out = cast(nr.intersection.project(start, out), WorldVec2);
							out.floor = nr.road.floor;
							return out;
						}
					}
				}
			} else {
				if (sr == er) {
					return null;
				} else {
					if (_checkCache(sr, er, start, out)) {
						return out;
					} else {
						//TODO: Implement A*
					}
				}
			}
		}
		return null;
	}
	
	private inline function _checkCache (sr:Road, er:Road, s:WorldVec2, out:WorldVec2):Bool {
		var pt:WorldVec2 = _cache.get(_getCacheId(Std.int(s.x), Std.int(s.y), s.floor, er.id));
		if (pt != null) {
			out.x = pt.x;
			out.y = pt.y;
			return true;
		} else {
			return false;
		}
	}
	
	private inline function _saveCache (sr:Road, er:Road, s:WorldVec2, pt:WorldVec2):Void {
		if (_cache.size() > _cacheSize) {
			_cache.clear();
		}
		_cache.set(_getCacheId(Std.int(s.x), Std.int(s.y), s.floor, er.id), new WorldVec2(pt.x, pt.y, pt.floor));
	}
	
	private var _idMul:Int;
	private var _floorMul:Int;
	private var _yMul:Int;
	private inline function _getCacheId (x:Int, y:Int, floor:Int, id:Int):Int {
		return (id * _idMul) + (floor * _floorMul) + Std.int(y * _yMul * _cacheRes + 0.5) + Std.int(x * _cacheRes + 0.5);
	}
	
	public function iterator ():de.polygonal.ds.Itr<Road> {
		return _roadList.iterator();
	}
	
	public inline function getContainingRectangle (pt:WorldVec2, out:WorldAABB2):WorldAABB2 {
		var road:Road = _getRoad(pt);
		if (road != null) {
			out.xmin = road.xmin;
			out.ymin = road.ymin;
			out.xmax = road.xmax;
			out.ymax = road.ymax;
			out.floor = road.floor;
			return out;
		} else {
			return null;
		}
	}
	
	private inline function _getX (floor:Int, x:Int):Int {
		return _xLookup.get(floor * _mapWidth + x);
	}
	
	private inline function _setX (floor:Int, x:Int, v:Int):Void {
		_xLookup.set(floor * _mapWidth + x, v);
	}
	
	private inline function _getY (floor:Int, y:Int):Int {
		return _yLookup.get(floor * _mapHeight + y);
	}
	
	private inline function _setY (floor:Int, y:Int, v:Int):Void {
		_yLookup.set(floor * _mapHeight + y, v);
	}
	
}

private class Road extends WorldAABB2 {
	
	public static var NEXT_ID:Int = 0;
	
	public var graphNode:de.polygonal.ds.GraphNode<Road>;
	public var cost:Float;
	public var parent:Road;
	public var routes:de.polygonal.ds.HashMap<Road, RoadRoute>;
	public var lenX:Int;
	public var lenY:Int;
	public var id:Int;
	
	public function new (?xmin:Float = 1.0, ?ymin:Float = 1.0, ?xmax:Float = -1.0, ?ymax:Float = -1.0, ?floor:Int = 0, ?level:Int = 0, ?lenX:Int = 1, ?lenY:Int = 1):Void {
		super(xmin, ymin, xmax, ymax, floor, level);
		
		routes = new de.polygonal.ds.HashMap<Road, RoadRoute>();
		this.lenX = lenX;
		this.lenY = lenY;
		this.id = NEXT_ID++;
	}
	
	public inline function addRoute (toRoad:Road, nextRoad:RoadRoute):Void {
		routes.set(toRoad, nextRoad);
	}
	
	public inline function getRoute (toRoad:Road):RoadRoute {
		return routes.get(toRoad);
	}
	
	public inline function hasRoute (toRoad:Road):Bool {
		return routes.hasKey(toRoad);
	}
	
}

private class RoadRoute {
	
	public var road:Road;
	public var intersection:Line;
	public var pt:Vec2;
	
	public function new (road:Road, intersection:Line, pt:Vec2) {
		this.road = road;
		this.intersection = intersection;
		this.pt = pt;
	}
	
}