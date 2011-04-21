/* Copyright (c) 2009-2011, Kundan Singh. See LICENSING for details. */
package my.containers
{
	import flash.display.DisplayObject;
	import flash.events.MouseEvent;
	
	import mx.collections.ArrayCollection;
	import mx.containers.Canvas;
	import mx.core.UIComponent;
	import mx.effects.Effect;
	import mx.effects.Move;
	import mx.effects.Parallel;
	import mx.effects.Resize;
	import mx.events.CollectionEvent;
	import mx.events.CollectionEventKind;
	import mx.events.ResizeEvent;
	
	/**
	 * Dispatched when a child compoenent is added, removed or replaced in this container box.
	 * This event indicates that the change has already happened.
	 */
	[Event(name="collectionChange", type="mx.events.CollectionEvent")]
	
	/**
	 * A container box to hold various other children component. The children are laid out in a tile. 
	 * If a child is maximized, it occupies as much as possible in the box without breaking the aspect ratio
	 * and remaining children are tiled in the remaining space. Any number of children can be undocked in which 
	 * case they appear as draggable picture-in-picture, and remaining children appear in background full
	 * view in tile mode.
	 */
	public class ContainerBox extends Canvas
	{
		//--------------------------------------
		// CLASS CONSTANTS
		//--------------------------------------
		
		// if maximized child is present, then minimum dimensions of the PIP or small child.
		private static const MIN_WIDTH:uint = 80;
		private static const MIN_HEIGHT:uint = 60;
		
		// default dimension of the undocked child
		private static const UNDOCK_DEFAULT_WIDTH:uint = 120;
		private static const UNDOCK_DEFAULT_HEIGHT:uint = 90;
		
		// max time to wait before doing animation, if two changes occur in succession.
		private static const MIN_CHANGE_TIME:uint = 100;
		
		// duration for which effect is played: either move or resize
		private static const EFFECT_DURATION:uint = 500;
		
		//--------------------------------------
		// PRIVATE VARIABLES
		//--------------------------------------
		
		// child layouts before drag. indexed by child. value is BoxLayout object.
		private var layouts:Object = new Object();
		
		// position of the configuration
		private var x0:uint = 0, y0:uint = 0, optCol:uint = 1;
		
		// the current maximized child. Null means pure tile mode.
		private var _maximized:DisplayObject = null;
		
		// the layout object for this box
		private var containerLayout:ContainerLayout = new ContainerLayout(1, 1, 1, 1, 0, 0, 0, 0, 0, 0, true);
		
		// we don't do animation if boxes are added/removed in quick succession.
		private var lastChange:Date = new Date();
		
		// list of children that are undocked: i.e., displayed as floating picture in picture
		private var undocked:ArrayCollection = new ArrayCollection();
				
		// whether drag is enabled or not? indexed by child
		private var drags:Object = new Object();
		
		// currently playing effects
		private var effects:Array = new Array();
		
		//--------------------------------------
		// PUBLIC VARIABLES
		//--------------------------------------
		
		/**
		 * Whether the children of this box are animated when the box is resized?
		 * The default value is true. If set to false, the children are not animated to resize.
		 */
		public var animateOnResize:Boolean = true;
		
		//--------------------------------------
		// CONSTRUCTOR
		//--------------------------------------
		
		/**
		 * Construct a new container box object.
		 */
		public function ContainerBox()
		{
			trace("ContainerBox created");
			addEventListener(ResizeEvent.RESIZE, resizeHandler, false, 0, true);
			undocked.addEventListener(CollectionEvent.COLLECTION_CHANGE, undockedChangeHandler, false, 0, true);
		}
		
		//--------------------------------------
		// GETTERS/SETTERS
		//--------------------------------------
		
		/**
		 * The maximized property represents the maximized child component of this box, if any. If a child is
		 * set as maximized, then previous maximized child is restored. Changing this property causes animation
		 * effect of moving the child component to maximized view so that it occupies most of the available
		 * space of this box, and all other children are accommodated in the remaining space. The undocked
		 * children are not affected as they remain floating on top.
		 */
		public function get maximized():DisplayObject
		{
			return _maximized;
		}
		public function set maximized(value:DisplayObject):void
		{
			var oldValue:DisplayObject = _maximized;
			_maximized = value;
			if (oldValue != value) {
				trace("maximized " + oldValue + "=>" + value);
				var stop:Boolean = true;
				if (value != null) {
					if (undocked.contains(value)) {
						undocked.removeItemAt(undocked.getItemIndex(value));
						stop = false;
					}
				}

				if (oldValue == null) {
					// bring new child to the front
					if (undocked.length < this.numChildren && contains(value) && getChildIndex(value) != this.numChildren - undocked.length - 1) {
						setChildIndex(value, this.numChildren - undocked.length - 1);
					}
				}
				else if (value == null) {
					// bring new child to the front
					if (undocked.length < this.numChildren && contains(oldValue) && getChildIndex(oldValue) != this.numChildren - undocked.length - 1) {
						setChildIndex(oldValue, this.numChildren - undocked.length - 1);
					}
				}
				else {
					// switch the maximized and old maximized position, and make maximized on front
					if (contains(value) && contains(oldValue))
						setChildIndex(oldValue, getChildIndex(value));
					if (undocked.length < this.numChildren && contains(value) && getChildIndex(value) != this.numChildren - undocked.length - 1) {
						setChildIndex(value, this.numChildren - undocked.length - 1);
					}
				}
				if (value == null || contains(value)) {
					calculateLayout(this.numChildren - undocked.length);
					layoutBoxes(stop);
				}
			}
		}
		
		//--------------------------------------
		// PUBLIC METHODS
		//--------------------------------------
		
		/* Just override various methods to add/remove child with our implementation. */
		
		override public function addChild(child:DisplayObject):DisplayObject
		{
			return addChildInternal(child, numChildren);
		}
		override public function addChildAt(child:DisplayObject, index:int):DisplayObject
		{
			return addChildInternal(child, index);
		}
		override public function removeChild(child:DisplayObject):DisplayObject
		{
			return removeChildInternal(getChildIndex(child));
		}
		override public function removeChildAt(index:int):DisplayObject
		{
			return removeChildInternal(index);
		}
		override public function removeAllChildren():void
		{
			removeAllChildrenInternal();
		}
		
		/**
		 * When an oldChild is replaced by a newChild, there is usually no animation to indicate the change.
		 * The newChild takes the position and dimension of the old child. If the old child was maximized or
		 * undocked then the new child is also maximized or undocked.
		 */
		public function replaceChild(oldChild:DisplayObject, newChild:DisplayObject):void
		{	
			var index:int = this.getChildIndex(oldChild);
			if (oldChild != newChild) {
				trace("replaceChild " + oldChild + "=>" + newChild);
				if (index >= 0) {
					newChild.x = oldChild.x;
					newChild.y = oldChild.y;
					newChild.width = oldChild.width;
					newChild.height = oldChild.height;
					newChild.addEventListener(MouseEvent.MOUSE_DOWN, mouseDownHandler, false, 0, true);
					newChild.addEventListener(MouseEvent.MOUSE_UP, mouseUpHandler, false, 0, true);
					newChild.addEventListener(MouseEvent.ROLL_OVER, rollOverHandler, false, 0, true);
					newChild.addEventListener(MouseEvent.ROLL_OUT, rollOutHandler, false, 0, true);
					oldChild.removeEventListener(MouseEvent.MOUSE_DOWN, mouseDownHandler);
					oldChild.removeEventListener(MouseEvent.MOUSE_UP, mouseUpHandler);
					oldChild.removeEventListener(MouseEvent.ROLL_OVER, rollOverHandler);
					oldChild.removeEventListener(MouseEvent.ROLL_OUT, rollOutHandler);
					
					if (undocked.contains(oldChild)) {
						var i:int = undocked.getItemIndex(oldChild);
						undocked.setItemAt(newChild, i);
					}
					if (oldChild == _maximized) {
						_maximized = newChild;
					}
					super.removeChild(oldChild);
					super.addChildAt(newChild, index);
					dispatchEvent(new CollectionEvent(CollectionEvent.COLLECTION_CHANGE, false, false, CollectionEventKind.REPLACE, index, index, [newChild, oldChild]));	
				}
				else {
					this.addChild(newChild);
				}
			}
		}
		
		/**
		 * Check whether the given child component is a docked child of this box, or not. If it is undocked
		 * this method returns false. If it is not a child, this method returns false too.
		 */
		public function isDocked(child:DisplayObject):Boolean
		{
			return this.contains(child) && !undocked.contains(child);
		}
		
		public function isUndocked(child:DisplayObject):Boolean
		{
			return this.contains(child) && undocked.contains(child);
		}
		
		/**
		 * Dock the given child component, so that it is removed from the floating undocked children 
		 * and merged into the tile.
		 */
		public function dock(child:DisplayObject):void
		{
			var index:int = undocked.getItemIndex(child);
			if (index >= 0)
				undocked.removeItemAt(index);
		}
		
		/**
		 * Un-dock the given child component, so that it is removed from the tile and moved to the floating
		 * undocked children as in picture-in-picture.
		 */
		public function undock(child:DisplayObject):void
		{
			undocked.addItem(child);
		}
		
		/**
		 * Add a child as undocked child. By default the addChild and addChildAt methods add the child in
		 * tile. Calling undock after adding the child causes animation effect where the child is moved from
		 * tile to undocked list. To avoid this, the application may invoke this method to directly add the 
		 * child as undocked.
		 */
		public function addChildUndocked(child:DisplayObject):DisplayObject
		{
			var result:DisplayObject = addChild(child);
			undocked.addItem(child);
			return result;
		}
		
		//--------------------------------------
		// PRIVATE METHODS
		//--------------------------------------
		
		/*
		 * Internal method to add a child component at the given index in this box.
		 */
		private function addChildInternal(child:DisplayObject, index:int):DisplayObject
		{
			trace("addChild " + child + " " + index);
			// calculate new positions for best layout
			calculateLayout(this.numChildren - undocked.length + 1);
			
			child.width = containerLayout.width;
			child.height = containerLayout.height;
			child.x = this.width - child.width;
			child.y = this.height - child.height;
			
			child.addEventListener(MouseEvent.MOUSE_DOWN, mouseDownHandler, false, 0, true);
			child.addEventListener(MouseEvent.MOUSE_UP, mouseUpHandler, false, 0, true);
			child.addEventListener(MouseEvent.ROLL_OVER, rollOverHandler, false, 0, true);
			child.addEventListener(MouseEvent.ROLL_OUT, rollOutHandler, false, 0, true);
			
			var result:DisplayObject = super.addChildAt(child, index);
			dispatchEvent(new CollectionEvent(CollectionEvent.COLLECTION_CHANGE, false, false, CollectionEventKind.ADD, index, -1, [child]));	
			layoutBoxes();
			updateLastChange();
			if (this.numChildren <= 1)
				stopEffects();
			return result;
		}
		
		/*
		 * Remove a child component from the given index in this box.
		 */
		private function removeChildInternal(index:int):DisplayObject
		{
			var child:DisplayObject = getChildAt(index);
			trace("removeChild " + child + " " + index);
			if (undocked.contains(child)) {
				undocked.removeItemAt(undocked.getItemIndex(child));
			}
			var result:DisplayObject = super.removeChild(child);
			if (child == maximized) {
				_maximized = null;
			}
			dispatchEvent(new CollectionEvent(CollectionEvent.COLLECTION_CHANGE, false, false, CollectionEventKind.REMOVE, -1, index, [child]));
			
			child.removeEventListener(MouseEvent.MOUSE_DOWN, mouseDownHandler);
			child.removeEventListener(MouseEvent.MOUSE_UP, mouseUpHandler);
			child.removeEventListener(MouseEvent.ROLL_OVER, rollOverHandler);
			child.removeEventListener(MouseEvent.ROLL_OUT, rollOutHandler);
			
			calculateLayout(this.numChildren - undocked.length);
			layoutBoxes();
			updateLastChange();
			return result;
		}
		
		/*
		 * Remove all children (tile or undocked) from this container box.
		 */
		private function removeAllChildrenInternal():void
		{
			trace("removeAllChildren");
			super.removeAllChildren();
			undocked.removeAll();
		}
		
		/*
		 * Find the best layout for the given number of children (count) in a space of size
		 * (wr, hr). It returns [wn, hn, cols] indicating dimension of individual child
		 * (wn, hn) and the number of columns in the tile.
		 */
		private function findBestLayout(wr:Number, hr:Number, count:int):Layout
		{
			var col:int = 1, row:int = 1;
			var wn:int = 0, hn:int = 0;
			var remSpace:int = wr*hr; // minimum remaining space.
			
			// iterate over all column values and find the best.
			for (var c:int=1; c <= count; ++c) {
				var r:int = int(Math.ceil(count/c)); // rows
				var w:Number = Math.min((hr/r)*(4.0/3.0), (wr/c));
				var h:Number = Math.min((hr/r), (wr/c)*(3.0/4.0));
				var space:Number = wr*hr - count*(w*h);
				if (space <= remSpace) {
					remSpace = space;
					col = c;
					row = r;
					wn = w;
					hn = h;
				}
			}
			return new Layout(col, row, wn, hn);
		}
		
		private function calculateLayout(count:uint):void
		{
			var ratio:Number = 3/4; // height/width aspect ratio inverse
			var layout:Layout; // layout for non-maximized children
			
			if (count <= 0) { //corner case
				trace("calculateLayout " + count);
				containerLayout.update(1, 1, 1, 1, 0, 0, 0, 0, 0, 0, true);
				return;
			}
			
			if (maximized != null) {
				// first calculate position of maximized
				var h1:Number = Math.min(this.height, this.width*ratio); // maximum height of maximized?
				var w1:Number = h1/ratio; // corresponding width
				var hr:Number = this.height - h1; // remaining height
				var wr:Number = this.width - w1;  // remaining width
				
				// if no space available either on right or bottom. Then assume on right, 
				// by reducing the width of w1, instead of doing picture in picture
				if (hr < MIN_HEIGHT && wr < MIN_WIDTH) {
					wr = MIN_WIDTH;
					w1 = this.width - wr;
					hr = 0;
					h1 = w1*ratio;
				}
				
				// calculate the best layout of the remaining children.
				layout = (hr > MIN_HEIGHT ? findBestLayout(this.width, hr, count-1) : findBestLayout(wr, this.height, count-1));
				
				// we need to horizontally center, and vertically top the views if maximized is present
				var xoff:int = 0;
				
				if (hr < MIN_HEIGHT) {
					var wtotal:int = w1 + layout.width*layout.col
					xoff = (this.width - wtotal) / 2;	
				}
				
				containerLayout.update(layout.col, layout.row, layout.width, layout.height, xoff, 0, w1, h1, 0, 0, hr > MIN_HEIGHT);
			}
			else {
				layout = findBestLayout(this.width, this.height, count);
				
				var x0:uint = this.width/2 - (layout.width * layout.col)/2;
				var y0:uint = this.height/2 - (layout.height * layout.row)/2;
				
				containerLayout.update(layout.col, layout.row, layout.width, layout.height, x0, y0, 0, 0, 0, 0, true);
			}
			trace("calculateLayout " + containerLayout.col + "x" + containerLayout.row + " each=" + containerLayout.width + "x" + containerLayout.height + " off=" + containerLayout.x0 + "," + containerLayout.y0 + " maximized=" + containerLayout.mwidth + "x" + containerLayout.mheight + " " + containerLayout.mx0 + "," + containerLayout.my0 + " is-right=" + containerLayout.right);
		}
		
		private function getChildPosition(index:int, count:int):Object
		{
			var result:Object = {x: 0, y: 0};
			var col:int = index % containerLayout.col;
			var row:int = Math.floor(index / containerLayout.col);
			if (maximized == null) {
				result.x = containerLayout.x0 + col * containerLayout.width;
				result.y = containerLayout.y0 + row * containerLayout.height;
				if ((containerLayout.row*containerLayout.col-index) <= containerLayout.col) {
					result.x += ((containerLayout.row*containerLayout.col-count) % containerLayout.col)*containerLayout.width/2;
				}
			}
			else {
				result.x = (containerLayout.right ? 0 : containerLayout.mwidth) + containerLayout.x0 + col * containerLayout.width;
				result.y = (containerLayout.right ? containerLayout.mheight : 0) + containerLayout.y0 + row * containerLayout.height;
			}
			return result;
		}
		
		private function layoutBoxes(stop:Boolean=true):void
		{
			if (stop)
				stopEffects();
			
			var effect:Parallel, resize:Resize, move:Move;
			
			// first position the maximized
			if (maximized != null) {
				if (maximized.width != containerLayout.mwidth || maximized.height != containerLayout.mheight
				|| maximized.x != (containerLayout.mx0 + containerLayout.x0) || maximized.y != (containerLayout.my0 + containerLayout.y0)) {
					effect = new Parallel(maximized);
					effect.duration = EFFECT_DURATION;
					resize = new Resize();
					resize.widthTo = containerLayout.mwidth;
					resize.heightTo = containerLayout.mheight;
					move = new Move();
					move.xTo = containerLayout.mx0 + containerLayout.x0;
					move.yTo = containerLayout.my0 + containerLayout.y0;
					effect.addChild(resize);
					effect.addChild(move);
					effect.play();
					effects.push(effect);
				}
			}

			var index:int = 0;
			for (var i:int=0; i<this.numChildren; ++i) {
				var c:DisplayObject = this.getChildAt(i);
				if (c == maximized) // ignore maximized now
					continue; 
				if (undocked.contains(c))
					continue;    // ignore undocked ones
					
				var xy:Object = getChildPosition(index, this.numChildren - undocked.length);
				index++;
				
				if (c.width != containerLayout.width || c.height != containerLayout.height || c.x != xy.x || c.y != xy.y) {
					effect = new Parallel(c);
					effect.duration = EFFECT_DURATION;
					resize = new Resize();
					resize.widthTo = containerLayout.width;
					resize.heightTo = containerLayout.height;
					move = new Move();
					move.xTo = xy.x;
					move.yTo = xy.y;
					effect.addChild(resize);
					effect.addChild(move);
					effect.play();
					effects.push(effect);
				}
			}
			
			if (!animateOnResize)
				stopEffects();
		}
		
		private function layoutUndocked(x1:int, y1:int, x2:int, y2:int):void
		{
			for each (var item:DisplayObject in undocked) {
				trace(item.x + ',' + (x1 - item.x - item.width));
				if (item.x > (x1 - item.x - item.width)) // at the right
					item.x += (x2 - x1);
				if (item.y > (y1 - item.y - item.width)) // at the bottom
					item.y += (y2 - y1);
			}
		}
		
		private function resizeHandler(event:ResizeEvent):void
		{
			if (Math.abs(event.oldWidth - this.width) > 1 || Math.abs(event.oldHeight - this.height) > 1) {
				trace("resize old=" + event.oldWidth + "x" + event.oldHeight + " new=" + this.width + "x" + this.height);
				calculateLayout(this.numChildren - undocked.length);
				layoutBoxes();
				layoutUndocked(event.oldWidth, event.oldHeight, this.width, this.height);
				if (!animateOnResize)
					stopEffects();
			}
		}
		
		private function stopEffects():void
		{
			for each (var effect:Effect in effects) {
				effect.end();
			}
			effects.splice(0, effects.length);
		}
		
		private function mouseDownHandler(event:MouseEvent):void
		{
			var target:UIComponent = event.currentTarget as UIComponent;
			if (target != null) {
				// setting the child index changes our order of child index, hence position in tile.
				var index:int = this.getChildIndex(target);
				if (undocked.contains(target)) {
					// drag the child
					if (index < this.numChildren - 1)
						this.setChildIndex(target, this.numChildren - 1);
				}
				else {
					stopEffects();
					if (undocked.length < this.numChildren && index < this.numChildren - undocked.length - 1)
						this.setChildIndex(target, this.numChildren - undocked.length - 1);
					// move the child		
					layouts[target] = new BoxLayout(target.x, target.y, index);
				}
				
				target.startDrag();
			}
		}
		
		private function mouseUpHandler(event:MouseEvent):void
		{
			var target:UIComponent = event.currentTarget as UIComponent;
			if (target != null) {
				target.stopDrag();
				
				if (target in layouts) {
					stopEffects();
					
					if (target in layouts) {
						// move in docked
						for (var count:int=0; count<this.numChildren; ++count) {
							var c:DisplayObject = this.getChildAt(count);
							if (c != target && !undocked.contains(c)) {
								if (this.mouseX > c.x && this.mouseX < (c.x + c.width) &&
									this.mouseY > c.y && this.mouseY < (c.y + c.height)) {
										break;
									}
							}
						}
						
						var co:BoxLayout = layouts[target];
						var oldCount:int  = co.index;
						
						var moveEffect:Move = new Move(target);
						moveEffect.duration = 500;
							
						if (count >= this.numChildren) {
							// first, restore the old child index of the target
							if (oldCount < this.numChildren - undocked.length - 1)
								this.setChildIndex(target, oldCount);
								
							moveEffect.xTo = co.x;
							moveEffect.yTo = co.y;
							moveEffect.play();
							effects.push(moveEffect);
						}
						else {
							// check if a child exists at the new position and new position is different.
							var existing:UIComponent = this.getChildAt(count) as UIComponent;
							
							// first, restore the old child index of the target
							if (oldCount < this.numChildren - undocked.length - 1)
								this.setChildIndex(target, oldCount);
							target.validateNow();
							
							if (existing != null) {
								// if yes, then swap the two child indices and move them
								if (existing == maximized || target == maximized) {
									if (existing == maximized) {
										this.maximized = target;
									}
									else if (target == maximized) {
										this.maximized = existing;
									}
									var effect1:Parallel = new Parallel(target);
									effect1.duration = 500;
									var move1:Move = new Move();
									move1.xTo = existing.x;
									move1.yTo = existing.y;
									var resize1:Resize = new Resize();
									resize1.widthTo = existing.width;
									resize1.heightTo = existing.height;
									effect1.addChild(move1);
									effect1.addChild(resize1);
									effect1.play();
									effects.push(effect1);
									
									var effect2:Parallel = new Parallel(existing);
									effect2.duration = 500;
									var move2:Move = new Move();
									move2.xTo = co.x;
									move2.yTo = co.y;
									var resize2:Resize = new Resize();
									resize2.widthTo = target.width;
									resize2.heightTo = target.height;
									effect2.addChild(move2);
									effect2.addChild(resize2);
									effect2.play();
									effects.push(effect2);
								}
								else {
									if (count < oldCount) {
										this.setChildIndex(target, count);
										this.setChildIndex(existing, oldCount);
									}
									else {
										this.setChildIndex(existing, oldCount);
										this.setChildIndex(target, count);
									}
									moveEffect.xTo = existing.x;
									moveEffect.yTo = existing.y;
									moveEffect.play();
									effects.push(moveEffect);
									
									var move:Move = new Move(existing);
									move.xTo = co.x;
									move.yTo = co.y;
									move.play();
									effects.push(move);
								}
								
							}
							else {
								// else move the target back to the original location
								moveEffect.xTo = co.x;
								moveEffect.yTo = co.y;
								moveEffect.play();
								effects.push(moveEffect);
								
							}
						}
						delete layouts[target];
					}
					else {
						// no need to move anything else
					}
				} 
			}
		}
		
		// set draggable on rollOver.
		private function rollOverHandler(event:MouseEvent):void 
		{
			var target:UIComponent = event.currentTarget as UIComponent;
			if (target != null) {
				drags[target] = true;
			}
		}
		
		// unset draggable on rollOut.
		private function rollOutHandler(event:MouseEvent):void 
		{
			var target:UIComponent = event.currentTarget as UIComponent;
			if (target != null) {
				delete drags[target];
				if (target in layouts) { // if we were dragging this, then release it
					mouseUpHandler(event);
				}
			}
		}
		
		/*
		 * update the lastChange time, and if difference with now is less than MIN_CHANGE_TIME
		 * then stop animation effects.
		 */
		private function updateLastChange():void
		{
			var now:Date = new Date();
			if (now.time - lastChange.time < MIN_CHANGE_TIME) 
				stopEffects();
			lastChange = now; 
		}
		
		// get the next undock window position
		private function getNextUndockPos(added:Array):Object
		{
			var pos:Object = { x: this.width - UNDOCK_DEFAULT_WIDTH - 10, y: this.height - UNDOCK_DEFAULT_HEIGHT - 10};
			pos.x -= (undocked.length-1) * UNDOCK_DEFAULT_WIDTH - 10;
			if (pos.x < 10)
				pos.x = 10;
			return pos;
		}
		
		// change in undocked handler.
		private function undockedChangeHandler(event:CollectionEvent):void
		{
			var item:DisplayObject;
			if (event.kind == CollectionEventKind.ADD) {
				// calculate the position and move it here
				stopEffects();
				for each (item in event.items) {
					addResizeControl(item as UIComponent);
					
					if (item == maximized) {
						this.maximized = null;
					}
					if (this.getChildIndex(item) < this.numChildren - 1) {
						this.setChildIndex(item, this.numChildren - 1);
					}
					
					var effect:Parallel = new Parallel(item);
					effect.duration = 500;
					var move:Move = new Move();
					var p:Object = getNextUndockPos(event.items);
					move.xTo = p.x;
					move.yTo = p.y;
					var resize:Resize = new Resize();
					resize.widthTo = UNDOCK_DEFAULT_WIDTH;
					resize.heightTo = UNDOCK_DEFAULT_HEIGHT;
					effect.addChild(move);
					effect.addChild(resize);
					effect.play();
					effects.push(effect);
				}
				calculateLayout(this.numChildren - undocked.length);
				layoutBoxes(false);
			}
			else if (event.kind == CollectionEventKind.REMOVE) {
				// no need to do anything
				stopEffects();
				for each (item in event.items) {
					removeResizeControl(item);
					
					if (undocked.length < this.numChildren && this.getChildIndex(item) > this.numChildren - undocked.length - 1) {
						this.setChildIndex(item, this.numChildren - undocked.length - 1 - (maximized != null ? 1 : 0));
					}
				}
				calculateLayout(this.numChildren - undocked.length);
				layoutBoxes(false);
			}
		}
		
		private function addResizeControl(item:UIComponent):void
		{
//http://www.flexer.info/2008/04/25/resizable-canvas-horizontally/
//			if (item == null)
//				return;
//				
//			var button:LinkButton = new LinkButton();
//			button.label = "";
//			button.toolTip = null;
//			button.tabEnabled = false;
//			button.setStyle("bottom", 0);
//			button.setStyle("right", 0);
//			button.width = 10;
//			button.height = 10;
//			
//			button.addEventListener(MouseEvent.MOUSE_OVER, itemResizeOverHandler, false, 0, true);
//			button.addEventListener(MouseEvent.MOUSE_MOVE, itemResizeOverHandler, false, 0, true);
//			button.addEventListener(MouseEvent.MOUSE_OUT, itemResizeOutHandler, false, 0, true);
//			button.addEventListener(MouseEvent.MOUSE_DOWN, itemDragStartHandler, false, 0, true);
//			button.addEventListener(Event.ENTER_FRAME, itemDragMoveHandler, false, 0, true);
//			button.addEventListener(MouseEvent.MOUSE_UP, itemDragStopHandler, false, 0, true);
//			
//			if (item is UIComponent) {
//				UIComponent(item).addChild(button);
//			}
		}
		private function removeResizeControl(item:DisplayObject):void
		{
		}
		
		private function itemMouseDownHandler(event:MouseEvent):void
		{
			var item:DisplayObject = event.currentTarget as DisplayObject;
			if (item.width - item.mouseX < 10 && item.height - item.mouseY < 10) {
			}
		}
		private function itemMouseUpHandler(event:MouseEvent):void
		{
			var item:DisplayObject = event.currentTarget as DisplayObject;
		}
	}
}

/**
 * The co-ordinate of a box is its position (x,y) and index in the child order.
 */
class BoxLayout
{
	public var x:uint, y:uint, index:uint;
	public function BoxLayout(x:uint, y:uint, index:uint) 
	{
		this.x = x;
		this.y = y;
		this.index = index;
	}
}

/**
 * The layout of the tile contains the number of columns and rows and width and height.
 */
class Layout
{
	public var col:uint, row:uint, width:uint, height:uint;
	public function Layout(col:uint, row:uint, width:uint, height:uint)
	{
		this.col = col;
		this.row = row;
		this.width = width;
		this.height = height;
	}
}

/**
 * The layout of the container box is stored in a ContainerLayout object. The object stores the number of 
 * columns and rows in the tile, the total width and height, the starting position of the first child, as well
 * as position and dimensions of the maximized child if any.
 */
class ContainerLayout
{
	public var col:uint, row:uint, width:uint, height:uint, x0:uint, y0:uint;
	public var mwidth:uint, mheight:uint, mx0:uint, my0:uint, right:Boolean=true;
	
	public function ContainerLayout(col:uint, row:uint, width:uint, height:uint, x0:uint, y0:uint, bwidth:uint, bheight:uint, bx0:uint, by0:uint, right:Boolean) 
	{
		update(col, row, width, height, x0, y0, bwidth, bheight, bx0, by0, right);
	}
	public function update(col:uint, row:uint, width:uint, height:uint, x0:uint, y0:uint, bwidth:uint, bheight:uint, bx0:uint, by0:uint, right:Boolean):void
	{
		this.col = col;
		this.row = row;
		this.width = width;
		this.height = height;
		this.x0 = x0;
		this.y0 = y0;
		this.mwidth = bwidth;
		this.mheight = bheight;
		this.mx0 = bx0;
		this.my0 = by0;
		this.right = right;
	}
}
