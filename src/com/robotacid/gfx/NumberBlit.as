package com.robotacid.gfx {
	import flash.display.BitmapData;
	import flash.display.MovieClip;
	import flash.geom.ColorTransform;
	import flash.geom.Rectangle;
	
	/**
	 * Renders a string of numbers from the current x,y position
	 * 
	 * Using setTargetValue and update rolls the numbers towards a target value
	 * 
	 * @author Aaron Steed, robotacid.com
	 */
	public class NumberBlit extends BlitSprite {
		
		public var spacing:int;
		public var drums:Array;
		public var digits:int;
		public var value:Number;
		public var target:Number;
		public var step:Number;
		
		private var sourceY:int;
		private var stepY:int;
		
		// temps
		private var i:int;
		private var str:String;
		private var remainder:Number;
		private var digit:Number;
		private var valueI:int;
		
		public function NumberBlit(spriteSheet:BitmapData, rect:Rectangle, digits:int = 1, step:Number = 0.25, dx:int = 0, dy:int = 0, spacing:int = 0, stepY:int = 0) {
			super(spriteSheet, rect, dx, dy);
			this.height = height;
			this.digits = digits;
			this.step = step;
			if(stepY) this.stepY = stepY;
			else this.stepY = rect.width;
			if(spacing) this.spacing = spacing;
			else this.spacing = rect.width;
			sourceY = rect.y;
			drums = new Array(digits);
			this.rect = new Rectangle(rect.x, rect.y, spacing, spacing + 1);
		}
		
		/* Rolls the number drums towards our target digits */
		public function update():void{
			if(value != target){
				if(value < target) value += step;
				if(value > target) value -= step;
				if(Math.abs(value - target) < step){
					setValue(target);
					return;
				}
				var valueI:int = value;
				remainder = value - valueI;
				str = valueI + "";
				if(digits){
					while(str.length < digits) str = "0" + str;
				}
				for(i = digits - 1; i > -1; i--){
					digit = int(str.charAt(i));
					drums[i] = digit + remainder;
					if(digit != 9) remainder = 0;
				}
			}
		}
		
		public function setTargetValue(n:int):void{
			target = n;
		}
		
		public function setValue(n:int):void{
			value = target = n;
			str = n + "";
			if(digits){
				while(str.length < digits) str = "0" + str;
			}
			for(i = 0; i < digits; i++){
				drums[i] = int(str.charAt(i));
			}
		}
		
		public function renderNumbers(bitmapData:BitmapData):void{
			var yTemp:Number = y;
			var rectTemp:Rectangle = rect.clone();
			for(i = 0; i < digits; i++){
				rect.y = sourceY + drums[i] * stepY;
				render(bitmapData);
				x += spacing;
			}
			rect = rectTemp;
		}
		
	}

}