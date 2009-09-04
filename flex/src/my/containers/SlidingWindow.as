/* Copyright (c) 2009, Kundan Singh. See LICENSING for details. */
package my.containers
{
	import flash.display.DisplayObject;
	import flash.events.MouseEvent;
	import flash.geom.Point;
		
	import mx.containers.Canvas;
	import mx.containers.Tile;
	import mx.core.UIComponent;
	import mx.effects.Move;
	import mx.events.ResizeEvent;

	/**
	 * Similar to the HBox, it applies the style to the inner Box.
	 */
	[Style(name="horizontalGap", type="Number", inherit="no")]
	
	/**
	 * Similar to the VBox, it applies the style to the inner Box.
	 */
	[Style(name="verticalGap", type="Number", inherit="no")]
	
	/**
	 * Dispatched when the user drags the component to change the selectedIndex property.
	 */
	[Event(name="selectedChange", type="flash.events.Event")]
	
	/**
	 * Implements a sliding window container similar to Box, but allows a window view
	 * smaller than the Box view, and user can slide the window over the box. All the
	 * children are resized to same value based on the size of this view and the
	 * visibleCount property.
	 */
	public class SlidingWindow extends Canvas
	{
		//--------------------------------------
		// CLASS CONSTANTS
		//--------------------------------------
		
		private static const inheritedStyles:Array = ["horizontalGap", "verticalGap",
			"paddingLeft", "paddingRight", "paddingTop", "paddingBottom"];
			
		//--------------------------------------
		// PRIVATE VARIABLES
		//--------------------------------------
		
		private var innerCanvas:Canvas;
		private var innerBox:Tile;
		private var _selectedIndex:int = -1;
		private var _numColumns:int = -1;
		private var _visibleCount:int = 1;
		private var _allowDrag:Boolean = false;
		private var _moveEffect:Move;
		private var _styleChange:Boolean = false;
		private var _lastChange:Date = new Date();
		
		//--------------------------------------
		// PUBLIC VARIABLES
		//--------------------------------------
		
		public var animateOnResize:Boolean = false;
		
		//--------------------------------------
		// CONSTRUCTOR
		//--------------------------------------

		public function SlidingWindow()
		{
			super();
		
			addEventListener(ResizeEvent.RESIZE, resizeHandler, false, 0, true);
			
			_moveEffect = new Move();
			_moveEffect.duration = 500;
			
			innerCanvas = new Canvas();
			innerBox = new Tile();
			innerBox.direction = 'horizontal';
			innerCanvas.horizontalScrollPolicy = innerCanvas.verticalScrollPolicy = "off";
			innerBox.horizontalScrollPolicy = innerBox.verticalScrollPolicy = "off";
			horizontalScrollPolicy = verticalScrollPolicy = "off";
			innerCanvas.addChildAt(innerBox, 0);
			
			super.addChildAt(innerCanvas, 0);
		}
		
		//--------------------------------------
		// GETTERS/SETTERS
		//--------------------------------------

		[Bindable]
		/**
		 * The currently selected index of the child that is visible in the window.
		 */
		public function get selectedIndex():Number
		{
			return _selectedIndex;
		}
		public function set selectedIndex(value:Number):void
		{
			var old:Number = _selectedIndex;
			_selectedIndex = value;
			
			var now:Date = new Date();
			var diff:int = (now.time - _lastChange.time);
			updatePosition(old != -1 && diff > 100); // don't animate for first assignment
			_lastChange = now;
		}
		
		/**
		 * Number of boxes in the sliding window. The numChildren property is not useful
		 * since we want the children of underying Box.
		 */
		public function get numBoxes():Number
		{
			return innerBox != null ? innerBox.numChildren : 0;
		}
		
		[Bindable]
		/**
		 * Number of columns.
		 */
		public function get numColumns():Number
		{
			if (_numColumns < 0) 
				_numColumns = numBoxes / 2;
			return _numColumns;
		}
		public function set numColumns(value:Number):void
		{
			_numColumns = value;
			updateSize();
			updatePosition();
		}
		
		[Bindable]
		/**
		 * The number of children that are visible in the window.
		 * Default is 1.
		 */
		public function get visibleCount():Number
		{
			return _visibleCount;
		}
		public function set visibleCount(value:Number):void
		{
			if (value >= 1) {
				_visibleCount = value;
				updateSize();
				updatePosition();
			}
		}
		
		[Bindable]
		/**
		 * Direction of the underlying Box. Default is 'horizontal'.
		 */
		public function get direction():String
		{
			return innerBox.direction;
		}
		public function set direction(value:String):void
		{
			innerBox.direction = value;
			updateSize();
			updatePosition();
		}
		
		[Bindable]
		/**
		 * Whether we allow user control to drag?
		 */
		public function get allowDrag():Boolean
		{
			return _allowDrag;
		}
		public function set allowDrag(value:Boolean):void
		{
			var old:Boolean = _allowDrag;
			_allowDrag = value;
			if (old != value) {
				if (!value) {
					innerBox.removeEventListener(MouseEvent.MOUSE_DOWN, mouseDownHandler);
					innerBox.removeEventListener(MouseEvent.MOUSE_UP, mouseUpHandler);
					removeEventListener(MouseEvent.ROLL_OVER, rollOverHandler);
					removeEventListener(MouseEvent.ROLL_OUT, rollOutHandler);
				}
				else {
					innerBox.addEventListener(MouseEvent.MOUSE_DOWN, mouseDownHandler, false, 0, true);
					innerBox.addEventListener(MouseEvent.MOUSE_UP, mouseUpHandler, false, 0, true);
					addEventListener(MouseEvent.ROLL_OVER, rollOverHandler, false, 0, true);
					addEventListener(MouseEvent.ROLL_OUT, rollOutHandler, false, 0, true);
				}
			}
		}
		
		//--------------------------------------
		// PUBLIC METHODS
		//--------------------------------------
		
		override public function addChild(child:DisplayObject):DisplayObject
		{
			callLater(updateSize);
			return innerBox.addChild(child);
		}
		override public function addChildAt(child:DisplayObject, index:int):DisplayObject
		{
			callLater(updateSize);
			return innerBox.addChildAt(child, index);
		}
		override public function removeChild(child:DisplayObject):DisplayObject
		{
			return innerBox.removeChild(child);
		}
		override public function removeChildAt(index:int):DisplayObject
		{
			return innerBox.removeChildAt(index);
		}
		override public function removeAllChildren():void
		{
			innerBox.removeAllChildren();
		}
		
		override public function styleChanged(styleProp:String):void
		{
			super.styleChanged(styleProp);
			if (styleProp == null) {
				propagateStyle("horizontalGap", innerBox);
				propagateStyle("verticalGap", innerBox);
				_styleChange = true;
			} 
			else if (inheritedStyles.indexOf(styleProp) >= 0) {
				if (styleProp == "horizontalGap" || styleProp == "verticalGap")
					propagateStyle(styleProp, innerBox);
				else
					_styleChange = true;
			}
		}
		
		/**
		 * Since we should not override the getChildIndex method, we define another one.
		 */
		public function getWindowIndex(child:DisplayObject):int
		{
			return innerBox.getChildIndex(child);
		}
		
		/**
		 * Since we should not override the getChildAt method, we define another one.
		 */
		public function getWindowAt(index:int):DisplayObject
		{
			return innerBox.getChildAt(index);
		}
		
		//--------------------------------------
		// PROTECTED METHODS
		//--------------------------------------

		override protected function updateDisplayList(w:Number, h:Number):void
		{
			super.updateDisplayList(w, h);
			if (_styleChange) {
				callLater(updateStyle);
				callLater(updateSize);
				callLater(updatePosition);
				_styleChange = false;
			}
		}
		
		//--------------------------------------
		// PRIVATE METHODS
		//--------------------------------------

		private function propagateStyle(styleProp:String, item:UIComponent):void
		{
			if (getStyle(styleProp) != undefined)
				item.setStyle(styleProp, getStyle(styleProp));
		}
		
		private function resizeHandler(event:ResizeEvent):void
		{
			updateStyle();
			updateSize();
			updatePosition(animateOnResize);
		}
		
		private function updateStyle():void
		{
 			innerCanvas.height = this.height - getStyle("paddingTop") - getStyle("paddingBottom")
 			innerCanvas.width = this.width - getStyle("paddingLeft") - getStyle("paddingRight");
 			innerCanvas.x = getStyle("paddingLeft");
 			innerCanvas.y = getStyle("paddingRight");
 		}
 		
		private function updateSize():void
		{
			var child:DisplayObject;
			var rows:int = (numColumns > 0 ? Math.ceil(numBoxes / numColumns) : 0);
 			innerBox.tileWidth = direction == 'horizontal' ? innerCanvas.width / this.visibleCount : innerCanvas.width;
 			innerBox.tileHeight = direction == 'horizontal' ? innerCanvas.height : innerCanvas.height / this.visibleCount;
			innerBox.height = this.height * rows;
			innerBox.width = this.width * numColumns;
 			
			if (direction == 'horizontal') {
				for each (child in innerBox.getChildren()) {
					child.height = innerCanvas.height;
					child.width = innerCanvas.width / this.visibleCount;
				}
			}
			else {
				for each (child in innerBox.getChildren()) {
					child.height = innerCanvas.height / this.visibleCount;
					child.width = innerCanvas.width;
				}
			}
		}
		
		private function updatePosition(animate:Boolean=true):void
		{
			var newPos:Point;
			var c:int, r:int;
			
			if (direction == 'horizontal') {
				c = (numColumns > 0 ? selectedIndex % numColumns : 0);
				r = (numColumns > 0 ? Math.floor(selectedIndex / numColumns) : 0);
				newPos = new Point(-c * innerCanvas.width / this.visibleCount, -r * innerCanvas.height);
			}
			else {
				c = (numColumns > 0 ? selectedIndex % numColumns : 0);
				r = (numColumns > 0 ? Math.floor(selectedIndex / numColumns) : 0);
				newPos = new Point(-c * innerCanvas.width, -r * innerCanvas.height / this.visibleCount);
			}
			
			if (newPos.x != innerBox.x || newPos.y != innerBox.y) {
				if (_moveEffect.isPlaying)
					_moveEffect.stop();
				if (animate) {
					_moveEffect.xTo = newPos.x;
					_moveEffect.yTo = newPos.y;
					_moveEffect.play([innerBox]);
				}
				else {
					innerBox.x = newPos.x;
					innerBox.y = newPos.y;
				}
			}
		}
		
		private var dragging:Boolean = false;
		private var draggable:Boolean = false;
		private var oldPos:Point;
		
		private function mouseDownHandler(event:MouseEvent):void
		{
			if (draggable) {
				dragging = true;
				oldPos = new Point(this.mouseX, this.mouseY);
				innerBox.startDrag();
			}
		}
		private function mouseUpHandler(event:MouseEvent):void
		{
			if (dragging) {
				dragging = false;
				innerBox.stopDrag();
				innerBox.validateNow();
				callLater(updateSelectedIndex);
			}
		}
		private function rollOverHandler(event:MouseEvent):void
		{
			draggable = true;
		}
		private function rollOutHandler(event:MouseEvent):void
		{
			draggable = false;
			if (dragging) {
				dragging = false;
				innerBox.stopDrag();
				callLater(updateSelectedIndex);
			}
		}
		
		private function updateSelectedIndex():void
		{
			var newPos:Point = new Point(this.mouseX, this.mouseY);
			var numRows:int = (numColumns > 0 ? Math.ceil(numBoxes / numColumns) : 0);
			var r:int = (numColumns > 0 ? Math.floor(selectedIndex / numColumns) : 0);
			var c:int = (numColumns > 0 ? selectedIndex % numColumns : 0);
			var diffX:int = Math.abs(newPos.x - oldPos.x);
			var diffY:int = Math.abs(newPos.y - oldPos.y);
			
			if (diffX > diffY) { // horizontal scroll
				if (newPos.x > oldPos.x && c > 0) // left scroll
					--c;
				else if (newPos.x < oldPos.x && c < numColumns-1)
					++c;
				else {
					updatePosition();
					return;
				}
			}
			else { // vertical scroll
				if (newPos.y > oldPos.y && r > 0) // left scroll
					--r;
				else if (newPos.y < oldPos.y && y < numRows-1)
					++r;
				else { 
					updatePosition();
					return;
				}
			}
			var i:int = r*numColumns + c;
			if (i < 0) i = 0;
			if (i >= numBoxes) i = numBoxes - 1;
			if (selectedIndex != i) {
				selectedIndex = i;
				dispatchEvent(new Event("selectedChange"));
			}
			else
				updatePosition();
		}
	}
}