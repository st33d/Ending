package com.robotacid.gfx {
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	/**
	* Renders a solid rect of colour to a BitmapData
	*
	* @author Aaron Steed, robotacid.com
	*/
	public class BlitRect {
		
		public var x:int, y:int, width:int, height:int;
		public var dx:int, dy:int;
		public var rect:Rectangle;
		public var col:uint;
		public var totalFrames:int;
		
		public static var p:Point = new Point();
		
		public function BlitRect(dx:int = 0, dy:int = 0, width:int = 1, height:int = 1, col:uint = 0xFF000000) {
			x = y = 0;
			this.dx = dx;
			this.dy = dy;
			this.width = width;
			this.height = height;
			this.col = col;
			totalFrames = 1;
			rect = new Rectangle(0, 0, width, height);
		}
		
		public function render(destination:BitmapData, frame:int = 0):void{
			rect.x = x + dx;
			rect.y = y + dy;
			destination.fillRect(rect, col);
		}
		
		/* Returns a a copy of this object */
		public function clone():BlitRect{
			var blit:BlitRect = new BlitRect();
			blit.x = x;
			blit.y = y;
			blit.dx = dx;
			blit.dy = dy;
			blit.width = width;
			blit.height = height;
			blit.rect = new Rectangle(0, 0, width, height);
			blit.col = col;
			return blit;
		}
		
	}
	
}