/* Copyright (c) 2009-2011, Kundan Singh. See LICENSING for details. */
package my.containers
{
	import flash.display.DisplayObject;
	
	import mx.containers.Canvas;
	import mx.events.ResizeEvent;
	import mx.effects.Move;

	/**
	 * A (vertical) Door container derived from Canvas behaves like a VBox, with an additional property called
	 * "locked". When locked is set to true, the door is locked and displays all the children elements.
	 * When the locked is set to false, the door gets unlocked and the children elements are animated away
	 * from the view as if the (sliding) door has opened. When the locked property is then set to true, the
	 * children slide back to the locked position. If there are N children, the door opens after floor(N/2)
	 * children, such that first floor(N/2) are moved to left, and remaining to right.
	 * 
	 * The Door component is used in RoomPage to display locked doors when the user lands on other person's
	 * page or on public room before the user enters the room.
	 */ 
	public class Door extends Canvas
	{
		//--------------------------------------
		// CLASS CONSTANTS
		//--------------------------------------
		
		private static const ANIMATE_DURATION:uint = 500;
		
		//--------------------------------------
		// PRIVATE VARIABLES
		//--------------------------------------
		
		private var _locked:Boolean = true;
		private var effects:Array = [];
		
		//--------------------------------------
		// CONSTRUCTOR
		//--------------------------------------
		
		/**
		 * Construct a new Door container.
		 */
		public function Door()
		{
			super();
			alpha = 1.0;
			setStyle("backgroundAlpha", 1.0);
			percentWidth = percentHeight = 100;
			horizontalScrollPolicy = verticalScrollPolicy = "off";
			addEventListener(ResizeEvent.RESIZE, resizeHandler, false, 0, true);
		}
		
		//--------------------------------------
		// GETTERS/SETTERS
		//--------------------------------------
		
		[Bindable]
		/**
		 * Whether the door is locked or not? If the door is locked, all the children are visible as
		 * normal position from left to right like in HBox. If the door is not locked, then the left
		 * children are hidden behind left edge and right ones behind right edge.
		 */
		public function get locked():Boolean
		{
			return _locked;
		}
		public function set locked(value:Boolean):void
		{
			var oldValue:Boolean = _locked;
			_locked = value;
			if (oldValue != value) {
				trace("Door.locked=" + value);
				var animate:Boolean = !stopEffects();
				
				var x:int, i:int, c:DisplayObject, move:Move;
				if (_locked) {
					for (x=0, i=0; i<this.numChildren; ++i) {
						c = this.getChildAt(i);
						move = new Move(c);
						move.xTo = x;
						effects.push(move);
						x += c.width;
					}
				}
				else {
					for (x=0, i=this.numChildren/2-1; i>=0; --i) {
						c = this.getChildAt(i);
						move = new Move(c);
						move.xTo = x - c.width;
						effects.push(move);
						x -= c.width;
					}
					for (x=this.width, i=this.numChildren/2; i<this.numChildren; ++i) {
						c = this.getChildAt(i);
						move = new Move(c);
						move.xTo = x;
						effects.push(move);
						x += c.width;
					}
				}
				for each (move in effects) {
					if (animate) {
						move.duration = ANIMATE_DURATION;
						move.play();
					}
					else {
						c = move.target as DisplayObject;
						c.x = move.xTo; 
					}
				}
				if (!animate)
					effects.splice(0, effects.length);
			}
		}
		
		//--------------------------------------
		// PUBLIC METHODS
		//--------------------------------------
		
		/**
		 * Override the addChildAt method to position the children correctly based on locked state.
		 */
		override public function addChildAt(child:DisplayObject, index:int):DisplayObject
		{
			var result:DisplayObject = super.addChildAt(child, index);
			
			var x:int, i:int, c:DisplayObject;
			
			stopEffects();
			if (locked) {
				for (x=0, i=0; i<this.numChildren; ++i) {
					c = this.getChildAt(i);
					c.x = x;
					x += c.width;
				}
			}
			else {
				for (x=0, i=this.numChildren/2-1; i>=0; --i) {
					c = this.getChildAt(i);
					c.x = x - c.width;
					x -= c.width;
				}
				for (x=this.width, i=this.numChildren/2; i<this.numChildren; ++i) {
					c = this.getChildAt(i);
					c.x = x;
					x += c.width;
				}
			}
			return result;
		}
		
		//--------------------------------------
		// PRIVATE METHODS
		//--------------------------------------
		
		private function resizeHandler(event:ResizeEvent):void
		{
			if (!locked) {
				stopEffects();
				var x:int, i:int, c:DisplayObject;
				for (x=this.width, i=this.numChildren/2; i<this.numChildren; ++i) {
					c = this.getChildAt(i);
					c.x = x;
					x += c.width;
				}
			}
		}
		
		/**
		 * Stop the currently playing effects, reset the effects array and return true if
		 * a playing effect was stopped.
		 */
		private function stopEffects():Boolean
		{
			var result:Boolean = false;
			for each (var move:Move in effects) {
				if (move.isPlaying) {
					move.end();
					result = true;
				}
			}
			effects.splice(0, effects.length);
			return result;
		}
	}
}
