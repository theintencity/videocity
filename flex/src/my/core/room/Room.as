/* Copyright (c) 2009-2011, Kundan Singh. See LICENSING for details. */
package my.core.room
{
	import flash.events.DataEvent;
	import flash.events.ErrorEvent;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.NetStatusEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.NetConnection;
	import flash.net.NetStream;
	import flash.net.SharedObject;
	import flash.net.ObjectEncoding;
	import flash.net.FileReference;
	import flash.net.FileReferenceList;
	import flash.utils.ByteArray;
	import flash.display.DisplayObject;
	import flash.display.Bitmap;
	
	import mx.controls.Image;
	import mx.controls.Alert;
	import mx.utils.ObjectProxy;
	import mx.events.DynamicEvent;
	import mx.events.PropertyChangeEvent;
	import mx.events.CollectionEvent;
	import mx.collections.ArrayCollection;
	import mx.collections.XMLListCollection;
	import mx.rpc.Responder;
	import mx.graphics.codec.JPEGEncoder;
	
	import my.controls.Prompt;
	import my.core.Constant;
	import my.core.playlist.PlayItem;
	import my.core.playlist.PlayList;
	import my.core.card.VisitingCard;
	import my.core.User;
	import my.core.Util;
	
	/**
	 * Dispatched when a control button is clicked. Possible values of data property:
	 * ENTER_ROOM, EXIT_ROOM, etc. This is dispatched on behalf in ControlBar, RoomController or RoomPage
	 * @eventType my.core.Constant.CONTROL_ROOM
	 */
	[Event(name="controlRoom", type="flash.events.DataEvent")]
	
	/**
	 * Dispatched when a playlist related button is clicked. Possible values of data property:
	 * TRASH_PLAYLIST, UPLOAD_PLAYLIST_TO_ROOM, etc.
	 * @eventType my.core.Constant.CONTROL_PLAYLIST
	 */
	[Event(name="controlPlaylist", type="flash.events.DataEvent")]
	
	/**
	 * Dispatched when an incoming message is received.
	 * @eventType my.core.Constant.RECEIVE_MESSAGE
	 */
	[Event(name="receiveMessage", type="flash.events.DynamicEvent")]
	
	/**
	 * Dispatched when the members property changes.
	 * @eventType my.core.Constant.MEMBERS_CHANGE
 	 */
	[Event(name="membersChange", type="mx.collections.CollectionEvent")]
	
	/**
	 * Dispatched when the streams property changes.
	 * @eventType my.core.Constant.STREAMS_CHANGE
	 */
	[Event(name="streamsChange", type="mx.collections.CollectionEvent")]
	
	/**
	 * Dispatched when the files property changes.
	 * @eventType my.core.Constant.FILES_CHANGE
	 */
	[Event(name="filesChange", type="mx.collections.CollectionEvent")]
	
	/**
	 * A room is represented by a unique URL that is used to connect to the room. One user can be the owner
	 * of many rooms. Each room has a visiting card. The owner can give out the visiting card of the room
	 * to friends so that they can join, or make the room public in which case the visiting card is available
	 * at the server for anyone to use.
	 * 
	 * The url, user and card are the important properties of the room. The current state of the room is
	 * defined by these properties: valid and connected. 
	 */
	public class Room extends EventDispatcher
	{
		//--------------------------------------
		// CLASS CONSTANTS
		//--------------------------------------
		
		private static const callbackMethods:Array = ['added', 'removed', 'published', 'unpublished', 'broadcast', 'unicast'];
		
		//--------------------------------------
		// PRIVATE VARIABLES
		//--------------------------------------
		
		private var _photo:Object;  // the photo image
		private var _url:String;    // URL string identifying the room
		private var _flashUrl:String; // URL for Flash access
		private var _card:VisitingCard; // visiting card of the room
		private var _isOwner:Boolean; // whether User is owner of this room?
		private var _nc:NetConnection; // underlying connection to the server for this room
		private var _ns:NetStream;  // local published stream for local video
		private var _stream:String; // local stream name that is published. This is randomly generated.
		private var _user:User;     // the local user for this room -- set only for RoomPage.room.
		
		private var _lock:Boolean = false;
		private var _isPublic:Boolean = false;
		private var _isController:Boolean = false;
		
		//--------------------------------------
		// PUBLIC PROPERTIES
		//--------------------------------------
		
		[Bindable]
		/**
		 * The optional name of the room. If this is not set, then the owner's name is used.
		 */
		public var name:String;
		
		[Bindable]
		/**
		 * The full name of the owner of the room.
		 */
		public var owner:String;
		
		[Bindable]
		/**
		 * The email address of the owner of the room. The room URL must contain the first scope as the 
		 * email address, e.g., http://server/kundan@39peers.net/Public.Forum
		 */
		public var email:String;
		
		[Bindable]
		/**
		 * The list of keywords that are used to indicate the room's content.
		 */
		public var keywords:Array;
		
		[Bindable]
		/**
		 * Whether we have a valid card for the room or not? When creating a room, this property indicates
		 * whether we have created the room or not?
		 */
		public var valid:Boolean = false; // whether created or not?
		
		[Bindable]
		/**
		 * Whether we have joined the room or not? An attempt to join the room when a card is not available
		 * results in error.
		 */
		public var connected:Boolean = false;
		
		[Bindable]
		/**
		 * List of all the members in this room. Each item is of type Member and contains properties
		 * such as name, photo and stream. The photo and stream objects are optional. The Room's streams
		 * property contains list of all the active Stream objects.
		 */
		public var members:ArrayCollection = new ArrayCollection();
		 
		[Bindable]
		/**
		 * List of all the streams in this room. Each item is of type Stream and contains properties
		 * such as name and stream (NetStream). A reference to the Stream object also exists in the
		 * corresponding Member's stream property.
		 */
		public var streams:ArrayCollection = new ArrayCollection();
		 
		[Bindable]
		/**
		 * List of all the shared media files in this room. Each item is of type PlayList. Each item
		 * represents a single playlist and may contain more than one files.
		 */
		public var files:ArrayCollection = new ArrayCollection();
		
		[Bindable]
		/**
		 * Base64 encoded opaque key or certificate.
		 */
		public var key:String; 
		
		[Bindable]
		/**
		 * The view object of this data model is of type RoomPage.
		 */
		public var view:RoomPage;
		
		//--------------------------------------
		// STATIC CONSTRUCTOR
		//--------------------------------------
		
		// Since our server only supports AMF0, this must be done before any NetConnection.
		{
			NetConnection.defaultObjectEncoding = ObjectEncoding.AMF0;
			SharedObject.defaultObjectEncoding = ObjectEncoding.AMF0;
		}
		
		//--------------------------------------
		// CONSTRUCTOR/DESTRUCTOR
		//--------------------------------------
		
		/**
		 * Constuct a new room object. Generates a random local stream name.
		 */
		public function Room()
		{
			_stream = Util.createId();
			members.addEventListener(CollectionEvent.COLLECTION_CHANGE, membersChangeHandler, false, 0, true);
			streams.addEventListener(CollectionEvent.COLLECTION_CHANGE, streamsChangeHandler, false, 0, true);
			files.addEventListener(CollectionEvent.COLLECTION_CHANGE, filesChangeHandler, false, 0, true);
		}
		
		/**
		 * Destroy and disconnect this room. This should be called by the application to cleanup the room.
		 */
		public function close():void
		{
			disconnect();
			members.removeEventListener(CollectionEvent.COLLECTION_CHANGE, membersChangeHandler);
			streams.removeEventListener(CollectionEvent.COLLECTION_CHANGE, streamsChangeHandler);
			files.removeEventListener(CollectionEvent.COLLECTION_CHANGE, filesChangeHandler);
		}
		
		//--------------------------------------
		// GETTERS/SETTERS
		//--------------------------------------
		
		[Bindable]
		/**
		 * The URL string identifying this room. For example, http://server/kundan@39peers.net represents
		 * the main visiting room of user kundan@39peers.net and http://server/kundan@39peers.net/Project.Conference
		 * represents the room named "Project Conference" created by user kundan@39peers.net.
		 * When the url property it set, it also updates flashUrl property by extracting the server part
		 * from the url http://server:5080/email/name and using it to construct flashUrl as 
		 * rtmp://server:1935/call/email/name
		 */
		public function get url():String
		{
			return _url;
		}
		public function set url(value:String):void
		{
			_url = value;
			if (value != null) {
				if (value.substr(0, 7) == 'http://') {
					var index:int = value.indexOf('/', 7);
					if (index >= 0) {
						var server:String = value.substring(7, index);
						var i:int = server.lastIndexOf(':');
						if (i >= 0)
							server = server.substr(0, i) + ':' + 1935;
						_flashUrl = 'rtmp://' + server + '/call' + value.substr(index);
					}
				}
			}
		}
		
		/**
		 * The write-only server property when set, updates the url property using the supplied server name
		 * and previously set email address and name if any. If email is not set or is not a valid email
		 * address, then the url property is set to null.
		 */
		public function set server(value:String):void
		{
			var url:String = Util.isEmail(email) ? 'http://' + value + '/' + email : null;
			var name:String = this.name != null ? this.name.split(" ").join(".") : null;
			if (url != null && name != null && Util.isValidRoomName(name))
				url += '/' + name;
			this.url = url;
		}
		
		/**
		 * The read-only flashUrl property is the RTMP URL used for connecting to the media server. 
		 * For a room with "url" property as "http://server:5080/user@domain/room.name" the "flashUrl"
		 * property is usually "rtmp://server:1935/call/user@domain/room.name" which uses the same server,
		 * different (RTMP) port 1935, and RTMP application "call".
		 */
		public function get flashUrl():String
		{
			return _flashUrl;
		}
		
		/**
		 * The read-only scriptUrl property is derived from the url property and represents the URL of
		 * the directory containing various XML script associated with this room. For a room with url 
		 * "http://server:5080/email/name" the scriptUrl is typically 
		 * "http://server:5080/users/email/name". The scriptUrl is
		 * used to download the script for this room by the RoomController, which then executes the script
		 * if found. The script can contain initial list of media files to keep in the room on join,
		 * for example.
		 */
		public function get scriptUrl():String
		{
			var result:String = null;
			
			if (url != null && url.substr(0, 7) == "http://") {
				var index:int = _url.indexOf('/', 7);
				if (user.server != null && user.server.indexOf(':') < 0)
					result = "http://" + user.server + '/users' + _url.substr(index);
				else
					result = _url.substr(0, index) + '/users' + _url.substr(index);
			}
			return result;
		}
		
		public function get embed():String
		{
			return User.EMBED_TEXT.replace(/{url}/gi, 'http://' + user.server + '/embed').replace(/{flashVars}/gi, 'target=' + url.substr(('http://'+user.server).length+1));
		}
		
		[Bindable]
		/**
		 * The photo object associated with this room. This is typically a Image object.
		 */
		public function get photo():Object
		{
			return _photo;
		}
		public function set photo(value:Object):void
		{
			_photo = value;
		}
		
		/**
		 * The application should use setPhoto method instead of setting the photo property, so that
		 * the Image object gets copied correctly instead of reusing the same Image object. This is useful
		 * to avoid run-time errors when the Image object is added to as a child in a display container.
		 */
		public function setPhoto(value:Object):void
		{
			if (value is Image) {
				photo = Util.copyImage(value as Image);
			}
		}
		
		[Bindable]
		/**
		 * The card property represents this room's visiting card object.
		 */
		public function get card():VisitingCard
		{
			return _card;
		}
		public function set card(value:VisitingCard):void
		{
			_card = value;
			setOwner();
		}
		
		[Bindable]
		/**
		 * Whether the user is owner of this room or not?.
		 */
		public function get isOwner():Boolean
		{
			return _isOwner;
		}
		public function set isOwner(value:Boolean):void
		{
			_isOwner = value;
		}
		
		[Bindable]
		/**
		 * The user object representing the currently logged in user. When set, the room listens for 
		 * change in some properties (camActive, micActive) and updates its state accordingly such as 
		 * publishing local video in the room.
		 */
		public function get user():User
		{
			return _user;
		}
		public function set user(value:User):void
		{
			var old:User = _user;
			_user = value;
			if (old != value) {
				if (old != null)
					old.removeEventListener(PropertyChangeEvent.PROPERTY_CHANGE, userChangeHandler);
				if (value != null)
					value.addEventListener(PropertyChangeEvent.PROPERTY_CHANGE, userChangeHandler, false, 0, true);
				setOwner();
			}
		}
		
		[Bindable]
		/**
		 * Whether this room is locked to do shared screen or not?
		 */
		public function get lock():Boolean
		{
			return _lock;
		}
		public function set lock(value:Boolean):void
		{
			_lock = value;
		}
		
		[Bindable]
		/**
		 * Whether this is a public or private room?
		 */
		public function get isPublic():Boolean
		{
			return _isPublic;
		}
		public function set isPublic(value:Boolean):void
		{
			if (_isOwner) {
				var oldValue:Boolean = _isPublic;
				if (value != oldValue) {
					var accessType:String = value ? Constant.MAKE_ROOM_PUBLIC : Constant.MAKE_ROOM_PRIVATE;
					dispatchEvent(new DataEvent(Constant.CONTROL_ROOM, false, false, accessType));
				}
			} else {
				Prompt.show("You do not have permissions to change access type of this room", "Error");
			}
		}
		
		[Bindable]
		/**
		 * Whether this user is controller of this presentation room?
		 * Setting this implies isOwner.
		 */
		public function get isController():Boolean
		{
			return _isController;
		}
		public function set isController(value:Boolean):void
		{
			var oldValue:Boolean = _isController;
			_isController = value;
		}
		
		//--------------------------------------
		// PUBLIC METHODS
		//--------------------------------------
		
		/**
		 * Connect to the server for this room using the flashUrl property as the connect URL.
		 * It also installs the 'added' and 'removed' as callback methods to be invoked by the server
		 * when a member joins or leaves this room.
		 */
		public function connect():void
		{
			connectInternal();
		}
		
		/**
		 * Disconnect from the server. It sets the connected property to false, closes all streams
		 * and closes the connection.
		 */
		public function disconnect():void
		{
			disconnectInternal();
		}
		
		/**
		 * Load the supplied file or file list in this room. If the supplied data is a single file (FileReference)
		 * then it is appended to files property as a playlist containing single file, otherwise if the
		 * supplied argument is a list (FileReferenceList) then all files are added to files as a single
		 * playlist containing all those files. If the supplied argument is a XML representing a <show> tag,
		 * then that playlist is constructed using the supplied show tag and added to files.
		 * 
		 * @see PlayItem for details on XML format.
		 */
		public function load(data:*):void
		{
			if (data is FileReference)
				loadInternal([data as FileReference]);
			else if (data is FileReferenceList)
				loadInternal((data as FileReferenceList).fileList);
			else if ((data is XML) && (data as XML).localName() == 'show')
				loadInternalXML(data as XML);
			else if ((data is Bitmap))
				loadInternalBitmap(data as Bitmap);
			else
				throw new Error("load must supply FileReference, FileReferenceList or XML <show>");
		}
	
		/**
		 * Send an instant message (IM) or chat message on behalf of local user in this room.
		 */
		public function send(text:String):void
		{
			if (connected && _nc != null) {
				if (user != null && user.card != null)
					commandSend(Constant.SEND_BROADCAST, Constant.ROOM_METHOD_MESSAGE, text, user.name);
				else
					commandSend(Constant.SEND_BROADCAST, Constant.ROOM_METHOD_MESSAGE, text);
			}
			else {
				message("Cannot send message without connection", null);
			}
		}
		
		/**
		 * Invoked when a new message is received in this room.
		 */
		public function message(text:String, sender:String):void
		{
			var event:DynamicEvent = new DynamicEvent(Constant.RECEIVE_MESSAGE);
			event.text = text;
			event.sender = sender != null ? sender : 'null';
			event.time = new Date();
			dispatchEvent(event);
		}
		
		/**
		 * Update the isOwner property based on the card and user.card properties.
		 */
		public function setOwner():void
		{
			isOwner = (user != null && user.card != null && card != null && card.url != null && card.url.indexOf(user.card.url) == 0);
		}
		
		//--------------------------------------
		// PRIVATE METHODS
		//--------------------------------------
		
		/**
		 * Connection related methods.
		 */
		 
		/*
		 * Internal method to actually perform connect.
		 */
		private function connectInternal(arg:String=null):void
		{
			_nc = new NetConnection();
			_nc.client = new CallbackObject(this, callbackMethods);
			_nc.addEventListener(NetStatusEvent.NET_STATUS, netStatusHandler, false, 0, true);
			_nc.addEventListener(IOErrorEvent.IO_ERROR, errorHandler, false, 0, true);
			_nc.addEventListener(SecurityErrorEvent.SECURITY_ERROR, errorHandler, false, 0, true);
			
			if (arg == null)
				_nc.connect(flashUrl);
			else
				_nc.connect(flashUrl, arg);
		}
		
		/*
		 * Internal method to actually perform disconnect.
		 */
		private function disconnectInternal():void
		{
			connected = false;
			// close any active participants.
			for (var i:int=members.length-1; i>=0; --i) {
				var m:Member = members.getItemAt(i) as Member;
				members.removeItemAt(i);
				m.close();
			}
			if (_ns != null) {
				_ns.close();
				_ns = null;
			}
			if (_nc != null) {
				_nc.close();
				if (_nc.client != null) 
					_nc.client.close();
				_nc = null;
			}
		}
		
		/*
		 * When connection's netStatus event is dispatched, then we update our "connected" property and
		 * if needed publish the local video.
		 */
		private function netStatusHandler(event:NetStatusEvent):void
		{
			trace('Room ' + event.info.code);
			switch (event.info.code) {
			case "NetConnection.Connect.Success":
				connected = true;
				dispatchEvent(new DataEvent(Constant.CONTROL_ROOM, false, false, Constant.ENTER_ROOM));
				publishLocal();
				break;
			case "NetConnection.Connect.Closed":
				if (connected) {
					connected = false;
					disconnect();
					//_nc.close();
					var closeHandler:Function = function(id:uint):void {
						if (id == Alert.YES) 
							connect();
					};
					Prompt.show("Disconnected from this room. Would you like to try another attempt to connect to this room?", "Disconnected from the room", Alert.YES | Alert.NO, null, closeHandler);
				}
				break;
			case "NetConnection.Connect.Failed":
			case "NetConnection.Connect.Rejected":
				connected = false;
				Prompt.show("Error connecting to the server: " + event.info.code + " " + event.info.description, "Cannot connect to server");
				break;
			}
		}
		
		/*
		 * When the connection error is dispatched, we close the connection and display the error.
		 */
		private function errorHandler(event:ErrorEvent):void
		{
			Prompt.show("Error connecting to the server: " + event.text, "Cannot connect to server");
			_nc.close();
			if (_nc.client != null) _nc.client.close();
			_nc = null;
		}

		/**
		 * Stream related methods.
		 */
		 
		/*
		 * Convinient method to get the Member object from the id. If not found, it returns null.
		 */
		private function getMember(id:String):Member {
			for each (var m:Member in members) {
				if (m.id == id) 
					return m;
			}
			return null;
		}

		/*
		 * Server callback method invoked to indicate that another user with the given id joined
		 * the room. We create a Member object and add to the members list.
		 */
		public function added(id:String):void
		{
			trace('Room.added ' + id);
			var m:Member = getMember(id);
			if (m == null) {
				m = new Member(id);
				members.addItem(m);
			}
		}
		
		/*
		 * Server callback method invoked when a person leaves the room. We remove that person's Member
		 * object from this room.
		 */
		public function removed(id:String):void
		{
			trace('Room.removed ' + id);
			var m:Member = getMember(id);
			if (m != null) {
				if (m.stream != null)
					unpublished(m.id, m.stream.name);
				var index:int = members.getItemIndex(m);
				if (index >= 0)
					members.removeItemAt(index);
				m.close();
			}
		}
		
		/*
		 * Server callback method invoked to indicate that another user started publishing a stream
		 * with the given name. We create a listening stream for that Member. If the play-list identified
		 * by the xml argument is published, we add a new play list to this room.
		 */
		public function published(id:String, name:String, xml:XML=null):void
		{
			trace('Room.published ' + id + ',' + name + ',' + xml);
			var m:Member = getMember(id);
			if (m != null) {
				if (xml == null) {
					var ns:NetStream = new NetStream(_nc);
					ns.client = new Object();
					ns.addEventListener(NetStatusEvent.NET_STATUS, netStatusHandler, false, 0, true);
					//Alert.show("playing " + name);
					ns.play(name);
					m.stream = new Stream(name, ns);
					streams.addItem(m.stream);
				}
				else {
					try {
						if (xml.@id == undefined)
							xml.@id = name;
						xml.@senderName = m.name;
						xml.@senderId = m.id;
						load(xml);
					}
					catch (e:Error) {
						trace("error parsing XML " + xml);
					}
				}
			}
		}
		
		/*
		 * Server callback method invoked when a person stops publishing in a room. We cleanup the stream
		 * for that Member. If a play-list specified by the xml argument is un-published, we remove the
		 * play list from this room.
		 */
		public function unpublished(id:String, name:String, xml:XML=null):void
		{
			trace('Room.unpublished ' + id + ',' + name);
			var m:Member = getMember(id);
			if (m != null) {
				if (xml == null) {
					var s:Stream = m.stream;
					if (s != null) {
						var index:int = streams.getItemIndex(s);
						if (index >= 0)
							streams.removeItemAt(index);
						m.stream = null;
						var ns:NetStream = s.stream;
						ns.removeEventListener(NetStatusEvent.NET_STATUS, netStatusHandler);
						ns.close();
					}
				}
				else {
					for (var i:int=files.length-1; i>=0; --i) {
						var playList:PlayList = files.getItemAt(i) as PlayList;
						if (playList != null && playList.id == name)
							files.removeItemAt(i);
					}
				}
			}
		}
		
		/*
		 * When user's cam/mic active property changes, start/stop local stream.
		 */
		private function userChangeHandler(event:PropertyChangeEvent):void
		{
			if (event.property == "micActive" || event.property == "camActive") {
				publishLocal();
			}
		}
		
		/*
		 * Publish a local stream if connected, user set, and user's mic/cam active. This function is invoked
		 * from multiple entry points: when connection is established, when user's micActive or camActive
		 * property are changes.
		 */
		private function publishLocal():void
		{
			if (user != null && (user.micActive || user.camActive) && _nc != null && _nc.connected) {
				if (_ns == null) {
					_ns = new NetStream(_nc);
					_ns.client = this;
					_ns.addEventListener(NetStatusEvent.NET_STATUS, netStatusHandler, false, 0, true);
					_ns.publish(_stream);
				}
				if (_ns != null)
					_ns.attachCamera(user.camera);
				if (_ns != null)
					_ns.attachAudio(user.mic);
			}
			else {
				if (_ns != null) {
					_ns.close();
					_ns.removeEventListener(NetStatusEvent.NET_STATUS, netStatusHandler);
					_ns.attachCamera(null);
					_ns.attachAudio(null);
					_ns = null;
				}
			}
		}
		
		/**
		 * Instant message, presence and network sharing related methods.
		 */
		
		public function broadcast(...args):void
		{
			commandReceived.apply(this, args);
		}
		
		public function unicast(...args):void
		{
			commandReceived.apply(this, args);
		}
		
		/*
		 * Call to the server to send a command to other participants using the supplied type.
		 */
		public function commandSend(type:String, ...args):void
		{
			if (connected && _nc != null) {
				args.unshift(null);
				args.unshift(type);
				_nc.call.apply(_nc, args);
			}
		}
		
		/*
		 * Callback method invoked by server (actually other participant) to broadcast or unicast a
		 * command. The first argument is the sender's clientId as string, and second onwards are
		 * the arguments supplied in the NetConnection's call method.
		 */
		public function commandReceived(...args):void
		{
			if (args.length > 0) {
				switch (args[1]) {
				case Constant.ROOM_METHOD_MESSAGE: // senderId, message, text, [senderName]
					if (args.length >= 3)
						message(args[2], args.length > 3 ? args[3] : "Guest " + args[0]);
					break;
					
				case Constant.ROOM_METHOD_PUBLISHED:
					if (args.length >= 4)
						published(args[0], args[2], new XML(args[3]));
					break;
					
				case Constant.ROOM_METHOD_UNPUBLISHED:
					if (args.length >= 3)
						unpublished(args[0], args[2], new XML(args[3]));
					break;
				}
			}
		}
		
		/**
		 * Media sharing related methods.
		 */
		
		/*
		 * Internal method to actually load a list of files.
		 */
		private function loadInternal(fileList:Array):void 
		{
			var xml:XML = <show/>;
			var file:FileReference;
			var files:Array = new Array();
						
			for each (file in fileList) {
				xml.appendChild(PlayItem.describeFile(file));
				files.push(file);
			} 
			
			this.files.addItem(new PlayList(xml, files, this));
		}
		
		/*
		 * Load the supplied image in this room as a separate play list.
		 */
		private function loadInternalBitmap(bm:Bitmap):void
		{
			// assume that the file name was snapshot.jpg
			var xml:XML = <show><file src="file://snapshot.jpg" smoothing="true" description="Captured Photo"/></show>;
			var jpgEncoder:JPEGEncoder = new JPEGEncoder();
			var data:ByteArray = jpgEncoder.encode(bm.bitmapData);
			this.files.addItem(new PlayList(xml, [data], this));
		}
		
		/*
		 * Load the supplied URL in this room as a separate play list.
		 */
		private function loadInternalXML(xml:XML):void
		{
			var id:String = xml.@id != undefined ? String(xml.@id) : null;
			var found:PlayList = null;
			
			for (var i:int=0; i<this.files.length; ++i) {
				var playList:PlayList = this.files.getItemAt(i) as PlayList;
				if (playList != null && id != null && playList.id == id) {
					found = playList;
					break;
				}
			}
			if (found == null)
				this.files.addItem(new PlayList(xml, [], this));
			else
				found.data = xml;
		}
		
		private function membersChangeHandler(event:CollectionEvent):void
		{
			dispatchEvent(new CollectionEvent(Constant.MEMBERS_CHANGE, false, false, event.kind, event.location, event.oldLocation, event.items));
		}
		
		private function streamsChangeHandler(event:CollectionEvent):void
		{
			dispatchEvent(new CollectionEvent(Constant.STREAMS_CHANGE, false, false, event.kind, event.location, event.oldLocation, event.items));
		}
		
		private function filesChangeHandler(event:CollectionEvent):void
		{
			dispatchEvent(new CollectionEvent(Constant.FILES_CHANGE, false, false, event.kind, event.location, event.oldLocation, event.items));
		}
		
	}
}

import flash.net.NetStream;
import flash.display.DisplayObject;

/**
 * Each item in the Room's streams list is a Stream object. The Stream object contains the stream's name,
 * the actual NetStream as stream property and any display object (box) to display this stream.
 */
class Stream
{
	public var name:String;
	public var stream:NetStream;
	public var box:DisplayObject;
	
	public function Stream(name:String, stream:NetStream)
	{
		this.name = name;
		this.stream = stream;
	}
	
	public function close():void 
	{
		if (stream != null) {
			stream.close();
			stream = null;
		}
	}
}

[Bindable]
/**
 * Each member in the room is represented using the Member class. The local user is not represented
 * as Member.
 */
class Member
{
	public var id:String;
	public var name:String;
	public var photo:Object;
	public var stream:Stream;
	
	public function Member(id:String)
	{
		this.id = id;
		this.name = "Guest " + id;
	}	
	
	public function close():void
	{
		if (stream != null) {
			stream.close();
			stream = null;
		}
	}
}
