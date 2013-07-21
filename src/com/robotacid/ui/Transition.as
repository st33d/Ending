package com.robotacid.ui {
	import flash.display.Sprite;
	/**
	 * A simple fade to segue between scenes with optional text inbetween
	 * 
	 * @author Aaron Steed, robotacid.com
	 */
	public class Transition extends Sprite{
		
		public var changeOverCallback:Function;
		public var completeCallback:Function;
		public var dir:int;
		public var fadeIn:int;
		public var fadeOut:int;
		public var delayCount:int;
		
		private var textBox:TextBox;
		private var textCount:int;
		private var fadeInAlpha:Number;
		private var fadeOutAlpha:Number;
		private var changeOverFrame:Boolean;
		
		public static const FADE_STEP:Number = 1.0 / 10;
		public static const TEXT_DELAY:int = 60;
		
		public function Transition() {
			dir = 0;
			alpha = 0;
			textBox = new TextBox(Game.WIDTH, Game.HEIGHT, 0xFF000000, 0xFF000000);
			textBox.alignVert = "center";
			textBox.align = "center";
			textBox.offsetY = -1;
			addChild(textBox);
			visible = false;
			changeOverFrame = false;
		}
		
		public function main():void{
			if(delayCount){
				delayCount--;
				return;
			}
			if(changeOverFrame){
				changeOverCallback();
				changeOverFrame = false;
			}
			// fade in text and delay
			if(alpha == 1 && textCount){
				textCount--;
				if(textCount == 0) dir = -1;
			// fade in, callback, fade out, callback
			} else {
				if(dir > 0){
					alpha += fadeInAlpha;
					fadeIn--;
					if(alpha >= 1 || fadeIn <= 0){
						alpha = 1;
						if(textCount == 0) dir = -1;
						if(Boolean(changeOverCallback)) changeOverFrame = true;
					}
				} else if(dir < 0){
					alpha -= fadeOutAlpha;
					fadeOut--;
					if(alpha <= 0 || fadeOut <= 0){
						dir = 0;
						alpha = 0;
						visible = false;
						if(Boolean(completeCallback)) completeCallback();
					}
				}
			}
		}
		
		/* Initiate a transition */
		public function begin(changeOverCallback:Function, fadeIn:int = 10, fadeOut:int = 10, text:String = "", textDelay:int = 0, completeCallback:Function = null, delayCount:int = 0):void{
			this.changeOverCallback = changeOverCallback;
			this.fadeIn = fadeIn;
			this.fadeOut = fadeOut;
			this.delayCount = delayCount;
			this.completeCallback = completeCallback;
			fadeInAlpha = fadeIn ? 1.0 / fadeIn : 1.0;
			fadeOutAlpha = fadeOut ? 1.0 / fadeOut : 1.0;
			textBox.text = text;
			textCount = textDelay;
			visible = true;
			dir = 1;
		}
		
	}

}