/* Copyright (c) 2009, Kundan Singh. See LICENSING for details. */
package my.video
{
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.NetStatusEvent;
	import flash.events.SecurityErrorEvent;
	import flash.media.Video;
	import flash.net.NetConnection;
	import flash.net.NetStream;
	
	import my.core.User;

	/**
	 * Dispatched when the playback starts.
	 */
	[Event(name="open", type="flash.events.Event")]
	
	/**
	 * Dispatched when the playback closes.
	 */
	[Event(name="close", type="flash.events.ErrorEvent")]
	
	/**
	 * Dispatched when the video has finished playing.
	 */
	[Event(name="stop", type="flash.events.Event")]
	
	/**
	 * The Play object represents the data model for playback of an RTMP stream. This complements the Record
	 * object in that, the Record object records a stream and Play object plays its.
	 * Each play object has a url of the form "rtmp://server:port/something?id=streamname". Note that
	 * unlike the Record object, the id property is merged into the url.
	 */
	public class Play extends EventDispatcher
	{
		//--------------------------------------
		// PRIVATE VARIABLES
		//--------------------------------------
		
		private var nc:NetConnection;
		private var ns:NetStream;
		private var _url:String;
		private var _id:String;
		private var _user:User;
		private var _video:Video;
		private var _playing:Boolean = true;
		
		/**
		 * Construct a new Play object using the supplied attributes.
		 * @param url the RTMP URL to connect to. 
		 * @param id the stream name to play.
		 * @param user the user object that is exposed as the user property from this object.
		 */
		public function Play(url:String, id:String, user:User)
		{
			_url = url;
			if (_url != null && _url.indexOf("rtmp:") == 0)
				_id = id;
			_user = user;
		}
		
		//--------------------------------------
		// GETTERS/SETTERS
		//--------------------------------------
		
		/**
		 * The RTMP URL of the form "rtmp://server:port/something?id=streamname"
		 */
		public function get url():String
		{
			return _url + '?id=' + _id;
		}
		
		/**
		 * The user object supplied in the constructor.
		 */
		public function get user():User
		{
			return _user;
		}
		
		/**
		 * The video property represents the Video display object that is used on this data model.
		 * When set, it gets attaches to the underlying network stream of this object.
		 */
		public function get video():Video
		{
			return _video;
		}
		public function set video(value:Video):void
		{
			var oldValue:Video = _video;
			_video = value;
			if (oldValue != value) {
				if (ns != null) {
					if (oldValue != null)
						oldValue.attachNetStream(null);
					if (value != null)
						value.attachNetStream(ns);
				}
			}
		}
		
		[Bindable]
		/**
		 * The playing property controls whether the video is being streamed from the network stream or not?
		 */
		public function get playing():Boolean
		{
			return _playing;
		}
		public function set playing(value:Boolean):void
		{
			_playing = value;
			if (ns != null) {
				if (value)
					ns.pause();
				else 
					ns.resume();
			}
		}
		
		//--------------------------------------
		// PUBLIC METHODS
		//--------------------------------------
		
		/**
		 * This methods initiates a connection to the server using RTMP.
		 */
		public function open():void
		{
			if (_url.indexOf("rtmp:") == 0 && nc == null) {
				nc = new NetConnection();
				nc.addEventListener(NetStatusEvent.NET_STATUS, netStatusHandler, false, 0, true);
				nc.addEventListener(IOErrorEvent.IO_ERROR, recordErrorHandler, false, 0, true);
				nc.addEventListener(SecurityErrorEvent.SECURITY_ERROR, recordErrorHandler, false, 0, true);
				nc.connect(_url);
			}
		}
		
		/**
		 * This method terminates the connection with the server and closes any network stream.
		 */
		public function close():void
		{
			if (nc != null) {
				nc.close();
				nc = null;
			}
			if (ns != null) {
				ns.close();
				ns = null;
			}
		}
		
		//--------------------------------------
		// PRIVATE METHODS
		//--------------------------------------
		
		// process event from the NetConnection object
		private function netStatusHandler(event:NetStatusEvent):void
		{
			trace("netStatusHandler " + event.info.code);
			switch (event.info.code) {
				case "NetConnection.Connect.Success":
					ns = new NetStream(nc);
					ns.addEventListener(NetStatusEvent.NET_STATUS, netStatusHandler, false, 0, true);
					ns.client = new Object();
					ns.play(_id);
					if (video != null)
						video.attachNetStream(ns);
					break;
				case "NetConnection.Connect.Closed":
				case "NetConnection.Connect.Failed":
				case "NetConnection.Connect.Rejected":
					close();
					dispatchEvent(new ErrorEvent("close", false, false, event.info.code));
					break;
				case "NetStream.Play.Stop":
					dispatchEvent(new Event("stop"));
					break;
			}
		}
		
		// on error dispatch the close event and close this play object.
		private function recordErrorHandler(event:ErrorEvent):void
		{
			close();
			dispatchEvent(new ErrorEvent("close", false, false, event.toString()));
		}
	}
}