package com.robotacid.engine {
	import com.robotacid.util.XorRandom;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	/**
	 * A template generator for rooms in the game
	 * 
	 * The data is designed so that all possible game states are bitwise flags on a 2D array.
	 * This keeps the scope small and portable. No good puzzle ever needed clutter.
	 * 
	 * PUZZLE rooms are limited to one grid with one exit
	 * ADVENTURE rooms are journeys between chains of rooms
	 * 
	 * @author Aaron Steed, robotacid.com
	 */
	public class Room {
		
		public var type:int;
		public var width:int;
		public var height:int;
		public var startX:int;
		public var startY:int;
		public var map:Array/*Array*/;
		public var doors:Array/*Point*/;
		public var roomTurns:int;
		public var vertHalfway:int;
		public var horizHalfway:int;
		public var endingDist:int;
		
		public static var random:XorRandom;
		
		// property constants
		public static const EMPTY:int = 0;
		// directions
		public static const UP:int = 1 << 0;
		public static const RIGHT:int = 1 << 1;
		public static const DOWN:int = 1 << 2;
		public static const LEFT:int = 1 << 3;
		// direction memory states
		public static const M_UP:int = 1 << 4;
		public static const M_RIGHT:int = 1 << 5;
		public static const M_DOWN:int = 1 << 6;
		public static const M_LEFT:int = 1 << 7;
		// properties
		public static const ATTACK:int = 1 << 8;
		public static const BLOCKED:int = 1 << 9;
		public static const PUSHED:int = 1 << 18;
		public static const GENERATOR:int = 1 << 21;
		public static const BOMB:int = 1 << 28;
		public static const SWAP:int = 1 << 20;
		public static const VOID:int = 1 << 27;
		public static const WALL:int = 1 << 10;
		public static const INDESTRUCTIBLE:int = 1 << 29;
		public static const TIMER_0:int = 1 << 22;
		public static const TIMER_1:int = 1 << 23;
		public static const TIMER_2:int = 1 << 24;
		public static const TIMER_3:int = 1 << 25;
		public static const ENEMY:int = 1 << 12;
		public static const ALLY:int = 1 << 26;
		public static const PLAYER:int = 1 << 11;
		public static const DOOR:int = 1 << 13;
		public static const VIRUS:int = 1 << 30;
		public static const TRAP:int = 1 << 19;
		public static const TURNER:int = 1 << 17;
		public static const MOVER:int = 1 << 14;
		public static const KILLER:int = 1 << 15;
		public static const INCREMENT:int = 1 << 16;
		public static const ENDING:int = 1 << 31;
		// combo constants
		public static const UP_DOWN_LEFT_RIGHT:int = 15;
		public static var M_UP_DOWN_LEFT_RIGHT:int;
		// utils
		public static var TIMER_MASK:int;
		public static const M_DIR_SHIFT:int = 4;
		
		// types
		public static const PUZZLE:int = 0;
		public static const ADVENTURE:int = 1;
		
		// compass
		public static const NORTH:int = 0;
		public static const EAST:int = 1;
		public static const SOUTH:int = 2;
		public static const WEST:int = 3;
		public static const compass:Array = [UP, RIGHT, DOWN, LEFT];
		public static const toCompass:Object = {
			1:0,
			2:1,
			4:2,
			8:3
		};
		public static var DIR_TO_COMPASS:Object;
		public static const compassPoints:Array/*Point*/ = [new Point(0, -1), new Point(1, 0), new Point(0, 1), new Point( -1, 0)];
		
		public static const DIST_TO_ENDING:int = 10;
		
		public function Room(type:int, width:int, height:int) {
			this.type = type;
			this.width = width;
			this.height = height;
			map = create2DArray(width, height, WALL | INDESTRUCTIBLE);
			startPosition();
		}
		public static function init():void{
			M_UP_DOWN_LEFT_RIGHT = (M_UP | M_DOWN | M_LEFT | M_RIGHT);
			TIMER_MASK = TIMER_0 | TIMER_1 | TIMER_2 | TIMER_3;
		}
		
		/* Creates the initial template room */
		public function startPosition():void{
			clear();
			startX = width * 0.5;
			startY = height * 0.5;
			doors = [
				new Point(startX, 0),
				new Point(width - 1, startY),
				new Point(startX, height - 1),
				new Point(0, startY)
			];
			horizHalfway = startX;
			vertHalfway = startY;
			roomTurns = 0;
			endingDist = DIST_TO_ENDING;
			random = new XorRandom();
		}
		
		public function init(door:Point = null, revealDir:int = -1):void{
			if(type == ADVENTURE){
				adventureFill(door, revealDir);
			} else if(type == PUZZLE){
				clear();
			}
			roomTurns++;
		}
		
		public function clear():void{
			fill(0, 0, width, height, map, WALL | INDESTRUCTIBLE);
			fill(1, 1, width - 2, height - 2, map, EMPTY);
		}
		
		/* Get where the doors should be in a new room (accounting for a door destroyed as well) */
		public function getDoors(door:Point = null, revealDir:int = -1):Array{
			var i:int, p:Point;
			var value:int;
			var skipDir:int = -1;
			var doors:Array = this.doors.slice();
			if(revealDir == NORTH){
				skipDir = SOUTH;
				door.y = height - 1;
			} else if(revealDir == EAST){
				skipDir = WEST;
				door.x = 0;
			} else if(revealDir == SOUTH){
				skipDir = NORTH;
				door.y = 0;
			} else if(revealDir == WEST){
				skipDir = EAST;
				door.x = width - 1;
			}
			var dists:Array = [0, 0, 0, 0];
			var length:int;
			var farthestLength:int = 0;
			var farthestIndex:int = -1;
			var closestLength:int = int.MAX_VALUE;
			var closestIndex:int = -1;
			// randomise door positions
			if(skipDir > -1){
				for(i = 0; i < 4; i++){
					if(i == skipDir){
						dists[i] = 0;
					} else {
						p = doors[i];
						if(i == NORTH || i == SOUTH) doors[i].x = 1 + random.rangeInt(width - 2);
						else if(i == EAST || i == WEST) doors[i].y = 1 + random.rangeInt(height - 2);
						length = Math.abs(p.x - door.x) + Math.abs(p.y - door.y);
						if(length > farthestLength){
							farthestLength = length;
							farthestIndex = i;
						}
						if(length < closestLength){
							closestLength = length;
							closestIndex = i;
						}
					}
				}
				// the ending is always the farthest away from the door entered
				dists[farthestIndex] = INCREMENT;
			} else {
				// the inital room must only show EAST or WEST - 1st door must always be visible
				dists[(random.coinFlip() ? EAST : WEST)] = INCREMENT;
			}
			for(i = 0; i < 4; i++){
				value = dists[i];
				if(i == skipDir){
					doors[i] = door;
					continue;
				}
				p = doors[i];
				map[p.y][p.x] = DOOR | ENEMY | (1 << (i + M_DIR_SHIFT));
				if(endingDist <= 2 && value == INCREMENT) value = ENDING;
				map[p.y][p.x] |= value;
			}
			return doors;
		}
		
		/* Dig routes between the door ways - removes anything that places the path in check */
		public function connectDoors(doors:Array):void{
			var p:Point;
			var r:int, c:int, x:int, y:int;
			// N S
			x = doors[NORTH].x;
			p = doors[SOUTH];
			for(r = 1; r < height - 1; r++){
				if(r == 1 || r == height - 2 || (map[r][x] & WALL)) map[r][x] = EMPTY;
				clearCheck(x, r);
				if(r == vertHalfway){
					while(x != p.x){
						if(x < p.x) x++;
						if(x > p.x) x--;
						if(map[r][x] & WALL) map[r][x] = EMPTY;
						clearCheck(x, r);
					}
				}
			}
			// W E
			y = doors[WEST].y;
			p = doors[EAST];
			for(c = 1; c < width - 1; c++){
				if(c == 1 || c == width - 2 || (map[y][c] & WALL)) map[y][c] = EMPTY;
				clearCheck(c, y);
				if(c == horizHalfway){
					while(y != p.y){
						if(y < p.y) y++;
						if(y > p.y) y--;
						if(map[y][c] & WALL) map[y][c] = EMPTY;
						clearCheck(c, y);
					}
				}
			}
			horizHalfway = 1 + random.rangeInt(width - 3);
			vertHalfway = 1 + random.rangeInt(height - 3);
		}
		
		/* Remove any enemies surrounding a space that would endanger it */
		public function clearCheck(x:int, y:int):void{
			if(y > 0 && (map[y - 1][x] & ENEMY) && (
					(
						(map[y - 1][x] & TURNER) && (map[y - 1][x] & DOWN)
					) || (
						(map[y - 1][x] & (TRAP | MOVER)) && (map[y - 1][x] & M_DOWN)
					) || (
						(map[y - 1][x] & GENERATOR)
					)
				)
			){
				map[y - 1][x] = EMPTY;
			}
			if(x < width - 1 && (map[y][x + 1] & ENEMY) && (
					(
						(map[y][x + 1] & TURNER) && (map[y][x + 1] & LEFT)
					) || (
						(map[y][x + 1] & (TRAP | MOVER)) && (map[y][x + 1] & M_LEFT)
					) || (
						(map[y][x + 1] & GENERATOR)
					)
				)
			){
				map[y][x + 1] = EMPTY;
			}
			if(y < height - 1 && (map[y + 1][x] & ENEMY) && (
					(
						(map[y + 1][x] & TURNER) && (map[y + 1][x] & UP)
					) || (
						(map[y + 1][x] & (TRAP | MOVER)) && (map[y + 1][x] & M_UP)
					) || (
						(map[y + 1][x] & GENERATOR)
					)
				)
			){
				map[y + 1][x] = EMPTY;
			}
			if(x > 0 && (map[y][x - 1] & ENEMY) && (
					(
						(map[y][x - 1] & TURNER) && (map[y][x - 1] & RIGHT)
					) || (
						(map[y][x - 1] & (TRAP | MOVER)) && (map[y][x - 1] & M_RIGHT)
					) || (
						(map[y][x - 1] & GENERATOR)
					)
				)
			){
				map[y][x - 1] = EMPTY;
			}
		}
		
		/* Create indestructible walls around unreachable areas and fill insides with VOID */
		public function fillVoid(entry:Point):void{
			var p:Point = entry;
			var voidMap:Array = create2DArray(width, height, 0);
			var i:int, x:int, y:int;
			var points:Array = [p];
			var property:int;
			var length:int = points.length;
			voidMap[p.y][p.x] = 1;
			
			while(length){
				while(length--){
					p = points.shift();
					x = p.x;
					y = p.y;
					property = map[y][x];
					if((property & WALL) && !(property & ENEMY)) continue;
					// cardinals
					if(y > 0 && voidMap[y - 1][x] == 0){
						points.push(new Point(x, y - 1));
						voidMap[y - 1][x] = 1;
					}
					if(x < width - 1 && voidMap[y][x + 1] == 0){
						points.push(new Point(x + 1, y));
						voidMap[y][x + 1] = 1;
					}
					if(y < height - 1 && voidMap[y + 1][x] == 0){
						points.push(new Point(x, y + 1));
						voidMap[y + 1][x] = 1;
					}
					if(x > 0 && voidMap[y][x - 1] == 0){
						points.push(new Point(x - 1, y));
						voidMap[y][x - 1] = 1;
					}
				}
				length = points.length;
			}
			var r:int, c:int;
			for(r = 0; r < height; r++){
				for(c = 0; c < width; c++){
					if(voidMap[r][c] == 0 && !(map[r][c] & INDESTRUCTIBLE)){
						map[r][c] = VOID;
					}
					if(voidMap[r][c] == 1 && (property & WALL) && !(property & ENEMY) &&
						(
							(r > 0 && voidMap[r - 1][c] == 0) ||
							(c < width - 1 && voidMap[r][c + 1] == 0) ||
							(r < height - 1 && voidMap[r + 1][c] == 0) ||
							(c > 0 && voidMap[r][c - 1] == 0)
						)
					){
						map[r][c] = WALL | INDESTRUCTIBLE;
					}
				}
			}
		}
		
		public function copyTo(target:Array, tx:int, ty:int):void{
			var r:int, c:int;
			for(r = 0; r < height; r++){
				for(c = 0; c < width; c++){
					target[ty + r][tx + c] = map[r][c];
				}
			}
		}
		
		public static function copyRectTo(source:Array, rect:Rectangle, target:Array, tx:int, ty:int, buffer:Array):void{
			var r:int, c:int;
			// buffering to account for any overlap
			for(r = 0; r < rect.height; r++){
				for(c = 0; c < rect.width; c++){
					buffer[r][c] = source[rect.y + r][rect.x + c];
				}
			}
			for(r = 0; r < rect.height; r++){
				for(c = 0; c < rect.width; c++){
					target[ty + r][tx + c] = buffer[r][c];
				}
			}
		}
		
		/* Used to clear out a section of a grid or flood it with a particular tile type */
		public static function fill(x:int, y:int, width:int, height:int, target:Array, index:int):void{
			var r:int, c:int;
			for(r = y; r < y + height; r++){
				for(c = x; c < x + width; c++){
					target[r][c] = index;
				}
			}
		}
		
		/* Scatter some tiles with Math.random */
		public static function scatterFill(x:int, y:int, width:int, height:int, target:Array, index:int, total:int, rotations:Array = null, add:int = 0):void{
			var r:int, c:int;
			var rot:int;
			var breaker:int = 0;
			while(total--){
				c = x + random.rangeInt(width);
				r = y + random.rangeInt(height);
				if(add){
					if(target[r][c] & add) target[r][c] |= index;
					else{
						total++;
						if(breaker++ > 200) break;
						continue;
					}
				} else target[r][c] = index;
				if(rotations){
					target[r][c] |= rotations[rot];
					rot++;
					if(rot >= rotations.length) rot = 0;
				}
			}
		}
		
		/* Put down a tile - avoiding certain tiles */
		public static function placeRandom(x:int, y:int, width:int, height:int, target:Array, index:int, avoid:int = 0):void{
			var r:int, c:int;
			var breaker:int = 0;
			do{
				c = x + random.rangeInt(width);
				r = y + random.rangeInt(height);
			} while((target[r][c] & avoid) && breaker++ < width + height);
			if(breaker < width + height) target[r][c] = index;
		}
		
		/* Scatter some tiles with Math.random */
		public static function scatterFillList(x:int, y:int, width:int, height:int, target:Array, list:Array):void{
			var i:int, r:int, c:int;
			var rot:int;
			var breaker:int = 0;
			for(i = 0; i < list.length; i++){
				c = x + random.rangeInt(width);
				r = y + random.rangeInt(height);
				target[r][c] = list[i];
			}
		}
		
		/* Scatter some strips with Math.random */
		public static function scatterStrips(x:int, y:int, width:int, height:int, target:Array, index:int, total:int, xStrip:int = 0, yStrip:int = 0):void{
			var r:int, c:int;
			//trace(xStrip, yStrip);
			var yRepeat:int, xRepeat:int;
			while(total--){
				if(random.coinFlip()){
					xRepeat = 1 + random.rangeInt(xStrip - 1);
					yRepeat = 0;
				} else {
					xRepeat = 0;
					yRepeat = 1 + random.rangeInt(yStrip - 1);
				}
				c = -xRepeat + x + random.rangeInt(width);
				r = -yRepeat + y + random.rangeInt(height);
				if(r >= x && c >= y && r < y + height && c < x + width){
					while(xRepeat || yRepeat){
						target[r][c] = index;
						if(xRepeat){
							xRepeat--;
							if(c < x + width - 1) c++;
							else xRepeat = 0;
						} else if(yRepeat){
							yRepeat--;
							if(r < y + height - 1) r++;
							else yRepeat = 0;
						}
					}
				}
			}
		}
		
		public static function create2DArray(width:int, height:int, base:* = null):Array {
			var r:int, c:int, a:Array = [];
			for(r = 0; r < height; r++){
				a[r] = [];
				for(c = 0; c < width; c++){
					a[r][c] = base;
				}
			}
			return a;
		}
		
		public static function randomiseArray(a:Array):void{
			for(var x:*, j:int, i:int = a.length; i; j = random.rangeInt(i), x = a[--i], a[i] = a[j], a[j] = x){}
		}
		
		/* Cyclically shift bits within a given range  - use a minus value for amount to shift left */
		public static function rotateBits(n:int, amount:int, rangeMask:int, rangeMaskWidth:int):int{
			var nRangeMasked:int = n & ~(rangeMask);
			n &= rangeMask;
			if(amount){
				var absAmount:int = (amount > 0 ? amount : -amount) % rangeMaskWidth;
				if(amount < 0){
					n = (n << absAmount) | (n >> (rangeMaskWidth - absAmount));
				} else if(amount > 0){
					n = (n >> absAmount) | (n << (rangeMaskWidth - absAmount));
				}
			}
			return (n & rangeMask) | nRangeMasked;
		}
		
		public static function setPropertyLocations(x:int, y:int, width:int, height:int, map:Array, property:int, locations:Array, properties:Array = null, ignore:int = 0):Array{
			var list:Array = [];
			var h:int = map.length;
			var w:int = map[0].length;
			var toX:int = x + width;
			var toY:int = y + height;
			var r:int, c:int;
			for(r = y; r < toY; r++){
				for(c = x; c < toX; c++){
					if(c >= 0 && r >= 0 && c < w && r < h && (map[r][c] & property) && !(map[r][c] & ignore)){
						locations.push(new Point(c, r));
						if(properties) properties.push(map[r][c]);
					}
				}
			}
			return list;
		}
		
		/* Creates a random room with enemies and doors to escape towards an ending
		 * - 
		 * also used for debugging
		 */
		public function adventureFill(door:Point = null, revealDir:int = -1):void{
			clear();
			var doors:Array = getDoors(door, revealDir);
			var walls:int = random.rangeInt(width + height) + width + height;
			scatterFill(1, 1, width - 2, height - 2, map, WALL, walls);
			//scatterStrips(1, 1, width - 2, height - 2, map, WALL, (roomTurns % 10) + (width + height) * 2, 2 + random.rangeInt(2), 2 + random.rangeInt(2));
			//fill(1, 1, width - 2, height - 2, map, WALL);
			
			var recipes:Array = [
				ENEMY | VIRUS,
				ENEMY | TRAP,
				ENEMY | TURNER,
				ENEMY | MOVER,
				ENEMY | MOVER | M_LEFT | M_RIGHT | M_UP | M_DOWN,
				ALLY | SWAP,
				SWAP | WALL
			];
			// when changing the recipe list, update this index
			var allyIndex:int = 5;
			
			var enemySpice:Array = [
				0,
				GENERATOR | TIMER_3,
				WALL,
				BOMB,
				BOMB | WALL,
				GENERATOR | TIMER_3 | WALL,
				BOMB | GENERATOR | TIMER_3,
				BOMB | GENERATOR | TIMER_3 | WALL
			];
			
			// change to 0 for a blank room to debug in
			var total:int = width + height + random.rangeInt(width);
			var turns:int;
			var dir:int;
			var compassPos:int = NORTH;
			var item:int;
			var bombSpice:int = 1 << 0;
			var wallSpice:int = 1 << 1;
			var generatorSpice:int = 1 << 2;
			var recipeRange:int = Math.min((DIST_TO_ENDING - endingDist) + 3, recipes.length);
			var spiceRange:int = Math.min((DIST_TO_ENDING - endingDist) + 1, enemySpice.length);
			var spice:int;
			var n:int;
			var generatorVirii:int;
			
			while(total--){
				n = random.rangeInt(recipeRange);
				// reroll swap recipes every second pick
				while(
					((total & 1) && (recipes[n] & SWAP))
				){
					n = random.rangeInt(recipeRange);
				}
				item = recipes[n];
				if(item & ENEMY){
					if(item & TURNER){
						dir = compass[random.rangeInt(compass.length)];
						item |= dir;
					} else if(item & TRAP){
						dir = 1 + random.rangeInt(15);
						dir <<= M_DIR_SHIFT;
						item |= dir;
					} else if(item & MOVER){
						if(!(item & M_UP_DOWN_LEFT_RIGHT)){
							item |= random.coinFlip() ? (M_UP | M_DOWN) : (M_LEFT | M_RIGHT);
						}
					}
					if(random.coinFlip()){
						spice = random.rangeInt(spiceRange);
						if((enemySpice[spice] & GENERATOR) && (item & VIRUS)){
							if(generatorVirii == 0) item |= enemySpice[spice];
							generatorVirii++;
						} else {
							item |= enemySpice[spice];
						}
					}
				} else if(item & SWAP){
					spice = random.rangeInt(spiceRange);
					if(enemySpice[spice] & BOMB){
						item |= BOMB;
					}
				}
				//item = VIRUS | ENEMY;
				placeRandom(1, 1, width - 2, height - 2, map, item, WALL);
			}
			// clear a path to the doors
			connectDoors(doors);
			
			fillVoid(revealDir == - 1 ?  new Point(startX, startY) : doors[revealDir]);
			
			// debugging recipes:
			//map[startY][startX + 1] = ENEMY | VIRUS;
			//map[startY + 1][startX + 1] = ENEMY | VIRUS;
			//map[startY][startX + 3] = ENEMY | VIRUS;
			//map[startY + 1][startX + 3] = ALLY | SWAP;
			//map[startY + 3][startX] = ENEMY | WALL | VIRUS | GENERATOR | TIMER_3;
			//map[startY][startX + 2] = ENEMY | MOVER | BOMB;
			//map[startY][startX + 3] = ENEMY | MOVER | BOMB;
			//map[startY][startX + 1] = WALL | SWAP;
			//map[startY][startX + 2] = ALLY | SWAP;
			//map[startY][startX + 3] = ALLY | SWAP;
			//map[startY][startX] = ENEMY | TURNER | UP | WALL | GENERATOR | TIMER_3;
			//map[startY][startX] = ENEMY | TURNER | RIGHT | WALL;
		}
		
		public static function oppositeDirection(dir:int):int{
			if(dir & UP) return DOWN;
			else if(dir & RIGHT) return LEFT;
			else if(dir & DOWN) return UP;
			else if(dir & LEFT) return RIGHT;
			return 0;
		}
		
	}

}