package {
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.utils.ByteArray;
	
	/**
	 * Initialises levels and manages requests for them
	 * 
	 * @author Aaron Steed, robotacid.com
	 */
	public class Library {
		
		[Embed(source = "levels.json", mimeType = "application/octet-stream")] public static var LevelsData:Class;
		
		public static var levels:Array;
		public static var loadUserLevelsCallback:Function;
		public static var saveUserLevelsCallback:Function;
		
		public static var PERMANENT_LEVELS:Array;
		public static var USER_LEVELS:Array;
		public static var maxLevel:int;
		
		public static const TOTAL_LEVELS:int = 100;
		
		public static function initLevels():void{
			var i:int;
			var byteArray:ByteArray = new LevelsData;
			PERMANENT_LEVELS = JSON.parse(byteArray.readUTFBytes(byteArray.length)) as Array;
			byteArray.position = 0;
			USER_LEVELS = JSON.parse(byteArray.readUTFBytes(byteArray.length)) as Array;
			
			for(i = 0; i < TOTAL_LEVELS; i++){
				if(!Boolean(PERMANENT_LEVELS[i])) PERMANENT_LEVELS[i] = null;
				if(!Boolean(USER_LEVELS[i])) USER_LEVELS[i] = null;
			}
			if(Boolean(loadUserLevelsCallback)) loadUserLevelsCallback();
		}
		
		public static function setLevels(permanent:Boolean = true):void{
			if(permanent){
				levels = PERMANENT_LEVELS;
				maxLevel = getMaxLevel();
			} else {
				levels = USER_LEVELS;
				maxLevel = levels.length - 1;
			}
		}
		
		private static function getMaxLevel():int{
			var i:int;
			for(i = 0; i < levels.length; i++){
				if(!levels[i]) return i - 1;
			}
			return levels.length - 1;
		}
	}
}