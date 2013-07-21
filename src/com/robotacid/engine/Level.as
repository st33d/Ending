package com.robotacid.engine {
	import com.robotacid.gfx.BlitClip;
	import com.robotacid.gfx.BlitRect;
	import com.robotacid.gfx.BlitSprite;
	import com.robotacid.gfx.FadingBlitClip;
	import com.robotacid.gfx.FoodClockFX;
	import com.robotacid.gfx.Renderer;
	import com.robotacid.sound.SoundManager;
	import com.robotacid.ui.BlitButton;
	import com.robotacid.ui.TextBox;
	import com.robotacid.ui.Key;
	import com.robotacid.ui.UIManager;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Shape;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.ui.Keyboard;
	import flash.utils.getTimer;
	/**
	 * Buffer between the game logic and the architecture
	 * 
	 * Input and rendering is handled at this tier.
	 * 
	 * This class requires heavy butchering to port to new languages. Show no mercy.
	 * 
	 * @author Aaron Steed, robotacid.com
	 */
	public class Level {
		
		public static var renderer:Renderer;
		public static var game:Game;
		
		public var data:LevelData;
		public var previousData:LevelData;
		public var room:Room;
		public var blackOutMap:Array;
		public var endingKillList:Array;
		
		public var uiManager:UIManager;
		public var foodClockGfx:FoodClockFX;
		public var checkButton:BlitButton;
		public var settingsButton:BlitButton;
		public var controlsButton:BlitButton;
		public var orientationButton:BlitButton;
		public var soundButton:BlitButton;
		public var fullscreenButton:BlitButton;
		public var scoreTextBox:TextBox;
		
		public var active:Boolean;
		public var state:int;
		public var phase:int;
		public var animCount:int;
		public var keyDown:Boolean;
		public var checkView:Boolean;
		public var tapControls:Boolean;
		public var animAccCount:int;
		public var animDelay:int;
		public var moveStep:Number;
		public var restStep:Number;
		public var endingKillCount:int;
		public var endingDir:int;
		
		private var blinkCount:int;
		public var blink:Boolean;
		
		// temp
		private var p:Point;
		
		// states
		public static const IDLE:int = 0;
		public static const ANIMATE:int = 1;
		public static const ENDING_ANIM:int = 2;
		
		// phases
		public static const PLAYER_PHASE:int = 0;
		public static const ENEMY_PHASE:int = 1;
		
		
		public static const SCALE:Number = Game.SCALE;
		public static const INV_SCALE:Number = 1 / Game.SCALE;
		public static const ANIM_FRAMES_MAX:int = 3;
		public static const ANIM_FRAMES_MIN:int = 2;
		public static const ANIM_ACC_DELAY:int = 10;
		public static const BLINK_DELAY:int = 30;
		public static const BLINK_DELAY_VISIBLE:int = 10;
		public static const ENDING_KILL_DELAY:int = 6;
		public static const SEGUE_SPEED:int = 2;
		// turner rotation frames
		public static const TURNER_N:int = 0;
		public static const TURNER_NE:int = 1;
		public static const TURNER_E:int = 2;
		public static const TURNER_SE:int = 3;
		public static const TURNER_S:int = 4;
		public static const TURNER_SW:int = 5;
		public static const TURNER_W:int = 6;
		public static const TURNER_NW:int = 7;
		
		public static const MAP_WIDTH:int = 25;
		public static const MAP_HEIGHT:int = 25;
		public static const ROOM_WIDTH:int = 13;
		public static const ROOM_HEIGHT:int = 13;
		
		public function Level(type:int = Room.PUZZLE, dataObj:Object = null) {
			active = true;
			room = new Room(type, ROOM_WIDTH, ROOM_HEIGHT);
			room.init();
			if(!LevelData.initialised) LevelData.init();
			var dataWidth:int = type == Room.PUZZLE ? ROOM_WIDTH : MAP_WIDTH;
			var dataHeight:int = type == Room.PUZZLE ? ROOM_HEIGHT : MAP_HEIGHT;
			data = new LevelData(room, dataWidth, dataHeight);
			if(dataObj){
				data.loadData(dataObj);
				if(type == Room.PUZZLE){
					blackOutMap = data.getBlackOutMap();
				}
			}
			state = IDLE;
			phase = PLAYER_PHASE;
			animDelay = ANIM_FRAMES_MAX;
			animAccCount = ANIM_ACC_DELAY;
			data.killCallback = kill;
			data.displaceCallback = displaceCamera;
			data.pushCallback = push;
			data.swapCallback = swap;
			data.generateCallback = generate;
			data.endingCallback = ending;
			data.blockedCallback = blocked;
			keyDown = false;
			blink = true;
			// copy player gfx buffer
			renderer.gameSpriteSheet.copyPixels(renderer.gameSpriteSheet, renderer.playerBuffer.rect, new Point(renderer.playerBlit.rect.x, renderer.playerBlit.rect.y));
			foodClockGfx = new FoodClockFX(renderer.playerBlit, Renderer.WALL_COL);
			renderer.numberBlit.setValue(data.food);
			previousData = data.copy();
			
			uiManager = new UIManager();
			uiManager.selectSoundCallback = game.selectSound;
			settingsButton = uiManager.addButton(Game.WIDTH - (renderer.settingsButtonBlit.width), 0, renderer.settingsButtonBlit, openSettings);
			settingsButton.visible = game.hideMouseFrames < Game.HIDE_MOUSE_FRAMES;
			
			uiManager.addGroup();
			uiManager.changeGroup(1);
			uiManager.addButton(Game.WIDTH - (renderer.settingsButtonBlit.width), 0, renderer.settingsButtonBlit, resume);
			var border:int = 2;
			var buttonRect:Rectangle = new Rectangle(0, 0, renderer.propertyButtonBlit.width, renderer.propertyButtonBlit.height);
			var buttonXs:Array = UIManager.distributeRects(Game.WIDTH * 0.5, buttonRect.width, 4, 3);
			var buttonYs:Array = UIManager.distributeRects(Game.HEIGHT * 0.5, buttonRect.height, 4, 2);
			var buttonX:Number;// = Game.HEIGHT * 0.5 - Game.SCALE + border;
			var buttonY:Number;// = Game.HEIGHT * 0.5 - Game.SCALE + border;
			buttonY = buttonYs[0];
			uiManager.addButton(buttonXs[0], buttonY, renderer.cancelButtonBlit, quit, buttonRect);
			uiManager.addButton(buttonXs[1], buttonY, renderer.resetButtonBlit, reset, buttonRect);
			checkButton = uiManager.addButton(buttonXs[2], buttonY, renderer.checkButtonBlit, toggleCheckView, buttonRect);
			checkButton.active = checkView;
			buttonXs = UIManager.distributeRects(Game.WIDTH * 0.5, buttonRect.width, 4, 2);
			// mobile buttons
			buttonY = buttonYs[1];
			controlsButton = uiManager.addButton(buttonXs[0], buttonY, renderer.controlsButtonBlit, toggleControls, buttonRect);
			controlsButton.active = tapControls;
			orientationButton = uiManager.addButton(buttonXs[1], buttonY, renderer.orientationButtonBlit, game.toggleOrientation, buttonRect);
			// desktop buttons
			soundButton = uiManager.addButton(buttonXs[0], buttonY, renderer.soundButtonBlit, toggleSound, buttonRect);
			soundButton.active = !SoundManager.active;
			fullscreenButton = uiManager.addButton(buttonXs[1], buttonY, renderer.fullscreenButtonBlit, toggleFullscreen, buttonRect);
			fullscreenButton.active = game.stage.displayState != "normal";;
			fullscreenButton.feedCallbackToEvent = true;
			if(!Game.MOBILE){
				controlsButton.visible = false;
				orientationButton.visible = false;
			} else {
				soundButton.visible = false;
				fullscreenButton.visible = false;
			}
			
			uiManager.changeGroup(0);
			
			scoreTextBox = new TextBox(Game.WIDTH, 8, 0x0, 0x0);
			scoreTextBox.align = "center";
		}
		
		private function resume():void{
			uiManager.changeGroup(0);
		}
		
		private function quit():void{
			active = false;
			game.transition.begin(game.quit, 10, 10);
		}
		
		private function reset():void{
			var str:String, time:int;
			if(room.type == Room.PUZZLE){
				str = (game.currentLevel < 10 ? "0" : "") + game.currentLevel;
				time = 30;
			} else {
				str = "everything was beautiful\nand nothing hurt";
				time = 45;
			}
			game.transition.begin(game.resetGame, Game.DEATH_FADE_COUNT, Game.DEATH_FADE_COUNT, str, time);
		}
		
		public function toggleControls():void{
			tapControls = !tapControls;
			controlsButton.active = tapControls;
			game.roomPainter.palette.controlsButton.active = tapControls;
			UserData.settings.tapControls = tapControls;
			UserData.push(true);
		}
		
		public function toggleSound():void{
			game.toggleSound();
			soundButton.active = !SoundManager.active;
			game.roomPainter.palette.soundButton.active = !SoundManager.active;
		}
		
		public function toggleFullscreen():void{
			game.toggleFullscreen();
			fullscreenButton.active = game.roomPainter.palette.fullscreenButton.active = game.stage.displayState != "normal";
		}
		
		public function main():void{
			
			var dir:int;
			
			if(uiManager.active) uiManager.update(
				game.mouseX,
				game.mouseY,
				game.mousePressed,
				game.mousePressedCount == game.frameCount
			);
			
			if(state == IDLE){
				if(phase == PLAYER_PHASE){
					
					if(!uiManager.mouseLock && uiManager.currentGroup == 0) dir = getInput();
					
					var playerProperty:int = data.map[data.player.y][data.player.x];
					// don't repeat a blocked move - no dry humping the walls
					if(dir && !((playerProperty & Room.BLOCKED) && (playerProperty & dir))){
						// accelerate animation length
						if(animAccCount){
							if(animDelay > ANIM_FRAMES_MIN) animDelay--;
						}
						animAccCount = ANIM_ACC_DELAY;
						if(!data.blockedDir(dir)) previousData.copyData(data);
						data.playerTurn(dir);
						if(data.map[data.player.y][data.player.x] & Room.BLOCKED){
							game.soundQueue.addRandom("blocked", ["blocked1", "blocked2", "blocked3", "blocked4"]);
						} else {
							game.soundQueue.addRandom("step", ["step1", "step2", "step3"]);
						}
						initAnimate();
					} else {
						if(animAccCount){
							animAccCount--;
							if(animAccCount == 0) animDelay = ANIM_FRAMES_MAX;
						}
					}
				} else if(phase == ENEMY_PHASE){
					data.enemyTurn();
					initAnimate();
					if(!data.alive()) game.soundQueue.addRandom("death", ["death1", "death2", "death3", "death4"]);
				}
			} else if(state == ANIMATE){
				animCount--;
				if(animCount == 0){
					state = IDLE;
					if(phase == PLAYER_PHASE && !(data.map[data.player.y][data.player.x] & Room.BLOCKED)){
						if(data.ended){
							if(room.type == Room.PUZZLE){
								game.puzzleWin();
							} else if(room.type == Room.ADVENTURE){
								state = ENDING_ANIM;
								endingKillList = [];
								data.fillPathMap(data.player.x, data.player.y, null, Room.ENEMY | Room.WALL, endingKillList, Room.DOOR);
								endingKillCount = ENDING_KILL_DELAY;
							}
						} else {
							phase = ENEMY_PHASE;
							blinkCount = BLINK_DELAY_VISIBLE;
						}
						
					} else if(phase == ENEMY_PHASE){
						foodClockGfx.setFood(data.food, LevelData.FOOD_MAX, data.player.x * SCALE, data.player.y * SCALE);
						if(!data.alive()){
							active = false;
							game.death();
						}
						phase = PLAYER_PHASE;
					}
				}
			} else if(state == ENDING_ANIM){
				if(endingKillCount){
					endingKillCount--;
					if(endingKillCount == 0){
						if(endingKillList.length){
							var p:Point = endingKillList.pop();
							data.kill(p.x, p.y, 0);
							endingKillCount = ENDING_KILL_DELAY + Math.random() * ENDING_KILL_DELAY;
						} else {
							if(endingDir & Room.UP){
								renderer.setSlide(0, SEGUE_SPEED);
							} else if(endingDir & Room.RIGHT){
								renderer.setSlide(-SEGUE_SPEED, 0);
							} else if(endingDir & Room.DOWN){
								renderer.setSlide(0, -SEGUE_SPEED);
							} else if(endingDir & Room.LEFT){
								renderer.setSlide(SEGUE_SPEED, 0);
							}
							game.soundQueue.addRandom("adventure", ["adventure1", "adventure2", "adventure3", "adventure4"]);
							game.soundQueue.addRandom("adventureEnding", ["ending1", "ending2", "ending3", "ending4"]);
							game.adventureWin();
						}
					}
				}
			}
			blinkCount--;
			if(blinkCount <= 0) blinkCount = BLINK_DELAY;
			blink = blinkCount >= BLINK_DELAY_VISIBLE;
		}
		
		public function initAnimate():void{
			state = ANIMATE;
			animCount = animDelay;
		}
		
		public function toggleCheckView():void{
			checkView = !checkView;
			checkButton.active = checkView;
			game.roomPainter.palette.checkButton.active = checkView;
			UserData.settings.checkView = checkView;
			UserData.push(true);
		}
		
		public function openSettings():void{
			if(game.editing){
				game.modifiedLevel = true;
				game.level.data.loadData(game.currentLevelObj);
				game.roomPainter.setActive(true);
			} else {
				uiManager.changeGroup(1);
				if(room.type == Room.ADVENTURE){
					scoreTextBox.text = "" + data.turns;
				}
			}
			fullscreenButton.active = game.roomPainter.palette.fullscreenButton.active = game.stage.displayState != "normal";
		}
		
		public function getInput():int{
			var dir:int = 0;
			if(Key.keysPressed == 1){
				if(Key.isDown(Keyboard.UP) || Key.isDown(Key.K) || Key.customDown(Game.UP_KEY) || Key.isDown(Key.NUMBER_8)) dir |= Room.UP;
				if(Key.isDown(Keyboard.LEFT) || Key.isDown(Key.H) || Key.customDown(Game.LEFT_KEY) || Key.isDown(Key.NUMBER_4)) dir |= Room.LEFT;
				if(Key.isDown(Keyboard.RIGHT) || Key.isDown(Key.L) || Key.customDown(Game.RIGHT_KEY) || Key.isDown(Key.NUMBER_6)) dir |= Room.RIGHT;
				if(Key.isDown(Keyboard.DOWN) || Key.isDown(Key.J) || Key.customDown(Game.DOWN_KEY) || Key.isDown(Key.NUMBER_2)) dir |= Room.DOWN;
			}
			if(game.mousePressed){
				if(tapControls){
					if(game.mouseCorner & Room.UP) dir |= Room.UP;
					else if(game.mouseCorner & Room.RIGHT) dir |= Room.RIGHT;
					else if(game.mouseCorner & Room.DOWN) dir |= Room.DOWN;
					else if(game.mouseCorner & Room.LEFT) dir |= Room.LEFT;
				} else {
					dir = game.getMouseSwipe();
				}
			}
			return dir;
		}
		
		public function push(x:int, y:int, dir:int):void{
			if(dir & Room.UP){
				renderer.glitchMap.pushCols(x * SCALE, (x + 1) * SCALE, -3);
			} else if(dir & Room.RIGHT){
				renderer.glitchMap.pushRows(y * SCALE, (y + 1) * SCALE, 3);
			} else if(dir & Room.DOWN){
				renderer.glitchMap.pushCols(x * SCALE, (x + 1) * SCALE, 3);
			} else if(dir & Room.LEFT){
				renderer.glitchMap.pushRows(y * SCALE, (y + 1) * SCALE, -3);
			}
			game.createDistSound(x, y, "push", ["push1", "push2", "push3", "push4"]);
		}
		
		public function swap(x:int, y:int, target:int):void{
			if(target & Room.ALLY){
				game.soundQueue.add("slide");
			} else if(target & Room.SWAP){
				game.soundQueue.add("strangeExchange");
			}
		}
		
		private function blocked(x:int, y:int, dir:int):void {
			game.createDistSound(x, y, "blocked", ["blocked1", "blocked2", "blocked3", "blocked4"], 0.5);
		}
		
		public function generate(x:int, y:int):void{
			game.createDistSound(x, y, "generator", ["generator1", "generator2", "generator3", "generator4"]);
		}
		
		public function kill(x:int, y:int, dir:int, property:int = 0, explosion:int = 0):void{
			if(explosion){
				renderer.addFX(x * SCALE, y * SCALE, renderer.explosionBlit, null, explosion);
			}
			if(property){
				var blit:BlitSprite = getPropertyBlit(property) as BlitSprite;
				var dirs:int = (~Room.rotateBits(dir, 2, Room.UP_DOWN_LEFT_RIGHT, 4)) & Room.UP_DOWN_LEFT_RIGHT;
				if(property & Room.ENDING){
					dirs = dir;
				}
				renderer.bitmapDebris(blit, x, y, dirs);
				if(property & Room.GENERATOR) renderer.bitmapDebris(renderer.generatorBlit, x, y, dirs);
				
				var soundStep:int = 1 + (data.turns % 4);
				
				if(property & Room.TURNER){
					game.createDistSound(x, y, "moverKill"+soundStep);
				} else if(property & Room.VIRUS){
					game.createDistSound(x, y, "virus", ["punchRattle", "hitRattle"]);
				} else if((property & Room.ALLY) && !(property & Room.PLAYER)){
					game.createDistSound(x, y, "ally"+soundStep);
				} else if(property & Room.TRAP){
					game.createDistSound(x, y, "rattle", ["rattle1", "rattle2"]);
				} else if(property & Room.ENDING){
					if(room.type == Room.PUZZLE) game.createDistSound(x, y, "ending" + soundStep);
					else {
						game.soundQueue.add("twangKill");
					}
				} else if(property & Room.DOOR){
					game.soundQueue.add("door" + soundStep);
					if(property & Room.INCREMENT){
						game.soundQueue.add("twangMove");
						var ex:int = x;
						var ey:int = y;
						if(property & Room.M_UP) ey--;
						else if(property & Room.M_RIGHT) ex++;
						else if(property & Room.M_DOWN) ey++;
						else if(property & Room.M_LEFT) ex--;
						renderer.bitmapDebris(renderer.whiteBlit, ex, ey, dirs);
					}
				} else if(property & Room.MOVER){
					game.createDistSound(x, y, "rattleKill"+soundStep);
					if((property & Room.M_UP_DOWN_LEFT_RIGHT) == Room.M_UP_DOWN_LEFT_RIGHT){
						game.createDistSound(x, y, "trapTwang"+soundStep);
					}
				} else if(property & Room.WALL){
					game.createDistSound(x, y, "wall", ["bassyKill1", "bassyKill2", "bassyKill3", "bassyKill4"]);
				}
				if(property & Room.GENERATOR){
					game.createDistSound(x, y, "meatyKill"+soundStep);
				}
			}
			if(explosion){
				game.createDistSound(x, y, "bitBlastRattle");
			}
			var shakeX:int = 0, shakeY:int = 0;
			if(dir & Room.UP){
				renderer.glitchMap.addGlitchCols(x * SCALE, (x + 1) * SCALE, -1);
				shakeY = -2;
			} else if(dir & Room.RIGHT){
				renderer.glitchMap.addGlitchRows(y * SCALE, (y + 1) * SCALE, 1);
				shakeX = 2;
			} else if(dir & Room.DOWN){
				renderer.glitchMap.addGlitchCols(x * SCALE, (x + 1) * SCALE, 1);
				shakeY = 2;
			} else if(dir & Room.LEFT){
				renderer.glitchMap.addGlitchRows(y * SCALE, (y + 1) * SCALE, -1);
				shakeX = -2;
			}
			renderer.shake(shakeX, shakeY);
		}
		
		public function ending(x:int, y:int, dir:int):void{
			renderer.refresh = false;
			renderer.trackPlayer = false;
			if(room.type == Room.PUZZLE){
				if(dir & Room.UP){
					renderer.setSlide(0, SEGUE_SPEED);
				} else if(dir & Room.RIGHT){
					renderer.setSlide(-SEGUE_SPEED, 0);
				} else if(dir & Room.DOWN){
					renderer.setSlide(0, -SEGUE_SPEED);
				} else if(dir & Room.LEFT){
					renderer.setSlide(SEGUE_SPEED, 0);
				}
			} else {
				renderer.setSlide(0, 0);
				endingDir = dir;
			}
			
			renderer.bitmapDebris(renderer.playerBlit, x, y, dir | Room.rotateBits(dir, 2, Room.UP_DOWN_LEFT_RIGHT, 4));
		}
		
		public function displaceCamera(x:int, y:int, revealDir:int, eraseDir:int):void{
			renderer.displace(x * SCALE, y * SCALE);
			renderer.addFX(0, 0, renderer.mapFadeBlits[revealDir], null, 0, false, false, false, true);
			// create render old room contents
			var bitmap:Bitmap
			var bx:Number = 0, by:Number = 0;
			if(eraseDir == Room.NORTH){
				bitmap = new Bitmap(renderMapSection(0, 0, data.width, room.height - 1));
			} else if(eraseDir == Room.EAST){
				bitmap = new Bitmap(renderMapSection(room.width, 0, room.width - 1, data.height));
				bx = room.width * SCALE;
			} else if(eraseDir == Room.SOUTH){
				bitmap = new Bitmap(renderMapSection(0, room.height, data.width, room.height - 1));
				by = room.height * SCALE;
			} else if(eraseDir == Room.WEST){
				bitmap = new Bitmap(renderMapSection(0, 0, room.width - 1, data.height));
			}
			var blit:BlitClip = new FadingBlitClip(bitmap.bitmapData, 15);
			renderer.addFX(bx + x * SCALE, by + y * SCALE, blit, null, 0, true, false, false, true);
		}
		
		public function renderMapSection(x:int, y:int, width:int, height:int):BitmapData{
			var bitmapData:BitmapData = new BitmapData(width * SCALE, height * SCALE, true, 0x0);
			var background:Shape = new Shape();
			var matrix:Matrix = new Matrix();
			matrix.tx = -x * SCALE;
			matrix.ty = -y * SCALE;
			background.graphics.lineStyle(0, 0, 0);
			background.graphics.beginBitmapFill(renderer.backgroundBitmapData, matrix);
			background.graphics.drawRect(0, 0, width * SCALE + 1, height * SCALE + 1);
			bitmapData.draw(background);
			var fromX:int = x;
			var fromY:int = y;
			var toX:int = x + width;
			var toY:int = y + height;
			var r:int, c:int;
			var renderMap:Array = data.map;
			for(r = fromY; r < toY; r++){
				for(c = fromX; c < toX; c++){
					if(
						(c >= 0 && r >= 0 && c < data.width && r < data.height)
					){
						if(renderMap[r][c]){
							renderProperty((c - x) * SCALE, (r - y) * SCALE, renderMap[r][c], bitmapData);
						}
					}
				}
			}
			return bitmapData;
		}
		
		public function getPropertyBlit(property:int, rotate:Boolean = false):BlitRect{
			var blit:BlitRect, blitClip:BlitClip;
			if(property & Room.PLAYER){
				blit = renderer.playerBlit;
			} else if(property & Room.ENEMY){
				if(property & Room.MOVER){
					if((property & Room.M_UP_DOWN_LEFT_RIGHT) == Room.M_UP_DOWN_LEFT_RIGHT){
						blit = renderer.moverBlit;
					} else if((property & Room.M_UP_DOWN_LEFT_RIGHT) == (Room.M_LEFT | Room.M_RIGHT)){
						blit = renderer.horizMoverBlit;
					} else if((property & Room.M_UP_DOWN_LEFT_RIGHT) == (Room.M_UP | Room.M_DOWN)){
						blit = renderer.vertMoverBlit;
					}
				} else if(property & Room.TRAP){
					blitClip = renderer.trapBlit as BlitClip;
					// all 15 trap direction combinations map to the bitwise direction properties
					blitClip.frame = -1 + ((property & Room.M_UP_DOWN_LEFT_RIGHT) >> Room.M_DIR_SHIFT);
					blit = renderer.trapBlit;
				} else if(property & Room.TURNER){
					blit = renderer.turnerBlit;
					blitClip = renderer.turnerBlit as BlitClip;
					blitClip.frame = getTurnerFrame(property, rotate);
				} else if(property & Room.DOOR){
					blit = renderer.doorBlit;
					blitClip = renderer.doorBlit as BlitClip;
					if(property & Room.ENDING){
						blitClip.frame = blitClip.totalFrames - 1;
					} else {
						blitClip.frame = blitClip.totalFrames - room.endingDist;
						if(property & Room.INCREMENT){
							blitClip.frame++;
						}
						if(blitClip.frame < 0) blitClip.frame = 0;
						if(blitClip.frame > blitClip.totalFrames - 1) blitClip.frame = blitClip.totalFrames - 1;
					}
				} else if(property & Room.VIRUS){
					blit = renderer.virusBlit;
				}
			} else if(property & Room.ALLY){
				blit = renderer.allyBlit;
			} else if(property & Room.WALL){
				if(property & Room.SWAP){
					blit = renderer.swapBlit;
				} else if(property & Room.INDESTRUCTIBLE){
					blit = renderer.indestructibleWallBlit;
				} else {
					blit = renderer.wallBlit;
				}
			} else {
				if(property == Room.BOMB){
					return renderer.bombBlit;
				} else if(property & Room.GENERATOR){
					return renderer.generatorBlit;
				}
				blit = renderer.errorBlit;
			}
			return blit;
		}
		
		public function renderProperty(x:Number, y:Number, property:int, bitmapData:BitmapData, renderCheck:Boolean = true):void{
			var blit:BlitRect, displace:Boolean = false, frame:int;
			if(property & Room.PLAYER){
				displace = phase == PLAYER_PHASE || (property & Room.PUSHED);
				blit = renderer.playerBlit;
			} else if(property & Room.ENEMY){
				displace = phase == ENEMY_PHASE;
				if(property & Room.TURNER){
					// check we aren't a turner that's rotating
					displace = (
						phase == ENEMY_PHASE &&
						(
							(Boolean(property & Room.UP) && Boolean(property & Room.M_UP)) ||
							(Boolean(property & Room.RIGHT) && Boolean(property & Room.M_RIGHT)) ||
							(Boolean(property & Room.DOWN) && Boolean(property & Room.M_DOWN)) ||
							(Boolean(property & Room.LEFT) && Boolean(property & Room.M_LEFT)) ||
							(Boolean(property & Room.GENERATOR) && Boolean(property & Room.ATTACK))
						)
					);
				} else if(property & Room.GENERATOR){
					if(!(property & Room.ATTACK)) displace = false;
				}
				blit = getPropertyBlit(
					property,
					(property & Room.TURNER) && state == ANIMATE && phase == ENEMY_PHASE && !displace
				);
			} else if(property & Room.ALLY){
				displace = phase == PLAYER_PHASE || (property & Room.PUSHED);
				blit = renderer.allyBlit;
			} else if(property & Room.WALL){
				if(property & Room.SWAP){
					blit = renderer.swapBlit;
					displace = phase == PLAYER_PHASE;
				} else if(property & Room.INDESTRUCTIBLE){
					blit = renderer.indestructibleWallBlit;
				} else {
					blit = renderer.wallBlit;
				}
			} else if(property & Room.VOID){
				blit = renderer.voidBlit;
			} else return;
			if(bitmapData == renderer.bitmapData){
				blit.x = renderer.canvasPoint.x + x;
				blit.y = renderer.canvasPoint.y + y;
			} else {
				blit.x = x;
				blit.y = y;
			}
			// to create a neat square without a shadow we copy straight to the shadow bitmap
			if(property & Room.VOID){
				if(bitmapData == renderer.bitmapData){
					blit.render(renderer.bitmapDataShadow);
				} else {
					blit.render(bitmapData);
				}
				return;
			}
			if(state == ANIMATE && displace){
				// displace towards previous postion or nudge towards attacked position 
				var displaceStep:int;
				if(property & (Room.ATTACK | Room.BLOCKED)){
					if(property & Room.ATTACK){
						displaceStep = -restStep * (animCount + 1);
					} else if(property & Room.BLOCKED){
						displaceStep = -restStep * animCount;
					}
				} else {
					displaceStep = moveStep * animCount;
				}
				if(property & Room.UP){
					blit.y += displaceStep;
				} else if(property & Room.RIGHT){
					blit.x -= displaceStep;
				} else if(property & Room.DOWN){
					blit.y -= displaceStep;
				} else if(property & Room.LEFT){
					blit.x += displaceStep;
				}
			} else {
				if(property & Room.KILLER){
					if(property & Room.UP){
						blit.y -= SCALE * 0.5;
					} else if(property & Room.RIGHT){
						blit.x += SCALE * 0.5;
					} else if(property & Room.DOWN){
						blit.y += SCALE * 0.5;
					} else if(property & Room.LEFT){
						blit.x -= SCALE * 0.5;
					}
				}
			}
			if((property & (Room.ENEMY)) && (property & (Room.WALL))){
				renderer.enemyWallBlit.x = blit.x;
				renderer.enemyWallBlit.y = blit.y;
				renderer.enemyWallBlit.render(bitmapData);
			}
			if(blit is BlitClip) frame = (blit as BlitClip).frame;
			
			blit.render(bitmapData, frame);
			
			if(property & Room.ENEMY){
				if(property & Room.GENERATOR){
					renderer.generatorBlit.x = blit.x;
					renderer.generatorBlit.y = blit.y;
					renderer.generatorBlit.render(bitmapData);
					if((property & Room.TIMER_1) && !blink){
						renderer.generatorWarningBlit.x = blit.x;
						renderer.generatorWarningBlit.y = blit.y;
						renderer.generatorWarningBlit.render(bitmapData);
					}
				}
				if(room.type == Room.ADVENTURE && (property & Room.DOOR)){
					if(property & (Room.ENDING | Room.INCREMENT)){
						renderer.incrementBlit.x = blit.x;
						renderer.incrementBlit.y = blit.y;
						renderer.incrementBlit.render(bitmapData, game.frameCount % renderer.incrementBlit.totalFrames);
						renderer.endingDistBlit.x = blit.x;
						renderer.endingDistBlit.y = blit.y;
						if(property & Room.M_UP) renderer.endingDistBlit.y -= SCALE;
						else if(property & Room.M_RIGHT) renderer.endingDistBlit.x += SCALE;
						else if(property & Room.M_DOWN) renderer.endingDistBlit.y += SCALE;
						else if(property & Room.M_LEFT) renderer.endingDistBlit.x -= SCALE;
						renderer.endingDistBlit.render(bitmapData, room.endingDist - 2);
					}
				}
			}
			if(property & Room.BOMB){
				renderer.bombBlit.x = blit.x;
				renderer.bombBlit.y = blit.y;
				renderer.bombBlit.render(bitmapData);
			}
			// render parity if checkView
			if(property & Room.ENEMY){
				if(
					state != ANIMATE && renderCheck && checkView && state == IDLE &&
					!(property & (
						Room.TURNER | Room.GENERATOR | Room.VIRUS | Room.TRAP | Room.DOOR
					)) &&
					((data.player.x + data.player.y * data.width) & 1) == 
					(((x * INV_SCALE + y * INV_SCALE * data.width) >> 0) & 1)
				){
					renderer.checkMarkBlit.x = blit.x;
					renderer.checkMarkBlit.y = blit.y;
					renderer.checkMarkBlit.render(bitmapData);
				}
			}
		}
		
		/* Get the correct frame for when the turner is facing a direction or turning to face it */
		public function getTurnerFrame(property:int, rotate:Boolean = false):int{
			if(property & Room.UP){
				if(rotate){
					if(property & Room.M_UP) return TURNER_N;
					else if(property & Room.M_RIGHT) return TURNER_NE;
					else if(property & Room.M_DOWN) return TURNER_W;
					else if(property & Room.M_LEFT) return TURNER_NW;
				}
				return TURNER_N;
			} else if(property & Room.RIGHT){
				if(rotate){
					if(property & Room.M_RIGHT) return TURNER_E;
					else if(property & Room.M_DOWN) return TURNER_SE;
					else if(property & Room.M_LEFT) return TURNER_S;
					else if(property & Room.M_UP) return TURNER_NE;
				}
				return TURNER_E;
			} else if(property & Room.DOWN){
				if(rotate){
					if(property & Room.M_DOWN) return TURNER_S;
					else if(property & Room.M_LEFT) return TURNER_SW;
					else if(property & Room.M_UP) return TURNER_E;
					else if(property & Room.M_RIGHT) return TURNER_SE;
				}
				return TURNER_S;
			} else if(property & Room.LEFT){
				if(rotate){
					if(property & Room.M_LEFT) return TURNER_W;
					else if(property & Room.M_UP) return TURNER_NW;
					else if(property & Room.M_RIGHT) return TURNER_N;
					else if(property & Room.M_DOWN) return TURNER_SW;
				}
				return TURNER_W;
			}
			return 0;
		}
		
		public function render():void{
			moveStep = SCALE / animDelay;
			restStep = moveStep * 0.5;
			var fromX:int = -renderer.canvasPoint.x * Game.INV_SCALE;
			var fromY:int = -renderer.canvasPoint.y * Game.INV_SCALE;
			var toX:int = 1 + fromX + Game.WIDTH * Game.INV_SCALE;
			var toY:int = 1 + fromY + Game.HEIGHT * Game.INV_SCALE;
			var property:int, i:int, r:int, c:int;
			var player:Point, p:Point;
			var entities:Array/*Point*/ = [];
			var renderMap:Array = data.map;
			
			for(r = fromY; r < toY; r++){
				for(c = fromX; c < toX; c++){
					if(
						(c >= 0 && r >= 0 && c < data.width && r < data.height)
					){
						if(blackOutMap && uiManager.active && blackOutMap[r][c] == 0){
							renderProperty(c * SCALE, r * SCALE, Room.VOID, renderer.bitmapData);
							
						} else if(renderMap[r][c]){
							property = renderMap[r][c];
							// always render the allies last
							if(property & Room.ALLY){
								entities.unshift(new Point(c, r));
								continue;
							} else if(property & Room.ENEMY){
								entities.push(new Point(c, r));
								continue;
							}
							renderProperty(c * SCALE, r * SCALE, property, renderer.bitmapData);
							
						} else if(checkView){
							if(data.getCheck(c, r)){
								renderer.checkMarkBlit.x = renderer.canvasPoint.x + c * Game.SCALE;
								renderer.checkMarkBlit.y = renderer.canvasPoint.y + r * Game.SCALE;
								renderer.checkMarkBlit.render(renderer.guiBitmapData);
							}
						}
					}
				}
			}
			
			// render objects above the map so blocked movement goes over the walls
			for(i = entities.length - 1; i > -1 ; i--){
				p = entities[i];
				property = renderMap[p.y][p.x];
				// blink the player when in check and in checkView
				if((property & Room.PLAYER) && checkView && !blink && data.getCheck(p.x, p.y)){
					renderer.checkMarkBlit.x = renderer.canvasPoint.x + p.x * Game.SCALE;
					renderer.checkMarkBlit.y = renderer.canvasPoint.y + p.y * Game.SCALE;
					renderer.checkMarkBlit.render(renderer.guiBitmapData);
				} else {
					renderProperty(p.x * SCALE, p.y * SCALE, property, renderer.bitmapData);
				}
			}
			
			//renderPathMap();
			
			// gui render
			if(uiManager.active){
				renderer.turnsBlit.x = renderer.turnsBlit.y = 2;
				renderer.turnsBlit.render(renderer.guiBitmapData);
				renderer.numberBlit.x = renderer.turnsBlit.x + 2;
				renderer.numberBlit.y = renderer.turnsBlit.y + 2;
				renderer.numberBlit.setTargetValue(data.food);
				renderer.numberBlit.update();
				renderer.numberBlit.renderNumbers(renderer.guiBitmapData);
				if(uiManager.currentGroup > 0){
					renderer.guiBitmapData.copyPixels(renderer.darkBitmapData, renderer.darkBitmapData.rect, new Point(), null, null, true);
					if(room.type == Room.ADVENTURE){
						renderer.guiBitmapData.copyPixels(scoreTextBox.bitmapData, scoreTextBox.bitmapData.rect, new Point(0, Game.HEIGHT - Game.SCALE * 3), null, null, true);
					}
				}
				uiManager.render(renderer.guiBitmapData);
			}
		}
		
		/* For debugging pathMap errors - needs rewriting a bit */
		public function renderPathMap():void{
			var r:int, c:int;
			var size:int = LevelData.pathMap.length;
			var rect:Rectangle = new Rectangle(0, 0, 3, 3);
			var fill:uint;
			//trace(renderer.canvas.x);
			for(r = 0; r < size; r++){
				for(c = 0; c < size; c++){
					//rect.x = -renderer.canvasPoint.x + ((data.player.x - LevelData.ENEMY_ACTIVE_RADIUS) * SCALE) + c * SCALE;
					//rect.y = -renderer.canvasPoint.y + ((data.player.y - LevelData.ENEMY_ACTIVE_RADIUS) * SCALE) + r * SCALE;
					//rect.width = LevelData.pathMap[r][c];
					//renderer.bitmapData.fillRect(rect, 0xFFFFFF00);
				}
				
			}
		}
		
		/* Creates a minimap of a level (used to preview levels in editor mode) */
		public static function getLevelBitmapData(map:Array, width:int, height:int):BitmapData{
			var r:int, c:int;
			var col:uint, property:int;
			var bitmapData:BitmapData = new BitmapData(width, height, true, 0xFF282828);
			for(r = 0; r < height; r++){
				for(c = 0; c < width; c++){
					property = map[r][c];
					if(property & Room.ENEMY){
						bitmapData.setPixel32(c, r, 0xFFFFFFFF);
					} else if(property & Room.WALL){
						bitmapData.setPixel32(c, r, Renderer.WALL_COL);
					} else if(property & Room.ALLY){
						bitmapData.setPixel32(c, r, Renderer.UI_COL);
					} else if(c + r * width & 1){
						bitmapData.setPixel32(c, r, 0xFF3A3A3A);
					}
				}
			}
			return bitmapData;
		}
		
	}

}