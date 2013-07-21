package com.robotacid.ui {
	import com.robotacid.gfx.Renderer;
	/**
	 * ...
	 * @author Aaron Steed, robotacid.com
	 */
	public class LevelButtonData {
		
		public static var game:Game;
		public static var renderer:Renderer;
		
		public var index:int;
		public var roomData
		
		public function LevelButtonData(index:int) {
			this.index = index;
		}
		
	}

}