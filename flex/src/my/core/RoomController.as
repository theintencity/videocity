/* Copyright (c) 2009-2011, Kundan Singh. See LICENSING for details. */
package my.core
{
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.events.DataEvent;
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.media.Video;
	import flash.net.FileReference;
	import flash.net.NetStream;
	import flash.net.URLRequest;
	
	import mx.controls.Alert;
	import mx.events.CollectionEvent;
	import mx.events.CollectionEventKind;
	import mx.events.DynamicEvent;
	import mx.events.PropertyChangeEvent;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	import mx.rpc.http.HTTPService;
	
	import my.containers.ContainerBox;
	import my.controls.PostIt;
	import my.controls.Prompt;
	import my.controls.TrashButton;
	import my.core.pages.RoomPage;
	import my.play.PlayItem;
	import my.play.PlayList;
	import my.play.PlayListBox;
	import my.video.VideoBox;
	
	/**
	 * Controller to update the page based on the user's script, streams or files..
	 */
	public class RoomController
	{
		//--------------------------------------
		// PRIVATE VARIABLES
		//--------------------------------------
		
		private var _user:User;
		
		// pending web requests
		private var pending:Object = new Object();
		
		//--------------------------------------
		// PUBLIC VARIABLES
		//--------------------------------------
		
		/**
		 * The associated main view.
		 */
		public var main:View;
		
		/**
		 * The associated controller.
		 */
		public var controller:Controller;
		
		//--------------------------------------
		// CONSTRUCTOR
		//--------------------------------------
		
		/*
		 * Empty constructor.
		 */
		public function RoomController()
		{
		}

		//--------------------------------------
		// GETTERS/SETTERS
		//--------------------------------------
		
		/**
		 * The user object must be set by the application, so that the controller can act on various
		 * events such as playList, enterRoom, exitRoom, etc.
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
					oldValue.removeEventListener(Constant.PLAY_LIST, playListHandler);
					oldValue.removeEventListener(Constant.ENTER_ROOM, roomHandler);
					oldValue.removeEventListener(Constant.EXIT_ROOM, roomHandler);
					oldValue.removeEventListener(PropertyChangeEvent.PROPERTY_CHANGE, userChangeHandler);
				}
				if (value != null) {
					value.addEventListener(Constant.PLAY_LIST, playListHandler, false, 0, true);
					value.addEventListener(Constant.ENTER_ROOM, roomHandler, false, 0, true);
					value.addEventListener(Constant.EXIT_ROOM, roomHandler, false, 0, true);
					value.addEventListener(PropertyChangeEvent.PROPERTY_CHANGE, userChangeHandler, false, 0, true);
				}
			}
		}
		
		//--------------------------------------
		// PRIVATE METHODS
		//--------------------------------------
		
		private function roomHandler(event:DataEvent):void
		{
			var room:Room = user.getRoom(event.data);
			
			switch (event.type) {
			case Constant.ENTER_ROOM:
				// a new room is created, fetch a welcome page if needed
				room.addEventListener(PropertyChangeEvent.PROPERTY_CHANGE, roomChangeHandler, false, 0, true);
				room.addEventListener(Constant.MESSAGE, messageHandler, false, 10, true);
				room.addEventListener(Constant.MEMBERS_CHANGE, membersChangeHandler, false, 0, true);
				room.addEventListener(Constant.STREAMS_CHANGE, streamsChangeHandler, false, 0, true);
				room.addEventListener(Constant.FILES_CHANGE, filesChangeHandler, false, 0, true);
				if (room.connected)
					scriptStart(room, Constant.PUBLIC);
				break;
			case Constant.EXIT_ROOM:
				room.files.removeAll();
				room.streams.removeAll();
				room.removeEventListener(PropertyChangeEvent.PROPERTY_CHANGE, roomChangeHandler);
				room.removeEventListener(Constant.MESSAGE, messageHandler);
				room.removeEventListener(Constant.MEMBERS_CHANGE, membersChangeHandler);
				room.removeEventListener(Constant.STREAMS_CHANGE, streamsChangeHandler);
				room.removeEventListener(Constant.FILES_CHANGE, filesChangeHandler);
				scriptStop(room);
				break;
			}
		}
		
		private function userChangeHandler(event:PropertyChangeEvent):void
		{
			if (event.property == "card" && event.oldValue != event.newValue) {
				if (user.card != null) {
					var room:Room = user.getRoom(user.card.url);
					if (room != null)
						scriptStart(room, Constant.PRIVATE);
				}
			}
		}
		
		private function roomChangeHandler(event:PropertyChangeEvent):void
		{
			var room:Room = event.currentTarget as Room;
			if (event.property == "connected") {
				if (event.newValue) {
					scriptStart(room, Constant.PUBLIC);
				}
				else {
					scriptStop(room);
					var roomPage:RoomPage = controller.getRoomView(room);
					roomPage.callBox.removeAllChildren();
				}
			}
		}

		private function membersChangeHandler(event:CollectionEvent):void
		{
			var room:Room = event.currentTarget as Room;
			var roomPage:RoomPage = controller.getRoomView(room);
			var callBox:ContainerBox = roomPage != null ? roomPage.callBox : null;
			var item:Object;
			
			switch (event.kind) {
			case CollectionEventKind.ADD:
				for each (item in event.items)
					postIt(item.name + " joined");
				break;
				
			case CollectionEventKind.REMOVE:
				for each (item in event.items)
					postIt(item.name + " left");
				break;
			}
		}
		
		private function postIt(msg:String):void
		{
			var index:int = controller.view.win.selectedIndex;
			var page:DisplayObjectContainer = controller.view.win.getWindowAt(index) as DisplayObjectContainer;
			PostIt.show(msg, page);
		}
		
		private function streamsChangeHandler(event:CollectionEvent):void
		{
			var room:Room = event.currentTarget as Room;
			var roomPage:RoomPage = controller.getRoomView(room);
			var callBox:ContainerBox = roomPage.callBox;
			
			var box:VideoBox;
			var video:Video;
			var ns:NetStream;
			var item:Object;
			
			switch (event.kind) {
			case CollectionEventKind.ADD:
				for each (item in event.items) {
					box = new VideoBox();
					video = new Video();
					video.attachNetStream(item.stream);
					box.video = video;
					box.data = item;
					item.box = box;
					callBox.addChild(box);
				}
				break;
				
			case CollectionEventKind.REMOVE:
				for each (item in event.items) {
					box = item.box;
					ns = item.stream;
					if (box != null) {
						video = box.video;
						if (video != null)
							video.attachNetStream(null);
						
						box.video = null;
						box.data = null;
						if (callBox.contains(box)) 
							callBox.removeChild(box);
					}
				}
				break;
			
			case CollectionEventKind.RESET:
				for each (var v:DisplayObject in callBox.getChildren()) {
					box = v as VideoBox;
					if (box != null && box.data != null && box.data.stream != null) {
						box.data.stream.close();
						box.data.stream = null;
						box.data = null;
						callBox.removeChild(box);
					}
				}
				break;
			}
		}
		
		private function filesChangeHandler(event:CollectionEvent):void
		{
			var room:Room = event.currentTarget as Room;
			var roomPage:RoomPage = controller.getRoomView(room);
			var callBox:ContainerBox = roomPage.callBox;
			
			var box:PlayListBox;
			var obj:Object;
			var xml:XML;
			var files:Array;
			
			switch (event.kind) {
			case CollectionEventKind.ADD:
				for each (obj in event.items) {
					box = new PlayListBox();
					box.playList = obj as PlayList;
					callBox.addChild(box);
				}
				break;
			case CollectionEventKind.REMOVE:
				for each (obj in event.items) {
					for (var i:int=callBox.numChildren-1; i>=0; --i) {
						box = callBox.getChildAt(i) as PlayListBox;
						if (box != null && box.playList == obj) {
							callBox.removeChildAt(i);
							box.playList = null;
						}
					}
				}
				break;
				
			case CollectionEventKind.RESET:
				for (var j:int=callBox.numChildren-1; j>=0; --j) {
					box = callBox.getChildAt(j) as PlayListBox;
					if (box != null) {
						callBox.removeChildAt(j);
						box.playList = null;
					}
				}
				break;
			}
		}
		
		private function messageHandler(event:DynamicEvent):void
		{
			var room:Room = event.currentTarget as Room;
			controller.addTextBox(room);
		}
		
		private function scriptStart(room:Room, target:String):void
		{
			scriptStop(room, target); // first stop any previous pending script
			
			var url:String = room.scriptUrl + '/' + target;
			var http:HTTPService = new HTTPService();
			http.addEventListener(ResultEvent.RESULT, httpResponseHandler, false, 0, true);
			http.addEventListener(FaultEvent.FAULT, httpResponseHandler, false, 0, true);
			http.resultFormat = "e4x";
			http.url = url;
			http.send();
			pending[url] = {http: http, room: room, target: target};
		}
		
		private function scriptStop(room:Room, target:String=null):void 
		{
			if (target == null) {
				scriptStop(room, Constant.ACTIVE);
				scriptStop(room, Constant.PUBLIC);
				scriptStop(room, Constant.PRIVATE);
			}
			else if (room != null) {
				var url:String = room.scriptUrl + '/' + target;
				if (url in pending) {
					var p:Object = pending[url];
					delete pending[url]
					if (p != null)
						HTTPService(p.http).cancel();
				}
			}
		}
		
		private function httpResponseHandler(event:Event):void
		{
			//var http:HTTPService = event.currentTarget as HTTPService;
			// in new SDK, the target is HTTPOperation, but does have url property.
			var url:String = event.currentTarget.url as String;
			var p:Object = pending[url]
			delete pending[url];
			if (event is ResultEvent) {
				var result:ResultEvent = event as ResultEvent;
				var xml:XML = result.result as XML;
				applyScript(p.room, xml);
				if (p.target == Constant.PUBLIC)
					scriptStart(p.room, Constant.ACTIVE);
				else if (p.target == Constant.ACTIVE) {
					if (Room(p.room).isOwner && user.card.url == Room(p.room).card.url)
						scriptStart(p.room, Constant.PRIVATE);
				}
			}
		}
		
		private function applyScript(room:Room, xml:XML):void
		{
			trace(xml.toXMLString());
			if (xml.localName() == "page") {
				for each (var cmd:XML in xml.children()) {
					if (cmd.localName() == "show")
						room.load(cmd);
				}
			}
		}
		
		/**
		 * Following are related to play list.
		 */
		 
		/*
		 * Handle the playList event triggered by SaveMediaPrompt on the user object.
		 * It internally invokes uploadPlayList or savePlayList. 
		 */  
		private function playListHandler(event:DynamicEvent):void
		{
			switch (event.command) {
				case Constant.SAVE:
					savePlayList(event.playItem);
					break;
				case Constant.SHARE:
					uploadPlayList(event.room, event.playList, Constant.ACTIVE);
					break;
				case Constant.UPLOAD:
					var room:Room = user.card != null ? user.getRoom(user.card.url) : null;
					if (room != null)
						uploadPlayList(room, event.playList, Constant.PUBLIC);
					else
						Prompt.show("You must be logged in to your room to send media to your room", "Error sending play-list");
					break;
				case Constant.SEND:
					uploadPlayList(event.room, event.playList, Constant.PRIVATE);
					break;
				case TrashButton.TRASH:
					trashPlayList(event.room, event.playList);
					break;
				default:
					trace("invalid playList command " + event.command);
					break;
			}
		}

		// temporary file reference does not work for FileReference.download() hence we need to make it
		// permanent by keeping in the member variable.
		private var _shareFile:FileReference;
		
		/*
		 * Save the current playItem to the local computer.
		 */
		private function savePlayList(playItem:PlayItem):void
		{
			if (playItem != null) {
				_shareFile = new FileReference();
				_shareFile.addEventListener(SecurityErrorEvent.SECURITY_ERROR, saveCompleteHandler, false, 0, true);
				_shareFile.addEventListener(IOErrorEvent.IO_ERROR, saveCompleteHandler, false, 0, true);
				_shareFile.addEventListener(Event.COMPLETE, saveCompleteHandler, false, 0, true);
				try {
					if (playItem.content == null) {
						var url:String = String(playItem.xml.@src);
						if (playItem.name == PlayItem.STREAM)
							url = user.getHttpURL(url, String(playItem.xml.@id));
						else if (url.indexOf("http://" + user.server) != 0)
							url = user.getProxiedURL(url, true);
						var req:URLRequest = new URLRequest(url);
						var name:String = (playItem.name == PlayItem.VIDEO || req.url.substr(req.url.length-4) == '.flv') ? 'video.flv' : null;
						trace("downloading " + playItem.source + " to " + name);
						_shareFile.download(req, name);
					}
					else {
						var fname:String = String(playItem.xml.@src);
						if (fname.substr(0, 7) == 'file://')
							fname = fname.substr(7);
						_shareFile.save(playItem.content, fname);
					}
				}
				catch (e:Error) {
					Prompt.show(e.toString(), "Cannot download content");
				}
			}
			else {
				Prompt.show("Not a valid play item in the play list", "Error downloding play item");
			}
		}	
		
		private function saveCompleteHandler(event:Event):void
		{
			if (_shareFile != null) {
				_shareFile.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, saveCompleteHandler);
				_shareFile.removeEventListener(IOErrorEvent.IO_ERROR, saveCompleteHandler);
				_shareFile.removeEventListener(Event.COMPLETE, saveCompleteHandler);
				_shareFile = null;
			}
			if (event.type != Event.COMPLETE && event is ErrorEvent) 
				Prompt.show(ErrorEvent(event).text, "Error downloading file");
			else
				postIt("File saved to disk");
		}
		
		/*
		 * Upload a play-list to this room. The target parameter determines how the play list is saved and/or
		 * authenticated. If the target is ACTIVE, then the files are shared in the currently active 
		 * session of the room, and disappear when the session is closed. The sender must be in the active
		 * session via RTMP connection to the room. If the target is PUBLIC then the files are saved in the
		 * supplied room permanently, e.g., referred in the index.xml file. The sender must have the login
		 * access to this room. If the target is PRIVATE then the files are saved in the supplied room
		 * permanently, but is available only to the owner of the room, e.g., referred in the inbox.xml file.
		 * The sender must have visiting access to this room. 
		 * The files are uploaded using HTTP. The actual play-list, which is an XML description referencing
		 * the files, are uploaded either using HTTP (when target is PUBLIC or PRIVATE) or RTMP/RPC (when 
		 * target is ACTIVE). If the play-list contains reference to external resources such as HTTP URLs
		 * then the files for those resources are not explicitly uploaded. If the play-list contains actual
		 * file content such as FileReference uploaded from local user's computer, then those files are
		 * uploaded using HTTP before the play-list gets uploaded. Also, the play-list is updated to refer
		 * to the HTTP URL of the uploaded files, instead of the file content.
		 */
		private function uploadPlayList(room:Room, playList:PlayList, target:String):void
		{
			var params:Object = {
				target: target,
				filedata: playList.data.toXMLString()
			};
			
			var index:int = 0;
			for each (var playItem:PlayItem in playList) {
				var xml1:XML = playItem.xml;
				if (xml1.@src != undefined && String(xml1.@src).substr(0, 7) == "file://") {
					params['filename' + index.toString()] = String(xml1.@src);
					params['filedata' + index.toString()] = Util.base64encode(playItem.content);
					++index;
				}
			}
			
			if (target == Constant.PUBLIC && user.card != null)
				params.logincard = Util.base64encode(user.card.rawData);
			else if (room.card != null)
				params.visitingcard = Util.base64encode(room.card.rawData);
				
			var context:Object = {
				room: room,
				playList: playList,
				target: target
			};
				
			user.httpSend(Constant.UPLOAD, params, context, uploadResultHandler);
		}

		private function uploadResultHandler(context:Object, result:XML):void 
		{
			if (context.target == Constant.PUBLIC || context.target == Constant.PRIVATE) {
				postIt("Upload success");
			}
			else {
				var room:Room = context.room;
				var playList:PlayList = context.playList;
				
				var show:XML = result.filedata != undefined && result.filedata[0].show != undefined ? result.filedata[0].show[0] : null;
				if (show != null) {
					room.commandSend(Constant.BROADCAST, "published", playList.id, show.toXMLString());
					postIt("Sharing completed");
				}
				else {
					Prompt.show("Your file upload failed", "Play list upload failure");
				} 
			}
		}

		private function trashPlayList(room:Room, playList:PlayList):void
		{
			var desc:String = playList.data.toXMLString();
			
			room.commandSend(Constant.BROADCAST, "unpublished", playList.id, desc);
			
			var params:Object = {
				filedata: desc
			};
			
			if (room.isOwner)
				params.logincard = Util.base64encode(user.card.rawData);
			else if (room.card != null)
				params.visitingcard = Util.base64encode(room.card.rawData);
				
			var context:Object = {
				room: room,
				playList: playList
			};
			
			user.httpSend(TrashButton.TRASH, params, context);
		}
	}
}