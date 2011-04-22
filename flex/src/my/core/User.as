/* Copyright (c) 2009-2011, Kundan Singh. See LICENSING for details. */
package my.core
{
	import flash.events.DataEvent;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.utils.Dictionary;
	
	import mx.core.Application;
	import mx.rpc.AsyncToken;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	import mx.rpc.http.HTTPService;
	
	import my.core.room.Room;
	import my.core.card.VisitingCard;
	import my.controls.Prompt;
	import mx.events.DynamicEvent;
	
	/**
	 * Dispatched when a control button is clicked. Possible values of data property:
	 * 'upload', 'phone', 'layout', 'home', etc. This is dispatched by ControlBar on behalf.
	 * @eventType my.core.Constant.CONTROL
	 */
	[Event(name="control", type="flash.events.DataEvent")]
	
	/**
	 * Dispatched when a user wants to download a card.
	 */
	[Event(name="download", type="mx.events.DynamicEvent")] 
	
	/**
	 * Dispatched when a menu item is selected. Possible values of data property:
	 * 'search', 'login', etc. This is dispatched by ControlBar on behalf.
	 * @eventType my.core.Constant.MENU
	 */
	[Event(name="menu", type="flash.events.DataEvent")]
	
	/**
	 * When a new room is created for this user view.
	 * The data property contains the room url which can be used in User.getRoom().
	 * @eventType my.core.Constant.CREATE_ROOM
 	 */
	[Event(name="createRoom", type="flash.events.DataEvent")]
	
	/**
	 * When an existing room is destroyed for this user view.
	 * The data property contains the room url which can be used in User.getRoom().
	 * The room object is actually destroyed after processing this event, hence room is 
	 * availble when processing this event.
	 * @eventType my.core.Constant.DESTROY_ROOM
 	 */
	[Event(name="destroyRoom", type="flash.events.DataEvent")]
	
	/**
	 * Extends UserBase to support rooms and target..
	 */
	public class User extends UserBase
	{
		//--------------------------------------
		// CLASS CONSTANTS
		//--------------------------------------
		
		public static const EMBED_TEXT:String = '<object classid="clsid:D27CDB6E-AE6D-11cf-96B8-444553540000" id="Main" width="470" height="285" codebase="http://fpdownload.macromedia.com/get/flashplayer/current/swflash.cab"><param name="movie" value="{url}" /><param name="quality" value="high" /><param name="bgcolor" value="#101010" /><param name="allowScriptAccess" value="sameDomain" /><param name="allowFullScreen" value="true" /><param name="flashVars" value="{flashVars}" /><embed src="{url}" quality="high" bgcolor="#101010" width="470" height="285" name="Main" align="middle" play="true" loop="false" quality="high" allowScriptAccess="sameDomain" allowFullScreen="true" flashVars="{flashVars}" type="application/x-shockwave-flash" pluginspage="http://www.adobe.com/go/getflashplayer"></embed></object>';
		
		public const DEFAULT_WEB_PORT:uint = 5080;
		public const DEFAULT_FLASH_PORT:uint = 1935;
		public const HELP_INTRO_URL:String = "/flvs/help1.flv";
		public const HELP_SIGNUP_URL:String = "/flvs/help2.flv";
		
		/**
		 * The connector stores and exposes certain properties to the main application. These
		 * properties are used in the View to display and be editable. These are also stored in
		 * the local shared object if user chose to remember his configuration. 
		 */
		public static const allowedParameters:Array = ["target"];
		
		//--------------------------------------
		// PRIVATE VARIABLES
		//--------------------------------------
		
		private var _email:String; // email of the user
		private var _name:String;  // full name of the user
		private var _photo:Object;  // photo object (usually a Image)
		private var _isGuest:Boolean = true; // whether signed in or not?
		private var _card:VisitingCard; // login card if logged in
		
		private var _status:Object;// any status text to display
		private var _talkTime:Number = 0; // talk time available for phone calls
		
		private var _server:String; // http server address (and optional port) as "host" or "host:port"
		private var _serverFlash:String; // rtmp server address (and optional port) as "host" or "host:port"
		
		private var _rooms:Object = new Object(); // list of rooms indexed by url
		private var _selected:Room = null; // the currently selected room
		private var _selectedIndex:int = -1; // currently selected page view
				
		// pending http requests
		private var _http:Dictionary = new Dictionary(); 
		
		//--------------------------------------
		// CONSTRUCTOR
		//--------------------------------------
		
		/**
		 * The constructor.
		 */
		public function User()
		{
			super();
			selectedIndex = Constant.INDEX_INTRO;
		}

		//--------------------------------------
		// GETTERS/SETTERS
		//--------------------------------------
		
		[Bindable]
		/**
		 * Name of the user if any.
		 */
		public function get name():String
		{
			return _name;
		}
		public function set name(value:String):void
		{
			_name = value;
		}
		
		[Bindable]
		/**
		 * Email of the user if any.
		 */
		public function get email():String
		{
			return _email;
		}
		public function set email(value:String):void
		{
			_email = value;
		}
		
		/**
		 * The URL string representing the page of this user, if the email is valid, otherwise the url
		 * is invalid.
		 */
		public function get url():String
		{
			return 'http://' + server + '/' + (email ? email.split(' ').join('+') : 'null'); 
		}
		
		/**
		 * The embed code to embed this user's page in some other web site.
		 */
		public function get embed():String
		{
			return EMBED_TEXT.replace(/{url}/gi, 'http://' + server + '/embed').replace(/{flashVars}/gi, '');
		}
		
		[Bindable]
		/**
		 * The available talk time.
		 */
		public function get talkTime():Number
		{
			return _talkTime;
		}
		public function set talkTime(value:Number):void
		{
			_talkTime = value;
		}
		
		[Bindable]
		/**
		 * The status of the user.
		 */
		public function get status():Object
		{
			return _status;
		}
		public function set status(value:Object):void
		{
			_status = value;
		}
		
		[Bindable]
		/**
		 * The photo of the user to display.
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
		 * The target property controls the target page of the application. When set, it tries to open a 
		 * new room for that target of the form "email" or "email/name". 
		 */
		public function set target(value:String):void
		{
			var url:String = (value ? 'http://' + server + '/' + value : null);
			var room:Room = getRoom(url);
			if (room == null) {
				room = new Room();
				room.url = url;
				_rooms[url] = room;
				loadTargetCard(value);
				dispatchEvent(new DataEvent(Constant.CREATE_ROOM, false, false, room.url));
			}
			this.selected = room;
		}
		
		[Bindable]
		/**
		 * The server property represents the web server "host:port" from which this application was
		 * downloaded.
		 */
		public function get server():String
		{
			if (_server == null) {
				var url:String = Application.application.url;
				var index:int = url.indexOf('://');
				_server = url.substring(index >= 0 ? index + 3 : index, url.indexOf('/', index >= 0 ? index + 3 : 0));
				if (_server == 'localhost')
					_server += ':' + DEFAULT_WEB_PORT; // add the default port if needed for local plugin test 
			}
			return _server;
		}
		public function set server(value:String):void
		{
			_server = value;
		}
		
		[Bindable]
		/**
		 * The serverFlash property represents the "host:port" for RTMP server to connect to. It is assumed
		 * that the RTMP server and web server are running on the same host, except that the RTMP server 
		 * is on port 1935. Hence serverFlash property can be derived from server property, if serverFlash
		 * is not explicitly set.
		 */
		public function get serverFlash():String
		{
			if (_serverFlash == null) {
				var value:String = this.server;
				var index:int = value.lastIndexOf(':');
				if (index >= 0)
					value = value.substr(0, index) + ":" + DEFAULT_FLASH_PORT;
				else
					value = value + ':' + DEFAULT_FLASH_PORT;
				_serverFlash = value;
			}
			return _serverFlash; 
		}
		public function set serverFlash(value:String):void
		{
			_serverFlash = value;
		}
		
		[Bindable]
		/**
		 * Whether this is a logged in user or a guest?
		 */
		public function get isGuest():Boolean
		{
			return _isGuest;
		}
		public function set isGuest(value:Boolean):void
		{
			_isGuest = value;
		}
		
		[Bindable]
		/**
		 * If this is a logged in user, then the login card of the user, else null.
		 */
		public function get card():VisitingCard
		{
			return _card;
		}
		public function set card(value:VisitingCard):void
		{
			var oldValue:VisitingCard = _card;
			_card = value;
			
			if (oldValue != value) { // set the owner property of all the rooms.
				for each (var room:Room in _rooms) {
					room.setOwner();
				}
			}
		}
		
		/**
		 * Method to get the Room object associated with the give room url, if available, else null.
		 */
		public function getRoom(url:String):Room
		{
			return url in _rooms ? _rooms[url] as Room : null;
		}
		
		[Bindable]
		/**
		 * The currently selected or viewing room object.
		 */
		public function get selected():Room
		{
			return _selected;
		}
		public function set selected(value:Room):void
		{
			_selected = value;
		}
		
		[Bindable]
		/**
		 * The currently selected index in the view pages. The view uses this property to update it's view.
		 * The controller updates selected index in response to user events or other events.
		 */
		public function get selectedIndex():Number
		{
			return _selectedIndex;
		}
		public function set selectedIndex(value:Number):void
		{
			_selectedIndex = value;
		}
		
		//--------------------------------------
		// PUBLIC METHODS
		//--------------------------------------
		
		/**
		 * This method initiates the login process using the supplied login card.
		 */
		public function login(card:VisitingCard):void
		{
			if (card.isLoginCard && card.validate() == null) {
				this.card = card;
				this.isGuest = false;
				var room:Room = addRoom(card);
				if (room != null) {
					this.name = room.owner;
					this.email = room.email;
					join(room);
				}
			}
			else {
				trace("cannot login as card is invalid");
			}
		}
		
		/**
		 * This method logs out the user.
		 */
		public function logout():void
		{
			if (this.card != null) {
				removeRoom(getRoom(this.card.url));
			}
			this.card = null;
			this.name = this.email = null;
			this.isGuest = true;
		}
		
		/**
		 * This method makes a call to the given address.
		 */
		public function callTo(addr:String):void
		{
			
		}
		
		/**
		 * This method causes the user to join the given room, by connecting to the room's server.
		 */
		public function join(room:Room):void
		{
			if (room != null && !room.connected)
				room.connect();
		}
		
		/**
		 * a new visiting card was uploaded. If a card exists for the url, it replaces it, else
		 * it adds a new card. If the card is added, a new room is created for that card.
		 */
		public function addRoom(newCard:VisitingCard):Room
		{
			var url:String = newCard.url;
			var room:Room;
			if (url in _rooms) {
				room = _rooms[url]
				if (newCard.isLoginCard && room.card != null && !room.card.isLoginCard)
					room.setOwner();
				else
					room.card = newCard;
			}
			else {
				room = newCard.createRoom(true);
				_rooms[url] = room;
				dispatchEvent(new DataEvent(Constant.CREATE_ROOM, false, false, room.url));
			}
			// connect the room if we are the owner
			if (!room.connected && (this.email != null && room.email == this.email)) {
				room.connect();
			}
			
			this.selected = room;
			return room;
		}
		
		/**
		 * Remove a room identified by the card or room object.
		 */
		public function removeRoom(room:Room):void
		{
			if (room != null) {
				room.close();
				dispatchEvent(new DataEvent(Constant.DESTROY_ROOM, false, false, room.url)); // dispatch event first
				delete _rooms[room.url];
			}
		}
		
		/**
		 * Get the previous room in the list.
		 */
		public function getPreviousRoom(room:Room):Room
		{
			var prev:Room = null;
			for (var s:String in _rooms) {
				if (_rooms[s] == room)
					break;
				else
					prev = _rooms[s] as Room;
			}
			return prev;
		}
		
		/**
		 * Convert a RTMP stream URL to its HTTP equivalent, assuming that the stream is on our web server.
		 * If the supplied URL is of the form "rtmp://server:port/app/something" and id is "stream" then the
		 * HTTP URL is "http://our-server:our-port/flvs/something/stream.flv"
		 */
		public function getHttpURL(url:String, id:String):String
		{
			if (url == null || url == '' || url.substr(0, 4) == 'http')
				return url;
			var index:int = url.indexOf(':');
			var prefix:String = index >= 0 ? url.substr(0, index) : '';
			if (prefix.toLowerCase() != "rtmp")
				throw new Error("Must be either http or rtmp URL: " + url);
			index = index >= 0 ? url.indexOf('/', index+3) : -1; // skip server:port
			index = index >= 0 ? url.indexOf('/', index+1) : -1; // skip app
			if (index < 0) return url; // cannot convert
			var http:String = 'http://' + server + '/flvs/' + url.substr(index+1) + '/' + id + '.flv';
			return http;
		}
		
		/**
		 * Get the proxied URL for the given URL. The proxy is at the server we are connected to.
		 * If the url already points to this server, then don't use a proxy.
		 */
		public function getProxiedURL(url:String, forceProxy:Boolean=false):String
		{
			if (url.indexOf("http://" + this.server) != 0) 
				return "http://" + this.server + "/www/cgi/play.py?" + (forceProxy ? 'mode=proxy&' : '') + "url=" + escape(url);
			else
				return url;
		}
		
		/**
		 * Method to invoke an HTTP RPC call.
		 */
		public function httpSend(command:String, params:Object, context:Object=null, success:Function=null, fault:Function=null):void
		{
			httpRequest("http://" + server + "/" + command, "POST", "e4x", params, context, success, fault);
		}
		
		/**
		 * Method to request a HTTP service.
		 */
		public function httpRequest(url:String, method:String="GET", resultFormat:String="e4x", params:Object=null, context:Object=null, success:Function=null, fault:Function=null):void
		{
			var http:HTTPService = new HTTPService();
			http.addEventListener(ResultEvent.RESULT, httpCompleteHandler, false, 0, true);
			http.addEventListener(FaultEvent.FAULT, httpCompleteHandler, false, 0, true);
			http.url = url;
			http.method = method;
			http.resultFormat = resultFormat;
			
			var token:AsyncToken = http.send(params);
			
			_http[token] = {context: context, success: success, fault: fault, url: url};
		}
		
		/**
		 * Dispatch an event to download the card, so that the controller can act on it.
		 */
		public function downloadCard(card:*, name:String=null):void
		{
			var event:DynamicEvent = new DynamicEvent(Constant.DOWNLOAD);
			event.card = card;
			if (name != null)
				event.name = name;
			dispatchEvent(event);
		}
		
		//--------------------------------------
		// PRIVATE METHODS
		//--------------------------------------
		
		private function httpCompleteHandler(event:Event):void 
		{
			var token:AsyncToken = (event is ResultEvent ? ResultEvent(event).token : FaultEvent(event).token);
			var value:Object = (token in _http ? _http[token] : null);
			var context:Object = (value != null && value.context != undefined ? value.context : null);
			var success:Function =  (value != null && value.success != undefined ? value.success : null);
			var fault:Function =  (value != null && value.fault != undefined ? value.fault : null);
			
			delete _http[token]
			if (event is ResultEvent) {
				var result:XML = XML(ResultEvent(event).result);
				if (result == null || result.error != undefined) {
					Prompt.show("Error in " + context.url + ": " + (result != null ? String(result.error) : "null"), "Error requesting web service");
					if (fault != null)
						fault(context, result);
				}
				else {
					trace("result is " + result.toXMLString());
					if (success != null)
						success(context, result);
				}
			}
			else {
				Prompt.show("Error in " + context.url + "\n" + (event is FaultEvent ? FaultEvent(event).message : ''), "Error requesting web service");
			}
		}
		
		private var targetLoader:URLLoader;
		
		// load the target's visiting card if available.
		private function loadTargetCard(target:String):void
		{
			var url:String = "http://" + server + "/www/users/" + target + "/visitingCard.png";
			targetLoader = new URLLoader();
			targetLoader.dataFormat = URLLoaderDataFormat.BINARY;
			targetLoader.addEventListener(Event.COMPLETE, targetHandler, false, 0, true);
			targetLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, targetHandler, false, 0, true); 
			targetLoader.addEventListener(IOErrorEvent.IO_ERROR, targetHandler, false, 0, true); 
			
			try {
				targetLoader.load(new URLRequest(url));
			} catch (e:Error) {
				trace("Unable to load " + url + ": " + e.message + "\n" + e.getStackTrace());
			}
		}
		
		private function targetHandler(event:Event):void 
		{
			if (event.type == Event.COMPLETE) {
				trace("target loaded " + targetLoader.data.length);
				targetLoader.data.position = 0;
				var card:VisitingCard = VisitingCard.load(targetLoader.data);
				var error:String = card.validate();
				if (error != null)
					Prompt.show(error, "Cannot validate this room card");
				else {
					var room:Room = addRoom(card);
				}
			}
			targetLoader = null;
		}
	}
}
