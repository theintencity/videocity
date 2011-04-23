/* Copyright (c) 2009-2011, Kundan Singh. See LICENSING for details. */
package my.core.room
{
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.DataEvent;
	import flash.display.DisplayObject;
	
	import mx.core.Application;
	import mx.events.CollectionEvent;
	import mx.events.CollectionEventKind;
	import mx.events.PropertyChangeEvent;
	
	import my.containers.BaseBox;
	import my.containers.ContainerBox;
	import my.core.video.VideoBox;
	import my.core.playlist.PlayListBox;
	import my.core.Constant;
	import mx.events.DynamicEvent;
	import my.core.playlist.PlayList;
	import mx.events.ResizeEvent;
	import mx.controls.Button;
	import mx.core.UIComponent;
	
	/**
	 * The controller for the ContainerBox and individual items to capture from shared room controller and
	 * give to the other participants.
	 */
	public class RemoteController
	{
		//--------------------------------------
		// PRIVATE VARIABLES
		//--------------------------------------
		
		private var _room:Room;
		private var _containerBox:ContainerBox;
		
		//--------------------------------------
		// CONSTRUCTOR
		//--------------------------------------
		
		public function RemoteController()
		{
		}

		//--------------------------------------
		// GETTERS/SETTERS
		//--------------------------------------
		
		[Bindable]
		/**
		 * The data model is a room object. 
		 */
		public function get room():Room
		{
			return _room;
		}
		public function set room(value:Room):void
		{
			var old:Room = _room;
			_room = value;
			if (old != value) {
				if (old != null) {
//					old.removeEventListener(PropertyChangeEvent.PROPERTY_CHANGE, roomChangeHandler);
					old.removeEventListener(Constant.CONTROLLED_CHANGE, controlledChangeHandler);
				}
				if (value != null) {
//					value.addEventListener(PropertyChangeEvent.PROPERTY_CHANGE, roomChangeHandler, false, 0, true);
					value.addEventListener(Constant.CONTROLLED_CHANGE, controlledChangeHandler, false, 0, true);
				}
			}
		}
		
		public function get containerBox():ContainerBox
		{
			return _containerBox;
		}
		public function set containerBox(value:ContainerBox):void
		{
			var oldValue:ContainerBox = _containerBox;
			_containerBox = value;
			if (oldValue != value) {
				if (oldValue != null) {
					oldValue.removeEventListener(CollectionEvent.COLLECTION_CHANGE, collectionChangeHandler);
					oldValue.removeEventListener(MouseEvent.MOUSE_MOVE, mouseMoveHandler);
//					oldValue.removeEventListener(ResizeEvent.RESIZE, resizeHandler);
				}
				if (value != null) {
					value.addEventListener(CollectionEvent.COLLECTION_CHANGE, collectionChangeHandler, false, 0, true);	
					value.addEventListener(MouseEvent.MOUSE_MOVE, mouseMoveHandler, false, 0, true);	
//					value.addEventListener(ResizeEvent, resizeHandler, false, 0, true);	
				}
			}
		}
		
		//--------------------------------------
		// PRIVATE METHODS
		//--------------------------------------
		
//		private function roomChangeHandler(event:PropertyChangeEvent):void
//		{
//			if (event.property == "isController") {
//
//			}
//			else if (event.property == "controllerId") {
//
//			}
//		}
//		
		
		private function controlledChangeHandler(event:DynamicEvent):void
		{
			if (event.command == "mouseMove")
				mouseMoveHandler_(event);
			else if (event.command == "replaceBox")
				replaceBoxHandler_(event);
			else if (event.command == "boxEvent")
				boxEventHandler_(event);
			else if (event.command == "playlistChange")
				playlistChangeHandler_(event);
		}
		
		private function mouseMoveHandler(event:MouseEvent):void
		{
			room.sendControlledChange("command", "mouseMove", "x", event.stageX, "y", event.stageY);
		}
		private function mouseMoveHandler_(event:DynamicEvent):void
		{
			var roomPage:RoomPage = room.view as RoomPage;
			var pointer:UIComponent = roomPage.getChildByName("pointer") as UIComponent;
			if (pointer == null) {
				pointer = new Button();
				pointer.name = "pointer";
				pointer.width = 20;
				pointer.height = 20;
				pointer.styleName = "pointerButtonStyle";
				roomPage.addChild(pointer);
			}
			pointer.x = event.x;
			pointer.y = event.y;
		}
		
		private function replaceBoxHandler(newBox:BaseBox, oldBox:BaseBox):void
		{
			var newData:String = represent(newBox);
			var oldData:String = represent(oldBox);
			if (newBox is PlayListBox) {
				var event:DynamicEvent = new DynamicEvent(Constant.CONTROL_PLAYLIST);
				event.command = Constant.SHARE_PLAYLIST_WITH_OTHERS;
				event.playList = PlayListBox(newBox).playList;
				room.dispatchEvent(event);
			}
			room.sendControlledChange("command", "replaceBox", "newData", newData, "oldData", oldData);
		}
		private function replaceBoxHandler_(event:DynamicEvent):void
		{
			var newBox:BaseBox = identify(event.newData);
			var oldBox:BaseBox = identify(event.oldData);
			
			if (event.newData == null && oldBox != null) { // remove existing
				oldBox.dispatchEvent(new Event(BaseBox.DELETE));
			}
			else if (event.newData != null && oldBox == null) { // add new
				if (event.newData == "text" && newBox == null)
					room.dispatchEvent(new DataEvent(Constant.CONTROL_ROOM, false, false, Constant.TOGGLE_TEXT_CHAT));
				// playlist is automatically shared, so no need to do again.
			}
			else if (event.newData != null && oldBox != null) { // replace
				// replace is not implemented
			}
		}
		
		private function boxEventHandler(event:Event):void
		{
			var data:String = represent(event.currentTarget as BaseBox);
			if (data != null)
				room.sendControlledChange("command", "boxEvent", "data", data, "eventType", event.type);
		}
		private function boxEventHandler_(event:DynamicEvent):void
		{
			var box:BaseBox = identify(event.data);
			trace("received boxEvent " + event.data + " " + event.eventType);
			if (box != null && 
				(event.eventType == BaseBox.DELETE || event.eventType == BaseBox.DOCK || event.eventType == BaseBox.MAXIMIZE))
				box.dispatchEvent(new Event(event.eventType));
		}
		
		private function playlistChangeHandler(event:Event):void
		{
			var playlist:PlayList = event.currentTarget as PlayList;
			if (playlist != null) {
				var data:String = "playlist:" + playlist.id;
				room.sendControlledChange("command", "playlistChange", "data", data, "selectedIndex", playlist.selectedIndex);
			}
		}
		private function playlistChangeHandler_(event:DynamicEvent):void
		{
			var box:PlayListBox = identify(event.data) as PlayListBox;
			trace("received playlistChange " + event.data + " " + event.selectedIndex);
			if (box != null) {
				box.playList.selectedIndex = event.selectedIndex;
			}
		}
		
		
		private function collectionChangeHandler(event:CollectionEvent):void
		{
			// ignore if not a controller
			if (room == null || !room.isController)
				return;
				
			var box:BaseBox;
			switch (event.kind) {
				case CollectionEventKind.ADD:
					for each (box in event.items) {
						replaceBoxHandler(box, null);
						box.addEventListener(BaseBox.DELETE, boxEventHandler, false, 0, true);
						box.addEventListener(BaseBox.MAXIMIZE, boxEventHandler, false, 0, true);
						box.addEventListener(BaseBox.DOCK, boxEventHandler, false, 0, true);
						if (box is PlayListBox) 
							PlayListBox(box).playList.addEventListener(PlayList.SELECTED_CHANGE, playlistChangeHandler, false, 0, true);
					}
					break;
				case CollectionEventKind.REMOVE:
					for each (box in event.items) {
						replaceBoxHandler(null, box);
						box.removeEventListener(BaseBox.DELETE, boxEventHandler);
						box.removeEventListener(BaseBox.MAXIMIZE, boxEventHandler);
						box.removeEventListener(BaseBox.DOCK, boxEventHandler);
						if (box is PlayListBox) 
							PlayListBox(box).playList.removeEventListener(PlayList.SELECTED_CHANGE, playlistChangeHandler);
					}
					break;
				case CollectionEventKind.REPLACE:
					replaceBoxHandler(event.items[0], event.items[1]);
					box = event.items[0];
					box.addEventListener(BaseBox.DELETE, boxEventHandler, false, 0, true);
					box.addEventListener(BaseBox.MAXIMIZE, boxEventHandler, false, 0, true);
					box.addEventListener(BaseBox.DOCK, boxEventHandler, false, 0, true);
					if (box is PlayListBox) 
						PlayListBox(box).playList.addEventListener(PlayList.SELECTED_CHANGE, playlistChangeHandler, false, 0, true);
					box = event.items[1];
					box.removeEventListener(BaseBox.DELETE, boxEventHandler);
					box.removeEventListener(BaseBox.MAXIMIZE, boxEventHandler);
					box.removeEventListener(BaseBox.DOCK, boxEventHandler);
					if (box is PlayListBox) 
						PlayListBox(box).playList.removeEventListener(PlayList.SELECTED_CHANGE, playlistChangeHandler);
					break;
			}
		}
		
		private function represent(box:BaseBox):String
		{
			if (box is PlayListBox) {
				return "playlist:" + PlayListBox(box).playList.id;
			}
			else if (box is TextBox) {
				return "text";
			}
			return null;
		}
		
		private function identify(data:String):BaseBox
		{
			if (data == "text") {
				var box0:TextBox = containerBox.getChildByName("text") as TextBox;
				if (box0 == null)
					box0 = Application.application.getChildByName("text") as TextBox;
				return box0;
			}
			else if (data != null && data.substr(0, 9) == "playlist:") {
				var id:String = data.substr(9);
				
				var children:Array = containerBox.getChildren();
				for (var i:int=children.length-1; i>= 0; --i) {
					var box1:PlayListBox = children[i] as PlayListBox;
					if (box1 != null && box1.playList != null && box1.playList.id == id) {
						return box1;
					} 
				}
				children = Application.application.getChildren();
				for (var j:int=children.length-1; j>= 0; --j) {
					var box2:PlayListBox = children[j] as PlayListBox;
					if (box2 != null && box2.playList != null && box2.playList.id == id) {
						return box2;
					} 
				}
			}
			return null;
		}
	}
}