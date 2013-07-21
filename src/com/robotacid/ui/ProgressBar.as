package com.robotacid.ui {
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Rectangle;
	
	/**
	 * ...
	 * @author Aaron Steed, robotacid.com
	 */
	public class ProgressBar extends Sprite{
		
		public var active:Boolean;
		public var bitmap:Bitmap
		public var bitmapData:BitmapData;
		
		public var borderCol:uint = 0xFFFFFFFF;
		public var backCol:uint = 0xFF000000;
		public var barCol:uint = 0xFFFFFFFF;
		
		private var rect:Rectangle;
		private var barRect:Rectangle;
		private var backRect:Rectangle;
		private var value:Number;
		
		public function ProgressBar(x:Number, y:Number, width:Number, height:Number) {
			this.x = x;
			this.y = y;
			rect = new Rectangle(0, 0, width, height);
			barRect = new Rectangle(1, 1, width - 2, height - 2);
			backRect = barRect.clone();
			value = 1.0;
			bitmap = new Bitmap(new BitmapData(width, height, true, 0x0));
			bitmapData = bitmap.bitmapData;
			addChild(bitmap);
			active = true;
			update();
		}
		
		public function setValue(n:Number, total:Number):void{
			if(total != 1) value = (1.0 / total) * n;
			else value = n;
			if(value < 0) value = 0;
			if(value > 1) value = 1;
			update();
		}
		
		public function update():void{
			bitmapData.fillRect(rect, borderCol);
			bitmapData.fillRect(backRect, backCol);
			barRect.width = (value * backRect.width) >> 0;
			bitmapData.fillRect(barRect, barCol);
		}
		
	}
	
}