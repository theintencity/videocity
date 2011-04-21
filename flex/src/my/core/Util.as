/* Copyright (c) 2009-2011, Kundan Singh. See LICENSING for details. */
package my.core
{
	import flash.display.Bitmap;
	import flash.utils.ByteArray;
		
	import mx.controls.Image;
	import mx.utils.Base64Encoder;
	
	/**
	 * The Util class provides various class methods for utilities, such as copying an Image, checking if a
	 * string is phone number, etc.
	 */
	public class Util
	{
		//--------------------------------------
		// CONSTRUCTOR
		//--------------------------------------
		
		// dummy constructor
		public function Util()
		{
		}

		//--------------------------------------
		// CLASS CONSTANTS
		//--------------------------------------
		
		private static var reEmail:RegExp = /^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}$/;
		private static var reANC:RegExp = /[^\ a-zA-Z0-9._',;+-]/;
		private static var reRoom:RegExp = /[^a-zA-Z0-9._'-]/;
		
		//--------------------------------------
		// STATIC METHODS
		//--------------------------------------
		
		/**
		 * Check whether the given text is an email address of the form "user@domain" or not?
		 * @param text The text string to check.
		 * @return true if text is an email address, and false otherwise.
		 */
		public static function isEmail(text:String):Boolean
		{
			return text != null && text.toUpperCase().search(reEmail) >= 0;
		}
		
		/**
		 * Check whether the given text contains only alpha-numeric characters and special ._',;+- or not?
		 * @param text The text string to check.
		 * @return true if text contains only alpha-numeric and special symbols allowed (._',;+-).
		 */
		public static function isAlphaNumComma(text:String):Boolean
		{
			return text != null && text.search(reANC) < 0;
		}
		
		/**
		 * Check whether the given text is a valid room name or not? Only alpha-numeric and special symbols
		 * such as ._'- are allowed in a room name.
		 * @param text The text string to check.
		 * @param allowSpaces Whether to allow spaces in the room name or not. Default is true.
		 * @return true if text is a valid room name, false otherwise.
		 */
		public static function isValidRoomName(text:String, allowSpaces:Boolean=true):Boolean
		{
			if (allowSpaces)
				text = text != null ? text.split(" ").join(".") : null
			return text != null && text != '' && text.search(reRoom) < 0;
		}
		
		/**
		 * Convert the URL to email, by assuming the URL of the form http://server:port/email 
		 * or http://server:port/email/name.
		 */
		public static function url2email(url:String):String
		{
			var i:int = url.indexOf('/', 7), j:int = -1;
			if (i > 0) 
				j = url.indexOf('/', i+1);
			return i > 0 ? url.substring(i+1, j >= 0 ? j : 0x7fffffff) : null;
		}
		
		/**
		 * Create a duplicate copy of the given Image object while keeping the same image content's data,
		 * hence doesn't cause more memory for large images. Certain properties such as width, height and
		 * maintainAspectRatio are also copied to the new image.
		 * @param img The original image to copy from.
		 * @return a new copy of the image img.
		 */
		public static function copyImage(img:Image):Image
		{
			var result:Image = new Image();
			result.width = img.width; 
			result.height = img.height;
			result.maintainAspectRatio = img.maintainAspectRatio;
			try {
				result.load(new Bitmap(Bitmap(img.content).bitmapData));
			}
			catch (e:Error) {
				trace("error loading bitmap data " + e.message + "\n" + e.getStackTrace());
			}
			return result;
		}

    	/**
    	 * Return a readable time string such as HH:MM.
		 */
		public static function readableTime(date:Date):String 	
		{
			return date == null ? '' : (date.hours.toString() + (date.minutes < 10 ? ':0' : ':') + date.minutes.toString());
		}			 
		
		/**
		 * Create a new random stream id.
		 */
		public static function createId():String
		{
			return Math.floor(Math.random()*Math.pow(2, 32)).toString(16);
		}
		
		/**
		 * Base64 encoding.
		 */
		public static function base64encode(data:ByteArray):String
		{
			var enc:Base64Encoder = new Base64Encoder();
			enc.insertNewLines = true;
			enc.encodeBytes(data);
			return enc.drain();
		}

	}
}