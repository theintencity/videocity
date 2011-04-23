/* Copyright (c) 2009, Mamta Singh. See LICENSING for details. */
package model
{
	import flash.net.NetConnection;
	import flash.net.NetStream;
	import flash.net.ObjectEncoding;
	import flash.net.SharedObject;
	import flash.events.AsyncErrorEvent;
	import flash.events.EventDispatcher;
	import flash.events.ErrorEvent;
	import flash.events.IOErrorEvent;
	import flash.events.NetStatusEvent;
	import flash.events.SecurityErrorEvent;
	import mx.collections.ArrayCollection;
	
	/**
	 * The Connector object provides the abstraction and API to connect to the backend SIP-RTMP
	 * gateway. To the rest of the Flash application, this acts as the data model.
	 * 
	 * The object abstracts a single-user, single-line, SIP user agent. In particular, it has one
	 * active SIP registration, and can be in atmost one active SIP call. It also holds the
	 * audio video streams to and from the remote party.
	 */
	public class VoIPConnector extends EventDispatcher
	{
		//--------------------------------------
		// CLASS CONSTANTS
		//--------------------------------------
		
		/**
		 * Various states in the connector. The 'idle' state means it is not yet connected to
		 * the service. The connecting state indicates a connection is in progress. The
		 * connected state indicates that it is connected to the server. 
		 */
		public static const IDLE:String      = "idle";
		public static const CONNECTING:String = "connecting";
		public static const CONNECTED:String = "connected";
		
		//--------------------------------------
		// PRIVATE PROPERTIES
		//--------------------------------------
		
		/**
		 * Internal property to store the connector's state.
		 */
		private var _currentState:String = IDLE;
		
		/**
		 * The unique NetConnection that is used to connect to the service.
		 */
		private var nc:NetConnection;
		
		/**
		 * There can be at most one publish stream and any-number of played streams.
		 */
		private var _publish:NetStream, _play:ArrayCollection = new ArrayCollection();
		
		//--------------------------------------
		// CONSTRUCTOR
		//--------------------------------------
		
		/**
		 * Constructing a new connector object
		 */
		public function VoIPConnector()
		{
		}
		
		//--------------------------------------
		// GETTERS/SETTERS
		//--------------------------------------
		
		[Bindable]
		/**
		 * The currentState property represents connector's state as mentioned before.
		 */
		public function get currentState():String
		{
			return _currentState;
		}
		public function set currentState(value:String):void
		{
			_currentState = value;
		}
		
		/**
		 * The read-only playStream property gives access to the currently playing
		 * NetStream array.
		 */
		public function get playStream():ArrayCollection
		{
			return _play;
		}
		
		/**
		 * The read-only publishStream property gives access to the currently published
		 * NetStream which publishes audio video of the local party.
		 */
		public function get publishStream():NetStream
		{
			return _publish;
		}
		
		//--------------------------------------
		// PUBLIC METHODS
		//--------------------------------------
		
		/**
		 * The method initiates a connection to the service.
		 */
		public function connect(url:String=null):void
		{
			if (currentState == IDLE) {
				currentState = CONNECTING;
				
				if (nc != null) {
					nc.close();
					nc = null; 
					_publish = null;
					_play.removeAll();
				}
				
		    	nc = new NetConnection();
		    	nc.objectEncoding = ObjectEncoding.AMF0; // This is MUST!
		    	nc.client = this;
		    	nc.addEventListener(NetStatusEvent.NET_STATUS, netStatusHandler, false, 0, true);
		    	nc.addEventListener(IOErrorEvent.IO_ERROR, errorHandler, false, 0, true);
		    	nc.addEventListener(SecurityErrorEvent.SECURITY_ERROR, errorHandler, false, 0, true);
		    	nc.addEventListener(AsyncErrorEvent.ASYNC_ERROR, errorHandler, false, 0, true);
		    	
		    	trace('connect() ' + url);
		    	nc.connect(url);
			}
		}

		/**
		 * The method causes the connector to disconnect with the service.
		 */
		public function disconnect():void
		{
			currentState = IDLE;
        	if (nc != null) {
        		nc.close();
				nc = null; 
				_publish = null;
				_play.removeAll();
        	}
		}
		
		//--------------------------------------
		// PRIVATE METHODS
		//--------------------------------------
		
		/**
		 * When the connection status is received take appropriate actions.
		 * For example, when the connection is successful, create a publish stream.
		 */
		private function netStatusHandler(event:NetStatusEvent):void 
		{
			trace('netStatusHandler() ' + event.type + ' ' + event.info.code);
			switch (event.info.code) {
			case 'NetConnection.Connect.Success':
				_publish = new NetStream(nc);
				_publish.addEventListener(NetStatusEvent.NET_STATUS, netStatusHandler, false, 0, true);
				if (currentState == CONNECTING)
					currentState = CONNECTED;
				break;
			case 'NetConnection.Connect.Failed':
			case 'NetConnection.Connect.Rejected':
			case 'NetConnection.Connect.Closed':
				if (nc != null)
					nc.close();
				nc = null; 
				_publish = null;
				_play.removeAll();
		    	currentState = IDLE;
				if ('description' in event.info)
					trace("reason: " + event.info.description);
				break;
			}
		}
		
		/**
		 * When there is an error in the connection, close the connection and
		 * any associated stream.
		 */
		private function errorHandler(event:ErrorEvent):void 
		{
			trace('errorHandler() ' + event.type + ' ' + event.text);
			if (nc != null)
				nc.close();
			nc = null; 
			_publish = null;
			_play.removeAll();
			currentState = IDLE;
		}
	}
}
