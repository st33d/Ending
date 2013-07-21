package com.robotacid.ui {
	import com.robotacid.gfx.BlitClip;
	import com.robotacid.gfx.BlitRect;
	import flash.display.BitmapData;
	import flash.geom.Rectangle;
	/**
	 * UIManager Button object
	 * 
	 * @author Aaron Steed, robotacid.com
	 */
	public class BlitButton {
		
		public var id:int;
		public var targetId:int;
		
		public var x:Number;
		public var y:Number;
		public var blit:BlitRect;
		public var over:Boolean;
		public var active:Boolean;
		public var area:Rectangle;
		public var callback:Function;
		public var visible:Boolean;
		public var frame:int;
		public var heldCallback:Function;
		public var heldCount:int;
		public var held:Boolean;
		public var releaseCallback:Function;
		public var focusLock:Boolean;
		public var feedCallbackToEvent:Boolean;
		public var silent:Boolean;
		
		private var states:Boolean;
		
		public static const HELD_DELAY:int = 15;
		
		public function BlitButton(x:Number, y:Number, blit:BlitRect, callback:Function, area:Rectangle = null, states:Boolean = true) {
			this.x = x;
			this.y = y;
			this.blit = blit;
			this.states = states;
			this.callback = callback;
			if(!area) area = new Rectangle(0, 0, blit.width, blit.height);
			this.area = area;
			visible = true;
			active = false;
			focusLock = true;
		}
		
		public function render(bitmapData:BitmapData):void{
			blit.x = x;
			blit.y = y;
			if(states){
				frame = over ? 1 : 0;
				frame += active ? 2 : 0;
			}
			blit.render(bitmapData, frame);
		}
		
	}

}