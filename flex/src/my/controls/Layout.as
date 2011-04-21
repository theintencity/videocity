/* Copyright (c) 2009-2011, Kundan Singh. See LICENSING for details. */
package my.controls
{
	import flash.display.Graphics;
	import flash.events.MouseEvent;
	
	import mx.core.UIComponent;
	
	/**
	 * The Layout component displays a small layout control view, which allows the user to change to a 
	 * different view. This component works in conjunction with the SlidingWindow container, and controls
	 * and/or displays the current state of the container view. The important properties are numBoxes,
	 * numColumns and selectedIndex. When the user clicks on a layout to change, the selectionChange event
	 * is dispatched. 
	 */
	public class Layout extends UIComponent
	{
		//--------------------------------------
		// PRIVATE PROPERTIES
		//--------------------------------------
		
		private var _selectedIndex:int = -1;
		private var _numBoxes:int = -1;
		private var _numColumns:int = 0;
		private var _numRows:int = 0;
		
		//--------------------------------------
		// CONSTRUCTOR
		//--------------------------------------
		
		public function Layout()
		{
			addEventListener(MouseEvent.CLICK, mouseClickHandler, false, 0, true);
		}
		
		//--------------------------------------
		// GETTERS/SETTERS
		//--------------------------------------
		
		[Bindable("selectionChange")]
		/**
		 * The selected index in the layout.
		 */
		public function get selectedIndex():Number
		{
			return _selectedIndex;
		}
		public function set selectedIndex(value:Number):void
		{
			if (value < _numBoxes) {
				var old:Number = _selectedIndex;
				_selectedIndex = value;
				if (old != value) {
					dispatchEvent(new Event("selectionChange"));
					invalidateDisplayList();
				}
			}
		}
		
		[Bindable]
		/**
		 * Number of boxes.
		 */
		public function get numBoxes():Number
		{
			return _numBoxes;
		}
		public function set numBoxes(value:Number):void
		{
			_numBoxes = value;
			if (_numColumns > 0)
				_numRows = Math.ceil(_numBoxes / _numColumns)
			invalidateDisplayList();
		}
		
		[Bindable]
		/**
		 * Number of columns (M) to define NxM layout of the boxes.
		 */
		public function get numColumns():Number
		{
			return _numColumns;
		}
		public function set numColumns(value:Number):void
		{
			_numColumns = value;
			if (_numColumns > 0)
				_numRows = Math.ceil(_numBoxes / _numColumns);
			invalidateDisplayList();
		}
		
		//--------------------------------------
		// PROTECTED METHODS
		//--------------------------------------
		
		override protected function updateDisplayList(w:Number, h:Number):void
		{
			var g:Graphics = graphics;
			g.clear();
			
			super.updateDisplayList(w, h);
			
			var color:uint = (getStyle("color") != null ? getStyle("color") as uint : 0x000000);
			var bg:uint = (getStyle("backgroundColor") != null ? getStyle("backgroundColor") as uint : 0xc8c8c8);
			
			g.beginFill(bg);
			g.drawRect(1, 1, w-2, h-2);
			g.endFill();
			
			g.lineStyle(1, color);
			g.drawRect(0, 0, w-1, h-1);
			
			var i:int = 0;
			for (var r:int=0; r<_numRows; ++r) {
				for (var c:int=0; c<_numColumns; ++c) {
					if (i < _numBoxes) {
						if (i == _selectedIndex)
							g.beginFill(color);
						g.drawRect(3+c*18, 3+r*14, 16, 12);
						if (i == _selectedIndex)
							g.endFill();
					}
					++i;
				}
			}
		}
		
		override protected function measure():void
		{
			measuredWidth = _numColumns * (16 + 2) - 2 + 6;
			measuredHeight = _numRows * (12 + 2) - 2 + 6;
		}
		
		//--------------------------------------
		// PRIVATE METHODS
		//--------------------------------------
		
		private function mouseClickHandler(event:MouseEvent):void
		{
			var c:int = Math.floor(this.mouseX / 18);
			var r:int = Math.floor(this.mouseY / 14);
			var i:int = r * _numColumns + c;
			if (i < 0) 
				i = 0;
			if (i >= _numBoxes)
				i = _numBoxes;
			this.selectedIndex = i;
		}
		
	}
}
