package com.robotacid.gfx {
	import flash.display.BitmapData;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	/**
	 * Manages the glitch line effects on the view port
	 * 
	 * @author Aaron Steed, robotacid.com
	 */
	public class GlitchMap {
		
		public var rows:Array/*Point*/;
		public var cols:Array/*Point*/;
		
		private var i:int;
		private var p:Point;
		private var rect:Rectangle;
		private var g:Point;
		private var glitchIndex:int;
		
		public static const TOLERANCE:Number = 0.2;
		public static const GLITCH_STEPS:Array = [0, 1, 2, 1, 4, 0, 2, 4, 0, 2, 1, 0, 4, 2, 1, 0, 2, 1, 4, 0, 2, 0, 1, 1, 0, 4, 1];
		
		public function GlitchMap() {
			rows = [];
			cols = [];
			p = new Point();
			rect = new Rectangle();
			glitchIndex = 0;
		}
		
		public function update():void{
			for(i = cols.length - 1; i > -1; i--){
				g = cols[i];
				if(g.y > TOLERANCE) g.y -= Math.random();
				else if(g.y < -TOLERANCE) g.y += Math.random();
				else cols.splice(i, 1);
			}
			for(i = rows.length - 1; i > -1; i--){
				g = rows[i];
				if(g.x > TOLERANCE) g.x -= Math.random();
				else if(g.x < -TOLERANCE) g.x += Math.random();
				else rows.splice(i, 1);
			}
		}
		
		public function addGlitchRows(ya:int, yb:int, dir:int):void{
			do{
				glitchIndex++;
				if(glitchIndex >= GLITCH_STEPS.length) glitchIndex = 0;
				rows.push(new Point(dir * GLITCH_STEPS[glitchIndex], ya));
				if(ya < yb) ya++;
				else if(ya > yb) ya--;
			} while(ya != yb);
		}
		
		public function pushRows(ya:int, yb:int, dir:int):void{
			do{
				glitchIndex++;
				if(glitchIndex >= GLITCH_STEPS.length) glitchIndex = 0;
				rows.push(new Point(dir, ya));
				if(ya < yb) ya++;
				else if(ya > yb) ya--;
			} while(ya != yb);
		}
		
		public function addGlitchCols(xa:int, xb:int, dir:int):void{
			do{
				glitchIndex++;
				if(glitchIndex >= GLITCH_STEPS.length) glitchIndex = 0;
				cols.push(new Point(xa, dir * GLITCH_STEPS[glitchIndex]));
				if(xa < xb) xa++;
				else if(xa > xb) xa--;
			} while(xa != xb);
		}
		
		public function pushCols(xa:int, xb:int, dir:int):void{
			do{
				glitchIndex++;
				if(glitchIndex >= GLITCH_STEPS.length) glitchIndex = 0;
				cols.push(new Point(xa, dir));
				if(xa < xb) xa++;
				else if(xa > xb) xa--;
			} while(xa != xb);
		}
		
		public function reset():void{
			cols.length = rows.length = 0;
		}
		
		public function apply(target:BitmapData, offsetX:int = 0, offsetY:int = 0):void{
			rect.y = 0;
			rect.width = 1;
			rect.height = target.height;
			for(i = cols.length - 1; i > -1; i--){
				g = cols[i];
				rect.x = p.x = g.x + offsetX;
				p.y = g.y;
				target.copyPixels(target, rect, p);
			}
			rect.x = 0
			rect.width = target.width;
			rect.height = 1;
			for(i = rows.length - 1; i > -1; i--){
				g = rows[i];
				rect.y = p.y = g.y + offsetY;
				p.x = g.x;
				target.copyPixels(target, rect, p);
			}
		}
		
	}

}