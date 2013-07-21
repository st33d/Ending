package com.robotacid.ui {
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Shape;
	import flash.geom.ColorTransform;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.getQualifiedClassName;
	
	/**
	 * Custom bitmap font - only renders one font between many instances
	 *
	 * @author Aaron Steed, robotacid.com
	 */
	public class TextBox extends Shape{
		
		public static var spriteSheet:BitmapData;
		public static var characters:Array;
		// the order in which to submit rects
		public static var characterNames:Array = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "'", "\\", ":", ",", "=", "!", "/", "-", "(", "+", "?", ")", ";", ".", "@", "_", "%", "*", "\""];
		
		public var bitmapData:BitmapData;
		public var lines:Array;						// a 2D array of all the bitmapDatas used, in lines
		public var lineWidths:Array;				// the width of each line of text (used for alignment)
		public var textLines:Array;					// a 2D array of the characters used (used for fetching offset and kerning data)
		public var tracking:int;					// tracking: the spacing between letters
		public var align:String;					// align: whether the text is centered, left or right aligned
		public var alignVert:String;				// align_vert: vertical alignment of the text
		public var lineSpacing:int;					// line_spacing: distance between each line of copy
		public var wordWrap:Boolean;				// turns wordWrap on and off
		public var backgroundCol:uint;
		public var borderCol:uint;
		public var backgroundAlpha:Number;
		public var leading:int;
		public var offsetX:int;
		public var offsetY:int;
		
		protected var _colorInt:uint;				// the actual uint of the color being applied
		protected var _color:ColorTransform;		// a color transform object that is applied to the whole TextBox
		
		protected var whitespaceLength:int;			// the distance a whitespace takes up
		
		protected var _width:int;
		protected var _height:int;
		protected var _text:String;
		protected var borderRect:Rectangle;
		protected var boundsRect:Rectangle;
		protected var maskRect:Rectangle;
		
		public static const BORDER_ALLOWANCE:int = 0;
		
		public function TextBox(_width:Number, _height:Number, backgroundCol:uint = 0xFF111111, borderCol:uint = 0xFF999999) {
			this._width = _width;
			this._height = _height;
			this.backgroundCol = backgroundCol;
			this.borderCol = borderCol;
			align = "left";
			alignVert = "top";
			_colorInt = 0xFFFFFF;
			wordWrap = true;
			tracking = 0;
			leading = 1;
			whitespaceLength = 2;
			lineSpacing = 8;
			_text = "";
			
			lines = [];
			
			borderRect = new Rectangle(0, 0, _width, _height);
			boundsRect = new Rectangle(0, 0, _width, _height);
			maskRect = new Rectangle(0, 0, 1, 1);
			bitmapData = new BitmapData(_width, _height, true, 0x0);
			drawBorder();
		}
		
		/* This must be called before any TextBox is created so sprites can be drawn */
		public static function init(characterList:Array, _spriteSheet:BitmapData):void{
			spriteSheet = _spriteSheet;
			characters = [];
			var characterName:String;
			var rect:Rectangle;
			for(var i:int = 0; i < characterList.length; i++){
				if(characterList[i]){
					rect = characterList[i];
				} else {
					rect = new Rectangle();
				}
				characterName = characterNames[i];
				characters[characterName] = rect;
			}
		}
		
		public function set text(str:String):void{
			_text = str;
			updateText();
			draw();
		}
		
		public function get text():String{
			return _text;
		}
		
		// color
		public function get color():uint {
			return _colorInt;
		}
		public function set color(c:uint):void {
			_colorInt = c;
			if(c == 0xFFFFFF) {
				_color = null;
			} else {
				_color = new ColorTransform(
					((c >> 16) % 256) / 255,
					((c >> 8) % 256) / 255,
					(c % 256) / 255
				);
			}
			if(_color) transform.colorTransform = _color;
		}
		
		public function setSize(width:int, height:int):void{
			_width = width;
			_height = height;
			borderRect = new Rectangle(1, 1, _width - 2, _height - 2);
			boundsRect = new Rectangle(2, 2, _width - 4, _height - 4);
			bitmapData = new BitmapData(width, height, true, 0x0);
			updateText();
			draw();
		}
		
		/* Calculates an array of BitmapDatas needed to render the text */
		protected function updateText():void{
			
			// we create an array called lines that holds references to all of the
			// bitmapDatas needed and structure it like the text
			
			// the lines property is public so it can be used to ticker text
			lines = [];
			lineWidths = [];
			textLines = [];
			
			var currentLine:Array = [];
			var currentTextLine:Array = [];
			var wordBeginning:int = 0;
			var currentLineWidth:int = 0;
			var completeWordsWidth:int = 0;
			var wordWidth:int = 0;
			var newLine:Array = [];
			var newTextLine:Array = [];
			var c:String;
			
			if(!_text) _text = "";
			
			var upperCaseText:String = _text.toUpperCase();
			
			for(var i:int = 0; i < upperCaseText.length; i++){
				
				c = upperCaseText.charAt(i);
				
				// new line characters
				if(c == "\n" || c == "\r" || c == "|"){
					lines.push(currentLine);
					textLines.push(currentTextLine);
					lineWidths.push(currentLineWidth);
					currentLineWidth = 0;
					completeWordsWidth = 0;
					wordBeginning = 0;
					wordWidth = 0;
					currentLine = [];
					currentTextLine = [];
					continue;
				}
				
				// push a character into the array
				if(characters[c]){
					// check we're in the middle of a word - spaces are null
					if(currentLine.length > 0 && currentLine[currentLine.length -1]){
						currentLineWidth += tracking;
						wordWidth += tracking;
					}
					wordWidth += characters[c].width
					currentLineWidth += characters[c].width;
					currentLine.push(characters[c]);
					currentTextLine.push(c);
				
				// the character is a SPACE or unrecognised and will be treated as a SPACE
				} else {
					if(currentLine.length > 0 && currentLine[currentLine.length - 1]){
						completeWordsWidth = currentLineWidth;
					}
					currentLineWidth += whitespaceLength;
					currentLine.push(null);
					currentTextLine.push(null);
					wordBeginning = currentLine.length;
					wordWidth = 0;
				}
				
				// if the length of the current line exceeds the width, we splice it into the next line
				// effecting word wrap
				
				if(currentLineWidth > _width - (BORDER_ALLOWANCE * 2) && wordWrap){
					// in the case where the word is larger than the text field we take back the last character
					// and jump to a new line with it
					if(wordBeginning == 0 && currentLine[currentLine.length - 1]){
						currentLineWidth -= tracking + currentLine[currentLine.length - 1].width;
						// now we take back the offending last character
						var lastBitmapData:BitmapData = currentLine.pop();
						var lastChar:String = currentTextLine.pop();
						
						lines.push(currentLine);
						textLines.push(currentTextLine);
						lineWidths.push(currentLineWidth);
						
						currentLineWidth = lastBitmapData.width;
						completeWordsWidth = 0;
						wordBeginning = 0;
						wordWidth = lastBitmapData.width;
						currentLine = [lastBitmapData];
						currentTextLine = [lastChar];
						continue;
					}
					
					newLine = currentLine.splice(wordBeginning, currentLine.length - wordBeginning);
					newTextLine = currentTextLine.splice(wordBeginning, currentTextLine.length - wordBeginning);
					lines.push(currentLine);
					textLines.push(currentTextLine);
					lineWidths.push(completeWordsWidth);
					completeWordsWidth = 0;
					wordBeginning = 0;
					currentLine = newLine;
					currentTextLine = newTextLine;
					currentLineWidth = wordWidth;
				}
			}
			// save the last line
			lines.push(currentLine);
			textLines.push(currentTextLine);
			lineWidths.push(currentLineWidth);
			
		}
		
		/* Render */
		public function draw():void{
			
			drawBorder();
			
			var i:int, j:int;
			var point:Point = new Point();
			var x:int;
			var y:int = BORDER_ALLOWANCE + offsetY;
			var alignX:int;
			var alignY:int;
			var char:Rectangle;
			var offset:Point;
			var wordBeginning:int = 0;
			var linesHeight:int = lineSpacing * lines.length;
			
			for(i = 0; i < lines.length; i++, point.y += lineSpacing){
				x = BORDER_ALLOWANCE + offsetX;
				
				wordBeginning = 0;
				for(j = 0; j < lines[i].length; j++){
					char = lines[i][j];
					
					// alignment to bitmap
					if(align == "left"){
						alignX = 0;
					} else if(align == "center"){
						alignX = _width * 0.5 - (lineWidths[i] * 0.5 + BORDER_ALLOWANCE);
					} else if(align == "right"){
						alignX = _width - lineWidths[i];
					}
					if(alignVert == "top"){
						alignY = 0;
					} else if(alignVert == "center"){
						alignY = _height * 0.5 - linesHeight * 0.5;
					} else if(alignVert == "bottom"){
						alignY = _height - linesHeight;
					}
					
					// print to bitmapdata
					if(char){
						if(j > wordBeginning){
							x += tracking;
						}
						point.x = alignX + x;
						point.y = alignY + y + leading;
						// mask characters that are outside the boundsRect
						if(
							point.x < boundsRect.x ||
							point.y < boundsRect.y ||
							point.x + char.width >= boundsRect.x + boundsRect.width ||
							point.y + char.height >= boundsRect.y + boundsRect.height
						){
							// are they even in the bounds rect?
							if(
								point.x + char.width > boundsRect.x &&
								boundsRect.x + boundsRect.width > point.x &&
								point.y + char.height > boundsRect.y &&
								boundsRect.y + boundsRect.height > point.y
							){
								// going to make a glib assumption that the TextBox won't be smaller than a single character
								maskRect.x = point.x >= boundsRect.x ? char.x : char.x + (point.x - boundsRect.x);
								maskRect.y = point.y >= boundsRect.y ? char.y : char.y + (point.y - boundsRect.y);
								// NB: just changed this class over to a sprite sheet, no idea if the above lines actually work
								maskRect.width = point.x + char.width <= boundsRect.x + boundsRect.width ? char.width : (boundsRect.x + boundsRect.width) - point.x;
								maskRect.height = point.y + char.height <= boundsRect.y + boundsRect.height ? char.height : (boundsRect.y + boundsRect.height) - point.y;
								if(point.x < boundsRect.x){
									maskRect.x = boundsRect.x - point.x;
									point.x = boundsRect.x;
								}
								if(point.y < boundsRect.y){
									maskRect.y = boundsRect.y - point.y;
									point.y = boundsRect.y;
								}
								bitmapData.copyPixels(spriteSheet, maskRect, point, null, null, true);
							}
						} else {
							bitmapData.copyPixels(spriteSheet, char, point, null, null, true);
						}
						x += char.width;
					} else {
						x += whitespaceLength;
						wordBeginning = j + 1;
					}
				}
				y += lineSpacing;
			}
			
			if(_color) transform.colorTransform = _color;
			
			graphics.clear();
			graphics.lineStyle(0, 0, 0);
			graphics.beginBitmapFill(bitmapData);
			graphics.drawRect(0, 0, _width, _height);
			graphics.endFill();
		}
		
		public function drawBorder():void{
			bitmapData.fillRect(bitmapData.rect, borderCol);
			bitmapData.fillRect(borderRect, backgroundCol);
		}
		
		public function renderTo(x:Number, y:Number, target:BitmapData):void{
			var p:Point = new Point(x, y);
			target.copyPixels(bitmapData, bitmapData.rect, p, null, null, true);
		}
		
	}

}