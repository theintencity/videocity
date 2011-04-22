/* Copyright (c) 2009-2011, Kundan Singh. See LICENSING for details. */
package my.core
{
	/**
	 * Global class to aggregate all the constant definitions.
	 */
	public class Constant
	{
		//--------------------------------------
		// CLASS CONSTANTS
		//--------------------------------------
		
		/**
		 * Index of various pages in the window.
		 */
		public static const INDEX_INTRO:int   = 0;
		public static const INDEX_CREATE:int  = 1;
		
		/**
		 * The event type used for DataEvent dispatched on Room object.
		 * createRoom: when a new room is created in the view.
		 * destroyRoom: when a room is removed from the view.
		 * enterRoom: when the user joins a room and connection is complete.
		 * exitRoom: when the user leaves a room.
		 */
		public static const CREATE_ROOM:String  = "createRoom";
		public static const DESTROY_ROOM:String = "destroyRoom";
		public static const ENTER_ROOM:String   = "enterRoom";
		public static const EXIT_ROOM:String    = "exitRoom";
		
		/**
		 * The event type used for received text message on a Room object.
		 */
		public static const MESSAGE:String = "message";
		public static const TOGGLE_TEXT:String = "toggleText";
		
		/**
		 * The event type and commands used by Play List to dispatch on User object.
		 */
		public static const PLAY_LIST:String   = "playList";
		public static const SAVE:String        = "save";
		public static const SHARE:String       = "share";
		public static const SEND:String        = "send";
		public static const UPLOAD:String      = "upload";
		public static const CONVERT:String     = "convert";

		public static const ACCESS:String  = "access";
		
		public static const PLAY_COMPLETE:String = "playComplete";
		
		/**
		 * Target types for uploading play list.
		 */
		public static const ACTIVE:String  = "active.xml";
		public static const PUBLIC:String  = "index.xml";
		public static const PRIVATE:String = "inbox.xml";
		
		/**
		 * Event types used from play list control.
		 */
		public static const DOWNLOAD:String    = "download";
		// public static const LAYOUT:String = "layout" // defined elesewhere
		public static const PLAY:String = "play";
		
		/**
		 * Events dispatched by a room.
		 */
		public static const MEMBERS_CHANGE:String = "membersChange";
		public static const STREAMS_CHANGE:String = "streamsChange";
		public static const FILES_CHANGE:String  = "filesChange";
		
		/**
		 * Methods name invoked on the server to send a message to others in a call.
		 */
		public static const BROADCAST:String = "broadcast";
		public static const UNICAST:String = "unicast";

		/**
		 * The event type used for DataEvent dispatched on User object, when user clicks on a menu.
		 */
		public static const MENU:String    = "menu";
		
		/**
		 * The event type used for DataEvent dispatched on User object, when user clicks on a control button.
		 */
		public static const CONTROL:String = "control";
		
		/**
		 * The data property of the DataEvent when type is "menu".
		 */
		public static const SMOOTH:String      = "smooth";
		public static const FULL_SCREEN:String = "fullScreen";
		public static const STRETCH:String     = "stretch";
		public static const SELECT:String      = "select";
		public static const DEVICE_SELECTION:String   = "deviceSelection";
		public static const DEVICE_SETTINGS:String    = "deviceSettings";
		public static const PHONE_SETTINGS:String     = "phoneSettings";
		public static const PHONE:String       = "phone"; 
		public static const EMBED:String       = "embed";
		public static const SEARCH:String      = "search";
		public static const CAPTURE:String     = "capture";
		public static const SIGNUP:String      = "signup";
		public static const LOGIN:String       = "login";
		
		/**
		 * The data property of the DataEvent when type "control".
		 * Dispatch by User.
		 */
		public static const HOME:String        = "home";
		public static const LAYOUT:String      = "layout";
		public static const CREATE:String      = "create";
		// following are already defined in this file.
		// public static const UPLOAD:String      = "upload";
		// public static const MESSAGE:String     = "messgae";
		// public static const PHONE:String       = "phone"; 
		public static const UPLOAD_CARD:String = "uploadCard";
		
		/**
		 * The data property of the DataEvent when type is "control".
		 * Dispatched by Room.
		 */
		public static const KNOCK:String       = "knock";
		public static const SEND_EMAIL:String  = "sendEmail";
		public static const JOIN_ROOM:String   = "joinRoom";
		public static const LEAVE_MESSAGE:String = "leaveMessage";
		// public static const PUBLIC
		// public static const PRIVATE
		public static const LOAD:String        = "load";
		
		
		/**
		 * The name of the company typically used in card editor to display the name of the issuer.
		 */
		public static const COMPANY_NAME:String = "39 peers";
		
		/**
		 * Help text for various places.
		 */
		// create page
		public static const HELP_CARD:String = 'After creating a room, you will receive two cards in your email. \nDownload and send your <a href="event:visiting"><font color="#6060a0">visiting card</font></a> to your friends and family so that they can contact you in one click. You can also embed the card in your web-page or blog.\nDownload and keep your <a href="event:login"><font color="#6060a0">login card</font></a> confidential. The card is a private key that helps you login and identify you to the site.';

		// room page with valid visiting card
		public static const HELP_ROOM:String = 'You are visiting a room. You can join the room or leave a message in the room. To start your camera and microphone before joining the room, click on the camera or microphone button in the bottom control bar. You may download and save the visiting card of this room for later use.';
		
		// room page with target URL and no visiting card
		public static const HELP_ROOM_TARGET:String = 'You are visiting a room for which you do not have Internet visiting card, and the room is not public. You can upload the visiting card if you have one, after which you will be able to join the room or leave a video message. Without a visiting card, you can only knock on the door to signal to the owner that you want to enter the room. When you knock, and the owner is currently signed in, he will get instant notication and may let you in. Otherwise, your knock goes unheard. You may also leave a message in owner\'s email box by copy-pasting the content that you get after you click on the "Send Email" button on the left.';

		// room page with valid login card
		public static const HELP_ROOM_LOGIN:String = 'You own this room. You can upload a visiting card and make this room public, or make it private. You can enter the room to access your inbox for messages and to decorate your room with photos and videos.';

		//--------------------------------------
		// CONSTRUCTOR
		//--------------------------------------
		
		// dummy constructor
		public function Constant()
		{
		}

	}
}