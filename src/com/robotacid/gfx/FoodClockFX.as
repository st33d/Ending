package com.robotacid.gfx {
	import flash.display.BitmapData;
	import flash.geom.Point;
	/**
	 * Manages the graphical representation of the food clock, drawn on to the player sprite
	 * 
	 * @author Aaron Steed, robotacid.com
	 */
	public class FoodClockFX {
		
		public static var renderer:Renderer;
		
		public var blit:BlitSprite;
		public var spriteSheet:BitmapData;
		public var food:int;
		public var maxFood:int;
		public var nearDeath:int;
		public var deadCol:uint;
		public var col:uint;
		public var compassIndex:int;
		
		private var p:Point;
		
		public static const NEAR_DEATH:Number = 0.4;
		public static const compassPoints:Array/*Point*/ = [new Point(0, -1), new Point(1, 0), new Point(0, 1), new Point( -1, 0)];
		// the pixels that make up the @
		public static const pixels:Array/*Point*/ = [
			new Point(4, 4), new Point(4, 4), new Point(5, 4), new Point(6, 4), new Point(6, 3), new Point(6, 2), new Point(6, 1),
			new Point(6, 0), new Point(5, 0), new Point(4, 0), new Point(3, 0), new Point(2, 0), new Point(1, 0),
			new Point(0, 0), new Point(0, 1), new Point(0, 2), new Point(0, 3), new Point(0, 4), new Point(0, 5),
			new Point(0, 6), new Point(1, 6), new Point(2, 6), new Point(3, 6), new Point(4, 6), new Point(5, 6), new Point(6, 6)
		];
		// I really did just type that out instead of wasting cpu on an automata or bothering to write a nifty bit
		// of code that would auto-generate it, figuring it out would have taken just as long
		// what makes this worse is that I realised I'd counted the pixels backwards and had to swap it around
		// for the sanity of the code. Oh, you want to change the player's graphics? Have fun.
		
		public function FoodClockFX(blit:BlitSprite, deadCol:uint) {
			this.blit = blit;
			spriteSheet = blit.spriteSheet;
			this.deadCol = deadCol;
			food = maxFood = pixels.length - 1;
			col = spriteSheet.getPixel32(blit.rect.x, blit.rect.y);
		}
		
		public function setFood(n:Number, total:Number, x:Number, y:Number):void{
			var ratio:Number = maxFood / total;
			var value:int = Math.ceil(ratio * n);
			while(food != value){
				p = pixels[food];
				if(food < value){
					spriteSheet.setPixel32(p.x + blit.rect.x, p.y + blit.rect.y, col);
					food++;
				} else if(food > value){
					if((1.0 / maxFood) * food <= NEAR_DEATH){
						renderer.addFX(x + p.x, y + p.y, renderer.debrisBlit, compassPoints[compassIndex], 0, true, true);
						if(food == 1){
							renderer.bitmapDebris(blit, x * Renderer.INV_SCALE, y * Renderer.INV_SCALE, 0);
						}
					}
					spriteSheet.setPixel32(p.x + blit.rect.x, p.y + blit.rect.y, deadCol);
					compassIndex++;
					if(compassIndex >= compassPoints.length) compassIndex = 0;
					food--;
				}
			}
		}
		
	}

}