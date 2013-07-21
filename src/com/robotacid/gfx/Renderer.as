package com.robotacid.gfx {
	import com.robotacid.engine.Level;
	import com.robotacid.engine.LevelData;
	import com.robotacid.engine.Room;
	import com.robotacid.ui.editor.RoomPainter;
	import com.robotacid.ui.editor.RoomPalette;
	import com.robotacid.ui.Key;
	import com.robotacid.ui.TextBox;
	import com.robotacid.ui.ProgressBar;
	import com.robotacid.ui.TitleMenu;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.BlendMode;
	import flash.display.Graphics;
	import flash.display.MovieClip;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.display.Stage;
	import flash.events.Event;
	import flash.filters.ColorMatrixFilter;
	import flash.geom.ColorTransform;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.getDefinitionByName;
	
	/**
	 * Global graphics rendering
	 *
	 * @author Aaron Steed, robotacid.com
	 */
	public class Renderer{
		
		public var game:Game;
		public var camera:CanvasCamera;
		
		// gfx holders
		public var canvas:Sprite;
		public var canvasPoint:Point;
		public var mouseScroll:Boolean;
		public var bitmapData:BitmapData;
		public var bitmapDataShadow:BitmapData;
		public var guiBitmapData:BitmapData;
		public var bitmap:Shape;
		public var guiBitmap:Shape;
		public var bitmapShadow:Shape;
		public var backgroundShape:Shape;
		public var backgroundBitmapData:BitmapData;
		public var darkBitmapData:BitmapData;
		public var exhibitTimeOut:TextBox;
		
		// sprite sheets
		[Embed(source = "../../../assets/game-sprites.png")] public static var GameSpriteSheet:Class;
		[Embed(source = "../../../assets/menu-sprites.png")] public static var MenuSpriteSheet:Class;
		public var gameSpriteSheet:BitmapData;
		public var menuSpriteSheet:BitmapData;
		
		// blits
		public var sparkBlit:BlitRect;
		public var wallBlit:BlitSprite;
		public var indestructibleWallBlit:BlitSprite;
		public var playerBlit:BlitSprite;
		public var playerBuffer:BlitSprite;
		public var allyBlit:BlitSprite;
		public var moverBlit:BlitSprite;
		public var horizMoverBlit:BlitSprite;
		public var vertMoverBlit:BlitSprite;
		public var turnerBlit:BlitClip;
		public var virusBlit:BlitSprite;
		public var debrisBlit:BlitRect;
		public var wallDebrisBlit:BlitRect;
		public var enemyWallBlit:BlitSprite;
		public var trapBlit:BlitClip;
		public var errorBlit:BlitRect;
		public var swapBlit:BlitRect;
		public var generatorBlit:BlitSprite;
		public var generatorWarningBlit:BlitRect;
		public var turnsBlit:BlitSprite;
		public var numberBlit:NumberBlit;
		public var notCompletedBlit:BlitRect;
		public var timerCountBlit:BlitClip;
		public var checkMarkBlit:BlitSprite;
		public var propertySelectedBlit:BlitSprite;
		public var roomPaletteBlit:BlitSprite;
		public var parityBlit:BlitSprite;
		public var voidBlit:BlitRect;
		public var doorBlit:BlitClip;
		public var bombBlit:BlitSprite;
		public var explosionBlit:BlitClip;
		public var mapFadeBlits:Array/*FadingBlitRect*/;
		public var paintBlit:BlitClip;
		public var lockedBlit:BlitSprite;
		public var slideFade:BlitSprite;
		public var incrementBlit:BlitClip;
		public var decrementBlit:BlitClip;
		public var endingDistBlit:BlitClip;
		
		public var puzzleButtonBlit:BlitClip;
		public var adventureButtonBlit:BlitClip;
		public var editorButtonBlit:BlitClip;
		public var checkButtonBlit:BlitClip;
		public var settingsButtonBlit:BlitClip;
		public var playButtonBlit:BlitClip;
		public var scrollButtonBlit:BlitClip;
		public var propertyButtonBlit:BlitClip;
		public var loadButtonBlit:BlitClip;
		public var saveButtonBlit:BlitClip;
		public var cancelButtonBlit:BlitClip;
		public var confirmButtonBlit:BlitClip;
		public var resetButtonBlit:BlitClip;
		public var controlsButtonBlit:BlitClip;
		public var orientationButtonBlit:BlitClip;
		public var soundButtonBlit:BlitClip;
		public var fullscreenButtonBlit:BlitClip;
		public var editButtonBlit:BlitClip;
		public var numberButtonBlit:BlitClip;
		public var leftButtonBlit:BlitClip;
		public var rightButtonBlit:BlitClip;
		public var confirmPanelBlit:BlitSprite;
		public var levelMovePanelBlit:BlitSprite;
		public var levelPreviewPanelBlit:BlitSprite;
		public var swapButtonBlit:BlitClip;
		public var insertBeforeButtonBlit:BlitClip;
		public var insertAfterButtonBlit:BlitClip;
		public var whiteBlit:BlitSprite;
		
		// self maintaining animations
		public var fx:Array;
		public var roomFx:Array;
		public var fxFilterCallBack:Function;
		
		// states
		public var glitchMap:GlitchMap;
		public var shakeOffset:Point;
		public var shakeDirX:int;
		public var shakeDirY:int;
		public var trackPlayer:Boolean;
		public var refresh:Boolean;
		public var slideX:Number;
		public var slideY:Number;
		public var sliding:Boolean;
		
		// temp variables
		private var i:int;
		
		public static var point:Point = new Point();
		public static var matrix:Matrix = new Matrix();
		
		// measurements from Game.as
		public static const SCALE:Number = Game.SCALE;
		public static const INV_SCALE:Number = Game.INV_SCALE;
		public static const WIDTH:Number = Game.WIDTH;
		public static const HEIGHT:Number = Game.HEIGHT;
		
		public static const SHAKE_DIST_MAX:int = 12;
		public static const INV_SHAKE_DIST_MAX:Number = 1.0 / SHAKE_DIST_MAX;
		public static const WALL_COL_TRANSFORM:ColorTransform = new ColorTransform(1, 1, 1, 1, -100, -100, -100);
		public static const WHITE_COL_TRANSFORM:ColorTransform = new ColorTransform(1, 1, 1, 1, 255, 255, 255);
		public static const WALL_COL:uint = 0xff9b9b9b;
		public static const UI_COL_TRANSFORM:ColorTransform = new ColorTransform(1, 1, 1, 1, -255 + 214, -255 + 232);
		public static const UI_COL_BORDER_TRANSFORM:ColorTransform = new ColorTransform(1, 1, 1, 1, -255 + 166, -255 + 198, -255 + 239);
		public static const UI_COL_BACK_TRANSFORM:ColorTransform = new ColorTransform(1, 1, 1, 1, -255 + 49, -255 + 59, -255 + 73);
		public static const UI_COL:uint = 0xffd6e8ff;
		public static const UI_COL_BORDER:uint = 0xffa6c6ef;
		public static const UI_COL_BACK:uint = 0xff313b49;
		public static const DEBRIS_SPEEDS:Array = [1.5, 1, 1.5, 2, 3, 2.5, 2, 1.5, 1];
		
		public function Renderer(game:Game){
			this.game = game;
			trackPlayer = true;
		}
		
		/* Prepares sprites and bitmaps for a game session */
		public function createRenderLayers(holder:Sprite = null):void{
			
			if(!holder) holder = game;
			
			canvasPoint = new Point();
			canvas = new Sprite();
			holder.addChild(canvas);
			
			backgroundShape = new Shape();
			backgroundBitmapData = new BitmapData(16, 16, true, 0x0);
			backgroundBitmapData.copyPixels(gameSpriteSheet, new Rectangle(0, 0, 16, 16), new Point());
			
			bitmapData = new BitmapData(WIDTH, HEIGHT, true, 0x0);
			bitmap = new Shape();
			bitmapDataShadow = bitmapData.clone();
			bitmapShadow = new Shape();
			guiBitmapData = new BitmapData(WIDTH, HEIGHT, true, 0x0);
			guiBitmap = new Shape();
			
			canvas.addChild(backgroundShape);
			canvas.addChild(bitmapShadow);
			canvas.addChild(bitmap);
			game.addChild(guiBitmap);
			
			fx = [];
			roomFx = [];
			
			camera = new CanvasCamera(canvasPoint, this);
			
			shakeOffset = new Point();
			shakeDirX = 0;
			shakeDirY = 0;
			slideX = 0;
			slideY = 0;
			sliding = false;
			refresh = true;
		}
		
		/* Destroy all objects */
		public function clearAll():void{
			while(canvas.numChildren > 0){
				canvas.removeChildAt(0);
			}
			bitmap = null;
			bitmapShadow = null;
			bitmapData.dispose();
			bitmapData = null;
			fx = null;
			game = null;
		}
		
		/* Clean graphics and reset camera - no object destruction/creation */
		public function reset():void{
			bitmapData.fillRect(bitmapData.rect, 0x0);
			bitmapDataShadow.fillRect(bitmapData.rect, 0x0);
			guiBitmapData.fillRect(bitmapData.rect, 0x0);
			backgroundShape.graphics.clear();
			glitchMap.reset();
			var data:LevelData = game.level.data;
			camera.mapRect = new Rectangle(0, 0, data.width * SCALE, data.height * SCALE);
			camera.setTarget((data.player.x + 0.5) * SCALE, (data.player.y + 0.5) * SCALE);
			camera.skipPan();
			fx.length = 0;
			slideX = slideY = 0;
			sliding = false;
			refresh = true;
			trackPlayer = true;
			if(exhibitTimeOut){
				exhibitTimeOut.alpha = 0;
			}
		}
		
		/* ================================================================================================
		 * MAIN
		 * Updates all of the rendering 
		 * ================================================================================================
		 */
		public function main():void {
			
			// clear bitmapDatas - refresh can be set to false for glitchy trails
			if(refresh) bitmapData.fillRect(bitmapData.rect, 0x0);
			bitmapDataShadow.fillRect(bitmapDataShadow.rect, 0x0);
			guiBitmapData.fillRect(guiBitmapData.rect, 0x0);
			
			if(game.state == Game.MENU){
				guiBitmapData.fillRect(guiBitmapData.rect, 0xFF1A1E26);
				game.titleMenu.render();
				canvasPoint.x -= 0.5;
				
			} else if(game.state == Game.GAME){
				updateShaker();
				
				var level:Level;
				level = game.level;
				
				if(trackPlayer){
					camera.setTarget(
						(level.data.player.x + 0.5) * SCALE,
						(level.data.player.y + 0.5) * SCALE
					);
				} else if(sliding){
					camera.targetPos.x += slideX;
					camera.targetPos.y += slideY;
					slideFade.render(bitmapData);
				}
				
				camera.main();
				
				updateCheckers();
				
				// black border around small levels
				if(canvasPoint.x > camera.mapRect.x){
					bitmapDataShadow.fillRect(new Rectangle(0, 0, canvasPoint.x, Game.HEIGHT), 0xFF000000);
				}
				if(canvasPoint.x + camera.mapRect.x + camera.mapRect.width < Game.WIDTH){
					bitmapDataShadow.fillRect(new Rectangle(canvasPoint.x + camera.mapRect.x + camera.mapRect.width, 0, Game.WIDTH - (canvasPoint.x + camera.mapRect.x + camera.mapRect.width), Game.HEIGHT), 0xFF000000);
				}
				if(canvasPoint.y > 0){
					bitmapDataShadow.fillRect(new Rectangle(0, 0, Game.WIDTH, canvasPoint.y), 0xFF000000);
				}
				if(canvasPoint.y + camera.mapRect.height < Game.HEIGHT){
					bitmapDataShadow.fillRect(new Rectangle(0, canvasPoint.y + camera.mapRect.height, Game.WIDTH, Game.HEIGHT - (canvasPoint.y + camera.mapRect.height)), 0xFF000000);
				}
				
				if(game.roomPainter.active) game.roomPainter.render();
				level.render();
				if(game.roomPainter.active) game.roomPainter.palette.render();
				
				if(fx.length) fx = fx.filter(fxFilterCallBack);
				
				glitchMap.apply(bitmapData, canvasPoint.x, canvasPoint.y);
				glitchMap.update();
				
				bitmapDataShadow.copyPixels(bitmapData, bitmapData.rect, new Point(1, 1), null, null, true);
				bitmapDataShadow.colorTransform(bitmapDataShadow.rect, new ColorTransform(0, 0, 0));
				
				if(roomFx.length) roomFx = roomFx.filter(fxFilterCallBack);
			}
			
			// update shapes
			bitmap.graphics.clear();
			matrix.identity();
			bitmap.graphics.lineStyle(0, 0, 0);
			bitmap.graphics.beginBitmapFill(bitmapData, matrix);
			bitmap.graphics.drawRect(0, 0, Game.WIDTH, Game.HEIGHT);
			bitmap.graphics.endFill();
			
			bitmapShadow.graphics.clear();
			matrix.identity();
			bitmapShadow.graphics.lineStyle(0, 0, 0);
			bitmapShadow.graphics.beginBitmapFill(bitmapDataShadow, matrix);
			bitmapShadow.graphics.drawRect(0, 0, Game.WIDTH, Game.HEIGHT);
			bitmapShadow.graphics.endFill();
			
			guiBitmap.graphics.clear();
			matrix.identity();
			guiBitmap.graphics.lineStyle(0, 0, 0);
			guiBitmap.graphics.beginBitmapFill(guiBitmapData, matrix);
			guiBitmap.graphics.drawRect(0, 0, Game.WIDTH, Game.HEIGHT);
			guiBitmap.graphics.endFill();
			
		}
		
		private function updateCheckers():void{
			// checker background
			backgroundShape.graphics.clear();
			matrix.identity();
			matrix.tx = canvasPoint.x;
			matrix.ty = canvasPoint.y;
			backgroundShape.graphics.lineStyle(0, 0, 0);
			backgroundShape.graphics.beginBitmapFill(backgroundBitmapData, matrix);
			backgroundShape.graphics.drawRect(0, 0, Game.WIDTH, Game.HEIGHT);
			backgroundShape.graphics.endFill();
		}
		
		public function displace(x:Number, y:Number):void{
			var i:int, item:FX;
			for(i = 0; i < fx.length; i++){
				item = fx[i];
				item.x += x;
				item.y += y;
			}
			camera.displace(x, y);
		}
		
		public function setSlide(x:Number, y:Number):void{
			slideX = x;
			slideY = y;
			var i:int, item:FX;
			for(i = 0; i < fx.length; i++){
				item = fx[i];
				if(item.dir){
					if(slideX){
						item.dir.y = 0;
					} else if(slideY){
						item.dir.x = 0;
					}
				}
			}
			if(x == 0){
				camera.targetPos.x = camera.canvas.x;
			}
			if(y == 0){
				camera.targetPos.y = camera.canvas.y;
			}
			sliding = true;
		}
		
		/* Shake the screen in any direction */
		public function shake(x:int, y:int, shakeSource:Point = null):void {
			if(!refresh) return;
			// sourced shakes drop off in intensity by distance
			// it stops the player feeling like they're in a cocktail shaker
			if(shakeSource){
				var dist:Number = Math.abs(game.level.data.player.x - shakeSource.x) + Math.abs(game.level.data.player.x - shakeSource.y);
				if(dist >= SHAKE_DIST_MAX) return;
				x = x * (SHAKE_DIST_MAX - dist) * INV_SHAKE_DIST_MAX;
				y = y * (SHAKE_DIST_MAX - dist) * INV_SHAKE_DIST_MAX;
				if(x == 0 && y == 0) return;
			}
			// ignore lesser shakes
			if(Math.abs(x) < Math.abs(shakeOffset.x)) return;
			if(Math.abs(y) < Math.abs(shakeOffset.y)) return;
			shakeOffset.x = x;
			shakeOffset.y = y;
			shakeDirX = x > 0 ? 1 : -1;
			shakeDirY = y > 0 ? 1 : -1;
		}
		
		/* resolve the shake */
		private function updateShaker():void {
			// shake first
			if(shakeOffset.y != 0){
				shakeOffset.y = -shakeOffset.y;
				if(shakeDirY == 1 && shakeOffset.y > 0) shakeOffset.y--;
				if(shakeDirY == -1 && shakeOffset.y < 0) shakeOffset.y++;
			}
			if(shakeOffset.x != 0){
				shakeOffset.x = -shakeOffset.x;
				if(shakeDirX == 1 && shakeOffset.x > 0) shakeOffset.x--;
				if(shakeDirX == -1 && shakeOffset.x < 0) shakeOffset.x++;
			}
		}
		
		/* Add to list */
		public function addFX(x:Number, y:Number, blit:BlitRect, dir:Point = null, delay:int = 0, push:Boolean = true, looped:Boolean = false, killOffScreen:Boolean = true, room:Boolean = false):FX{
			var item:FX = new FX(x, y, blit, bitmapData, canvasPoint, dir, delay, looped, killOffScreen);
			if(room){
				if(push) roomFx.push(item);
				else roomFx.unshift(item);
			} else {
				if(push) fx.push(item);
				else fx.unshift(item);
			}
			return item;
		}
		
		/* Cyclically throw off pixel debris from where white pixels used to be on the blit
		 * use dir to specify bitwise flags for directions able to throw debris in */
		public function bitmapDebris(blit:BlitSprite, x:int, y:int, dir:int = 15):void{
			var r:int, c:int;
			var blitClip:BlitClip = blit as BlitClip;
			var source:Rectangle = blitClip ? blitClip.frames[blitClip.frame] : blit.rect;
			var compassIndex:int = 0, speedIndex:int = 0;
			var compassPoint:Point, p:Point = new Point();
			var debrisSpeed:Number, u:uint;
			for(r = 0; r < source.height; r++){
				for(c = 0; c < source.width; c++){
					u = blit.spriteSheet.getPixel32(source.x + c, source.y + r);
					if(u == 0xFFFFFFFF || u == WALL_COL){
						compassPoint = Room.compassPoints[compassIndex];
						debrisSpeed = DEBRIS_SPEEDS[speedIndex];
						p.x = compassPoint.x * debrisSpeed;
						p.y = compassPoint.y * debrisSpeed;
						if(Room.compass[compassIndex] & dir) addFX(x * SCALE + c + blit.dx, y * SCALE + r + blit.dy, u == 0xFFFFFFFF ? debrisBlit : wallDebrisBlit, p.clone(), 0, true, true);
						speedIndex++;
						compassIndex++;
						if(compassIndex >= Room.compassPoints.length) compassIndex = 0;
						if(speedIndex >= DEBRIS_SPEEDS.length) speedIndex = 0;
					}
				}
			}
		}
		
		/* A check to see if (x,y) is on screen plus a border */
		public function onScreen(x:Number, y:Number, border:Number):Boolean{
			return x + border >= -canvasPoint.x && y + border >= -canvasPoint.y && x - border < -canvasPoint.x + Game.WIDTH && y - border < -canvasPoint.y + Game.HEIGHT;
		}
		
		/* ===============================================================================================================
		 * 
		 *  INIT
		 * 
		 * Initialisation is separated from the constructor to allow reference paths to be complete before all
		 * of the graphics are generated - an object is null until its constructor has been exited
		 * 
		 * ===============================================================================================================
		 */
		public function init():void{
			
			FX.renderer = this;
			FoodClockFX.renderer = this;
			Level.renderer = this;
			TitleMenu.renderer = this;
			RoomPainter.renderer = this;
			RoomPalette.renderer = this;
			
			var gameSpriteSheetBitmap:Bitmap = new GameSpriteSheet();
			var menuSpriteSheetBitmap:Bitmap = new MenuSpriteSheet();
			gameSpriteSheet = gameSpriteSheetBitmap.bitmapData;
			menuSpriteSheet = menuSpriteSheetBitmap.bitmapData;
			
			sparkBlit = new BlitRect(0, 0, 1, 1, 0xffffffff);
			debrisBlit = new BlitRect(0, 0, 1, 1, 0xffffffff);
			wallDebrisBlit = new BlitRect(0, 0, 1, 1, WALL_COL);
			wallBlit = new BlitSprite(gameSpriteSheet, new Rectangle(24, 0, 8, 8));
			indestructibleWallBlit = new BlitSprite(gameSpriteSheet, new Rectangle(80, 0, 8, 8));
			enemyWallBlit = new BlitSprite(gameSpriteSheet, new Rectangle(88, 0, 8, 8));
			trapBlit = new BlitClip(gameSpriteSheet, [
				new Rectangle(0, 16, 8, 8),
				new Rectangle(8, 16, 8, 8),
				new Rectangle(16, 16, 8, 8),
				new Rectangle(24, 16, 8, 8),
				new Rectangle(32, 16, 8, 8),
				new Rectangle(40, 16, 8, 8),
				new Rectangle(48, 16, 8, 8),
				new Rectangle(56, 16, 8, 8),
				new Rectangle(64, 16, 8, 8),
				new Rectangle(72, 16, 8, 8),
				new Rectangle(80, 16, 8, 8),
				new Rectangle(88, 16, 8, 8),
				new Rectangle(96, 16, 8, 8),
				new Rectangle(104, 16, 8, 8),
				new Rectangle(0, 24, 8, 8)
			]);
			generatorBlit = new BlitSprite(gameSpriteSheet, new Rectangle(96, 0, 8, 8));
			generatorWarningBlit = new BlitRect(0, 0, 7, 7, 0xFFFFFFFF);
			playerBlit = new BlitSprite(gameSpriteSheet, new Rectangle(16, 0, 8, 8));
			playerBuffer = new BlitSprite(gameSpriteSheet, new Rectangle(96, 64, 8, 8));
			allyBlit = new BlitSprite(gameSpriteSheet, new Rectangle(64, 0, 8, 8));
			moverBlit = new BlitSprite(gameSpriteSheet, new Rectangle(48, 0, 8, 8));
			horizMoverBlit = new BlitSprite(gameSpriteSheet, new Rectangle(40, 0, 8, 8));
			vertMoverBlit = new BlitSprite(gameSpriteSheet, new Rectangle(32, 0, 8, 8));
			turnerBlit = new BlitClip(gameSpriteSheet, [
				new Rectangle(16, 8, 8, 8),
				new Rectangle(24, 8, 8, 8),
				new Rectangle(32, 8, 8, 8),
				new Rectangle(40, 8, 8, 8),
				new Rectangle(48, 8, 8, 8),
				new Rectangle(56, 8, 8, 8),
				new Rectangle(64, 8, 8, 8),
				new Rectangle(72, 8, 8, 8)
			]);
			virusBlit = new BlitSprite(gameSpriteSheet, new Rectangle(56, 0, 8, 8));
			errorBlit = new BlitRect(3, 3, 3, 3, 0xFFFF0000);
			swapBlit = new BlitSprite(gameSpriteSheet, new Rectangle(72, 0, 8, 8));
			numberBlit = new NumberBlit(gameSpriteSheet, new Rectangle(112, 0, 8, 80), 2, 0.25, -1, -1, 6);
			notCompletedBlit = new BlitRect( -1, -1, 3, 3, UI_COL_BORDER);
			timerCountBlit = new BlitClip(gameSpriteSheet, [
				new Rectangle(112, 0, 8, 8),
				new Rectangle(112, 8, 8, 8),
				new Rectangle(112, 16, 8, 8),
				new Rectangle(112, 24, 8, 8)
			]);
			checkMarkBlit = new BlitSprite(gameSpriteSheet, new Rectangle(56, 32, 8, 8));
			voidBlit = new BlitRect(0, 0, SCALE, SCALE, 0xFF000000);
			doorBlit = new BlitClip(gameSpriteSheet, [
				new Rectangle(8, 24, 8, 8),
				new Rectangle(16, 24, 8, 8),
				new Rectangle(24, 24, 8, 8),
				new Rectangle(32, 24, 8, 8),
				new Rectangle(40, 24, 8, 8),
				new Rectangle(48, 24, 8, 8),
				new Rectangle(56, 24, 8, 8),
				new Rectangle(64, 24, 8, 8),
				new Rectangle(72, 24, 8, 8),
				new Rectangle(80, 24, 8, 8)
			]);
			bombBlit = new BlitSprite(gameSpriteSheet, new Rectangle(104, 0, 8, 8));
			explosionBlit = new BlitClip(gameSpriteSheet, [
				new Rectangle(80, 8, 8, 8),
				new Rectangle(80, 8, 8, 8),
				new Rectangle(88, 8, 8, 8),
				new Rectangle(88, 8, 8, 8),
				new Rectangle(96, 8, 8, 8),
				new Rectangle(96, 8, 8, 8),
				new Rectangle(104, 8, 8, 8),
				new Rectangle(104, 8, 8, 8)
			]);
			whiteBlit = new BlitSprite(gameSpriteSheet, new Rectangle(88, 64, 8, 8));
			errorBlit = new BlitRect(1, 1, 5, 5, 0xFFFF0000);
			incrementBlit = new BlitClip(gameSpriteSheet, [
				new Rectangle(88, 24, 8, 8),
				new Rectangle(88, 24, 8, 8),
				new Rectangle(96, 24, 8, 8),
				new Rectangle(96, 24, 8, 8),
				new Rectangle(104, 24, 8, 8),
				new Rectangle(104, 24, 8, 8),
				new Rectangle(0, 32, 8, 8),
				new Rectangle(0, 32, 8, 8),
				new Rectangle(8, 32, 8, 8),
				new Rectangle(8, 32, 8, 8),
				new Rectangle(16, 32, 8, 8),
				new Rectangle(16, 32, 8, 8),
				new Rectangle(24, 32, 8, 8),
				new Rectangle(24, 32, 8, 8),
				new Rectangle(32, 32, 8, 8),
				new Rectangle(32, 32, 8, 8),
				new Rectangle(40, 32, 8, 8),
				new Rectangle(40, 32, 8, 8),
				new Rectangle(48, 32, 8, 8),
				new Rectangle(48, 32, 8, 8),
				null,
				null,
				null,
				null,
				null,
				null,
				null,
				null,
				null,
				null
			]);
			endingDistBlit = new BlitClip(gameSpriteSheet, [
				new Rectangle(0, 56, 8, 8),
				new Rectangle(8, 56, 8, 8),
				new Rectangle(16, 56, 8, 8),
				new Rectangle(24, 56, 8, 8),
				new Rectangle(32, 56, 8, 8),
				new Rectangle(40, 56, 8, 8),
				new Rectangle(48, 56, 8, 8),
				new Rectangle(56, 56, 8, 8),
				new Rectangle(64, 56, 8, 8),
				new Rectangle(72, 56, 8, 8)
			]);
			settingsButtonBlit = new BlitClip(gameSpriteSheet, [
				new Rectangle(64, 32, 8, 8),
				new Rectangle(72, 32, 8, 8)
			]);
			turnsBlit = new BlitSprite(menuSpriteSheet, new Rectangle(48, 60, 16, 10));
			propertySelectedBlit = new BlitSprite(menuSpriteSheet, new Rectangle(79, 88, 9, 9), -1, -1);
			roomPaletteBlit = new BlitSprite(menuSpriteSheet, new Rectangle(44, 72, 35, 67), -1, -1);
			
			puzzleButtonBlit = new BlitClip(menuSpriteSheet, [
				new Rectangle(0, 72, 22, 22),
				new Rectangle(22, 72, 22, 22)
			]);
			adventureButtonBlit = new BlitClip(menuSpriteSheet, [
				new Rectangle(0, 94, 22, 22),
				new Rectangle(22, 94, 22, 22)
			]);
			editorButtonBlit = new BlitClip(menuSpriteSheet, [
				new Rectangle(0, 116, 22, 22),
				new Rectangle(22, 116, 22, 22)
			]);
			checkButtonBlit = new BlitClip(menuSpriteSheet, [
				new Rectangle(48, 12, 12, 12),
				new Rectangle(60, 12, 12, 12),
				new Rectangle(72, 12, 12, 12),
				new Rectangle(84, 12, 12, 12)
			]);
			playButtonBlit = new BlitClip(menuSpriteSheet, [
				new Rectangle(48, 48, 12, 12),
				new Rectangle(60, 48, 12, 12)
			]);
			propertyButtonBlit = new BlitClip(menuSpriteSheet, [
				new Rectangle(72, 48, 12, 12),
				new Rectangle(84, 48, 12, 12)
			]);
			scrollButtonBlit = new BlitClip(menuSpriteSheet, [
				new Rectangle(24, 60, 12, 12),
				new Rectangle(36, 60, 12, 12),
				new Rectangle(79, 106, 12, 12),
				new Rectangle(79, 118, 12, 12)
			]);
			loadButtonBlit = new BlitClip(menuSpriteSheet, [
				new Rectangle(0, 36, 12, 12),
				new Rectangle(12, 36, 12, 12)
			]);
			saveButtonBlit = new BlitClip(menuSpriteSheet, [
				new Rectangle(72, 24, 12, 12),
				new Rectangle(84, 24, 12, 12)
			]);
			cancelButtonBlit = new BlitClip(menuSpriteSheet, [
				new Rectangle(0, 0, 12, 12),
				new Rectangle(12, 0, 12, 12)
			]);
			confirmButtonBlit = new BlitClip(menuSpriteSheet, [
				new Rectangle(24, 0, 12, 12),
				new Rectangle(36, 0, 12, 12)
			]);
			resetButtonBlit = new BlitClip(menuSpriteSheet, [
				new Rectangle(0, 12, 12, 12),
				new Rectangle(12, 12, 12, 12)
			]);
			controlsButtonBlit = new BlitClip(menuSpriteSheet, [
				new Rectangle(0, 48, 12, 12),
				new Rectangle(12, 48, 12, 12),
				new Rectangle(24, 48, 12, 12),
				new Rectangle(36, 48, 12, 12)
			]);
			orientationButtonBlit = new BlitClip(menuSpriteSheet, [
				new Rectangle(24, 12, 12, 12),
				new Rectangle(36, 12, 12, 12)
			]);
			soundButtonBlit = new BlitClip(menuSpriteSheet, [
				new Rectangle(24, 36, 12, 12),
				new Rectangle(36, 36, 12, 12),
				new Rectangle(48, 36, 12, 12),
				new Rectangle(36, 36, 12, 12)
			]);
			fullscreenButtonBlit = new BlitClip(menuSpriteSheet, [
				new Rectangle(84, 36, 12, 12),
				new Rectangle(72, 36, 12, 12),
				new Rectangle(60, 36, 12, 12),
				new Rectangle(72, 36, 12, 12)
			]);
			editButtonBlit = new BlitClip(menuSpriteSheet, [
				new Rectangle(0, 60, 12, 12),
				new Rectangle(12, 60, 12, 12)
			]);
			numberButtonBlit = new BlitClip(menuSpriteSheet, [
				new Rectangle(48, 60, 16, 10),
				new Rectangle(64, 60, 16, 10)
			]);
			leftButtonBlit = new BlitClip(menuSpriteSheet, [
				new Rectangle(48, 0, 12, 12),
				new Rectangle(60, 0, 12, 12)
			]);
			rightButtonBlit = new BlitClip(menuSpriteSheet, [
				new Rectangle(72, 0, 12, 12),
				new Rectangle(84, 0, 12, 12)
			]);
			swapButtonBlit = new BlitClip(menuSpriteSheet, [
				new Rectangle(48, 24, 12, 12),
				new Rectangle(60, 24, 12, 12)
			]);
			insertBeforeButtonBlit = new BlitClip(menuSpriteSheet, [
				new Rectangle(0, 24, 12, 12),
				new Rectangle(12, 24, 12, 12)
			]);
			insertAfterButtonBlit = new BlitClip(menuSpriteSheet, [
				new Rectangle(24, 24, 12, 12),
				new Rectangle(36, 24, 12, 12)
			]);
			confirmPanelBlit = new BlitSprite(menuSpriteSheet, new Rectangle(0, 157, 31, 19));
			levelMovePanelBlit = new BlitSprite(menuSpriteSheet, new Rectangle(0, 139, 70, 18));
			levelPreviewPanelBlit = new BlitSprite(menuSpriteSheet, new Rectangle(79, 72, 16, 16));
			paintBlit = new BlitClip(menuSpriteSheet, [
				new Rectangle(79, 97, 9, 9),
				new Rectangle(80, 60, 9, 9)
			], -1, -1);
			lockedBlit = new BlitSprite(menuSpriteSheet, new Rectangle(89, 60, 7, 7));
			
			var fade_delay:int = 10;
			mapFadeBlits = [
				new FadingBlitRect(0, 0, Level.MAP_WIDTH * SCALE, (Level.ROOM_HEIGHT - 1) * SCALE, fade_delay),
				new FadingBlitRect(Level.ROOM_WIDTH * SCALE, 0, (Level.ROOM_WIDTH - 1) * SCALE, Level.MAP_HEIGHT * SCALE, fade_delay),
				new FadingBlitRect(0, Level.ROOM_HEIGHT * SCALE, Level.MAP_WIDTH * SCALE, (Level.ROOM_HEIGHT - 1) * SCALE, fade_delay),
				new FadingBlitRect(0, 0, (Level.ROOM_WIDTH - 1) * SCALE, Level.MAP_HEIGHT * SCALE, fade_delay),
			];
			darkBitmapData = new BitmapData(Game.WIDTH, Game.HEIGHT, true, 0x88000000);
			
			glitchMap = new GlitchMap();
			
			slideFade = new BlitSprite(new BitmapData(Game.WIDTH, Game.HEIGHT, true, 0x08000000), new Rectangle(0, 0, Game.WIDTH, Game.HEIGHT));
			
			TextBox.init([
				new Rectangle(1, 40, 6, 7),// a
				new Rectangle(9, 40, 6, 7),// b
				new Rectangle(17, 40, 6, 7),// c
				new Rectangle(25, 40, 6, 7),// d
				new Rectangle(33, 40, 6, 7),// e
				new Rectangle(41, 40, 6, 7),// f
				new Rectangle(49, 40, 6, 7),// g
				new Rectangle(57, 40, 6, 7),// h
				new Rectangle(65, 40, 6, 7),// i
				new Rectangle(73, 40, 6, 7),// j
				new Rectangle(81, 40, 6, 7),// k
				new Rectangle(89, 40, 6, 7),// l
				new Rectangle(97, 40, 6, 7),// m
				new Rectangle(105, 40, 6, 7),// n
				new Rectangle(1, 48, 6, 7),// o
				new Rectangle(9, 48, 6, 7),// p
				new Rectangle(17, 48, 6, 7),// q
				new Rectangle(25, 48, 6, 7),// r
				new Rectangle(33, 48, 6, 7),// s
				new Rectangle(41, 48, 6, 7),// t
				new Rectangle(49, 48, 6, 7),// u
				new Rectangle(57, 48, 6, 7),// v
				new Rectangle(65, 48, 6, 7),// w
				new Rectangle(73, 48, 6, 7),// x
				new Rectangle(81, 48, 6, 7),// y
				new Rectangle(89, 48, 6, 7),// z
				new Rectangle(1, 56, 6, 7),// 0
				new Rectangle(9, 56, 6, 7),// 1
				new Rectangle(17, 56, 6, 7),// 2
				new Rectangle(25, 56, 6, 7),// 3
				new Rectangle(33, 56, 6, 7),// 4
				new Rectangle(41, 56, 6, 7),// 5
				new Rectangle(49, 56, 6, 7),// 6
				new Rectangle(57, 56, 6, 7),// 7
				new Rectangle(65, 56, 6, 7),// 8
				new Rectangle(73, 56, 6, 7),// 9
				new Rectangle(19, 64, 2, 4),// '
				new Rectangle(33, 64, 6, 7),// backslash
				new Rectangle(),// :
				new Rectangle(3, 64, 2, 8),// ,
				new Rectangle(73, 64, 6, 7),// =
				new Rectangle(99, 56, 2, 7),// !
				new Rectangle(81, 64, 6, 7),// /
				new Rectangle(41, 64, 6, 7),// -
				new Rectangle(58, 64, 3, 8),// (
				new Rectangle(49, 64, 6, 7),// +
				new Rectangle(89, 56, 6, 7),// ?
				new Rectangle(66, 64, 3, 8),// )
				new Rectangle(),// ;
				new Rectangle(107, 56, 2, 7),// .
				new Rectangle(8, 64, 8, 7),// @
				new Rectangle(),// _
				new Rectangle(81, 56, 6, 7),// %
				new Rectangle(),// *
				new Rectangle(26, 64, 4, 4)// "
			], gameSpriteSheet);
			
			fxFilterCallBack = function(item:FX, index:int, list:Array):Boolean{
				item.main();
				return item.active;
			};
		}
		
	}

}