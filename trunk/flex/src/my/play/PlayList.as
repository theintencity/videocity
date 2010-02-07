/* Copyright (c) 2009, Kundan Singh. See LICENSING for details. */
package my.play
{
	import flash.events.Event;
	import flash.net.FileReference;
	
	import mx.collections.ArrayCollection;
	import mx.events.CollectionEvent;
	import mx.events.PropertyChangeEvent;
	import mx.events.PropertyChangeEventKind;
	
	import my.controls.Prompt;
	import my.core.Constant;
	import my.core.User;
	import my.core.Util;
	
	/**
	 * Represents a play-list that is used as the data model for PlayListBox. Each item in this list is
	 * actually of type PlayItem.
	 */
	public class PlayList extends ArrayCollection
	{
		//--------------------------------------
		// CLASS CONSTANTS
		//--------------------------------------
		
		/**
		 * Event type that is dispatched when the selected playItem changes in this play list.
		 */
		public static const SELECTED_CHANGE:String = "selectedChange";
		
		//--------------------------------------
		// PRIVATE VARIABLES
		//--------------------------------------
		
		// list of contents supplied in the constructor, such as for uploaded files.
		private var _content:Array = [];
		
		// associated user object
		private var _user:User;
		
		// XML description of this play list
		private var _data:XML;
		
		// currently selected item index and item in this play list.
		private var _selectedIndex:int = -1;
		private var _selectedItem:PlayItem = null;
		
		// whether the play list is currently playing or not?
		private var _playing:Boolean = false;
		
		// whether the data property is being updated currently or not? This is used to avoid
		// changing the collection redundantly.
		private var _updatingData:Boolean = false;
		
		//--------------------------------------
		// CONSTRUCTOR
		//--------------------------------------
		
		/**
		 * Construct a new play list object using the supplied XML description. The content property is
		 * an optional array of content (ByteArray) if the play list is built using files uploaded from
		 * the computer or snapshot captured from camera.
		 */
		public function PlayList(xml:XML=null, content:Array=null, user:User=null)
		{
			if (user != null)
				this.user = user;
			if (content != null)
				this.content = content;
			if (xml != null) // this must be set at the end.
				this.data = xml;
				 
			addEventListener(CollectionEvent.COLLECTION_CHANGE, collectionChangeHandler, false, 0, true);
		}

		//--------------------------------------
		// GETTERS/SETTERS
		//--------------------------------------
		
		[Bindable]
		/**
		 * The data property represents the XML description of this play list. When set, it also updates this
		 * play list collection with new play items. If atleast one play item is found, then it sets the 
		 * selectedIndex property to 0 so that the play pointer is at the first play item.
		 */
		public function get data():XML
		{
			return _data;
		}
		public function set data(value:XML):void
		{
			_data = value;
			
			_updatingData = true;
			this.removeAll(); // first remove all previous items.
			if (value != null) {
				if (value.@id == undefined || String(value.@id) == '')
					value.@id = Util.createId();
					
				var index:int = 0;
				var context:Object;
				for each (var xml:XML in value.children()) {
					if (xml.localName() == PlayItem.SHOW) {
						context = {index: index};
						user.httpRequest(user.getProxiedURL(xml.@src), "GET", "e4x", null, context, showHandler);
					}
					else if (xml.localName() == PlayItem.FILE && PlayItem.getFileType(xml.@src) == PlayItem.VIDEO 
						&& index < _content.length && _content[index] is FileReference) {
						context = {index: index, xml: xml};
						var params:Object = {filename: String(xml.@src), filedata: Util.base64encode(_content[index].data), visitingcard: Util.base64encode(user.selected.card.rawData)};
						user.httpSend(Constant.CONVERT, params, context, videoHandler);
					}
					else {
						var item:PlayItem = new PlayItem(xml, _user, index < _content.length ? _content[index] : null);
						this.addItem(item);
					}
					index = index + 1;
				}
			}
			_updatingData = false;
			
			selectedIndex = -1; // so that it resets first
			if (this.length > 0)
				selectedIndex = 0;
		}
		
		/**
		 * The read-only id property returns the unique id of this play list.
		 */ 
		public function get id():String
		{
			return data != null ? data.@id : null;
		}
		
		/**
		 * The content property set in the constructor.
		 */
		public function set content(value:Array):void
		{
			_content = value;
		}
		
		/**
		 * The associated user object with this collection.
		 */
		public function get user():User
		{
			return _user;
		}
		public function set user(value:User):void
		{
			_user = value;
		}
		
		[Bindable("selectedChange")]
		/**
		 * The selectedIndex property controls and represents the current play item in the collection.
		 * A play operation will start playing from this index.
		 */
		public function get selectedIndex():Number
		{
			return _selectedIndex;
		}
		public function set selectedIndex(value:Number):void
		{
			var old:int = _selectedIndex;
			_selectedIndex = value;
			if (old != value) {
				trace("selectedIndex changed " + old + " to " + value);
				selectedItem = (_selectedIndex >= 0 ? this.getItemAt(_selectedIndex) as PlayItem : null);
				dispatchEvent(new PropertyChangeEvent(PropertyChangeEvent.PROPERTY_CHANGE, false, false, PropertyChangeEventKind.UPDATE, "selectedIndex", old, value));
				dispatchEvent(new Event(SELECTED_CHANGE));
			}
		}
		
		[Bindable]
		/**
		 * The selectedItem represents the current play item in the collection.
		 * A play operation will start playing from this item.
		 */
		public function get selectedItem():PlayItem
		{
			return _selectedItem;
		}
		private function set selectedItem(value:PlayItem):void
		{
			trace("selectedItem changed " + _selectedItem + " to " + value);
			_selectedItem = value;
			if (value == null)
				trace("selectedItem is set to null");
		}
		
		[Bindable]
		/**
		 * The playing property controls the playback of video or timer for slide/photo show.
		 */
		public function get playing():Boolean
		{
			return _playing;
		}
		public function set playing(value:Boolean):void
		{
			var oldValue:Boolean = _playing;
			_playing = value;
		}
		
		//--------------------------------------
		// PUBLIC METHODS
		//--------------------------------------
		
		/**
		 * Close this play list by removing all content and data.
		 */
		public function close():void
		{
			selectedIndex = -1; // this will do all clean up
			_content.splice(0, _content.length); // clear file references.
			_data = null;
		}
		
		/**
		 * Add another playlist to this one. 
		 * If move is true (default), then delete from value, else keep in value.
		 */
		public function add(value:PlayList, move:Boolean=true):void
		{
			if (value.length > 0) {
				var index:int = 0;
				for each (var playItem:PlayItem in value) {
					this.addItem(playItem);
				}
			}
			
			value.removeAll();
			
			if (this.length > 0 && selectedIndex < 0)
				selectedIndex = 0;
		}
		
		//--------------------------------------
		// PRIVATE METHODS
		//--------------------------------------
		
		/*
		 * Save the existing list by updating the data/XML property.
		 */
		private function collectionChangeHandler(event:CollectionEvent):void
		{
			if (!_updatingData) {
				var xml:XML = _data != null ? _data.copy() : <show/>;
				xml.setChildren(new XMLList()); // remove old children and keep the top node.
				for each (var item:PlayItem in this) {
					xml.appendChild(item.xml);
				}
				var old:XML = _data;
				_data = xml;
				dispatchEvent(new PropertyChangeEvent(PropertyChangeEvent.PROPERTY_CHANGE, false, false, PropertyChangeEventKind.UPDATE, "data", old, _data));
			}
		}

		/*
		 * When a show description is downloaded from the server, add all Slide/Image elements to this playlist
		 * at the appropriate location.
		 * TODO: note that this is not re-entrant. In particular if two show items are in progress, then 
		 * it won't merge the resolved items correctly.
		 */
		private function showHandler(context:Object, result:XML):void
		{
			var index:int = context.index;
			
			for each (var child:XML in result.children())
				this.addItemAt(new PlayItem(child, _user), index++);
				
			if (selectedIndex == -1 && this.length > 0)
				selectedIndex = 0;
		}
		
		/*
		 * When the convert RPC returns, we update the XML description with the resolved URL of the video.
		 */
		private function videoHandler(context:Object, result:XML):void
		{
			var index:int = context.index;
			var xml:XML = context.xml;
			if (result.url != undefined) {
				xml.setLocalName(PlayItem.VIDEO);
				xml.@src = String(result.url);
				this.addItemAt(new PlayItem(xml, _user), index < this.length ? index : this.length);
				if (selectedIndex == -1 && this.length > 0)
					selectedIndex = 0;
			}
			else {
				Prompt.show("Cannot convert or upload your video file " + String(xml.@src), "Error in video upload");
			}
		}
	}
}