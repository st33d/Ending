package {
	import com.robotacid.ui.ProgressBar;
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.ProgressEvent;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.utils.getDefinitionByName;
	
	// default
	[SWF(width = "480", height = "320", frameRate="30", backgroundColor = "#000000")]
	// cluster-fuck of devices
	//[SWF(width = "960", height = "540", frameRate="30", backgroundColor = "#000000")]
	//[SWF(width = "1024", height = "768", frameRate="30", backgroundColor = "#000000")]
	//[SWF(width = "1136", height = "640", frameRate="30", backgroundColor = "#000000")]
	//[SWF(width = "800", height = "480", frameRate="30", backgroundColor = "#000000")]
	//[SWF(width = "897", height = "540", frameRate="30", backgroundColor = "#000000")]
	// youtube/16:9
	//[SWF(width = "854", height = "480", frameRate = "30", backgroundColor = "#000000")]
	// my mac-top scale
	//[SWF(width = "640", height = "400", frameRate="30", backgroundColor = "#000000")]
	
	/**
	 * Loads Game class
	 * 
	 * @author Aaron Steed, robotacid.com
	 */
	public class Preloader extends MovieClip {
		
		public var bar:ProgressBar;
		public var focusPrompt:Boolean;
		
		public function Preloader() {
			if (stage) init();
			else addEventListener(Event.ADDED_TO_STAGE, init);
		}
		
		private function init(e:Event = null):void{
			removeEventListener(Event.ADDED_TO_STAGE, init);
			addEventListener(Event.ENTER_FRAME, checkFrame);
			focusPrompt = true;
			stage.addEventListener(Event.ACTIVATE, onFocus);
			loaderInfo.addEventListener(ProgressEvent.PROGRESS, progress);
            stage.scaleMode = StageScaleMode.SHOW_ALL;
			//stage.align = StageAlign.TOP_LEFT;
			// show loader
			bar = new ProgressBar(0, 0, 40, 10);
			bar.barCol = 0xff313b49;
			bar.setValue(0, 1);
			bar.scaleX = bar.scaleY = 4;
			bar.x = 240 - bar.width * 0.5;
			bar.y = 160 - bar.height * 0.5;
			addChild(bar);
			graphics.beginFill(0x1A1E26);
			graphics.drawRect(0, 0, 480, 320);
			graphics.endFill();
			graphics.beginFill(0x0);
			graphics.drawRect(bar.x + 2, bar.y + 2, bar.width + 2, bar.height + 2);
			graphics.endFill();
		}
		
		private function progress(e:ProgressEvent):void {
			// update loader
			bar.setValue(root.loaderInfo.bytesLoaded / root.loaderInfo.bytesTotal, 1);
		}
		
		private function checkFrame(e:Event):void {
			if(currentFrame == totalFrames){
				removeEventListener(Event.ENTER_FRAME, checkFrame);
				startup();
			}
		}
		
		private function startup():void {
			// hide loader
			removeChild(bar);
			graphics.clear();
			stop();
			loaderInfo.removeEventListener(ProgressEvent.PROGRESS, progress);
			var mainClass:Class = getDefinitionByName("Game") as Class;
			var game:* = new mainClass();
			game.forceFocus = focusPrompt;
			addChild(game as DisplayObject);
		}
		
		/* This is a double hack to get around the force focus hack not working with
		 * a pre-loader */
		private function onFocus(e:Event = null):void{
			focusPrompt = false;
			stage.removeEventListener(Event.ACTIVATE, onFocus);
		}
		
	}
	
}