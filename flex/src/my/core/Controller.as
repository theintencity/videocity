/* Copyright (c) 2009-2011, Kundan Singh. See LICENSING for details. */
package my.core
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
	import my.core.CreatePage;
	import my.core.photo.PhotoCapture;
	import my.core.room.Room;
	import my.core.room.RoomPage;
	import my.core.room.TextBox;
	import my.core.settings.AddMediaPrompt;
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
		// CLASS CONSTANTS
		//--------------------------------------
		
		// file extensions for cards.
		private static var cardTypes:FileFilter = new FileFilter("Card (*.png)", "*.png");
		
		// file extensions for uploading local files.
		private static var fileTypes:FileFilter = new FileFilter("Files (*.png, *.jpg, *.jpeg, *.gif, *.flv, *.avi, *.mpg, *.mpeg)", "*.png;*.jpg;*.jpeg;*.gif;*.flv;*.avi;*.mpg;*.mpeg");
		
		//--------------------------------------
		// PRIVATE VARIABLES
		//--------------------------------------
		
		// associated user object
		private var _user:User;
		
		// the local video's singleton instance.
		private var local0:LiveVideoBox; 
		
		// only one file operation can be in progress at any instant
		private var file:FileReference;
		private var files:FileReferenceList;
		
		private var layoutBox:Layout;
		private var layoutHideTimer:Timer;
		
		// all the rooms in this application, indexed by room's url
		private var _rooms:Dictionary = new Dictionary(true);
		
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
					oldValue.removeEventListener(Constant.CREATE_ROOM, roomHandler);
					oldValue.removeEventListener(Constant.DESTROY_ROOM, roomHandler);
					oldValue.removeEventListener(Constant.SELECT_ROOM, roomHandler);
					oldValue.removeEventListener(Constant.EXIT_ROOM, roomHandler);
					oldValue.removeEventListener("cameraChange", deviceChangeHandler);
					oldValue.removeEventListener("micChange", deviceChangeHandler);
					oldValue.removeEventListener(PropertyChangeEvent.PROPERTY_CHANGE, userChangeHandler);
				}
				if (value != null) {
					value.addEventListener(Constant.CONTROL, controlHandler, false, 0, true);
					value.addEventListener(Constant.MENU, menuHandler, false, 0, true);
					value.addEventListener(Constant.CREATE_ROOM, roomHandler, false, 0, true);
					value.addEventListener(Constant.DESTROY_ROOM, roomHandler, false, 0, true);
					value.addEventListener(Constant.SELECT_ROOM, roomHandler, false, 0, true);
					value.addEventListener(Constant.EXIT_ROOM, roomHandler, false, 0, true);
					value.addEventListener("cameraChange", deviceChangeHandler, false, 0, true);
					value.addEventListener("micChange", deviceChangeHandler, false, 0, true);
					value.addEventListener(PropertyChangeEvent.PROPERTY_CHANGE, userChangeHandler, false, 0, true);
				}
			}
		}
			
		/**
		 * Get the active box where next control can be placed, such as new dialpad or text box.
		 */
		public function get activeBox():ContainerBox
		{
			try {
				return RoomPage(view.win.getWindowAt(user.selectedIndex)).callBox;
			}
			catch (e:Error) {
				trace("exception in get activeBox: " + e.toString());
			}
			return null;
		}
		
		//--------------------------------------
		// PUBLIC METHODS
		//--------------------------------------
		
		/**
		 * Select a given container box. It finds the RoomPage associated with the container box
		 * and changes the selectedIndex to that room page.
		 */
		public function selectBox(value:ContainerBox):void
		{
			var index:int = view.win.getWindowIndex(value.parent);
			if (index >= 0)
				user.selectedIndex = index;
		}
		
		/*
		 * Following are invoked by the IntroPage view.
		 */ 
		 
		/**
		 * When user clicks on the 'create ...' button in the introduction page, switch to the 'create page'.
		 */
		public function createRoomHandler():void
		{
			user.selectedIndex = Constant.INDEX_CREATE;
		}
		
		/**
		 * When the user clicks on the 'go to ...' button in the introduction page, locate the user's
		 * logged in room page, and switch to that page.
		 */
		public function gotoGuestRoom():void
		{
			if (user != null && user.card != null) {
				user.selected = user.getRoom(user.card.url);
			}
		}
		
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
				view.createPage.reset(room);
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
				
				view.createPage.reset(room);
				user.selectedIndex = Constant.INDEX_INTRO;
				
				var closeHandler:Function = function(id:uint):void {
					if (id == Alert.YES && logincard != null) 
						downloadCardInternal(logincard, 'loginCard.png');
					else if (id == Alert.NO && visitingcard != null)
						downloadCardInternal(visitingcard);
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
		
		/*
		 * Following are invoked for uploading or downloading cards.
		 */ 
		
		public function downloadCard(card:*):void
		{
			downloadCardInternal(card);
		}
		
		public function uploadCard():void
		{
			uploadCardInternal();
		}
		
		/*
		 * Following are invoked for uploading or downloading files.
		 */
		public function downloadFiles(room:Room):void
		{
			// TODO
		}
		public function uploadFiles():void
		{
			uploadFilesInternal();
		}
		
		/*
		 * Following are invoked by the RoomPage view.
		 */ 
		 
		public function knockRoomHandler(room:Room):void
		{
			Prompt.show("This feature is not yet implemented", "Not Implemented");
		}
		
		public function sendEmailHandler(room:Room):void
		{
			var email:String = (room.email != null ? room.email : Util.url2email(room.url));
			if (Util.isEmail(email)) {
				var text:String = _("Dear Friend,\nPlease checkout the Internet Video City to live chat with me at\nhttp://{0}", user.server);
				var closeHandler:Function = function(id:uint):void {
					System.setClipboard(text);
				};
				Alert.okLabel = "copy";
				Prompt.show("<p>" + text + "<br/><font color='#ff0000'>Copy this, paste in your email client and send email</font>", 
					"Copy the email text to clipboard", Alert.OK, null, closeHandler);
				Alert.okLabel = "OK";
			}
			else {
				Prompt.show("<br/>Please enter a valid email address, e.g., bob@iptel.org"
				 + "<br/><b>Invalid email address</b>: " + email + "."
				 , "Error in parsing email address");
			}
		}
		
		public function leaveMessageHandler(room:Room):void
		{
			var closeHandler:Function = function(id:uint):void {
				if (id == Alert.OK && !user.recording) 
					user.recording = true;
			}
			Prompt.show("<br/>1. Click 'OK' to start recording.<br/>2. Click on <font color='#ff0000'>red</font> record button again to finish recording.<br/>3. Click on save button, then send to owner.", "How to record a video message", Alert.OK | Alert.CANCEL, null, closeHandler);
		}
		
		public function joinRoomHandler(room:Room):void
		{
			user.join(room);
			//user.selectedIndex = Constant.INDEX_CALL;
		}
		
		public function setRoomAccess(room:Room, type:String):void
		{
			if (user.card != null && room.isOwner) {
				if (room.card.isLoginCard && type == "public") {
					Prompt.show("You must first upload the visiting card for this room to make it public", "Error changing room access");
				}
				else {
					var params:Object = {
						logincard: Util.base64encode(user.card.rawData),
						room: room.url,
						type: type
					};
					
					if (type == "public")
						params.visitingcard = Util.base64encode(room.card.rawData);
					user.httpSend(Constant.ACCESS, params, {room: room, type: type}, setRoomAccessHandler);
				}
			}
			else {
				Prompt.show("You must login and be owner of the room to change the room access", "Error changing room access");
			}
		}
		
		private function setRoomAccessHandler(obj:Object, result:XML):void
		{
			Prompt.show('<br/>Your room is set to <font color="' + (obj.type == "public" ? '#00ff00' : '#ff0000') + '">"' + obj.type + '</font><br/><font color="#0000ff">' + obj.room.url + '</font>', "Room access changed");
		}
		
		//--------------------------------------
		// PRIVATE METHODS
		//--------------------------------------
		
		/*
		 * Following are invoked to upload or download card.
		 */
		
		private function downloadCardInternal(card:*, name:String=null):void
		{
			if (!(card is CardEditor) && !(card is VisitingCard))
				throw new Error("must supply either a VisitingCard or a CardEditor object");
			if (file == null && files == null) {
				file = new FileReference();
				file.addEventListener(Event.SELECT, downloadSelectHandler);
				file.addEventListener(Event.CANCEL, fileCancelHandler);
				file.addEventListener(Event.COMPLETE, downloadCompleteHandler);
				
				var bytes:ByteArray = card.rawData;
				if (name == null)
					name = (card is CardEditor) ? (CardEditor(card).name.split(' ').join('.') + '.png') : 'visitingCard.png';
				file.save(bytes, name);
			}
			else {
				Prompt.show("Another file operation in progress", "Error downloading file");
			}
			
		}
		
		private function downloadSelectHandler(event:Event):void
		{
		}
		
		private function downloadCompleteHandler(event:Event):void
		{
			file = null;
		}
		
		private function uploadCardInternal():void
		{
			if (file == null && files == null) {
				file = new FileReference();
				file.addEventListener(Event.SELECT, uploadSelectHandler);
				file.addEventListener(Event.CANCEL, fileCancelHandler);
				file.addEventListener(Event.COMPLETE, uploadCompleteHandler);
				try {
					file.browse([cardTypes]);
				}
				catch (error:Error) {
					file = null;
					Prompt.show(error.message, "Error opening file");
				}
			}
			else {
				Prompt.show("Another file operation in progress", "Error uploading file");
			}
		}
		
		private function uploadSelectHandler(event:Event):void
		{
			file.load();
		}
		private function fileCancelHandler(event:Event):void
		{
			file = null;
		}
		
		private function uploadCompleteHandler(event:Event):void
		{
			trace("loaded " + file.data.length);
			var card:VisitingCard = VisitingCard.load(file.data);
			file = null;
			//card.popup();
			var error:String = card.validate();
			if (error != null) {
				Prompt.show(error, "Cannot load the card");
			}
			else {
				if (card.isLoginCard) {
					user.login(card);
				}
				else {
					user.addRoom(card);
				}
			}
		}

		/**
		 * Following are used for uploading files such as photos in a room.
		 */
		private function uploadFilesInternal():void
		{
			if (file == null && files == null) {
				files = new FileReferenceList();
				files.addEventListener(Event.SELECT, filesSelectHandler);
				files.addEventListener(Event.CANCEL, filesCancelHandler);
				try {
					files.browse([fileTypes]);
				}
				catch (error:Error) {
					files = null;
					Prompt.show(error.message, "Error opening files");
				}
			}
			else {
				Prompt.show("Another file operation in progress", "Error uploading file");
			}
		}
		
		private var pendingFiles:Array = [];
		
		private function filesSelectHandler(event:Event):void
		{
			for (var i:int=0; i<files.fileList.length; ++i) {
				var file:FileReference = FileReference(files.fileList[i]);
				pendingFiles.push(file);
				file.addEventListener(Event.COMPLETE, loadCompleteHandler);
				file.addEventListener(IOErrorEvent.IO_ERROR, loadErrorHandler);
				file.addEventListener(SecurityErrorEvent.SECURITY_ERROR, loadErrorHandler);
				file.load();
			}
		}
		
		private function filesCancelHandler(event:Event):void
		{
			files = null;
		}
		
		private function loadErrorHandler(event:Event):void
		{
			var file:FileReference = event.currentTarget as FileReference;
			var index:int = pendingFiles.indexOf(file);
			if (index >= 0) pendingFiles.splice(index, 1);
			if (files != null) {
				for (var i:int=0; i<files.fileList.length; ++i) {
					if (files.fileList[i] == file) {
						files.fileList.splice(i, 1);
						break;
					}
				}
			}
			if (files != null && pendingFiles.length == 0) {
				if (user.selected != null && files.fileList.length > 0) {
					user.selected.load(files);
				}
				files = null;
			}
		}
		
		private function loadCompleteHandler(event:Event):void
		{
			var file:FileReference = event.currentTarget as FileReference;
			var index:int = pendingFiles.indexOf(file);
			if (index >= 0) pendingFiles.splice(index, 1);
			
			
			var isCard:Boolean = false; // if loaded file is a card, don't display as image in playlist
			
			trace("loaded name=" + file.name + " type=" + file.type + " size=" + file.size);
			index = String(file.name).lastIndexOf('.');
			var ext:String = index >= 0 ? String(file.name).substr(index) : '';
			if (ext.toLowerCase() == '.png') {
				// this could be a visiting card.
				var card:VisitingCard = VisitingCard.load(file.data);
				var error:String = card.validate();
				if (error == null) {
					if (card.isLoginCard)
						user.login(card);
					else
						user.addRoom(card);
					isCard = true;
				}
			}

			if (isCard && files != null) {
				for (var i:int=0; i<files.fileList.length; ++i) {
					if (files.fileList[i] == file) {
						files.fileList.splice(i, 1);
						break;
					}
				}
			}
			
			if (files != null && pendingFiles.length == 0) {
				if (user.selected != null && files.fileList.length > 0) {
					user.selected.load(files);
				}
				files = null;
			}
		}
		
		/*
		 * Following are invoked by user model related to room.
		 */
		private function roomHandler(event:DataEvent):void
		{
			var room:Room = user.getRoom(event.data);
			var roomView:RoomPage = getRoomView(room);
			var index:int = (roomView != null ? view.win.getWindowIndex(roomView) : -1);
			switch (event.type) {
			case Constant.SELECT_ROOM:
				if (user.selected != room)
					user.selected = room;
				break;
			case Constant.EXIT_ROOM:
				if (room.connected) 
					room.disconnect();
				else
					user.selected = user.getPreviousRoom(room);
				break;
			case Constant.CREATE_ROOM:
				if (roomView == null) {
					roomView = new RoomPage();
					roomView.controller = this;
					roomView.user = user;
					roomView.room = room;
					_rooms[room] = roomView;
					view.win.addChild(roomView);
				}
				user.selected = room;
				break;
			case Constant.DESTROY_ROOM:
				user.selected = user.getPreviousRoom(room);
				if (room.connected)
					room.disconnect();
				if (roomView != null) {
					// need to remove from view after a timeout for good animation effect.
					var t:Timer = new Timer(1000, 1);
					var removeChild:Function = function(event:Event):void {
						t.removeEventListener(TimerEvent.TIMER, removeChild);
						view.win.removeChild(roomView);
					}
					t.addEventListener(TimerEvent.TIMER, removeChild);
					t.start();
					//view.win.removeChild(roomView);
					delete _rooms[room];
				}
				break;
			}
		}
		
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
			case Constant.UPLOAD:
				if (user.selected == null || !user.selected.connected)
					uploadCard(); // upload card on other pages.
				else
					uploadFiles(); // upload files on connected room pages. May include a card.
				break;
			case Constant.LOAD:
				AddMediaPrompt.show(user);
				break;
			case Constant.CREATE:
				if (user.selected != null && user.selected.connected) {
					user.selected.load(XML('<show description="Click to edit title"/>'));
				}
				break;
			case Constant.CAPTURE:    
				captureHandler(event); 
				break;
				
			case Constant.PHONE:
				Prompt.show("This feature is currently not implemented", "Not implemented yet");
				break;
				
			case Constant.MESSAGE:
				if (user.selected != null) {
					var roomPage:RoomPage = getRoomView(user.selected);
					var box:ContainerBox = roomPage.callBox;
					var text:TextBox = box.getChildByName("text") as TextBox;
					if (text == null) {
						text = new TextBox();
						text.room = user.selected;
						box.addChild(text);
					}
					else {
						box.removeChild(text);
					}
				}
				break;
			case Constant.ENTER_ROOM:
				if (user.selected != null)
					joinRoomHandler(user.selected);
				break;
			}
		}
		
		public function addTextBox(room:Room):void
		{
			var roomPage:RoomPage = getRoomView(room);
			var box:ContainerBox = roomPage != null ? roomPage.callBox : null;
			var text:TextBox = box != null ? box.getChildByName("text") as TextBox : null;
			if (text == null) {
				text = new TextBox();
				text.room = room;
				box.addChild(text);
			}	
		}
		
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
		 * Following are invoked by the User model.
		 */ 
		 
		private function userChangeHandler(event:PropertyChangeEvent):void
		{
			var property:String = event.property as String;
			var roomView:RoomPage;
			
			switch (property) {
			case "name":
				if (view.createPage.createOwnerText != null) {
					view.createPage.createOwnerText.text = user.name == null ? '' : user.name as String;
					view.createPage.createOwnerText.dispatchEvent(new Event(Event.CHANGE));
				}
				break;
				
			case "email":
				if (view.createPage.createEmailText != null) {
					view.createPage.createEmailText.text = user.email == null ? '' : user.email as String;
					view.createPage.createEmailText.dispatchEvent(new Event(Event.CHANGE));
				}
				break;
				
			case "card":
				if (view.createPage.cardImage != null) {
					view.createPage.cardImage.data = user.card;
					//view.createPage.update();
					var p:CreatePage = view.createPage;
					var t:Timer = new Timer(500, 1);
					var callback:Function = function(event:Event):void {
						t.removeEventListener(TimerEvent.TIMER, callback);
						p.update();
					};
					t.addEventListener("timer", callback);
					t.start();
				}
				
				if (view.createPage.cardList != null && view.createPage.loginCard != null) {
					if (view.createPage.cardList.contains(view.createPage.loginCard) && user.card != null) {
						view.createPage.cardList.removeChild(view.createPage.loginCard);
					}
					else if (!view.createPage.cardList.contains(view.createPage.loginCard) && user.card == null) {
						try {
							view.createPage.cardList.addChild(view.createPage.loginCard);
						} catch (e:Error) { }
					}
				}
				break;
				
			case "selected":
				roomView = getRoomView(user.selected);
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
		
		private function deviceChangeHandler(event:Event):void
		{
			if (local0 != null)
				local0.video.attachCamera(user.camera);
		}
		
		private function addStickyBox(box:BaseBox):void
		{
			var roomView:RoomPage = getRoomView(user.selected);
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
		
		/*
		 * Following are invoked by the MenuBox.
		 */ 
		 
		private function menuHandler(event:DataEvent):void
		{
			switch (event.data) {
			case Constant.SMOOTH:     if (user) user.smoothing = !user.smoothing; break;
			case Constant.FULL_SCREEN:FullScreen.toggleFullScreen(); break;
			case Constant.STRETCH:    FullScreen.toggleFullScreen(true); break;
			case Constant.SELECT:     startSelectScreen(); break;
			case Constant.SETTINGS:   Security.showSettings(); break;
			case Constant.DEVICE:     DeviceSettings.show(user); break;
			case Constant.PHONE:      Prompt.show("This feature is currently not implemented.", "Not Implemented"); break; // PhoneSettings.show(); break;
			case Constant.EMBED:      showEmbedSettings(); break;
			case Constant.SEARCH:     Prompt.show("This feature is currently not implemented.", "Not Implemented"); break;
				
			case Constant.LOGIN:
				if (user != null) {
					if (user.isGuest) uploadCard(); 
					else user.logout(); 
				}
				break;
			
			case Constant.SIGNUP:
				if (user != null) {
					if (user.isGuest)
						createRoomHandler();
					else
						LoginSettings.show(user);
				}
				break;
			}
		}

		/**
		 * Return an array [activeBox, activePlayList]
		 */
		public function getMaximizedBox():Array
		{
			var callBox:ContainerBox = this.activeBox;
			var playlist:DisplayObject = null;
			if (callBox != null) {
				if (callBox.maximized != null) {
					playlist = callBox.maximized;
				}
			}
			return [callBox, playlist]
		}
		
		public function getRoomView(room:Room):RoomPage
		{
			return (room in _rooms ? _rooms[room] as RoomPage : null);		
		}
		
		
		private var capture:PhotoCapture;
		
		private function captureHandler(event:Event):void
		{
			if (user.selected != null && user.selected.connected) {
				capture = PopUpManager.createPopUp(Application.application as DisplayObject, PhotoCapture, true) as PhotoCapture;
				capture.addEventListener(Event.COMPLETE, captureCompleteHandler, false, 0, true);
				capture.maintainAspectRatio = false;
				PopUpManager.centerPopUp(capture);
			}
			else {
				Prompt.show("You must be inside a room to launch this tool", "Error launching tool");
			}
		}
		
		private function captureCompleteHandler(event:Event):void
		{
			if (capture != null && capture.selectedPhoto != null) {
				if (user.selected != null && user.selected.connected)
					user.selected.load(capture.selectedPhoto.getChildAt(0));
			}
			capture = null;
		}
		
		private function startSelectScreen():void
		{
			if (!FullScreen.fullScreen) {
				PostIt.show("<b>Drag &amp; Select<br/>a region</b>", Application.application.root);
				Application.application.mouseChildren = false;
				Application.application.addEventListener(MouseEvent.MOUSE_DOWN, selectMouseDownHandler, false, 0, true);
			}
		}
		
		private var dragRect:Canvas = null;
		
		private function selectMouseDownHandler(event:MouseEvent):void
		{
			Application.application.removeEventListener(MouseEvent.MOUSE_DOWN, selectMouseDownHandler);
			Application.application.addEventListener(MouseEvent.MOUSE_UP, selectMouseUpHandler, false, 0, true);
			Application.application.addEventListener(MouseEvent.MOUSE_MOVE, selectMouseMoveHandler, false, 0, true);
			dragRect = new Canvas();
			dragRect.setStyle("borderStyle", "solid");
			dragRect.setStyle("borderColor", 0xffffff);
			dragRect.setStyle("borderThickness", 1);
			dragRect.setStyle("backgroundAlpha", 0);
			dragRect.x = Application.application.mouseX;
			dragRect.y = Application.application.mouseY;
			dragRect.width = dragRect.height = 0;
			Application.application.addChild(dragRect);
		}
		
		private function selectMouseMoveHandler(event:MouseEvent):void
		{
			if (dragRect != null) {
				dragRect.width = Application.application.mouseX - dragRect.x;
				dragRect.height = Application.application.mouseY - dragRect.y;
			}
		}
		
		private function selectMouseUpHandler(event:MouseEvent):void
		{
			Application.application.mouseChildren = true;
			Application.application.removeEventListener(MouseEvent.MOUSE_UP, selectMouseUpHandler);
			Application.application.removeEventListener(MouseEvent.MOUSE_MOVE, selectMouseMoveHandler);
			
			if (dragRect != null) {
				var rect:Rectangle = new Rectangle(dragRect.x, dragRect.y, dragRect.x+dragRect.width, dragRect.y+dragRect.height);
				Application.application.removeChild(dragRect);
				dragRect = null;
				
				trace("rect=" + rect.x + "," + rect.y + " " + rect.width + "x" + rect.height);
				if (rect.width >= 10 && rect.height >= 10) {
					FullScreen.toggleFullScreen(true, rect);
				}
			}
			
		}
	}
}
