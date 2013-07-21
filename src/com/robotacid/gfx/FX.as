package com.robotacid.gfx {
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.geom.Point;
	
	/**
	* Self managing BlitClip wrapper
	* Accounts for Blit being projected onto tracking the viewport and
	* self terminates after animation is complete
	*
	* @author Aaron Steed, robotacid.com
	*/
	public class FX extends Point{
		
		public static var game:Game;
		public static var renderer:Renderer;
		
		public var blit:BlitRect;
		public var frame:int;
		public var active:Boolean;
		public var canvasPoint:Point;
		public var bitmapData:BitmapData;
		public var dir:Point;
		public var looped:Boolean;
		public var killOffScreen:Boolean;
		
		public function FX(x:Number, y:Number, blit:BlitRect, bitmapData:BitmapData, canvasPoint:Point, dir:Point = null, delay:int = 0, looped:Boolean = false, killOffScreen:Boolean = true) {
			super(x, y);
			this.blit = blit;
			this.bitmapData = bitmapData;
			this.canvasPoint = canvasPoint;
			this.dir = dir;
			this.looped = looped;
			this.killOffScreen = killOffScreen;
			frame = 0 - delay;
			active = true;
		}
		
		public function main():void {
			if(frame > -1){
				blit.x = (canvasPoint.x) + x;
				blit.y = (canvasPoint.y) + y;
				// just trying to ease the collosal rendering requirements going on
				if(blit.x + blit.dx + blit.width >= 0 &&
					blit.y + blit.dy + blit.height >= 0 &&
					blit.x + blit.dx <= Game.WIDTH &&
					blit.y + blit.dy <= Game.HEIGHT){
					blit.render(bitmapData, frame++);
				} else {
					frame++;
				}
				if(frame == blit.totalFrames){
					if(looped) frame = 0;
					else active = false;
				}
			} else {
				frame++;
			}
			if(dir){
				x += dir.x;
				y += dir.y;
			}
			if(!renderer.onScreen(x, y, 5) && killOffScreen) active = false;
		}
		
		
	}
	
}