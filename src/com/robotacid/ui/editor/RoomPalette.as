package com.robotacid.ui.editor {
	import com.robotacid.engine.Level;
	import com.robotacid.engine.Room;
	import com.robotacid.gfx.BlitClip;
	import com.robotacid.gfx.BlitRect;
	import com.robotacid.gfx.Renderer;
	import com.robotacid.ui.BlitButton;
	import com.robotacid.ui.FileManager;
	import com.robotacid.ui.UIManager;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	/**
	 * Provides UI options for the RoomPainter
	 * 
	 * @author Aaron Steed, robotacid.com
	 */
	public class RoomPalette {
		
		public static var game:Game;
		public static var renderer:Renderer;
		
		public var uiManager:UIManager;
		public var property:int;
		public var properties:Array/*BlitButton*/;
		public var propertyButton:BlitButton;
		public var playButton:BlitButton;
		public var scrollButton:BlitButton;
		public var optionsButton:BlitButton;
		public var back:BlitButton;
		public var controlsButton:BlitButton;
		public var soundButton:BlitButton;
		public var fullscreenButton:BlitButton;
		public var checkButton:BlitButton;
		public var orientationButton:BlitButton;
		public var propertyLegal:Boolean;
		
		private var paletteRight:Boolean;
		private var paletteButtons:Array;
		
		private var playerButton:BlitButton;
		private var generatorButton:BlitButton;
		private var turnerButton:BlitButton;
		
		private var i:int;
		private var button:BlitButton;
		
		public function RoomPalette(level:Level) {
			uiManager = new UIManager();
			uiManager.selectSoundCallback = game.selectSound;
			
			// PALETTE
			paletteRight = Boolean(UserData.settings.paletteLeft);
			back = uiManager.addButton(0, Game.SCALE + ((Game.HEIGHT * 0.5 - renderer.roomPaletteBlit.height * 0.5) >> 0), renderer.roomPaletteBlit, null, new Rectangle(0, 0, Game.SCALE * 4, Game.SCALE * 8));
			// properties
			propertyLegal = true;
			properties = [];
			var generator:int = Room.GENERATOR | Room.TIMER_0;
			var allyCancel:int = Room.INDESTRUCTIBLE | Room.ALLY | Room.ENEMY | Room.WALL | generator | Room.UP_DOWN_LEFT_RIGHT | Room.M_UP_DOWN_LEFT_RIGHT;
			var enemyCancel:int = Room.INDESTRUCTIBLE | Room.ALLY | Room.SWAP | Room.ENEMY | Room.UP_DOWN_LEFT_RIGHT | Room.M_UP_DOWN_LEFT_RIGHT;
			var nonTrapCancel:int = Room.INDESTRUCTIBLE | Room.ALLY | Room.TURNER | Room.MOVER | Room.VIRUS;
			addPropertyButton(Game.SCALE * 0, Game.SCALE * 0, Room.INDESTRUCTIBLE | Room.WALL, -1, true);
			playerButton = addPropertyButton(Game.SCALE * 1, Game.SCALE * 0, Room.PLAYER | Room.ALLY, allyCancel | Room.BOMB, true);
			addPropertyButton(Game.SCALE * 2, Game.SCALE * 0, Room.ALLY | Room.SWAP, allyCancel, true);
			addPropertyButton(Game.SCALE * 3, Game.SCALE * 0, Room.WALL | Room.SWAP, allyCancel, true);
			addPropertyButton(Game.SCALE * 0, Game.SCALE * 1, Room.WALL, Room.ALLY | Room.SWAP | Room.WALL, true);
			addPropertyButton(Game.SCALE * 1, Game.SCALE * 1, Room.BOMB, Room.PLAYER | Room.INDESTRUCTIBLE | Room.BOMB, true);
			generatorButton = addPropertyButton(Game.SCALE * 2, Game.SCALE * 1, generator, Room.ALLY | Room.INDESTRUCTIBLE | generator | Room.SWAP, true);
			generatorButton.heldCallback = propertyHeldCallback;
			addPropertyButton(Game.SCALE * 3, Game.SCALE * 1, Room.ENEMY | Room.VIRUS, enemyCancel, true);
			turnerButton = addPropertyButton(Game.SCALE * 0, Game.SCALE * 2, Room.ENEMY | Room.TURNER | Room.UP, enemyCancel, true);
			turnerButton.heldCallback = propertyHeldCallback;
			addPropertyButton(Game.SCALE * 1, Game.SCALE * 2, Room.ENEMY | Room.MOVER | Room.M_LEFT | Room.M_RIGHT, enemyCancel, true);
			addPropertyButton(Game.SCALE * 2, Game.SCALE * 2, Room.ENEMY | Room.MOVER | Room.M_UP | Room.M_DOWN, enemyCancel, true);
			addPropertyButton(Game.SCALE * 3, Game.SCALE * 2, Room.ENEMY | Room.MOVER | Room.M_UP_DOWN_LEFT_RIGHT, enemyCancel, true);
			addPropertyButton(Game.SCALE * 0, Game.SCALE * 3, Room.ENEMY | Room.TRAP | Room.M_UP, nonTrapCancel | Room.M_UP, true);
			addPropertyButton(Game.SCALE * 1, Game.SCALE * 3, Room.ENEMY | Room.TRAP | Room.M_RIGHT, nonTrapCancel | Room.M_RIGHT, true);
			addPropertyButton(Game.SCALE * 2, Game.SCALE * 3, Room.ENEMY | Room.TRAP | Room.M_DOWN, nonTrapCancel | Room.M_DOWN, true);
			addPropertyButton(Game.SCALE * 3, Game.SCALE * 3, Room.ENEMY | Room.TRAP | Room.M_LEFT, nonTrapCancel | Room.M_LEFT, true);
			
			var buttonRect:Rectangle = new Rectangle(0, 0, renderer.propertyButtonBlit.width, renderer.propertyButtonBlit.height);
			var border:int = 2;
			propertyButton = uiManager.addButton(2 * Game.SCALE + border, back.y + 4 * Game.SCALE + border, renderer.propertyButtonBlit, clearProperty, buttonRect);
			playButton = uiManager.addButton(0 * Game.SCALE + border, back.y + 6 * Game.SCALE + border, renderer.playButtonBlit, playRoom, buttonRect);
			uiManager.addButton(2 * Game.SCALE + border, back.y + 6 * Game.SCALE + border, renderer.swapButtonBlit, togglePaletteSide, buttonRect);
			scrollButton = uiManager.addButton(0 * Game.SCALE + border, back.y + 4 * Game.SCALE + border, renderer.scrollButtonBlit, toggleScroll, buttonRect);
			scrollButton.active = !renderer.camera.dragScroll;
			paletteButtons = uiManager.buttons.slice();
			if(paletteRight){
				togglePaletteSide(false);
			}
			
			optionsButton = uiManager.addButton(Game.WIDTH - renderer.settingsButtonBlit.width, 0, renderer.settingsButtonBlit, options);
			
			// OPTIONS
			uiManager.addGroup();
			uiManager.changeGroup(1);
			uiManager.addButton(Game.WIDTH - renderer.settingsButtonBlit.width, 0, renderer.settingsButtonBlit, cancel);
			var buttonXs:Array = UIManager.distributeRects(Game.WIDTH * 0.5, buttonRect.width, 4, 4);
			var buttonYs:Array = UIManager.distributeRects(Game.HEIGHT * 0.5, buttonRect.height, 4, 2);
			var buttonY:Number;// = Game.HEIGHT * 0.5 - Game.SCALE + border;
			buttonY = buttonYs[0];
			uiManager.addButton(buttonXs[0], buttonY, renderer.cancelButtonBlit, quit, buttonRect);
			uiManager.addButton(buttonXs[1], buttonY, renderer.loadButtonBlit, load, buttonRect);
			uiManager.addButton(buttonXs[2], buttonY, renderer.saveButtonBlit, save, buttonRect);
			checkButton = uiManager.addButton(buttonXs[3], buttonY, renderer.checkButtonBlit, level.toggleCheckView, buttonRect);
			checkButton.active = level.checkView;
			
			// mobile buttons
			buttonY = buttonYs[1];
			buttonXs = UIManager.distributeRects(Game.WIDTH * 0.5, buttonRect.width, 4, 2);
			controlsButton = uiManager.addButton(buttonXs[0], buttonY, renderer.controlsButtonBlit, level.toggleControls, buttonRect);
			controlsButton.active = level.tapControls;
			orientationButton = uiManager.addButton(buttonXs[1], buttonY, renderer.orientationButtonBlit, game.toggleOrientation, buttonRect);
			// desktop buttons
			soundButton = uiManager.addButton(buttonXs[0], buttonY, renderer.soundButtonBlit, level.toggleSound, buttonRect);
			soundButton.active = level.soundButton.active;
			fullscreenButton = uiManager.addButton(buttonXs[1], buttonY, renderer.fullscreenButtonBlit, level.toggleFullscreen, buttonRect);
			fullscreenButton.active = level.fullscreenButton.active;
			fullscreenButton.feedCallbackToEvent = true;
			if(!Game.MOBILE){
				controlsButton.visible = false;
				orientationButton.visible = false;
			} else {
				soundButton.visible = false;
				fullscreenButton.visible = false;
			}
			uiManager.changeGroup(0);
		}
		
		private function addPropertyButton(x:Number, y:Number, property:int, cancels:int, silent:Boolean = false):BlitButton{
			var button:BlitButton = uiManager.addButton(x, y + back.y, game.level.getPropertyBlit(property), propertySelect, new Rectangle(0, 0, Game.SCALE, Game.SCALE), false);
			button.id = property;
			button.active = false;
			button.targetId = cancels;
			button.frame = button.blit is BlitClip ? (button.blit as BlitClip).frame : 0;
			button.focusLock = false;
			button.silent = silent;
			properties.push(button);
			return button;
		}
		
		public function main():void{
			if(UIManager.dialog){
				UIManager.dialog.update(game.mouseX, game.mouseY, game.mousePressed, game.mousePressedCount == game.frameCount);
			} else {
				uiManager.update(game.mouseX, game.mouseY, game.mousePressed, game.mousePressedCount == game.frameCount);
				renderer.camera.uiStopDrag = uiManager.mouseOver || uiManager.mouseLock;
				playButton.visible = Boolean(game.level.data.map[game.level.data.player.y][game.level.data.player.x] & Room.PLAYER);
			}
		}
		
		private function propertySelect():void{
			var id:int, cancels:int;
			button = uiManager.lastButton;
			if(button == playerButton) pressPlayer();
			var active:Boolean = !button.active;
			cancels = button.targetId;
			//if(!button.active) cancels = button.id | cancels;
			property = 0;
			
			for(i = 0; i < properties.length; i++){
				button = properties[i];
				if(cancels & button.id){
					button.active = false;
					continue;
				}
				if(button.active) property |= button.id;
			}
			
			if(active){
				property |= uiManager.lastButton.id;
				uiManager.lastButton.active = true;
			}
			propertyLegal = (property & (Room.WALL | Room.ENEMY | Room.ALLY)) || property == 0;
		}
		
		private function propertyHeldCallback():void{
			var dir:int, mask:int, amount:int, button:BlitButton;
			button = uiManager.lastButton;
			if(button == turnerButton){
				mask = Room.UP_DOWN_LEFT_RIGHT;
				amount = -1;
			} else if(button == generatorButton){
				mask = Room.TIMER_0 | Room.TIMER_1 | Room.TIMER_2 | Room.TIMER_3;
				amount = 1;
			}
			button.id = Room.rotateBits(button.id, amount, mask, 4);
			button.blit = game.level.getPropertyBlit(button.id);
			button.frame = button.blit is BlitClip ? (button.blit as BlitClip).frame : 0;
			if(button.active){
				property &= ~mask;
				property |= button.id;
			}
		}
		
		private function clearProperty():void{
			property = 0;
			for(i = 0; i < properties.length; i++){
				button = properties[i];
				button.active = false;
			}
		}
		
		private function toggleScroll():void{
			renderer.camera.toggleDragScroll();
			scrollButton.active = !renderer.camera.dragScroll;
			renderer.trackPlayer = false;
			renderer.camera.setTarget(-renderer.camera.canvas.x + Game.WIDTH * 0.5, -renderer.camera.canvas.y + Game.HEIGHT * 0.5);
		}
		
		private function togglePaletteSide(saveSettings:Boolean = true):void{
			var i:int, button:BlitButton;
			var step:Number = Game.WIDTH - Game.SCALE * 4;
			paletteRight = !paletteRight;
			if(!paletteRight) step = -step;
			for(i = 0; i < paletteButtons.length; i++){
				button = paletteButtons[i];
				button.x += step;
			}
			UserData.settings.paletteRight = paletteRight;
			if(saveSettings){
				UserData.push(true);
			}
		}
		
		private function playRoom():void{
			game.currentLevelObj = game.level.data.saveData();
			game.roomPainter.setActive(false);
		}
		
		private function pressPlayer():void{
			if(scrollButton.active){
				renderer.trackPlayer = true;
			}
		}
		
		private function options():void{
			uiManager.changeGroup(1);
		}
		
		private function load():void{
			confirmDialog(confirmLoad);
		}
		
		private function confirmLoad():void{
			game.level.data.loadData(Library.levels[game.currentLevel]);
			UIManager.closeDialog();
		}
		
		private function save():void{
			confirmDialog(confirmSave);
		}
		
		private function toggleControls():void{
			game.level.toggleControls();
		}
		
		private function confirmSave():void{
			var obj:Object = game.level.data.saveData();
			Library.levels[game.currentLevel] = obj;
			game.currentLevelObj = obj;
			if(Boolean(Library.saveUserLevelsCallback)) Library.saveUserLevelsCallback();
			UIManager.closeDialog();
		}
		
		private function confirmDialog(callback:Function):void{
			if(UIManager.dialog) UIManager.closeDialog();
			UIManager.confirmDialog(
				Game.WIDTH * 0.5 - renderer.confirmPanelBlit.width * 0.5,
				Game.HEIGHT * 0.5 - renderer.confirmPanelBlit.height * 0.5,
				renderer.confirmPanelBlit,
				callback,
				renderer.confirmButtonBlit,
				renderer.cancelButtonBlit,
				null,
				game.selectSound
			);
		}
		
		private function levelLoaded():void{
			game.level.data.loadData(JSON.parse(FileManager.data.readUTFBytes(FileManager.data.length)));
		}
		
		private function cancel():void{
			uiManager.changeGroup(0);
		}
		
		private function quit():void{
			
			game.transition.begin(game.quit, 10, 10);
		}
		
		private function getTimerFrame(n:int):int{
			if(n & Room.TIMER_0) return 3;
			else if(n & Room.TIMER_1) return 0;
			else if(n & Room.TIMER_2) return 1;
			else if(n & Room.TIMER_3) return 2;
			return 4;
		}
		
		public function render():void{
			var blit:BlitRect;
			if(uiManager.currentGroup == 1){
				renderer.guiBitmapData.copyPixels(renderer.darkBitmapData, renderer.darkBitmapData.rect, new Point(), null, null, true);
			}
			uiManager.render(renderer.guiBitmapData);
			if(uiManager.currentGroup == 0){
				for(i = 0; i < properties.length; i++){
					button = properties[i];
					if(button.active){
						renderer.propertySelectedBlit.x = button.x;
						renderer.propertySelectedBlit.y = button.y;
						renderer.propertySelectedBlit.render(renderer.guiBitmapData);
						button.render(renderer.guiBitmapData);
					}
				}
				if(property){
					game.level.renderProperty(propertyButton.x + 2, propertyButton.y + 2, property, renderer.guiBitmapData, false);
				}
				if(renderer.camera.dragScroll){
					renderer.lockedBlit.x = propertyButton.x + 2;
					renderer.lockedBlit.y = propertyButton.y + 2;
					renderer.lockedBlit.render(renderer.guiBitmapData);
				}
				if(generatorButton.over){
					renderer.timerCountBlit.x = generatorButton.x - 0;
					renderer.timerCountBlit.y = generatorButton.y - 0;
					renderer.timerCountBlit.render(renderer.guiBitmapData, getTimerFrame(generatorButton.id));
					if(generatorButton.held && (property & Room.GENERATOR)){
						renderer.timerCountBlit.x = propertyButton.x + 2;
						renderer.timerCountBlit.y = propertyButton.y + 2;
						renderer.timerCountBlit.render(renderer.guiBitmapData, getTimerFrame(property));
					}
				}
			}
			if(UIManager.dialog) UIManager.dialog.render(renderer.guiBitmapData);
		}
		
	}

}