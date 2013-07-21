package com.robotacid.ui.editor {
	import com.robotacid.engine.Level;
	import com.robotacid.engine.LevelData;
	import com.robotacid.engine.Room;
	import com.robotacid.gfx.BlitRect;
	import com.robotacid.gfx.Renderer;
	import flash.geom.Point;
	/**
	 * Edits the Room object via user interaction
	 * 
	 * @author Aaron Steed, robotacid.com
	 */
	public class RoomPainter {
		
		public static var game:Game;
		public static var renderer:Renderer;
		
		public var active:Boolean;
		public var px:int;
		public var py:int;
		public var palette:RoomPalette;
		public var data:LevelData;
		public var level:Level;
		
		private var paintCol:int;
		private var endingPos:Point;
		// paint cols
		private static const PAINT:int = 0;
		private static const ILLEGAL:int = 1;
		
		public function RoomPainter(level:Level, data:LevelData) {
			this.level = level;
			this.data = data;
			active = false;
			palette = new RoomPalette(level);
			endingPos = new Point();
		}
		
		public function main():void{
			palette.main();
			px = (renderer.canvas.mouseX - renderer.canvasPoint.x) * Game.INV_SCALE;
			py = (renderer.canvas.mouseY - renderer.canvasPoint.y) * Game.INV_SCALE;
			if(!palette.uiManager.mouseLock && !renderer.camera.dragScroll && palette.uiManager.currentGroup == 0){
				if(game.mousePressed){
					paintCol = PAINT;
					if(px >= 0 && py >= 0 && px < data.width && py < data.height){
						if(
							px == 0 ||
							py == 0 ||
							px == data.width - 1 ||
							py == data.height -1 ||
							(data.room.type == Room.ADVENTURE &&
								(
									px == (data.width * 0.5) >> 0 ||
									py == (data.height * 0.5) >> 0
								)
							) ||
							((palette.property & Room.PLAYER) && game.mousePressedCount != game.frameCount) ||
							(data.map[py][px] & Room.VOID)
						){
							// set ending in puzzle mode
							if(
								data.room.type == Room.PUZZLE &&
								(
									px == 0 ||
									py == 0 ||
									px == data.width - 1 ||
									py == data.height -1
								) && !(
									px == py ||
									(px == data.width - 1 && py == 0) ||
									(px == 0 && py == data.height - 1)
								)
							){
								data.map[endingPos.y][endingPos.x] = Room.WALL | Room.INDESTRUCTIBLE;
								endingPos.x = px;
								endingPos.y = py;
								data.map[py][px] = Room.ENEMY | Room.DOOR | Room.ENDING;
							} else {
								paintCol = ILLEGAL;
							}
						} else {
							if(palette.property & Room.PLAYER){
								if(data.map[data.player.y][data.player.x] & Room.PLAYER){
									data.map[data.player.y][data.player.x] = Room.EMPTY;
								}
								data.player.x = px;
								data.player.y = py;
							}
							if(palette.propertyLegal){
								data.map[py][px] = palette.property;
							} else {
								paintCol = ILLEGAL;
							}
						}
					} else {
						paintCol = ILLEGAL;
					}
				}
			}
		}
		
		public function setActive(value:Boolean):void{
			active = value;
			game.level.uiManager.setActive(!active);
			game.level.uiManager.mouseLock = true;
			game.level.uiManager.ignore = true;
			if(active){
				if(!palette.scrollButton.active){
					renderer.camera.toggleDragScroll();
				}
				var list:Array = [];
				Room.setPropertyLocations(0, 0, data.width, data.height, data.map, Room.ENDING, list);
				endingPos = list[0] || endingPos;
			} else {
				if(renderer.camera.dragScroll){
					renderer.camera.toggleDragScroll();
				}
				renderer.trackPlayer = true;
				if(game.level.room.type == Room.PUZZLE){
					game.level.blackOutMap = game.level.data.getBlackOutMap();
				}
			}
		}
		
		public function render():void{
			if(!palette.uiManager.mouseLock && palette.uiManager.currentGroup == 0){
				if(game.mousePressed){
					if(palette.property & Room.PLAYER){
						if(game.mousePressedCount != game.frameCount) return;
					}
					var blit:BlitRect = renderer.paintBlit;
					blit.x = renderer.canvasPoint.x + px * Game.SCALE;
					blit.y = renderer.canvasPoint.y + py * Game.SCALE;
					blit.render(renderer.bitmapData, paintCol);
				}
			}
		}
	}

}