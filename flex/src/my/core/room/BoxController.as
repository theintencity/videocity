/* Copyright (c) 2009-2011, Kundan Singh. See LICENSING for details. */
package my.core.room
{
	import flash.display.DisplayObject;
	import flash.events.DataEvent;
	import flash.events.Event;
	import flash.events.MouseEvent;
	
	import mx.containers.Canvas;
	import mx.core.Application;
	import mx.effects.AnimateProperty;
	import mx.effects.Parallel;
	import mx.events.CollectionEvent;
	import mx.events.CollectionEventKind;
	import mx.events.FlexEvent;
	import mx.events.PropertyChangeEvent;
	
	import my.containers.BaseBox;
	import my.containers.ContainerBox;
	import my.controls.PauseCanvas;
	import my.controls.Prompt;
	import my.core.User;
	import my.core.playlist.PlayItem;
	import my.core.playlist.PlayList;
	import my.core.playlist.PlayListBox;
	import my.core.video.VideoBox;
	import my.core.video.record.RecordVideoBox;
	
	/**
	 * The controller for the ContainerBox object. It should handle adding and removing from the container.
	 */
	public class BoxController
	{
		//--------------------------------------
		// PRIVATE VARIABLES
		//--------------------------------------
		
		private var _user:User;
		private var _box:ContainerBox;
		private var _fullBox:BaseBox = null;
		

		//--------------------------------------
		// CONSTRUCTOR
		//--------------------------------------
		
		public function BoxController()
		{
		}

		//--------------------------------------
		// GETTERS/SETTERS
		//--------------------------------------
		
		public function get user():User
		{
			return _user;
		}
		
		public function set user(value:User):void
		{
			var oldValue:User = _user;
			_user = value;
			if (oldValue != value) {
				if (oldValue != null) {
					oldValue.removeEventListener("cameraChange", deviceChangeHandler);
					oldValue.removeEventListener("micChange", deviceChangeHandler);
					oldValue.removeEventListener(PropertyChangeEvent.PROPERTY_CHANGE, propertyChangeHandler);
				}
				if (value != null) {
					value.addEventListener("cameraChange", deviceChangeHandler, false, 0, true);
					value.addEventListener("micChange", deviceChangeHandler, false, 0, true);
					value.addEventListener(PropertyChangeEvent.PROPERTY_CHANGE, propertyChangeHandler, false, 0, true);
				}
			}
		}
		
		public function get box():ContainerBox
		{
			return _box;
		}
		public function set box(value:ContainerBox):void
		{
			var oldValue:ContainerBox = _box;
			_box = value;
			if (oldValue != value) {
				if (oldValue != null) {
					oldValue.removeEventListener(CollectionEvent.COLLECTION_CHANGE, boxChangeHandler);
					oldValue.removeEventListener("callTo", callToHandler);
				}
				if (value != null) {
					value.addEventListener(CollectionEvent.COLLECTION_CHANGE, boxChangeHandler, false, 0, true);	
					value.addEventListener("callTo", callToHandler, false, 0, true);
				}
			}
		}
		
		//--------------------------------------
		// PRIVATE METHODS
		//--------------------------------------
		
//		private function controlHandler(event:DataEvent):void
//		{
//			if (controller.activeBox == box) {
////				if (event.data == "phone") {
////					if (box.getChildByName("phone") == null) {
////						var item:PhoneBox = new PhoneBox();
////						item.user = user;
////						controller.selectBox(box);
////						box.addChild(item);
////					}
////				}
//			}
//		}
		
		private function callToHandler(event:DataEvent):void
		{
			Prompt.show("Dialing is not configured", "Error");
		}
		
		private function boxChangeHandler(event:CollectionEvent):void
		{
			var video:BaseBox;
			switch (event.kind) {
				case CollectionEventKind.ADD:
					for each (video in event.items) {
						video.addEventListener(BaseBox.DELETE, deleteHandler, false, 0, true);
						video.addEventListener(BaseBox.MAXIMIZE, maximizeHandler, false, 0, true);
						video.addEventListener(BaseBox.DOCK, dockHandler, false, 0, true);
					}
					break;
				case CollectionEventKind.REMOVE:
					for each (video in event.items) {
						video.removeEventListener(BaseBox.DELETE, deleteHandler);
						video.removeEventListener(BaseBox.MAXIMIZE, maximizeHandler);
						video.removeEventListener(BaseBox.DOCK, dockHandler);
					}
					break;
				case CollectionEventKind.REPLACE:
					video = event.items[0];
					video.addEventListener(BaseBox.DELETE, deleteHandler, false, 0, true);
					video.addEventListener(BaseBox.MAXIMIZE, maximizeHandler, false, 0, true);
					video.addEventListener(BaseBox.DOCK, dockHandler, false, 0, true);
					video = event.items[1];
					video.removeEventListener(BaseBox.DELETE, deleteHandler);
					video.removeEventListener(BaseBox.MAXIMIZE, maximizeHandler);
					video.removeEventListener(BaseBox.DOCK, dockHandler);
					break;
			}
		}
		
		private function deleteHandler(event:Event):void
		{
			if (box.contains(event.currentTarget as DisplayObject))
				box.removeChild(event.currentTarget as DisplayObject);
		}
		
		// suppress the add and remove events from the child when the child is moved from one place to another.
		private function suppressEvent(event:Event):void
		{
			event.stopImmediatePropagation();
		}
		
		private function maximizeHandler(event:Event):void
		{
			if (box.maximized == event.currentTarget) {
				_fullBox = event.currentTarget as BaseBox
				box.maximized = null;
				_fullBox.addEventListener(FlexEvent.ADD, suppressEvent, false, 10000, true);
				_fullBox.addEventListener(FlexEvent.REMOVE, suppressEvent, false, 10000, true);
				_box.animateOnResize = false;
				_box.removeChild(_fullBox);
				_box.animateOnResize = true;
				Application.application.addChild(_fullBox);
				Application.application.validateNow();
				_fullBox.removeEventListener(FlexEvent.ADD, suppressEvent);
				_fullBox.removeEventListener(FlexEvent.REMOVE, suppressEvent);
				_fullBox.addEventListener(BaseBox.MAXIMIZE, maximizeHandler, false, 0, true);
				_fullBox.styleName = "baseBoxFull";
				_fullBox.autoHide = true;
				_fullBox.width = Application.application.width;
				_fullBox.height = Application.application.height;
			}
			else if (_fullBox != null) {
				//fullBox.removeEventListener(BaseBox.MAXIMIZE, maximizeHandler);
				_fullBox.addEventListener(FlexEvent.ADD, suppressEvent, false, 10000, true);
				_fullBox.addEventListener(FlexEvent.REMOVE, suppressEvent, false, 10000, true);
				Application.application.removeChild(_fullBox);
				Application.application.validateNow();
				_fullBox.removeEventListener(FlexEvent.ADD, suppressEvent);
				_fullBox.removeEventListener(FlexEvent.REMOVE, suppressEvent);
				_fullBox.autoHide = false;
				_fullBox.styleName = "baseBox";
				_box.animateOnResize = false;
				_box.addChild(_fullBox);
				_box.animateOnResize = true;
				_fullBox = null;
			}
			else {
				box.maximized = event.currentTarget as DisplayObject;
			}
			//box.maximized = (box.maximized == event.target ? null : event.target as DisplayObject);
		}
		
		private function dockHandler(event:Event):void
		{
			if (!box.isDocked(event.currentTarget as DisplayObject)) {
				box.dock(event.currentTarget as DisplayObject);
				if (event.currentTarget is VideoBox) 
					VideoBox(event.currentTarget).resizeable = false;
			}
			else {
				box.undock(event.currentTarget as DisplayObject);
				if (event.currentTarget is VideoBox)
					VideoBox(event.currentTarget).resizeable = true;
			}
				
		}
		
		private function propertyChangeHandler(event:PropertyChangeEvent):void
		{
			var p:String = event.property as String;
			if (p == "playing") {
				for (var i:int=0; i<box.numChildren; ++i) {
					var item:BaseBox = box.getChildAt(i) as BaseBox;
					if (item != null) 
						item.playing = user.playing;
				}
				if (!user.playing) {
					var canvas:Canvas = null;
					if (Application.application.getChildByName("pause") == null) {
						canvas = new PauseCanvas();
						canvas.name = "pause";
						PauseCanvas(canvas).warning = (user.camActive || user.micActive) ? _('your capture devices are on') : null;
						canvas.addEventListener(MouseEvent.CLICK, pauseCanvasClickHandler, false, 0, true);
						Application.application.addChild(canvas);
					}
				}
				else {
					if (Application.application.getChildByName("pause") != null) {
						canvas = Application.application.getChildByName("pause") as Canvas;
						Application.application.removeChild(canvas);
					}
				}
			}
			else if (p == "recording") {
				var rec:RecordVideoBox = box.getChildByName("record") as RecordVideoBox;
				if (user.recording) {
					if (rec == null) {
						rec = new RecordVideoBox();
						rec.user = user;
						box.maximized = rec;
						box.addChild(rec);
					}
				}
				else {
					if (rec != null && rec.user != null) {
						if (user.record.lastError != null) {
							Prompt.show(user.record.lastError, "Recording Error");
							box.removeChild(rec);
						}
						else {
							var play:PlayListBox = new PlayListBox();
							play.playList = new PlayList(PlayItem.describeRecord(user.record.url, user.record.id, user.name), null, user.selected);
							box.replaceChild(rec, play);
						}
					}
				}
			}
			else if (p == "smoothing") {
				for each (var child:DisplayObject in box.getChildren()) {
					var videoBox:VideoBox = child as VideoBox;
					if (videoBox != null && videoBox.video != null) {
						videoBox.video.smoothing = user.smoothing;
					}
				}
			}
		}
		
		private function pauseCanvasClickHandler(event:Event):void
		{
			user.playing = true;
		}
		
		private function deviceChangeHandler(event:Event):void
		{
//			var local:VideoBox = box.getChildByName("local") as VideoBox;
//			if (local != null && local.video != null) {
//				local.video.attachCamera(user.camera);
//			}
			var record:VideoBox = box.getChildByName("record") as VideoBox;
			if (record != null && record.video != null) {
				record.video.attachCamera(user.camera);
			}
		}
	}
}