package {
	import com.robotacid.engine.*;
	import com.robotacid.gfx.Renderer;
	import com.robotacid.gfx.FX;
	import com.robotacid.gfx.PNGEncoder;
	import com.robotacid.sound.SoundManager;
	import com.robotacid.sound.SoundQueue;
	import com.robotacid.ui.editor.*;
	import com.robotacid.ui.FileManager;
	import com.robotacid.ui.ProgressBar;
	import com.robotacid.ui.TextBox;
	import com.robotacid.ui.Key;
	import com.robotacid.ui.TitleMenu;
	import com.robotacid.ui.Transition;
	import com.robotacid.ui.UIManager;
	import com.robotacid.util.XorRandom;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Graphics;
	import flash.display.MovieClip;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.display.StageQuality;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.events.TouchEvent;
	import flash.external.ExternalInterface;
	import flash.geom.ColorTransform;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.media.Sound;
	import flash.net.SharedObject;
	import flash.system.Capabilities;
	import flash.text.TextField;
	import flash.ui.Keyboard;
	import flash.ui.Mouse;
	import flash.utils.getTimer;
	
	/**
	 * Ending
	 *
	 * A roguelike puzzle game
	 * 
	 * This is a god-object singleton. 
	 *
	 * @author Aaron Steed, robotacid.com
	 */
	
	public class Game extends Sprite {
		
		public static const TEST_BED_INIT:Boolean = false;
		public static var MOBILE:Boolean = false;
		
		public static var game:Game;
		public static var renderer:Renderer;
		
		// core engine objects
		public var titleMenu:TitleMenu;
		public var level:Level;
		public var roomPainter:RoomPainter;
		public var soundQueue:SoundQueue;
		public var transition:Transition;
		
		// ui
		public var focusPrompt:Sprite;
		
		// states
		public var state:int;
		public var focusPreviousState:int;
		public var frameCount:int;
		public var fireButtonPressed:Boolean;
		public var fireButtonPressedCount:int;
		public var keyPressedCount:int;
		public var mousePressed:Boolean;
		public var mousePressedCount:int;
		public var mouseReleasedCount:int;
		public var mouseVx:Number;
		public var mouseVy:Number;
		public var mouseSwipeSent:int;
		public var mouseSwipeCount:int;
		public var mouseSwipeDelay:int;
		private var lastMouseX:Number;
		private var lastMouseY:Number;
		private var mouseDownX:Number;
		private var mouseDownY:Number;
		public var paused:Boolean;
		public var shakeDirX:int;
		public var shakeDirY:int;
		public var forceFocus:Boolean = false;
		public var mouseCorner:int;
		public var regainedFocus:Boolean = false;
		public var currentLevel:int;
		public var currentLevelType:int;
		public var currentLevelObj:Object;
		public var editing:Boolean;
		public var modifiedLevel:Boolean;
		public var scaleRatio:Number;
		public var defaultStageRatio:Number;
		public var stageRatio:Number;
		public var realStageWidth:Number;
		public var realStageHeight:Number;
		public var hideMouseFrames:int;
		
		public static const MOUSE_SWIPE_DELAY_DEFAULT:int = 4;
		
		// temp variables
		private var i:int;
		public static var point:Point = new Point();
		
		// CONSTANTS
		
		public static const SCALE:Number = 8;
		public static const INV_SCALE:Number = 1.0 / 8;
		
		public static const DEFAULT_SCREEN_RATIO:Number = 480 / 320;
		public static var SCREEN_RATIO:Number;
		
		// states
		public static const GAME:int = 0;
		public static const MENU:int = 1;
		public static const DIALOG:int = 2;
		public static const SEGUE:int = 3;
		public static const UNFOCUSED:int = 4;
		
		public static var WIDTH:Number = 120;
		public static var HEIGHT:Number = 80;
		
		// game key properties
		public static const UP_KEY:int = 0;
		public static const DOWN_KEY:int = 1;
		public static const LEFT_KEY:int = 2;
		public static const RIGHT_KEY:int = 3;
		
		public static const MAX_LEVEL:int = 20;
		
		public static const TURN_FRAMES:int = 2;
		public static const HIDE_MOUSE_FRAMES:int = 60;
		public static const DEATH_FADE_COUNT:int = 10;
		
		public static var fullscreenToggled:Boolean;
		public static var allowScriptAccess:Boolean;
		
		public static const SOUND_DIST_MAX:int = 8;
		public static const INV_SOUND_DIST_MAX:Number = 1.0 / SOUND_DIST_MAX;
		
		public function Game():void {
			
			visible = false;
			
			game = this;
			UserData.game = this;
			FX.game = this;
			Level.game = this;
			TitleMenu.game = this;
			RoomPainter.game = this;
			RoomPalette.game = this;
			
			// detect allowScriptAccess for tracking
			allowScriptAccess = ExternalInterface.available;
			if(allowScriptAccess){
				try{
					ExternalInterface.call("");
				} catch(e:Error){
					allowScriptAccess = false;
				}
			}
			
			Library.initLevels();
			
			// init UserData
			UserData.initSettings();
			UserData.initGameState();
			UserData.pull();
			// check the game is alive
			if(UserData.gameState.dead) UserData.initGameState();
			
			state = TEST_BED_INIT ? GAME : MENU;
			
			// init sound
			SoundManager.init();
			soundQueue = new SoundQueue();
			
			if (stage) addedToStage();
			else addEventListener(Event.ADDED_TO_STAGE, addedToStage);
		}
		
		/* Determine scaling and extra rows/cols for different devices */
		private function setStageRatio():void{
			if(MOBILE){
				realStageWidth = Math.max(Capabilities.screenResolutionX, Capabilities.screenResolutionY);
				realStageHeight = Math.min(Capabilities.screenResolutionX, Capabilities.screenResolutionY);
			} else {
				realStageWidth = stage.stageWidth;
				realStageHeight = stage.stageHeight;
			}
			stageRatio = realStageWidth / realStageHeight;
			defaultStageRatio = WIDTH / HEIGHT;
			
			// pad extra rows/cols to fill aspect ratio better
			if(stageRatio > defaultStageRatio){
				scaleRatio = realStageHeight / HEIGHT;
				while((WIDTH + SCALE) * scaleRatio < realStageWidth){
					WIDTH += SCALE;
				}
			} else {
				scaleRatio = realStageWidth / WIDTH;
				while((HEIGHT + SCALE) * scaleRatio < realStageHeight){
					HEIGHT += SCALE;
				}
			}
		}
		
		private function addedToStage(e:Event = null):void{
			removeEventListener(Event.ADDED_TO_STAGE, init);
			
			// KEYS INIT
			if(!Key.initialized){
				Key.init(stage);
				Key.custom = UserData.settings.customKeys.slice();
				Key.hotKeyTotal = 10;
			}
			
			// GRAPHICS INIT
			
			setStageRatio();
			trace("new width/height:", WIDTH + "/" + HEIGHT);
			
			renderer = new Renderer(this);
			renderer.init();
			
			transition = new Transition();
			
			x = (realStageWidth * 0.5 - WIDTH * scaleRatio * 0.5) >> 0;
			y = (realStageHeight * 0.5 - HEIGHT * scaleRatio * 0.5) >> 0;
			
			scaleX = scaleY = scaleRatio;
			
			stage.quality = StageQuality.LOW;
			visible = true;
			
			if(UserData.settings.orientation){
				toggleOrientation();
			}
			
			// launch
			init();
		}
		
		/*  */
		private function init():void {
			
			// GAME GFX AND UI INIT
			if(state == GAME || state == MENU){
				renderer.createRenderLayers(this);
			}
			
			addChild(transition);
			
			if(!focusPrompt){
				focusPrompt = new Sprite();
				focusPrompt.addChild(screenText("click"));
				stage.addEventListener(Event.DEACTIVATE, onFocusLost);
				stage.addEventListener(Event.ACTIVATE, onFocus);
			}
			
			if(state == GAME || state == MENU){
				frameCount = 1;
				currentLevel = 0;
				currentLevelType = TEST_BED_INIT ? Room.ADVENTURE : Room.PUZZLE;
				currentLevelObj = null;
				titleMenu = new TitleMenu();
				if(state == GAME) initLevel();
			}
			
			addListeners();
			
			// this is a hack to force clicking on the game when the browser first pulls in the swf
			if(forceFocus){
				onFocusLost();
				forceFocus = false;
			} else {
			}
		}
		
		/* Pedantically clear all memory and re-init the project */
		public function reset(newGame:Boolean = true):void{
			removeEventListener(MouseEvent.MOUSE_DOWN, mouseDown);
			removeEventListener(MouseEvent.MOUSE_UP, mouseUp);
			removeEventListener(Event.ENTER_FRAME, main);
			stage.removeEventListener(KeyboardEvent.KEY_DOWN, keyPressed);
			stage.removeEventListener(Event.DEACTIVATE, onFocusLost);
			stage.removeEventListener(Event.ACTIVATE, onFocus);
			stage.removeEventListener(MouseEvent.MOUSE_MOVE, mouseMove);
			//removeEventListener(TouchEvent.TOUCH_BEGIN, touchBegin);
			while(numChildren > 0){
				removeChildAt(0);
			}
			level = null;
			if(newGame){
				UserData.initGameState();
				UserData.push();
			}
			init();
		}
		
		private function addListeners():void{
			stage.addEventListener(Event.DEACTIVATE, onFocusLost);
			stage.addEventListener(Event.ACTIVATE, onFocus);
			stage.addEventListener(MouseEvent.MOUSE_MOVE, mouseMove);
			stage.addEventListener(MouseEvent.MOUSE_DOWN, mouseDown);
			stage.addEventListener(MouseEvent.MOUSE_UP, mouseUp);
			stage.addEventListener(KeyboardEvent.KEY_DOWN, keyPressed);
			addEventListener(Event.ENTER_FRAME, main);
		}
		
		// =================================================================================================
		// MAIN LOOP
		// =================================================================================================
		
		private function main(e:Event):void {
			
			// copy out when needed
			// var t:int = getTimer();
			
			if(transition.visible) transition.main();
			
			if(state == GAME) {
				
				if(roomPainter.active) roomPainter.main();
				if(level.active && transition.dir < 1) level.main();
				soundQueue.play();
				renderer.main();
				
			} else if(state == MENU){
				
				if(transition.dir < 1) titleMenu.main();
				renderer.main();
				
			}
			
			// hide the mouse when not in use
			if(hideMouseFrames < HIDE_MOUSE_FRAMES){
				hideMouseFrames++;
				if(hideMouseFrames >= HIDE_MOUSE_FRAMES){
					Mouse.hide();
					if(!MOBILE){
						if(!(roomPainter && roomPainter.active)){
							if(level && level.settingsButton){
								level.settingsButton.visible = false;
							}
						}
					}
				}
			}
			
			mouseVx = mouseX - lastMouseX;
			mouseVy = mouseY - lastMouseY;
			lastMouseX = mouseX;
			lastMouseY = mouseY;
			frameCount++;
		}
		
		public function initLevel():void{
			level = new Level(currentLevelType, currentLevelObj);
			level.checkView = level.checkButton.active = UserData.settings.checkView;
			level.tapControls = level.controlsButton.active = UserData.settings.tapControls;
			renderer.reset();
			roomPainter = new RoomPainter(level, level.data);
			//roomPainter.setActive(true);
			state = GAME;
		}
		
		public function resetGame():void{
			if(!editing){
				if(level.data.room.type == Room.ADVENTURE){
					UserData.settings.adventureData = null;
					currentLevelObj = null;
				} else if(level.data.room.type == Room.PUZZLE){
					UserData.settings.puzzleData = null;
					currentLevelObj = Library.levels[currentLevel];;
				}
				UserData.push(true);
			}
			initLevel();
		}
		
		public function setNextGame(type:int, levelNum:int = 0):void{
			modifiedLevel = false;
			currentLevel = levelNum;
			currentLevelType = type;
			if(type == Room.ADVENTURE){
				currentLevelObj = null;
				if(UserData.settings.adventureData){
					currentLevelObj = UserData.settings.adventureData;
				}
			} else if(type == Room.PUZZLE){
				if(UserData.settings.puzzleData && !editing){
					currentLevelObj = UserData.settings.puzzleData;
					currentLevel = UserData.settings.puzzleLevel;
				} else {
					currentLevelObj = Library.levels[levelNum];
				}
			}
		}
		
		public function saveProgress(appExit:Boolean = false):void{
			if(!editing){
				if(state == GAME){
					if(level.data.room.type == Room.ADVENTURE){
						if(!level.data.ended){
							UserData.settings.adventureData = level.data.saveData(true);
						} else {
							UserData.settings.adventureData = null;
						}
					} else if(level.data.room.type == Room.PUZZLE){
						if(!level.data.ended && appExit){
							UserData.settings.puzzleData = level.data.saveData(true);
							UserData.settings.puzzleLevel = currentLevel;
						} else {
							UserData.settings.puzzleData = null;
						}
					}
					UserData.push(true);
				}
			}
		}
		
		public function puzzleWin():void{
			if(!editing || !modifiedLevel){
				currentLevel++;
				currentLevelObj = currentLevel < Library.TOTAL_LEVELS ? Library.levels[currentLevel] : null;
			}
			if(currentLevelObj){
				var str:String = (currentLevel < 10 ? "0" : "") + currentLevel;
				transition.begin(nextLevel, DEATH_FADE_COUNT, DEATH_FADE_COUNT, str, 15, null, 20);
			} else {
				transition.begin(quit, DEATH_FADE_COUNT, DEATH_FADE_COUNT, "\"poo-tee-weet?\"", 90, null, 30);
			}
		}
		
		public function adventureWin():void{
			var str:String = "" + level.data.turns;
			transition.begin(quit, DEATH_FADE_COUNT, DEATH_FADE_COUNT, str, 30, null, 90);
		}
		
		public function blackOut():void{
			renderer.reset();
			state = SEGUE;
		}
		
		public function nextLevel():void{
			if(!editing) completePreviousLevel();
			initLevel();
		}
		
		private function completePreviousLevel():void{
			if(!editing){
				if(level.data.room.type == Room.PUZZLE){
					UserData.settings.completed[currentLevel - 1] = true;
					UserData.settings.puzzleData = null;
					UserData.push(true);
				} else if(level.data.room.type == Room.ADVENTURE){
					if(!UserData.settings.best || level.data.turns < UserData.settings.best){
						UserData.settings.best = level.data.turns;
						UserData.settings.adventureData = null;
						UserData.push(true);
						titleMenu.setScore(level.data.turns);
					}
				}
			}
		}
		
		public function death():void{
			transition.begin(resetGame, DEATH_FADE_COUNT, DEATH_FADE_COUNT, "@", 5, null, 15);
		}
		
		public function quit():void{
			if(level.active) completePreviousLevel();
			else saveProgress();
			
			if(roomPainter.active) roomPainter.setActive(false);
			renderer.reset();
			state = MENU;
		}
		
		public function screenText(str:String):TextBox{
			var textBox:TextBox = new TextBox(WIDTH, HEIGHT, 0xFF000000, 0xFF000000);
			textBox.align = "center";
			textBox.alignVert = "center";
			textBox.text = str;
			return textBox;
		}
		
		/* Play a sound at a volume based on the distance to the player */
		public function createDistSound(mapX:int, mapY:int, name:String, names:Array = null, volume:Number = 1):void{
			var dist:Number = Math.abs(level.data.player.x - mapX) + Math.abs(level.data.player.y - mapY);
			if(dist < SOUND_DIST_MAX){
				if(names) soundQueue.addRandom(name, names, (SOUND_DIST_MAX - dist) * INV_SOUND_DIST_MAX * volume);
				else if(name) soundQueue.add(name, (SOUND_DIST_MAX - dist) * INV_SOUND_DIST_MAX * volume);
			}
		}
		
		private function mouseDown(e:MouseEvent = null):void{
			// ignore the first click returning to the game
			if(!MOBILE){
				if(regainedFocus){
					regainedFocus = false;
					return;
				}
			}
			mouseSwipeSent = 0;
			mousePressed = true;
			mousePressedCount = frameCount;
			lastMouseX = mouseDownX = mouseX;
			lastMouseY = mouseDownY = mouseY;
			setMouseCorner();
		}
		
		private function mouseUp(e:MouseEvent = null):void{
			mousePressed = false;
			mouseReleasedCount = frameCount;
			// this is how you bypass security restrictions on method calls that require a MouseEvent to validate
			if(Boolean(UIManager.mousePressedCallback)){
				UIManager.mousePressedCallback();
				UIManager.mousePressedCallback = null;
			}
		}
		
		public function getMouseSwipe():int{
			if(mouseSwipeSent == 0){
				var vx:Number = mouseX - mouseDownX;
				var vy:Number = mouseY - mouseDownY;
				var len:Number = Math.sqrt(vx * vx + vy * vy);
				if(len > 3){
					mouseSwipeCount = mouseSwipeDelay = MOUSE_SWIPE_DELAY_DEFAULT;
					if(Math.abs(vy) > Math.abs(vx)){
						if(vy > 0){
							mouseSwipeSent = Room.DOWN;
						} else {
							mouseSwipeSent = Room.UP;
						}
					} else {
						if(vx > 0){
							mouseSwipeSent = Room.RIGHT;
						} else {
							mouseSwipeSent = Room.LEFT;
						}
					}
					return mouseSwipeSent;
				}
			} else {
				if(mouseSwipeCount){
					mouseSwipeCount--;
				} else {
					if(mouseSwipeDelay){
						mouseSwipeDelay--;
					}
					mouseSwipeCount = mouseSwipeDelay;
					return mouseSwipeSent;
				}
			}
			return 0;
		}
		
		private function mouseMove(e:MouseEvent):void{
			if(hideMouseFrames >= HIDE_MOUSE_FRAMES){
				Mouse.show();
				if(!MOBILE){
					if(level && level.settingsButton){
						level.settingsButton.visible = true;
					}
				}
			}
			hideMouseFrames = 0;
			setMouseCorner();
		}
		
		private function setMouseCorner():void{
			//var xSlope:Number = (WIDTH / HEIGHT) * mouseY;
			//var ySlope:Number = HEIGHT - (HEIGHT / WIDTH) * mouseX;
			var x:Number = mouseX - (WIDTH - HEIGHT) * 0.5;
			var y:Number = mouseY;
			var xSlope:Number = y;
			var ySlope:Number = HEIGHT - x;
			if(x > xSlope && y > ySlope){
				mouseCorner = Room.RIGHT
			} else if(x > xSlope && y < ySlope){
				mouseCorner = Room.UP
			} else if(x < xSlope && y > ySlope){
				mouseCorner = Room.DOWN
			} else if(x < xSlope && y < ySlope){
				mouseCorner = Room.LEFT
			}
			if(Math.abs(mouseX - WIDTH * 0.5) < SCALE * 0.75 && Math.abs(mouseY - HEIGHT * 0.5) < SCALE * 0.75){
				mouseCorner = 0;
			}
		}
		
		public function selectSound():void{
			SoundManager.playSound("chirup");
		}
		
		public function toggleOrientation():void{
			if(scaleY > 0){
				scaleY = -scaleY;
				scaleX = -scaleX;
				UserData.settings.orientation = -1;
				x = (realStageWidth * 0.5 + WIDTH * scaleRatio * 0.5) >> 0;
				y = (realStageHeight * 0.5 + HEIGHT * scaleRatio * 0.5) >> 0;
			} else {
				scaleY = -scaleY;
				scaleX = -scaleX;
				UserData.settings.orientation = 0;
				x = (realStageWidth * 0.5 - WIDTH * scaleRatio * 0.5) >> 0;
				y = (realStageHeight * 0.5 - HEIGHT * scaleRatio * 0.5) >> 0;
			}
			UserData.push(true);
		}
		
		private function keyPressed(e:KeyboardEvent):void{
			keyPressedCount = frameCount;
			if(Key.lockOut) return;
			if(level){
				if(Key.isDown(Key.R)){
					initLevel();
				}
				//if(Key.isDown(Key.T)){
					//LevelData.printPathMap();
				//}
				if(
					Key.isDown(Keyboard.CONTROL) ||
					Key.isDown(Keyboard.SHIFT) ||
					Key.isDown(Keyboard.CONTROL)
				){
					level.toggleCheckView();
				}
			}
			if(Key.isDown(Key.P)){
				//var tempBitmap:BitmapData = new BitmapData(WIDTH * scaleX, HEIGHT * scaleY, true, 0x0);
				var tempBitmap:BitmapData = new BitmapData(stage.stageWidth, stage.stageHeight, true, 0x0);
				tempBitmap.draw(this, transform.matrix);
				FileManager.save(PNGEncoder.encode(tempBitmap), "screenshot.png");
			}
			/**/
			/*
			if(Key.isDown(Key.NUMBER_1)){
				SoundManager.playSound("door1");
			}
			if(Key.isDown(Key.NUMBER_2)){
				SoundManager.playSound("door2");
			}
			if(Key.isDown(Key.NUMBER_3)){
				SoundManager.playSound("door3");
			}
			if(Key.isDown(Key.NUMBER_4)){
				SoundManager.playSound("door4");
			}*/
		}
		
		/* Must be called through a mouse event to fire in a browser */
		public function toggleFullscreen():void{
			if(stage.displayState == "normal"){
				try{
					stage.displayState = "fullScreen";
					stage.scaleMode = "showAll";
				} catch(e:Error){
				}
			} else {
				stage.displayState = "normal";
			}
			fullscreenToggled = true;
		}
		
		public function toggleSound():void{
			SoundManager.active = !SoundManager.active;
			UserData.settings.sfx = SoundManager.active;
			UserData.push(true);
		}
		
		/* When the flash object loses focus we put up a splash screen to encourage players to click to play */
		private function onFocusLost(e:Event = null):void{
			if(MOBILE || state == UNFOCUSED || state == MENU) return;
			focusPreviousState = state;
			state = UNFOCUSED;
			Key.clearKeys();
			addChild(focusPrompt);
		}
		
		/* When focus returns we remove the splash screen -
		 * 
		 * WARNING: Activating fullscreen mode causes this method to be fired twice by the Flash Player
		 * for some unknown reason.
		 * 
		 * Any modification to this method should take this into account and protect against repeat calls
		 */
		private function onFocus(e:Event = null):void{
			if(focusPrompt.parent) focusPrompt.parent.removeChild(focusPrompt);
			if(state == UNFOCUSED) state = focusPreviousState;
			if(state != MENU && !fullscreenToggled) regainedFocus = true;
			if(fullscreenToggled) fullscreenToggled = false;
		}
		
	}
	
}