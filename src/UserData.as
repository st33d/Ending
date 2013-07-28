package {
	import com.robotacid.gfx.Renderer;
	import com.robotacid.sound.SoundManager;
	import com.robotacid.ui.Key;
	import com.robotacid.util.XorRandom;
	import com.robotacid.ui.FileManager;
	import flash.net.navigateToURL;
	import flash.net.URLRequest;
	import flash.ui.Keyboard;
	import flash.net.SharedObject;
	import flash.utils.ByteArray;
	/**
	 * Provides an interface for storing game data in a shared object and restoring the game from
	 * the shared object
	 * 
	 * @author Aaron Steed, robotacid.com
	 */
	public class UserData {
		
		public static var game:Game
		public static var renderer:Renderer;
		
		public static var settings:Object;
		public static var gameState:Object;
		
		public static var settingsBytes:ByteArray;
		public static var gameStateBytes:ByteArray;
		
		// assign these to default to writing to a file instead of the SharedObject
		public static var fileSaveCallback:Function;
		public static var fileLoadCallback:Function;
		
		private static var loadSettingsCallback:Function;
		
		public static var disabled:Boolean = false;
		
		private static var i:int;
		
		public function UserData() {
			
		}
		
		public static function push(settingsOnly:Boolean = false):void{
			if(disabled) return;
			
			if(Boolean(fileSaveCallback)){
				var userDataObj:Object = {
					settings:settings,
					gameState:gameState
				}
				fileSaveCallback(userDataObj);
				
			} else {
				var sharedObject:SharedObject = SharedObject.getLocal("ending");
				// SharedObject.data has a nasty habit of writing direct to the file
				// even when you're not asking it to. So we offload into a ByteArray instead.
				settingsBytes = new ByteArray();
				settingsBytes.writeObject(settings);
				sharedObject.data.settingsBytes = settingsBytes;
				if(!settingsOnly){
					gameStateBytes = new ByteArray();
					gameStateBytes.writeObject(gameState);
					sharedObject.data.gameStateBytes = gameStateBytes;
				}
				settingsBytes = null;
				gameStateBytes = null;
				// wrapper to send users to manage their shared object settings if blocked
				try{
					sharedObject.flush();
					sharedObject.close();
				} catch(e:Error){
					if(!Game.MOBILE) navigateToURL(new URLRequest("http://www.macromedia.com/support/documentation/en/flashplayer/help/settings_manager03.html"));
				}
			}
		}
		
		public static function pull():void{
			if(disabled) return;
			
			if(Boolean(fileLoadCallback)){
				var userDataObj:Object = fileLoadCallback();
				if(userDataObj){
					if(userDataObj.settings){
						overwrite(settings, userDataObj.settings);
					}
					if(userDataObj.gameState){
						overwrite(gameState, userDataObj.gameState);
					}
				}
				
			} else {
			
				var sharedObject:SharedObject = SharedObject.getLocal("ending");
				
				// comment out the following blocks to flush save state bugs
				
				// the overwrite method is used to ensure older save data does not delete new features
				if(sharedObject.data.settingsBytes){
					settingsBytes = sharedObject.data.settingsBytes;
					overwrite(settings, settingsBytes.readObject());
				}
				if(sharedObject.data.gameStateBytes){
					gameStateBytes = sharedObject.data.gameStateBytes;
					overwrite(gameState, gameStateBytes.readObject());
				}/**/
				settingsBytes = null;
				gameStateBytes = null;
				// wrapper to send users to manage their shared object settings if blocked
				try{
					sharedObject.flush();
					sharedObject.close();
				} catch(e:Error){
					if(!Game.MOBILE) navigateToURL(new URLRequest("http://www.macromedia.com/support/documentation/en/flashplayer/help/settings_manager03.html"));
				}
			}
		}
		
		public static function reset():void{
			initSettings();
			initGameState();
			push();
		}
		
		/* Overwrites matching variable names with source to target */
		public static function overwrite(target:Object, source:Object):void{
			for(var key:String in source){
				target[key] = source[key];
			}
		}
		
		/* This is populated on the fly by com.robotacid.level.Content */
		public static function initGameState():void{
			gameState = {
				data:null,
				previousData:null
			};
			
		}
		
		public static function saveGameState():void{
			if(game.level){
				gameState.data = game.level.data.saveData();
				push();
			}
		}
		
		/* Create the default settings object to initialise the game from */
		public static function initSettings():void{
			settings = {
				customKeys:[Key.W, Key.S, Key.A, Key.D],
				sfx:true,
				music:true,
				ascended:false,
				checkView:false,
				tapControls:!Game.MOBILE,
				completed:[],
				orientation:0,
				best:null
			};
			var i:int;
			for(i = 0; i < Library.TOTAL_LEVELS; i++){
				settings.completed[i] = false;
			}
		}
		
	}

}