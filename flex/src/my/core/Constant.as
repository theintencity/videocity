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
		
		/*
		 * Event dispatched on User object.
		 */
		 
		/**
		 * The event type of DataEvent dispatched on User object, when user clicks on a menu item.
		 * Dispatched on behalf by ControlBar and processed in Controller.
		 */
		public static const MENU_CLICK:String    = "menuClick";
		
		/**
		 * The data property of the DataEvent when type is MENU_CLICK.
		 */
		public static const SMOOTH_VIDEO:String      = "smoothVideo";
		public static const FULL_SCREEN:String       = "fullScreen";
		public static const STRETCH_FULL:String      = "stretchFull";
		public static const STRETCH_SELECTED:String  = "stretchSelect";
		public static const DEVICE_SELECTION:String  = "deviceSelection";
		public static const DEVICE_SETTINGS:String   = "deviceSettings";
		public static const VOIP_SETTINGS:String     = "voipSettings";
		public static const SHOW_EMBED:String        = "showEmbed";
		public static const SHOW_SEARCH:String       = "showSearch";
		public static const SIGNUP_ACCOUNT:String    = "signupAccount";
		public static const LOGIN_LOGOUT:String      = "loginLogout";
		
		
		/**
		 * The event type of DataEvent dispatched on User object, when user clicks on a control button.
		 * Dispatched on behalf by ControlBar and processed in Controller or FileController.
		 */
		public static const CONTROL_BAR:String = "controlBar";
		
		/**
		 * The data property of DataEvent when type is CONTROL_BAR.
		 */
		public static const GOTO_HOME:String         = "gotoHome";
		public static const GOTO_NEXT_ROOM:String    = "gotoNextRoom";
		public static const UPLOAD_CARD:String       = "uploadCard";
		public static const UPLOAD_FILES:String      = "uploadFiles"; // Dispatched by AddMediaPrompt
		public static const DOWNLOAD_CARD:String     = "downloadCard";
		public static const CHANGE_SKIN:String       = "changeSkin";
		
		/**
		 * The event type of DataEvent dispatched on User object, when a room is created or destroyed.
		 * Dispatched by User and processed in RoomController.
		 */
		public static const CREATE_ROOM:String  = "createRoom";
		public static const DESTROY_ROOM:String = "destroyRoom";
		
		/*
		 * Event dispatched on Room object.
		 */
		 
		/**
		 * The event type of DataEvent dispatched on Room object, when user clicks on a control button.
		 * Dispatched on behalf by ControlBar or RoomPage and processed in RoomController
		 */
		public static const CONTROL_ROOM:String = "controlRoom";
		
		/**
		 * The data property of DataEvent when type is CONTROL_ROOM.
		 */
		public static const TRY_ENTER_ROOM:String         = "tryEnterRoom";
		public static const ENTER_ROOM:String             = "enterRoom";   // Dispatched also by Room
		public static const EXIT_ROOM:String              = "exitRoom";
		public static const KNOCK_ON_DOOR:String          = "knockOnDoor";
		public static const SEND_EMAIL_TO_OWNER:String    = "sendEmailToOwner";
		public static const LEAVE_MESSAGE_TO_OWNER:String = "leaveMessageToOwner";
		public static const MAKE_ROOM_PUBLIC:String       = "makeRoomPublic";
		public static const MAKE_ROOM_PRIVATE:String      = "makeRoomPrivate";
		public static const SHOW_UPLOAD_PROMPT:String     = "showUploadPrompt";
		public static const CREATE_NEW_PLAYLIST:String    = "createNewPlaylist";// Dispatched by AddMediaPrompt
		public static const SHOW_CAPTURE_SNAPSHOT:String  = "showCaptureSnapshot";
		public static const SHOW_VOIP_DIALER:String       = "showVoipDialer";
		public static const TOGGLE_TEXT_CHAT:String       = "toggleTextChat";
		
		/**
		 * Event type of DynamicEvent dispatched by the Room object.
		 * Dispatched by Room when data model changes and processed by RoomController.
		 */
		public static const MEMBERS_CHANGE:String = "membersChange";
		public static const STREAMS_CHANGE:String = "streamsChange";
		public static const FILES_CHANGE:String   = "filesChange";
		
		/**
		 * The event type of DynamicEvent used for received text message on a Room object.
		 */
		public static const RECEIVE_MESSAGE:String = "receiveMessage";
		
		/**
		 * The event type of DynamicEvent used for dispatching controlled change received
		 * in a shared room, so that RemoteController can update the local room.
		 */
		public static const CONTROLLED_CHANGE:String = "controlledChange";
		
		/*
		 * Event dispatched on PlayList object.
		 */
		 
		/**
		 * Event type of Event dispatched on ListControl object and captured by PlayListBox.
		 */
		public static const CHANGE_PLAYLIST_LAYOUT:String   = "changePlaylistLayout";
		public static const DOWNLOAD_PLAYLIST_FILES:String  = "downloadPlaylistFiles";
		
		/**
		 * Event type of Event dispatched on PlayItem views such as PhotoItem, StreamItem, etc.
		 * It is captured by ListItem for a slide show.
		 */
		public static const PLAY_COMPLETE:String = "playComplete";
		
		/**
		 * Event type of DynamicEvent dispatched on Room on behalf by SaveMediaPrompt or PlayListBox.
		 */
		public static const CONTROL_PLAYLIST:String  = "controlPlaylist";
		
		/**
		 * The command property of DynamicEvent when type is "controlPlaylist".
		 */
		public static const TRASH_PLAYLIST:String              = "trashPlaylist";
		public static const SAVE_PLAYLIST_FILE_LOCALLY:String  = "savePlaylistFileLocally";
		public static const SHARE_PLAYLIST_WITH_OTHERS:String  = "sharePlaylistWithOthers";
		public static const SEND_PLAYLIST_TO_OWNER:String      = "sendPlaylistToOwner";
		public static const UPLOAD_PLAYLIST_TO_ROOM:String     = "uploadPlaylistToRoom";

		/*
		 * Additional constants for room, playlist, etc.
		 */
		
		/**
		 * Values of room access types.
		 */
		public static const ROOM_ACCESS_PUBLIC:String     = "public";
		public static const ROOM_ACCESS_PRIVATE:String    = "private";
		
		/**
		 * Optional parameters sent in connect to the server.
		 */
		public static const ROOM_CONNECT_CONTROLLED:String  = "controlled";
		
		/**
		 * The send mode invoked on the server to send a message to others in a room.
		 * If you change this, also change the name of the functions on server backend.
		 */
		public static const SEND_BROADCAST:String = "broadcast";
		public static const SEND_UNICAST:String   = "unicast";

		/**
		 * The method name invoked on other clients via the server in a room.
		 * If you change this, also change the name of the functions in Room.
		 */
		public static const ROOM_METHOD_PUBLISHED:String   = "published";
		public static const ROOM_METHOD_UNPUBLISHED:String = "unpublished";
		public static const ROOM_METHOD_MESSAGE:String     = "message";
		
		/**
		 * The method name invoked on clients by the server in a room.
		 * If you change this, also change the name of the function in Room and on the server backend.
		 */
		public static const ROOM_METHOD_CONTROLLED:String = "controlled";
		public static const ROOM_METHOD_CONTROLLED_CHANGE:String = "controlledChange";
				
		/**
		 * HTTP commands sent to the backend. Any changes to this must be replicated in backend.
		 */
		public static const HTTP_FILE_CONVERT:String      = "convert";
		public static const HTTP_PLAYLIST_TRASH:String    = "trash";
		public static const HTTP_PLAYLIST_UPLOAD:String   = "upload";
		public static const HTTP_ROOM_ACCESS:String       = "access";
		public static const HTTP_ROOM_CREATE:String       = "create";
		
		/**
		 * Target types for uploading play list.
		 */
		public static const PLAYLIST_TARGET_ACTIVE:String  = "active.xml";
		public static const PLAYLIST_TARGET_PUBLIC:String  = "index.xml";
		public static const PLAYLIST_TARGET_PRIVATE:String = "inbox.xml";
		
		/*
		 * Additional misc constants.
		 */
		
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
	}
}