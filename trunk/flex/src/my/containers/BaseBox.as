/* Copyright (c) 2009, Kundan Singh. See LICENSING for details. */
package my.containers
{
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	
	import mx.containers.Canvas;
	import mx.controls.Button;
	import mx.controls.Label;
	import mx.effects.Move;
	import mx.events.FlexEvent;
	import mx.events.ResizeEvent;
	
	/**
	 * Dispatched when the user clicks on the delete button on top-right corner.
	 */
	[Event(name="delete", type="flash.events.Event")]
	
	/**
	 * Dispatched when the user clicks on the maximize/minimize button on top-right corner.
	 */
	[Event(name="maximize", type="flash.events.Event")]
	
	/**
	 * Dispatched when the user clicks on the dock/undock button on top-right corner.
	 */
	[Event(name="dock", type="flash.events.Event")]
	
	/**
	 * BaseBox is the base class of all other boxes that can be added to ContainerBox. The user interface
	 * displays the top-bar with buttons and label text. The class defines certain common properties and 
	 * methods that are available to all sub-classes.
	 */
	public class BaseBox extends Canvas
	{
		//--------------------------------------
		// CLASS CONSTANTS
		//--------------------------------------
		
		// various event types.
		public static const DELETE:String   = "delete";
		public static const MAXIMIZE:String = "maximize";
		public static const DOCK:String     = "dock";
		
		//--------------------------------------
		// PRIVATE PROPERTIES
		//--------------------------------------

		[Bindable]
		/*
		 * Whether the user has mouse rolled over this box or not? The top-bar automatically hides on roll-out.
		 */
		protected var hover:Boolean = false;
		
		/*
		 * In the docked mode, there is a drag button on the bottom right corner which is used to re-size the
		 * component's view.
		 */
		private var dragButton:Button;
		
		/*
		 * The currently playing move effect on the top-bar to show or hide.
		 */
		private var effect:Move;
		
		/*
		 * The top-bar that displays the title and buttons.
		 */
		private var _titleBar:Canvas;
		
		/*
		 * The text to be displayed as title in the top-bar.
		 */
		private var _titleBarLabel:Label;
		
		/*
		 * The button used to maximize or minimize the component.
		 */
		private var _maximizeButton:Button;
		
		/*
		 * The button used to dock or undock the component.
		 */
		private var _dockButton:Button;
		
		/*
		 * The button used to delete (remove) the component.
		 */
		private var _deleteButton:Button;
		
		/*
		 * The optional status bar gets displayed in some boxes in the bottom bar.
		 */
		private var _statusBar:Canvas;
		
		/*
		 * Whether to show the status bar or not? Default is false.
		 */
		private var _showStatusBar:Boolean = false;
		
		/*
		 * Whether the current component is in playing or paused state.
		 */
		private var _playing:Boolean = true;
		
		/*
		 * Whether to auto-hide the status after a timeout or not?
		 */
		private var _autoHide:Boolean = false;
		
		/*
		 * Timeout for auto-hide of the status bar.
		 */
		private var _autoHideTimer:Timer = null;
		
		//--------------------------------------
		// CONSTRUCTOR
		//--------------------------------------

		/**
		 * Construct a new object, initialize certain properties and add event listeners.
		 */
		public function BaseBox() 
		{
			this.minWidth = 80;
			this.minHeight = 60;
			this.styleName = "baseBox";
			this.doubleClickEnabled = true;
			this.addEventListener(MouseEvent.ROLL_OVER, rollOverHandler, false, 0, true);
			this.addEventListener(MouseEvent.ROLL_OUT, rollOutHandler, false, 0, true);
			this.addEventListener(MouseEvent.DOUBLE_CLICK, doubleClickHandler, false, 0, true);
			this.addEventListener(FlexEvent.REMOVE, removeHandler, false, 0, true);
			this.addEventListener(ResizeEvent.RESIZE, resizeHandler, false, 0, true);
			
			effect = new Move();
			effect.duration = 200;
			
			createTitleBar();
			createStatusBar();
		}
	
		//--------------------------------------
		// GETTERS/SETTERS
		//--------------------------------------

		[Bindable]
		/**
		 * The label text that gets displayed in the top title bar. Setting this to null actually 
		 * resets the value to empty string "".
		 */
		override public function get label():String
		{
			return super.label;
		}
		override public function set label(value:String):void
		{
			if (value == null)
				value = "";
			super.label = value;
			if (_titleBarLabel)
				_titleBarLabel.text = value;
		}
		
		[Bindable]
		/**
		 * Whether this component is currently in the playing (true) or paused (false) state. The 
		 * interpretation of this property is left to the sub-class. In general, a video related sub-class
		 * will pause the video when playing is false.
		 */
		public function get playing():Boolean
		{
			return _playing;
		}
		public function set playing(value:Boolean):void
		{
			_playing = value;
		}
		
		/**
		 * Whether this component shows the bottom status bar or not?
		 */
		public function get showStatusBar():Boolean
		{
			return _showStatusBar;
		}
		public function set showStatusBar(value:Boolean):void
		{
			var oldValue:Boolean = _showStatusBar;
			_showStatusBar = value;
			if (value != oldValue) {
				if (_statusBar) {
					if (value) {
						_statusBar.height = 15;
						_statusBar.visible = true;
					}
					else {
						_statusBar.visible = false;
						_statusBar.height = 0;
					}
				}
			}
		}
		
		/**
		 * The status bar component in this box.
		 */
		public function get statusBar():Canvas
		{
			return _statusBar;
		}
		
		/**
		 * Whether the component is resize enabled or not? A resizeable view has a drag button,
		 * which the user can click and drag to resize the view.
		 */
		public function get resizeable():Boolean
		{
			return dragButton != null;
		}
		public function set resizeable(value:Boolean):void
		{
			var oldValue:Boolean = (dragButton != null);
			if (oldValue != value) {
				if (value) { // add a button
					dragButton = new Button();
					dragButton.width = 12;
					dragButton.height = 12;
					dragButton.buttonMode = true;
					dragButton.styleName = "dragButtonStyle";
					dragButton.addEventListener(MouseEvent.MOUSE_DOWN, dragButtonDownHandler, false, 0, true);
					this.addChild(dragButton);
				}
				else if (oldValue) {
					this.removeChild(dragButton);
					dragButton = null;
				}
			}
		}
		
		/**
		 * Whether this component auto-hides the status bar or not?
		 */
		public function get autoHide():Boolean
		{
			return _autoHide;
		}
		public function set autoHide(value:Boolean):void
		{
			var oldValue:Boolean = _autoHide;
			_autoHide = value;
			if (value != oldValue) {
				if (value) {
					this.addEventListener(MouseEvent.MOUSE_MOVE, mouseMoveHandler, false, 0, true);
					startAutoHideTimer();
				}
				else {
					this.removeEventListener(MouseEvent.MOUSE_MOVE, mouseMoveHandler);
					stopAutoHideTimer();
				}
			}
		}
		
		//--------------------------------------
		// PUBLIC METHODS
		//--------------------------------------

		/**
		 * When a new child is added, the title bar is moved to the top of the Z stack so that it
		 * is visible above all.
		 */
		override public function addChildAt(child:DisplayObject, index:int):DisplayObject
		{
			var result:DisplayObject = super.addChildAt(child, index);
			if (_titleBar)
				super.setChildIndex(_titleBar, this.numChildren-1);
			return result;
		}

		//--------------------------------------
		// PRIVATE METHODS
		//--------------------------------------

		/*
		 * The dragging logic is implemented by handling the mouseMove event on the drag button between a
		 * buttonDown and a buttonUp event timeline. On mouseMove, the width and height of this component is
		 * adjusted based on the position of the mouse.
		 */
		  
		private function dragButtonDownHandler(event:MouseEvent):void
		{
			event.stopPropagation();
			if (stage != null) {
				stage.addEventListener(MouseEvent.MOUSE_MOVE, dragMouseMoveHandler, false, 0, true);
				stage.addEventListener(MouseEvent.MOUSE_UP, dragMouseUpHandler, false, 0, true);
			}
		}
		
		private function dragMouseMoveHandler(event:MouseEvent):void
		{
			if (stage != null) {
				this.width = stage.mouseX - this.x;
				this.height = stage.mouseY - this.y;
			}
		}
		
		private function dragMouseUpHandler(event:MouseEvent):void
		{
			if (stage != null) {
				stage.removeEventListener(MouseEvent.MOUSE_MOVE, dragMouseMoveHandler);
				stage.removeEventListener(MouseEvent.MOUSE_UP, dragMouseUpHandler);
			}
		}
		
		private function removeHandler(event:Event):void
		{
			if (stage != null) {
				stage.removeEventListener(MouseEvent.MOUSE_MOVE, dragMouseMoveHandler);
				stage.removeEventListener(MouseEvent.MOUSE_UP, dragMouseUpHandler);
			}
		}
		
		/*
		 * The top title bar is shown and hidden based on mouse roll-over and roll-out events.
		 */
		private function rollOverHandler(event:MouseEvent):void
		{
			if (_titleBar) {
				_titleBar.endEffectsStarted();
				_titleBar.y = 0;
			}
			this.hover = true;
			
			if (autoHide) {
				startAutoHideTimer();
			}
		}
		private function rollOutHandler(event:MouseEvent):void
		{
			if (_titleBar) {
				_titleBar.endEffectsStarted();
				_titleBar.y = -15;
			}
			this.hover = false;
			
			if (autoHide) {
				stopAutoHideTimer();
			}
		}
		
		private function mouseMoveHandler(event:MouseEvent):void
		{
			
			if (!this.hover) {
				if (_titleBar) {
					_titleBar.endEffectsStarted();
					_titleBar.y = 0;
				}
				this.hover = true;
			}
				
			startAutoHideTimer();
		}
		
		private function startAutoHideTimer():void
		{
			stopAutoHideTimer();
			if (_autoHideTimer == null) {
				_autoHideTimer = new Timer(3000, 1);
				_autoHideTimer.addEventListener(TimerEvent.TIMER, autoHideTimerHandler, false, 0, true);
				_autoHideTimer.start();
			}
		}
		private function stopAutoHideTimer():void
		{
			if (_autoHideTimer != null) {
				_autoHideTimer.stop();
				_autoHideTimer = null;
			}
		}
		private function autoHideTimerHandler(event:TimerEvent):void
		{
			_autoHideTimer = null;
			if (_autoHide) {
				if (_titleBar) {
					_titleBar.endEffectsStarted();
					_titleBar.y = -15;
				}
				this.hover = false;
			}
		}
		
		/*
		 * Double clicking on this component dispatched the maximize event.
		 */
		private function doubleClickHandler(event:MouseEvent):void
		{
			this.dispatchEvent(new Event(MAXIMIZE));
		}
		
		/*
		 * Create the top title bar including the text label and the buttons.
		 */ 
		private function createTitleBar():void
		{
			_titleBar = new Canvas();
			_titleBar.percentWidth = 100;
			_titleBar.height = 15;
			_titleBar.y = -15;
			_titleBar.setStyle("moveEffect", effect);
			_titleBar.setStyle("backgroundColor", 0x000000);
			_titleBar.setStyle("backgroundAlpha", 0.2);
			_titleBar.addEventListener(MouseEvent.MOUSE_DOWN, stopPropagation, false, 0, true);
			_titleBar.addEventListener(MouseEvent.MOUSE_UP, stopPropagation, false, 0, true);
			this.addChild(_titleBar);
			
			_titleBarLabel = new Label();
			_titleBarLabel.text = super.label;
			_titleBarLabel.x = 2;
			_titleBarLabel.y = 0;
			_titleBarLabel.setStyle("color", 0xffffff);
			_titleBarLabel.setStyle("fontSize", 9);
			_titleBar.addChild(_titleBarLabel);
			
			_deleteButton = new Button();
			_deleteButton.width = 10;
			_deleteButton.height = 10;
			_deleteButton.x = this.width - 14;
			_deleteButton.y = 2;
			_deleteButton.doubleClickEnabled = true;
			_deleteButton.setStyle("cornerRadius", 5);
			_deleteButton.setStyle("fillColors", [0xffa0a0, 0xe0a0a0]);
			_deleteButton.toolTip = _("remove");
			_deleteButton.addEventListener(MouseEvent.CLICK, deleteButtonHandler, false, 0, true);
			_titleBar.addChild(_deleteButton);
			
			_maximizeButton = new Button();
			_maximizeButton.width = 10;
			_maximizeButton.height = 10;
			_maximizeButton.x = this.width - 26;
			_maximizeButton.y = 2;
			_maximizeButton.setStyle("cornerRadius", 5);
			_maximizeButton.setStyle("fillColors", [0xa0ffa0, 0xa0e0a0]);
			_maximizeButton.toolTip = _("maximize") + "/" + _("restore");
			_maximizeButton.addEventListener(MouseEvent.CLICK, maximizeButtonHandler, false, 0, true);
			_titleBar.addChild(_maximizeButton);
			
			_dockButton = new Button();
			_dockButton.width = 10;
			_dockButton.height = 10;
			_dockButton.x = this.width - 38;
			_dockButton.y = 2;
			_dockButton.setStyle("cornerRadius", 5);
			_dockButton.setStyle("fillColors", [0xa0a0ff, 0xa0a0e0]);
			_dockButton.toolTip = _("dock") + "/" + _("undock");
			_dockButton.addEventListener(MouseEvent.CLICK, dockButtonHandler, false, 0, true);
			_titleBar.addChild(_dockButton);
		}
		
		/*
		 * Dispatch the appropriate events when the buttons are clicked.
		 */

		private function deleteButtonHandler(event:MouseEvent):void
		{
			dispatchEvent(new Event(DELETE));
		}
		
		private function maximizeButtonHandler(event:MouseEvent):void
		{
			dispatchEvent(new Event(MAXIMIZE));
		}
		
		private function dockButtonHandler(event:MouseEvent):void
		{
			dispatchEvent(new Event(DOCK));
		}
		
		/*
		 * Move the buttons to the top-right corner when the component is resized.
		 */
		private function resizeHandler(event:ResizeEvent):void
		{
			if (_deleteButton)
				_deleteButton.x = this.width - 14;
			if (_maximizeButton)
				_maximizeButton.x = this.width - 26;
			if (_dockButton)
				_dockButton.x = this.width - 38;
		}
		
		/*
		 * Create a status bar at the bottom.
		 */
		private function createStatusBar():void
		{
			_statusBar = new Canvas();
			_statusBar.percentWidth = 100;
			_statusBar.setStyle("backgroundColor", 0xc8c8c8);
			_statusBar.setStyle("bottom", 0);
			_statusBar.visible = _showStatusBar ? true : false;
			_statusBar.height = _showStatusBar ? 15 : 0;
			this.addChild(_statusBar);
		}
		
		/*
		 * Stopping event propagation.
		 */
		private function stopPropagation(event:MouseEvent):void
		{
			event.stopPropagation();
		}
	}
}
