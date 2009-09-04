/* Copyright (c) 2009, Kundan Singh. See LICENSING for details. */
package my.card
{
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	import flash.geom.Rectangle;
	
	import mx.controls.Image;
	import mx.utils.Base64Decoder;
	
	import my.core.Room;
	
	/**
	 * This is an immutable object representing a visiting card.
	 * A visiting card has a card image and some additional control data such as certificate.
	 * If the certificate cannot be verified or if the control data is incomplete, then
	 * a 'Not Valid' text is overlayed on top of the visiting card image.
	 * 
	 * The PNG image data can have two additional chunks for info and key. The info chunk with
	 * identifier "lsAB" is used to store list of name-value attributes, where name can be 
	 * "title", "email", "owner", "name", "keywords", "url", "photo" identifying the room and card, and
	 * value can be a string representing the attribute's value. The key chunk with identifier
	 * "ksAB" is used by the service to authenticate the cards and stores the opaque key or
	 * certificate of the card. The client doesn't use this chunk except for perhaps checking
	 * the presence of the chunk in the image.
	 */
	public class VisitingCard
	{
		//--------------------------------------
		// CLASS CONSTANTS
		//--------------------------------------

		/**
		 * Text displayed as title on a visiting card.
		 */
		public static const INTERNET_VISITING_CARD:String = 'Internet Visiting Card';
		
		/**
		 * Text displayed as title on a login card.
		 */
		public static const PRIVATE_LOGIN_CARD:String = 'Private Login Card';
		
		//--------------------------------------
		// CLASS VARIABLES
		//--------------------------------------

		private static const INFO_TYPE:uint = 0x6c734142; // PNG chunk type for "info" is lsAB
		private static const KEY_TYPE:uint = 0x6b734142; // PNG chunk type for "key" is ksAB
		private static var util:PNGUtil = new PNGUtil();
		
		//--------------------------------------
		// PRIVATE PROPERTIES
		//--------------------------------------

		private var _isLoginCard:Boolean = false;
		private var _rawData:ByteArray;
		private var _info:ByteArray;
		private var _url:String;
		private var _photoRect:Rectangle;
		
		//--------------------------------------
		// GETTERS/SETTERS
		//--------------------------------------

		/**
		 * Indicate whether this is a login card (true) or visiting card (false).
		 */
		public function get isLoginCard():Boolean
		{
			return _isLoginCard;
		}
		
		/**
		 * Access the raw data associated with this card. The raw data contains everything in this card
		 * file including the image pixels and metadata information.
		 */
		public function get rawData():ByteArray
		{
			return _rawData;
		}
		
		/**
		 * Access the information (binary data) associated with this card. The information is metadata
		 * excluding the image pixels, and is stored in a PNG chunk.
		 */
		public function get info():ByteArray
		{
			return _info;
		}
		
		/**
		 * Get the url identifying this visiting card.
		 */
		public function get url():String
		{
			return _url;
		}
		
		/**
		 * Get the photo rectangle from the binary data.
		 */
		public function get photoRect():Rectangle
		{
			return _photoRect;
		}
		
		//--------------------------------------
		// PUBLIC METHODS
		//--------------------------------------

		/**
		 * Create a new room from this card.
		 */
		public function createRoom(setCard:Boolean=true):Room
		{
			var tb:Array = readInfo(_info);
			if (tb != null) {
				var room:Room = tb[1] as Room;
				if (room != null && setCard) {
					room.card = this;
				}
				return room;
			}
			else {
				return null;
			}
		}
		
		/**
		 * Validate the card. In case of invalid card, it returns a detailed error report.
		 * In case of valid card it returns null.
		 */
		public function validate(room:Room=null):String
		{
			if (rawData == null || rawData.length == 0)
				return 'There is no image data available in this card. Please use the original card sent to you in email. A modified or forged card cannot be validated.';
			if (info == null || info.length == 0)
				return 'There is no user information available in this card. Please use the original card sent to you in email. A modified or forged card cannot be validated.';
				
			if (room == null)
				room = createRoom(false);
			
			if (room == null)
				return 'The card does not have any room information. Please use the original card sent to you in email. A modified or forged card cannot be validated.';
			var invalid:Array = [];
			if (room.email == null) invalid.push("owner's email");
			if (room.owner == null) invalid.push("owner's name");
			if (room.url == null) invalid.push("room URL");
			if (invalid.length > 0)
				return 'The card has incomplete information. The following data are missing: ' + invalid.join(', ')
				+ '. Please use the original card sent to you in email';
			return null;
		}
		
		//--------------------------------------
		// STATIC METHODS
		//--------------------------------------

		/**
		 * Load a new visiting card from the given array of bytes. The supplied raw binary data also gets stored
		 * in the rawData property of the returned VisitingCard.
		 */
		public static function load(bytes:ByteArray):VisitingCard
		{
			var b:ByteArray = new ByteArray();
			b.endian = Endian.BIG_ENDIAN;
			bytes.endian = Endian.BIG_ENDIAN;
			
			if (bytes.length >= 8) {
				bytes.position = 8;
				for (; bytes.bytesAvailable >= 12; ) {
					var len:uint = bytes.readUnsignedInt();
					var type:uint = bytes.readUnsignedInt();
					if (type == INFO_TYPE && len > 0) {
						bytes.readBytes(b, 0, len);
					}
					else if (len > 0) {
						bytes.position += len;
					}
					bytes.position += 4; // ignore CRC
				}
			}
			
			b.position = 0;
			
			var card:VisitingCard = new VisitingCard();
			card._rawData = bytes;
			card._info = b;
			var tb:Array = readInfo(b);
			card._isLoginCard = (tb[0] == PRIVATE_LOGIN_CARD);
			card._url = (tb[1] == null ? null : Room(tb[1]).url);
			card._photoRect = tb[2];
			bytes.position = 0;
			return card;
		}
		
		/**
		 * Save a new visiting card to the given array of bytes, including the room information.
		 * The returned binary data is used as the rawData property of a VisitingCard.
		 */
		public static function save(bytes:ByteArray, info:ByteArray):ByteArray
		{
			var b:ByteArray = new ByteArray();
			b.endian = Endian.BIG_ENDIAN;
			bytes.endian = Endian.BIG_ENDIAN;
			
			if (bytes.length >= 8) {
				var i:int = 8;
				var len:uint = (bytes[i] << 24) & 0xff000000 | (bytes[i+1] << 16) & 0x00ff0000 | (bytes[i+2] << 8) & 0x0000ff00 | bytes[i+3] & 0x000000ff;
				var off:int = 8 + 4 + 4 + 4 + len;
				// write upto header
				b.writeBytes(bytes, 0, off);
				
				util.writeChunk(b, INFO_TYPE, info);
					
				// write everything after header
				b.writeBytes(bytes, off, bytes.length-off);
			}
			
			b.position = 0;
			return b;
		}
		
		/**
		 * Create the metadata information from the individual objects (title string, room object and photo
		 * dimensions. The returned value is used for the info property of VisitingCard.
		 */
		public static function createInfo(title:String, room:Room, photo:Rectangle):ByteArray
		{
			var info:ByteArray = new ByteArray();
			info.endian = Endian.BIG_ENDIAN;
			try {
				writeUTF(info, "title", title);
				if (room != null) {
					writeUTF(info, "email", room.email);
					writeUTF(info, "owner", room.owner);
					writeUTF(info, "name", room.name);
					writeUTF(info, "keywords", room.keywords != null ? room.keywords.join(';') : null);
					writeUTF(info, "url", room.url);
					writeUTF(info, "photo", photo.x.toString() + " " + photo.y.toString() + " " + photo.width.toString() + " " + photo.height.toString());
				}				
			} catch (e:Error) {
				trace("Error storing the info: " + e);
			}
			info.position = 0;
			trace('b=' + info[0] + ',' + info[1]);
			return info;
		}
		
		/**
		 * Read the metadata information from the given binary raw data. The returned array has three elements:
		 * title string, room object and photo dimension.
		 */ 
		public static function readInfo(b:ByteArray):Array
		{
			try {
				var title:String;
				b.position = 0;
				var room:Room = new Room();
				var photoRect:Rectangle = null;
				while (true) {
					var name:String = readUTF(b);
					if (name == null) break;
					var value:String = readUTF(b);
					
					switch (name) {
					case 'title': title = value; break;
					case 'email': room.email = value; break;
					case 'owner': room.owner = value; break;
					case 'name': room.name = value; break;
					case 'keywords': room.keywords = (value != null ? value.split(';') : []); break;
					case 'url': room.url = value; break;
					case 'photo':
						var values:Array = value.split(" ");
						if (values != null && values.length == 4) 
							photoRect = new Rectangle(parseInt(values[0]), parseInt(values[1]), parseInt(values[2]), parseInt(values[3])); 
						break;
					}
				}
				return [title, room, photoRect];
			}
			catch (e:Error) {
				trace("error reading the info: " + e);
			}
			return ['', null, null];
		}

		/**
		 * Read the supplied base64 data and build a VisitingCard out of it.
		 */
		public static function readCard(data:String):VisitingCard
		{
			var dec:Base64Decoder = new Base64Decoder();
			dec.decode(String(data));
			var bytes:ByteArray = dec.drain();
			bytes.position = 0;
			return VisitingCard.load(bytes);
		}
		
		/**
		 * Read some UTF string from byte array.
		 */
		private static function readUTF(b:ByteArray):String
		{
			if (b.bytesAvailable < 2) 
				return null;
			var str:String = b.readUTF();
			if (str == '') str = null;
			return str;
		}
			
		/**
		 * Write some property as UTF string.
		 */
		private static function writeUTF(b:ByteArray, name:String, value:String):void
		{
			if (value != null) {
				b.writeUTF(name);
				b.writeUTF(value);
			}
		}
	}
}