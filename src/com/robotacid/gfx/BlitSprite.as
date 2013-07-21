package com.robotacid.gfx {
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.filters.BitmapFilter;
	import flash.geom.ColorTransform;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	/**
	* Renders a section of a sprite sheet BitmapData to another BitmapData
	*
	* @author Aaron Steed, robotacid.com
	*/
	public class BlitSprite extends BlitRect{
		
		public var spriteSheet:BitmapData;
		
		public function BlitSprite(spriteSheet:BitmapData, rect:Rectangle, dx:int = 0, dy:int = 0) {
			super(dx, dy, rect.width, rect.height);
			this.spriteSheet = spriteSheet;
			this.rect = rect;
		}
		
		/* Returns a a copy of this object, must be cast into a BlitSprite */
		override public function clone():BlitRect{
			var blit:BlitSprite = new BlitSprite(spriteSheet, rect, dx, dy);
			return blit;
		}
		
		override public function render(destination:BitmapData, frame:int = 0):void{
			p.x = x + dx;
			p.y = y + dy;
			destination.copyPixels(spriteSheet, rect, p, null, null, true);
		}
		
	}
	
}