package com.robotacid.gfx {
	
	import com.robotacid.gfx.BlitRect;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.filters.BitmapFilter;
	import flash.geom.ColorTransform;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	/**
	* Renders an animation to a BitmapData using a series of references to animation frames
	* on a sprite sheet
	*
	* @author Aaron Steed, robotacid.com
	*/
	public class BlitClip extends BlitSprite{
		
		public var frame:int;
		public var frames:Array/*Rectangle*/;
		
		public function BlitClip(spriteSheet:BitmapData, frames:Array, dx:int = 0, dy:int = 0) {
			super(spriteSheet, frames[0], dx, dy);
			this.frames = frames;
			totalFrames = frames.length;
			
			// collapse multiple references
			var i:int, j:int, a:Rectangle, b:Rectangle;
			for(i = 0; i < frames.length; i++){
				for(j = i + 1; j < frames.length; j++){
					a = frames[i];
					b = frames[j];
					if(a && b && a.x == b.x && a.y == b.y && a.width == b.width && a.height == b.height){
						frames[j] = frames[i];
					}
				}
			}
		}
		
		/* Returns a a copy of this object, must be cast into a BlitClip */
		override public function clone():BlitRect {
			var blit:BlitClip = new BlitClip(spriteSheet, frames.slice(), dx, dy);
			return blit;
		}
		override public function render(destination:BitmapData, frame:int = 0):void{
			if(frames[frame]){
				p.x = x + dx;
				p.y = y + dy;
				destination.copyPixels(spriteSheet, frames[frame], p, null, null, true);
			}
		}
		
	}
	
}