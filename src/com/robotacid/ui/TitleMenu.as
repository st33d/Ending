package com.robotacid.ui {
	import com.robotacid.engine.Level;
	import com.robotacid.engine.LevelData;
	import com.robotacid.engine.Room;
	import com.robotacid.gfx.Renderer;
	import flash.display.BitmapData;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	/**
	 * The entry point into the game
	 * 
	 * @author Aaron Steed, robotacid.com
	 */
	public class TitleMenu {
		
		public static var game:Game;
		public static var renderer:Renderer;
		
		public var uiManager:UIManager;
		public var scoreTextBox:TextBox;
		
		private var i:int, r:int, c:int;
		private var puzzleButton:BlitButton;
		private var adventureButton:BlitButton;
		private var editorButton:BlitButton;
		private var leftButton:BlitButton;
		private var rightButton:BlitButton;
		private var backButton:BlitButton;
		private var saveToDesktopButton:BlitButton;
		private var loadFromDesktopButton:BlitButton;
		private var levelButtons:Array/*BlitButton*/;
		private var levelButtonRect:Rectangle;
		private var firstLevel:int;
		private var buttonInHand:BlitButton;
		private var prevButtonX:Number;
		private var prevButtonY:Number;
		private var sourceLevel:Object;
		private var targetLevel:Object;
		private var sourceId:int;
		private var targetId:int;
		private var mapCopyBuffer:Array/*Array*/;
		
		public static const ROOT:int = 0;
		public static const PUZZLE_LEVELS:int = 1;
		public static const ADVENTURE:int = 2;
		public static const EDITOR_LEVELS:int = 3;
		
		public static const BUTTON_HEIGHT:Number = 12;
		
		public static const LEVEL_BUTTONS_WIDE:int = 5;
		public static const LEVEL_BUTTONS_HIGH:int = 4;
		public static const PAGE_LEVELS:int = LEVEL_BUTTONS_WIDE * LEVEL_BUTTONS_HIGH;
		public static const LEVEL_BUTTON_GAP:int = 2;
		
		public function TitleMenu() {
			uiManager = new UIManager();
			uiManager.selectSoundCallback = game.selectSound;
			levelButtonRect = new Rectangle(0, 0, renderer.numberButtonBlit.width - 1, renderer.numberButtonBlit.height - 1);
			
			mapCopyBuffer = Room.create2DArray(Level.ROOM_WIDTH, Level.ROOM_HEIGHT);
			
			// puzzle, adventure, editor
			puzzleButton = uiManager.addButton(Game.WIDTH * 0.5 - renderer.puzzleButtonBlit.width * 2, Game.HEIGHT * 0.5 - renderer.puzzleButtonBlit.height * 0.5, renderer.puzzleButtonBlit, puzzlePressed);
			adventureButton = uiManager.addButton(Game.WIDTH * 0.5 - renderer.adventureButtonBlit.width * 0.5, Game.HEIGHT * 0.5 - renderer.adventureButtonBlit.height * 0.5, renderer.adventureButtonBlit, adventurePressed);
			editorButton = uiManager.addButton(Game.WIDTH * 0.5 + renderer.editorButtonBlit.width, Game.HEIGHT * 0.5 - renderer.editorButtonBlit.height * 0.5, renderer.editorButtonBlit, puzzlePressed);
			
			// level button grid
			uiManager.addGroup();
			uiManager.changeGroup(1);
			levelButtons = [];
			var buttonX:Number = Game.WIDTH * 0.5 - ((LEVEL_BUTTONS_WIDE - 1) * LEVEL_BUTTON_GAP + levelButtonRect.width * LEVEL_BUTTONS_WIDE) * 0.5;
			var buttonY:Number = Game.HEIGHT * 0.5 - ((LEVEL_BUTTONS_HIGH - 1) * LEVEL_BUTTON_GAP + levelButtonRect.height * LEVEL_BUTTONS_HIGH) * 0.5;
			var levelButton:BlitButton;
			for(r = 0; r < LEVEL_BUTTONS_HIGH; r++){
				for(c = 0; c < LEVEL_BUTTONS_WIDE; c++){
					levelButton = uiManager.addButton(
						buttonX + c * (levelButtonRect.width + LEVEL_BUTTON_GAP),
						buttonY + r * (levelButtonRect.height + LEVEL_BUTTON_GAP),
						renderer.numberButtonBlit, levelPressed, levelButtonRect
					);
					levelButton.releaseCallback = levelReleased;
					levelButton.id = c + r * LEVEL_BUTTONS_WIDE;
					levelButton.targetId = 1;
					levelButtons.push(levelButton);
				}
			}
			var border:int = 2;
			var buttonRect:Rectangle = new Rectangle(0, 0, renderer.cancelButtonBlit.width, renderer.cancelButtonBlit.height);
			leftButton = uiManager.addButton(Game.WIDTH * 0.5 - 3 * Game.SCALE + border, Game.HEIGHT - Game.SCALE * 2 + border, renderer.leftButtonBlit, directionPressed, buttonRect);
			leftButton.visible = false;
			backButton = uiManager.addButton(Game.WIDTH * 0.5 - 1 * Game.SCALE + border, Game.HEIGHT - Game.SCALE * 2 + border, renderer.cancelButtonBlit, backPressed, buttonRect);
			rightButton = uiManager.addButton(Game.WIDTH * 0.5 + 1 * Game.SCALE + border, Game.HEIGHT - Game.SCALE * 2 + border, renderer.rightButtonBlit, directionPressed, buttonRect);
			if(!Game.MOBILE){
				loadFromDesktopButton = uiManager.addButton(Game.WIDTH * 0.5 - 5 * Game.SCALE + border, Game.HEIGHT - Game.SCALE * 2 + border, renderer.loadButtonBlit, loadFromDesktop, buttonRect);
				loadFromDesktopButton.feedCallbackToEvent = true;
				saveToDesktopButton = uiManager.addButton(Game.WIDTH * 0.5 + 3 * Game.SCALE + border, Game.HEIGHT - Game.SCALE * 2 + border, renderer.saveButtonBlit, saveToDesktop, buttonRect);
				saveToDesktopButton.feedCallbackToEvent = true;
			}
			scoreTextBox = new TextBox(Game.WIDTH, 8, 0x0, 0x0);
			scoreTextBox.align = "center";
			if(UserData.settings.best){
				setScore(UserData.settings.best);
			}
			uiManager.changeGroup(0);
		}
		
		public function main():void{
			if(UIManager.dialog){
				UIManager.dialog.update(
					game.mouseX,
					game.mouseY,
					game.mousePressed,
					game.mousePressedCount == game.frameCount,
					game.mouseReleasedCount == game.frameCount
				);
			} else {
				uiManager.update(
					game.mouseX,
					game.mouseY,
					game.mousePressed,
					game.mousePressedCount == game.frameCount,
					game.mouseReleasedCount == game.frameCount
				);
				if(game.editing){
					if(buttonInHand && buttonInHand.heldCount == 0){
						buttonInHand.x = game.mouseX - buttonInHand.blit.width * 0.5;
						buttonInHand.y = game.mouseY - buttonInHand.blit.height * 0.5;
					}
				}
			}
		}
		
		public function setScore(n:int):void{
			scoreTextBox.text = "" + n;
			scoreTextBox.bitmapData.colorTransform(scoreTextBox.bitmapData.rect, Renderer.UI_COL_TRANSFORM);
		}
		
		private function adventurePressed():void{
			game.editing = false;
			game.setNextGame(Room.ADVENTURE);
			game.transition.begin(game.initLevel, 10, 10, "@", 15);
		}
		
		private function puzzlePressed():void{
			game.editing = uiManager.lastButton == editorButton;
			if(game.editing){
				Library.setLevels(false);
				if(loadFromDesktopButton) loadFromDesktopButton.visible = true;
				if(saveToDesktopButton) saveToDesktopButton.visible = true;
			} else {
				Library.setLevels(true);
				if(loadFromDesktopButton) loadFromDesktopButton.visible = false;
				if(saveToDesktopButton) saveToDesktopButton.visible = false;
			}
			// restore puzzle progress from app exit if available
			if(!game.editing && UserData.settings.puzzleData){
				var n:int = UserData.settings.puzzleLevel;
				var str:String = (n < 10 ? "0" : "") + n;
				game.setNextGame(Room.PUZZLE, n);
				game.transition.begin(game.initLevel, 10, 10, str, 15);
			} else {
				if(firstLevel > Library.maxLevel) firstLevel = 0;
				if(firstLevel == 0){
					leftButton.visible = false;
				} else {
					leftButton.visible = true;
				}
				if(firstLevel < Library.maxLevel - PAGE_LEVELS){
					rightButton.visible = true;
				} else {
					rightButton.visible = false;
				}
				uiManager.changeGroup(PUZZLE_LEVELS);
			}
		}
		
		private function backPressed():void{
			uiManager.changeGroup(ROOT);
		}
		
		private function levelPressed():void{
			if(!game.editing){
				var n:int = uiManager.lastButton.id + firstLevel;
				var str:String = (n < 10 ? "0" : "") + n;
				game.setNextGame(Room.PUZZLE, n);
				game.transition.begin(game.initLevel, 10, 10, str, 15);
			} else {
				buttonInHand = uiManager.lastButton;
				sourceId = buttonInHand.id + firstLevel;
				sourceLevel = Library.levels[sourceId];
				targetLevel = null;
				prevButtonX = uiManager.lastButton.x;
				prevButtonY = uiManager.lastButton.y;
				
			}
		}
		
		private function levelReleased():void{
			if(buttonInHand){
				buttonInHand.x = prevButtonX;
				buttonInHand.y = prevButtonY;
				var i:int, overButton:BlitButton;
				var x:int = Game.WIDTH * 0.5 - renderer.levelMovePanelBlit.width * 0.5;
				var y:int = Game.HEIGHT * 0.5 - renderer.levelMovePanelBlit.height * 0.5;
				for(i = 0; i < uiManager.buttonsOver.length; i++){
					overButton = uiManager.buttonsOver[i];
					if(overButton != buttonInHand){
						if(overButton.targetId){
							var step:int = renderer.cancelButtonBlit.width + 1;
							UIManager.openDialog(
								[
									new Point(x, y),
									new Point(x + 3, y + 3),
									new Point(x + 3 + (step * 1), y + 3),
									new Point(x + 3 + (step * 2), y + 3),
									new Point(x + 3 + (step * 3), y + 3),
									new Point(x + 3 + (step * 4), y + 3)
								],
								[
									renderer.levelMovePanelBlit,
									renderer.cancelButtonBlit,
									renderer.insertBeforeButtonBlit,
									renderer.insertAfterButtonBlit,
									renderer.swapButtonBlit,
									renderer.saveButtonBlit
								],
								[
									null,
									UIManager.closeDialog,
									insertBefore,
									insertAfter,
									swapLevels,
									writeSourceToTarget
								],
								game.selectSound
							);
							// swap init
							targetId = firstLevel + overButton.id;
							targetLevel = Library.levels[targetId];
							overButton.over = false;
							buttonInHand.over = false;
							buttonInHand = null;
							uiManager.buttonsOver.length = 0;
							return;
						} else {
							if(overButton == backButton){
								confirmDialog(deleteLevelDialog);
							} else if(overButton == rightButton){
								targetId = sourceId + PAGE_LEVELS;
								insertAfter();
							} else if(overButton == leftButton){
								targetId = sourceId - PAGE_LEVELS;
								insertBefore();
							}
						}
					}
				}
				buttonInHand = null;
			}
			if(game.editing && uiManager.lastButton.heldCount){
				var n:int = uiManager.lastButton.id + firstLevel;
				var str:String = (n < 10 ? "0" : "") + n;
				game.setNextGame(Room.PUZZLE, n);
				game.transition.begin(game.initLevel, 10, 10, str, 30);
			}
		}
		
		public function deleteLevelDialog():void{
			Library.levels[sourceId] = null;
			sourceLevel = null;
			if(Boolean(Library.saveUserLevelsCallback)) Library.saveUserLevelsCallback();
			UIManager.closeDialog();
		}
		
		public function swapLevels():void{
			if(!targetLevel) return;
			Library.levels[sourceId] = targetLevel;
			Library.levels[targetId] = sourceLevel;
			sourceLevel = Library.levels[sourceId];
			targetLevel = Library.levels[targetId];
			sourceId ^= targetId;
			targetId ^= sourceId;
			sourceId ^= targetId;
			if(Boolean(Library.saveUserLevelsCallback)) Library.saveUserLevelsCallback();
		}
		
		public function writeSourceToTarget():void{
			if(!targetLevel){
				targetLevel = LevelData.saveObject(Level.ROOM_WIDTH, Level.ROOM_HEIGHT);
			}
			confirmDialog(confirmWrite);
		}
		
		private function confirmWrite():void{
			LevelData.writeToObject(sourceLevel, targetLevel, Level.ROOM_WIDTH, Level.ROOM_HEIGHT);
			Library.levels[targetId] = targetLevel;
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
				game.selectSound
			);
		}
		
		private function insertAfter():void{
			Library.levels.splice(sourceId, 1);
			if(targetId < sourceId) targetId++;
			Library.levels.splice(targetId, 0, sourceLevel);
			if(Boolean(Library.saveUserLevelsCallback)) Library.saveUserLevelsCallback();
			UIManager.closeDialog();
		}
		
		private function insertBefore():void{
			Library.levels.splice(sourceId, 1);
			if(targetId > sourceId) targetId--;
			Library.levels.splice(targetId, 0, sourceLevel);
			if(Boolean(Library.saveUserLevelsCallback)) Library.saveUserLevelsCallback();
			UIManager.closeDialog();
		}
		
		private function directionPressed():void{
			if(uiManager.lastButton == leftButton){
				if(firstLevel > 0){
					firstLevel -= PAGE_LEVELS;
					if(firstLevel == 0){
						leftButton.visible = false;
					}
					rightButton.visible = true;
				}
			} else if(uiManager.lastButton == rightButton){
				if(firstLevel <= Library.maxLevel - PAGE_LEVELS){
					firstLevel += PAGE_LEVELS;
					if(firstLevel > Library.maxLevel - PAGE_LEVELS){
						rightButton.visible = false;
					}
					leftButton.visible = true;
				}
			}
		}
		
		private function loadFromDesktop():void{
			FileManager.load(levelsLoaded);
		}
		
		private function levelsLoaded():void{
			if(FileManager.data){
				try{
					Library.USER_LEVELS = JSON.parse(FileManager.data.readUTFBytes(FileManager.data.length)) as Array;
					Library.levels = Library.USER_LEVELS;
				} catch(e:Error){
				}
			};
		}
		
		private function saveToDesktop():void{
			FileManager.save(JSON.stringify(Library.USER_LEVELS), "levels.json");
		}
		
		public function renderPreview(obj:Object, x:Number, y:Number, target:BitmapData):void{
			var bitmapData:BitmapData = Level.getLevelBitmapData(obj.map, Level.ROOM_WIDTH, Level.ROOM_HEIGHT);
			var p:Point = new Point(x, y);
			target.copyPixels(bitmapData, bitmapData.rect, p);
		}
		
		public function render():void{
			uiManager.render(renderer.guiBitmapData);
			
			if(uiManager.currentGroup == ROOT){
				renderer.guiBitmapData.copyPixels(scoreTextBox.bitmapData, scoreTextBox.bitmapData.rect, new Point(0, adventureButton.y + adventureButton.blit.height), null, null, true);
			} else if(uiManager.currentGroup == PUZZLE_LEVELS){
				var i:int, button:BlitButton;
				for(r = 0; r < LEVEL_BUTTONS_HIGH; r++){
					for(c = 0; c < LEVEL_BUTTONS_WIDE; c++){
						i = c + r * LEVEL_BUTTONS_WIDE;
						button = levelButtons[i];
						button.visible = true;
						if(!game.editing){
							if(firstLevel + i > Library.maxLevel){
								button.visible = false;
								continue;
							}
						}
						if(Library.levels[firstLevel + i]){
							if(!game.editing){
								if(!UserData.settings.completed[firstLevel + i]){
									renderer.notCompletedBlit.x = button.x;
									renderer.notCompletedBlit.y = button.y;
									renderer.notCompletedBlit.render(renderer.guiBitmapData);
								}
							}
							renderer.numberBlit.setValue(firstLevel + i);
							renderer.numberBlit.x = button.x + 2;
							renderer.numberBlit.y = button.y + 2;
							renderer.numberBlit.renderNumbers(renderer.guiBitmapData);
							
						}
					}
				}
				if(game.editing && game.transition.dir <= 0){
					if(!UIManager.dialog){
						if(!(Game.MOBILE && game.mouseReleasedCount == game.frameCount)){
							for(i = uiManager.buttonsOver.length - 1; i > -1; i--){
								button = uiManager.buttonsOver[i];
								if(button.targetId && Library.levels[firstLevel + button.id]){
									button.render(renderer.guiBitmapData);
									renderer.numberBlit.setValue(firstLevel + button.id);
									renderer.numberBlit.x = button.x + 2;
									renderer.numberBlit.y = button.y + 2;
									renderer.numberBlit.renderNumbers(renderer.guiBitmapData);
									renderer.levelPreviewPanelBlit.x = button.x;
									renderer.levelPreviewPanelBlit.y = (
										button == buttonInHand ? button.y - (Level.ROOM_HEIGHT + 3) : button.y + button.blit.height
									);
									renderer.levelPreviewPanelBlit.render(renderer.guiBitmapData);
									renderPreview(Library.levels[firstLevel + button.id], renderer.levelPreviewPanelBlit.x + 1, renderer.levelPreviewPanelBlit.y + 1, renderer.guiBitmapData);
								}
							}
						}
					} else {
						if(sourceLevel || targetLevel){
							button = UIManager.dialog.buttons[0];
							renderer.levelPreviewPanelBlit.x = button.x + button.blit.width * 0.5 - renderer.levelPreviewPanelBlit.width * 0.5;
							if(sourceLevel){
								renderer.levelPreviewPanelBlit.y = button.y - (Level.ROOM_HEIGHT + 3);
								renderer.levelPreviewPanelBlit.render(renderer.guiBitmapData);
								renderPreview(sourceLevel, renderer.levelPreviewPanelBlit.x + 1, renderer.levelPreviewPanelBlit.y + 1, renderer.guiBitmapData);
							}
							if(targetLevel){
								renderer.levelPreviewPanelBlit.y = button.y + button.blit.height;
								renderer.levelPreviewPanelBlit.render(renderer.guiBitmapData);
								renderPreview(targetLevel, renderer.levelPreviewPanelBlit.x + 1, renderer.levelPreviewPanelBlit.y + 1, renderer.guiBitmapData);
							}
						}
					}
				}
				if(UIManager.dialog) UIManager.dialog.render(renderer.guiBitmapData);
				
			}
		}
		
	}

}