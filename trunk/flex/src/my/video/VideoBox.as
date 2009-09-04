/* Copyright (c) 2009, Kundan Singh. See LICENSING for details. */
package my.video
{
	import flash.media.Video;
	
	import mx.core.UIComponent;
	import mx.events.FlexEvent;
	import mx.events.ResizeEvent;
	
	import my.containers.BaseBox;
	
	/**
	 * A VideoBox component displays a video via NetStream. There is a video property representing the child
	 * Video object.
	 */  
	public class VideoBox extends BaseBox
	{
		//--------------------------------------
		// PRIVATE VARIABLES
		//--------------------------------------
		
		private var _video:Video;
		private var _moving:Boolean = false;
		
		//--------------------------------------
		// CONSTRUCTOR
		//--------------------------------------
		
		/**
		 * Construct a new video box  object.
		 */
		public function VideoBox()
		{
			addEventListener(FlexEvent.REMOVE, removeHandler, false, 0, true);
		}

		//--------------------------------------
		// GETTERS/SETTERS
		//--------------------------------------
		
		[Bindable]
		/**
		 * The Video object associated with this view. When the video object is set, it attaches it to this
		 * component. An intermediate parent UIComponent is needed so that resizing works as expected.
		 */
		public function get video():Video
		{
			return _video;
		}
		public function set video(value:Video):void
		{
			var oldValue:Video = _video;
			_video = value;
			if (value != oldValue) {
				var index:int = oldValue != null ? this.getChildIndex(oldValue.parent) : 0;
				if (oldValue != null)
					this.removeChild(oldValue.parent);
				if (value != null) {
					var parent:UIComponent = new UIComponent();
					parent.addChild(value);
					parent.percentWidth = parent.percentHeight = 100;
					resizeVideoHandler(null);
					parent.addEventListener(ResizeEvent.RESIZE, resizeVideoHandler, false, 0, true);
					this.addChildAt(parent, index);
				}
			}
		}
		
		[Bindable]
		/**
		 * Whether this video box is going to be moved from one parent to another? If yes, then add and remove
		 * events are ignored.
		 */
		public function get moving():Boolean
		{
			return _moving;
		}
		public function set moving(value:Boolean):void
		{
			_moving = value;
		}
		
		//--------------------------------------
		// PROTECTED METHODS
		//--------------------------------------
		
		/**
		 * Override the base box's resize handler to update the size of the embedded Video object when
		 * this component size changes.
		 */
		protected function resizeVideoHandler(event:ResizeEvent):void
		{
			if (_video != null) {
				_video.width = _video.parent.width;
				_video.height = _video.parent.height;
			}
		}
		
		//--------------------------------------
		// PRIVATE VARIABLES
		//--------------------------------------
		
		/*
		 * Remove the camera and NetStream attachment with this video object when this component is removed
		 * from its parent.
		 */
		private function removeHandler(event:Event):void
		{
			if (video != null && !moving) {
				video.attachCamera(null);
				video.attachNetStream(null);
			}
		}
	}
}
