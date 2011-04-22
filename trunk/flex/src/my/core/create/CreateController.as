/* Copyright (c) 2009-2011, Kundan Singh. See LICENSING for details. */
package my.core.create
{	
	import flash.display.DisplayObject;
	import flash.events.DataEvent;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.MouseEvent;
	import flash.events.SecurityErrorEvent;
	import flash.events.TimerEvent;
	import flash.geom.Rectangle;
	import flash.net.FileFilter;
	import flash.net.FileReference;
	import flash.net.FileReferenceList;
	import flash.system.Security;
	import flash.system.System;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	import flash.utils.Timer;
	
	import mx.containers.Canvas;
	import mx.controls.Alert;
	import mx.core.Application;
	import mx.events.PropertyChangeEvent;
	import mx.managers.PopUpManager;
	import mx.utils.StringUtil;
	
	import my.containers.BaseBox;
	import my.containers.ContainerBox;
	import my.controls.FullScreen;
	import my.controls.Layout;
	import my.controls.PostIt;
	import my.controls.Prompt;
	import my.core.card.CardEditor;
	import my.core.card.VisitingCard;
	import my.core.Constant;
	import my.core.create.CreatePage;
	import my.core.FileController;
	import my.core.room.Room;
	import my.core.room.RoomPage;
	import my.core.room.TextBox;
	import my.core.settings.AddMediaPrompt;
	import my.core.settings.DeviceSettings;
	import my.core.settings.LoginSettings;
	import my.core.User;
	import my.core.Util;
	import my.core.video.live.LiveVideoBox;
	import my.core.video.snap.PhotoCapture;
	import mx.events.DynamicEvent;
	
	/**
	 * The controller object that receives events from the CreatePage views and controls the model
	 * such as user or rooms.
	 */
	public class CreateController
	{
		//--------------------------------------
		// PRIVATE VARIABLES
		//--------------------------------------
		
		// associated user object
		private var _user:User;
		
		//--------------------------------------
		// PUBLIC PROPERTIES
		//--------------------------------------
		
		// associated view object
		public var view:CreatePage;
		
		//--------------------------------------
		// CONSTRUCTOR
		//--------------------------------------
		
		/*
		 * Empty constructor.
		 */
		public function CreateController()
		{
		}
		
		//--------------------------------------
		// GETTERS/SETTERS
		//--------------------------------------
		
		/**
		 * The associated user object must be set by the application, so that this controller can listen 
		 * for various property change events.
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
					oldValue.removeEventListener(PropertyChangeEvent.PROPERTY_CHANGE, userChangeHandler);
				}
				if (value != null) {
					value.addEventListener(PropertyChangeEvent.PROPERTY_CHANGE, userChangeHandler, false, 0, true);
				}
			}
		}
			
		//--------------------------------------
		// PUBLIC METHODS
		//--------------------------------------
		
		/*
		 * Following are invoked by the CreatePage view.
		 */ 
		
		/**
		 * When the user edits his name in the create page, update room's name and server.
		 */ 
		public function updateNameHandler(room:Room, text:String):void
		{
			if (room) { 
				room.name = text != "" ? text : null;
				room.server = user.server;
			}
		}
		
		/**
		 * When the user edits his email in the create page, update the room's email and server.
		 */
		public function updateEmailHandler(room:Room, text:String):void
		{
			if (room) { 
				room.email = text != "" ? text : null;
				room.server = user.server;
			}			
		}
		
		/**
		 * When the user edits the owner in create page, update the room's owner property.
		 */
		public function updateOwnerHandler(room:Room, text:String):void
		{
			if (room) { 
				room.owner = text != "" ? text : null;
			}			
		}
		
		/**
		 * When the user edits the keywords in create page, update the room's keywords.
		 */
		public function updateKeywordsHandler(room:Room, text:String):void
		{
			if (room) { 
				// TODO: this needs to be fixed
				var parts:Array = text.split(/[,;]/g);
				if (parts.length == 1) {
					parts = text.split(" ");
				}
				var texts:Array = [];
				for (var i:int=0; i<parts.length; ++i) {
					var str:String = StringUtil.trim(parts[i]);
					if (str != "")
						texts.push(str);
				}
				room.keywords = texts;
			}			
		}
		
		/**
		 * When the user clicks on the cancel button in the create page, switch to the introduction page.
		 */
		public function createCancelHandler():void
		{
			user.selectedIndex = Constant.INDEX_INTRO;
		}
		
		/**
		 * When the user clicks on the create button in the create page, initiate the room creation
		 * RPC call.
		 */
		public function createButtonHandler(room:Room, loginData:ByteArray, visitingData:ByteArray):void
		{
			if (room.owner == null || room.email == null) {
				Prompt.show("Missing owner information. Please enter you full name and email address to create a room", "Error creating new room");
			}
			else if (room.photo == null) {
				Prompt.show("Missing owner's photo. Please upload a photo or capture using your webcam by clicking on the 'live capture' or 'upload file' button", "Error creating new room");
			}
			else {
				if (room.owner == null && room.name == null) {
					Prompt.show("Cannot create an empty named room. Please enter either your name or the name of the room", "Error creating new room");
				}
				else if (room.name != null && !Util.isValidRoomName(room.name, true) || room.owner != null && !Util.isValidRoomName(room.owner, true)) {
					Prompt.show("Invalid characters in room name " + room.name + ". Please use a simple name with spaces, letters and numbers only.", "Error creating new room");
				}
				else {
					trace("creating new room");
					//CursorManager.setBusyCursor();
					var params:Object = {
						logincard: Util.base64encode(loginData),
						visitingcard: Util.base64encode(visitingData)
					};
					user.httpSend(Constant.CREATE, params, room, roomCreateHandler);
				}
			}
		}
		
		/**
		 * When the room is created, inform the user about it, and load the newly created card.
		 */
		private function roomCreateHandler(obj:Object, result:XML):void 
		{
			var room:Room = obj as Room;
			
			// if successfully sent email.
			if (result.logincard == undefined && result.visitingcard == undefined) {
				view.reset(room);
				user.selectedIndex = Constant.INDEX_INTRO;
				Prompt.show("Your room is created successfully. You will receive your card in your email " + room.email + " shortly. Please upload the card to login and/or access your room", "Room successfully created");
			}
			else {
				var logincard:VisitingCard, visitingcard:VisitingCard;
				if (result.logincard != undefined) {
					logincard = VisitingCard.readCard(String(result.logincard)); 
					if (logincard.isLoginCard)
						user.login(logincard);
				}
				if (result.visitingcard != undefined) {
					visitingcard = VisitingCard.readCard(String(result.visitingcard));
					//user.addRoom(visitingcard);
				}
				
				view.reset(room);
				user.selectedIndex = Constant.INDEX_INTRO;
				
				var closeHandler:Function = function(id:uint):void {
					var event:DynamicEvent = new DynamicEvent(Constant.DOWNLOAD);
					if (id == Alert.YES && logincard != null)
						user.downloadCard(logincard, 'loginCard.png');
					else if (id == Alert.NO && visitingcard != null)
						user.downloadCard(visitingcard);
					if (id != Alert.CANCEL)  
						throw new Error("don't close this box");
				};
				Alert.yesLabel = "Login";
				Alert.noLabel = "Visiting";
				Alert.cancelLabel = "Close";
				Prompt.show("Could not send card(s) in email. Please download your card(s) by clicking on buttons below and use as needed.", "Error sending card in email", (logincard != null ? Alert.YES : 0) | Alert.NO | Alert.CANCEL, null, closeHandler);
				Alert.yesLabel = "Yes";
				Alert.noLabel = "No";
				Alert.cancelLabel = "Cancel";
			}
		}
		
		//--------------------------------------
		// PRIVATE METHODS
		//--------------------------------------
		 
		private function userChangeHandler(event:PropertyChangeEvent):void
		{
			var property:String = event.property as String;
			var roomView:RoomPage;
			
			switch (property) {
			case "name":
				if (view.createOwnerText != null) {
					view.createOwnerText.text = user.name == null ? '' : user.name as String;
					view.createOwnerText.dispatchEvent(new Event(Event.CHANGE));
				}
				break;
				
			case "email":
				if (view.createEmailText != null) {
					view.createEmailText.text = user.email == null ? '' : user.email as String;
					view.createEmailText.dispatchEvent(new Event(Event.CHANGE));
				}
				break;
				
			case "card":
				if (view.cardImage != null) {
					view.cardImage.data = user.card;
					//view.createPage.update();
					var p:CreatePage = view;
					var t:Timer = new Timer(500, 1);
					var callback:Function = function(event:Event):void {
						t.removeEventListener(TimerEvent.TIMER, callback);
						p.update();
					};
					t.addEventListener("timer", callback);
					t.start();
				}
				
				if (view.cardList != null && view.loginCard != null) {
					if (view.cardList.contains(view.loginCard) && user.card != null) {
						view.cardList.removeChild(view.loginCard);
					}
					else if (!view.cardList.contains(view.loginCard) && user.card == null) {
						try {
							view.cardList.addChild(view.loginCard);
						} catch (e:Error) { }
					}
				}
				break;
				
			}
		}
	}
}
