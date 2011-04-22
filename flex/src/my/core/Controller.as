/* Copyright (c) 2009-2011, Kundan Singh. See LICENSING for details. */
package my.core
{	
	import flash.display.DisplayObject;
	import flash.events.DataEvent;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.geom.Rectangle;
	import flash.system.Security;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	import flash.utils.Timer;
	import flash.system.System;
	
	import mx.controls.Alert;
	import mx.core.Application;
	import mx.events.PropertyChangeEvent;
	import mx.utils.StringUtil;
	
	import my.containers.BaseBox;
	import my.containers.ContainerBox;
	import my.controls.FullScreen;
	import my.controls.Layout;
	import my.controls.PostIt;
	import my.controls.Prompt;
	import my.core.room.Room;
	import my.core.room.RoomPage;
	import my.core.room.TextBox;
	import my.core.settings.DeviceSettings;
	import my.core.settings.LoginSettings;
	import my.core.video.live.LiveVideoBox;
	
	/**
	 * The controller object that receives events from the various page views and controls the model
	 * such as user or rooms.
	 */
	public class Controller
	{
		//--------------------------------------
		// PRIVATE VARIABLES
		//--------------------------------------
		
		// associated user object
		private var _user:User;
		
		// the local video's singleton instance.
		private var local0:LiveVideoBox; 
		
		private var layoutBox:Layout;
		private var layoutHideTimer:Timer;
		
		//--------------------------------------
		// PUBLIC VARIABLES
		//--------------------------------------
		
		/**
		 * The associated main view object. Must be supplied by the application.
		 */
		public var view:View;
		
		//--------------------------------------
		// CONSTRUCTOR
		//--------------------------------------
		
		/*
		 * Empty constructor.
		 */
		public function Controller()
		{
		}
		
		//--------------------------------------
		// GETTERS/SETTERS
		//--------------------------------------
		
		/**
		 * The associated user object must be set by the application, so that this controller can listen 
		 * for various events such as menu click, control button click, etc.
		 */
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
					oldValue.removeEventListener(Constant.CONTROL, controlHandler);
					oldValue.removeEventListener(Constant.MENU, menuHandler);
					oldValue.removeEventListener("cameraChange", deviceChangeHandler);
					oldValue.removeEventListener("micChange", deviceChangeHandler);
					oldValue.removeEventListener(PropertyChangeEvent.PROPERTY_CHANGE, userChangeHandler);
				}
				if (value != null) {
					value.addEventListener(Constant.CONTROL, controlHandler, false, 0, true);
					value.addEventListener(Constant.MENU, menuHandler, false, 0, true);
					value.addEventListener("cameraChange", deviceChangeHandler, false, 0, true);
					value.addEventListener("micChange", deviceChangeHandler, false, 0, true);
					value.addEventListener(PropertyChangeEvent.PROPERTY_CHANGE, userChangeHandler, false, 0, true);
				}
			}
		}
		
		//--------------------------------------
		// PRIVATE METHODS
		//--------------------------------------
		
		/*
		 * Following are invoked by the ControlBox.
		 */ 
		 
		private function controlHandler(event:DataEvent):void
		{
			switch (event.data) {
			case Constant.LAYOUT:
				changeLayoutHandler();
				break;
			case Constant.HOME:
				if (!user.isGuest && user.selected != null && user.selected.isOwner)
					user.selected = user.getRoom(user.card.url);
				else
					user.selectedIndex = Constant.INDEX_INTRO;
				break;
			}
		}
		
		/*
		 * Following are related to layout box's event to change to different view.
		 */ 
		 
		private function changeLayoutHandler():void
		{
			var index:int;
			if (layoutBox == null) {
				layoutBox = new Layout();
				layoutBox.addEventListener("selectionChange", layoutChangeHandler, false, 0, true);
				
				layoutHideTimer = new Timer(4000, 1);
				layoutHideTimer.addEventListener(TimerEvent.TIMER, layoutTimerHandler, false, 0, true);
				layoutHideTimer.start();
				
				layoutBox.setStyle("bottom", 20);
				layoutBox.setStyle("right", 60);
				layoutBox.setStyle("color", 0x000000);
				
				layoutBox.buttonMode = true;
				layoutBox.numBoxes = view.win.numBoxes;
				layoutBox.numColumns = view.win.numColumns;
				layoutBox.selectedIndex = user.selectedIndex;
				view.addChild(layoutBox);
			}
			else {
				index = user.selectedIndex;
				index = (index + 1) % view.win.numBoxes;
				user.selectedIndex = index;
				if (layoutHideTimer != null) { 
					layoutHideTimer.reset();
					layoutHideTimer.start();
				}
			}
		}
		private function layoutChangeHandler(event:Event):void
		{
			if (layoutHideTimer != null) { 
				layoutHideTimer.reset();
				layoutHideTimer.start();
			}
			if (layoutBox != null && user.selectedIndex != layoutBox.selectedIndex)
				user.selectedIndex = layoutBox.selectedIndex;
		}
		private function layoutTimerHandler(event:TimerEvent):void
		{
			if (layoutHideTimer != null) {
				layoutHideTimer.stop();
				layoutHideTimer = null;
			}
			if (layoutBox != null) {
				if (layoutBox.parent != null)
					layoutBox.parent.removeChild(layoutBox);
				layoutBox = null;
			}
		}
		
		/*
		 * Following are invoked by the User model when selected room changes.
		 */ 
		 
		private function userChangeHandler(event:PropertyChangeEvent):void
		{
			var property:String = event.property as String;
			var roomView:RoomPage;
			
			switch (property) {
			case "selected":
				roomView = user.selected != null ? user.selected.view : null;
				user.selectedIndex = roomView == null ? Constant.INDEX_INTRO : view.win.getWindowIndex(roomView);
				break;
				
			case "selectedIndex":
				{
					if (layoutBox != null) {
						layoutBox.selectedIndex = user.selectedIndex;
					}
					var roomPage:RoomPage = view.win.getWindowAt(user.selectedIndex) as RoomPage;
					var oldSelected:Room = user.selected;
					user.selected = (roomPage != null ? roomPage.room : null);
	
					// update live video box
					if (local0 != null)
						moveStickyBox(local0);
				}
				break;
				
			case "camActive":
			case "micActive":
				if (user.camActive || user.micActive) {
					if (local0 == null) {
						local0 = new LiveVideoBox();
						local0.user = user;
						addStickyBox(local0);
					}
					local0.video.attachCamera(user.camActive ? user.camera : null);
				}
				else if (!user.camActive && !user.micActive) {
					local0.video.attachCamera(null);
					if (local0 != null) {
						removeStickyBox(local0);
						local0 = null;
					}
				}
				break;
			}
		}
		
		/*
		 * Following are related to the sticky local video box.
		 */ 
		 
		private function deviceChangeHandler(event:Event):void
		{
			if (local0 != null)
				local0.video.attachCamera(user.camera);
		}
		
		private function addStickyBox(box:BaseBox):void
		{
			var roomView:RoomPage = user.selected != null ? user.selected.view : null;
			if (roomView == null || !user.selected.connected) {
				box.width = 120; 
				box.height = 90;
				box.x = view.width - box.width - 10;
				box.y = view.height- box.height- 30;
				box.resizeable = true;
				view.addChild(box);
			}
			else {
				box.x = box.y = 0;
				roomView.callBox.addChildAt(box, 0);
			}
		}
		
		private function removeStickyBox(box:BaseBox):void
		{
			if (box != null && box.parent != null) 
				box.parent.removeChild(box);
		}
		
		private function moveStickyBox(box:LiveVideoBox):void
		{
			box.moving = true;
			removeStickyBox(box);
			addStickyBox(box);
			box.moving = false;
		}
		
		/*
		 * Following are invoked by the Menu.
		 */ 
		 
		private function menuHandler(event:DataEvent):void
		{
			switch (event.data) {
			case Constant.SMOOTH:     if (user) user.smoothing = !user.smoothing; break;
			case Constant.FULL_SCREEN:FullScreen.toggleFullScreen(); break;
			case Constant.STRETCH:    FullScreen.toggleFullScreen(true); break;
			case Constant.SELECT:     FullScreen.startSelectScreen(); break;
			case Constant.DEVICE_SELECTION:   Security.showSettings(); break;
			case Constant.DEVICE_SETTINGS:     DeviceSettings.show(user); break;
			case Constant.PHONE_SETTINGS:  Prompt.show("This feature is currently not implemented.", "Not Implemented"); break; // PhoneSettings.show(); break;
			case Constant.EMBED:      showEmbedSettings(); break;
			case Constant.SEARCH:     Prompt.show("This feature is currently not implemented.", "Not Implemented"); break;
				
			case Constant.LOGIN:
				if (user != null) {
					if (user.isGuest) 
						user.dispatchEvent(new DataEvent(Constant.CONTROL, false, false, Constant.UPLOAD_CARD)); 
					else 
						user.logout(); 
				}
				break;
			
			case Constant.SIGNUP:
				if (user != null) {
					if (user.isGuest)
						user.selectedIndex = Constant.INDEX_CREATE;
					else
						LoginSettings.show(user);
				}
				break;
			}
		}

		private function showEmbedSettings():void
		{
			if (user.selected == null) {
				Prompt.show("You must be in a room to share its URL or embed code. To share your home room, please signup and login first.", "Error sharing URL or embed");
				return;
			}
			
			var url:String = user.selected.url;
			var embed:String = user.selected.embed;
			
			var shareHandler:Function = function(id:uint):void {
				if (id == Alert.YES || id == Alert.NO) {
					System.setClipboard(id == Alert.YES ? url : embed);
				}
			};
			
			Alert.yesLabel = 'URL';
			Alert.noLabel  = 'Embed';
			var m:Prompt = Prompt.show("<b>Click</b> on the button below to copy either room URL or room embed code to the clipboard, which you can paste elsewhere on email, blog or web page.<br/><font color='#0000ff'>" + url + "</font>"
			, "Share room URL or copy embed code", Alert.YES | Alert.NO | Alert.CANCEL, null, shareHandler);
			Alert.yesLabel = 'Yes';
			Alert.noLabel  = 'No';
		}
	}
}
