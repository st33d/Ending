package com.robotacid.gfx {
	import flash.display.BitmapData;
	import flash.geom.ColorTransform;
	import flash.geom.Rectangle;
	
	/**
	 * Dirty hack for fading out a snapshot
	 * 
	 * @author Aaron Steed, robotacid.com
	 */
	public class FadingBlitClip extends BlitClip {
		
		public var spriteSheets:Array;
		
		public function FadingBlitClip(spriteSheet:BitmapData, fadeFrames:int) {
			rect = new Rectangle(0, 0, spriteSheet.width, spriteSheet.height);
			frames = [rect];
			spriteSheets = [spriteSheet];
			var colorTransform:ColorTransform = new ColorTransform();
			var alphaStep:Number = 1.0 / fadeFrames;
			var bitmapData:BitmapData;
			for(var i:int = 1; i < fadeFrames; i++){
				frames.push(new Rectangle(0, 0, spriteSheet.width, spriteSheet.height));
				colorTransform.alphaMultiplier -= alphaStep;
				bitmapData = spriteSheet.clone();
				bitmapData.colorTransform(rect, colorTransform);
				spriteSheets.push(bitmapData);
			}
			super(spriteSheet, frames);
		}
		
		override public function render(destination:BitmapData, frame:int = 0):void {
			spriteSheet = spriteSheets[frame];
			super.render(destination, frame);
		}
	}

}