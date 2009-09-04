/* Copyright (c) 2009, Kundan Singh. See LICENSING for details. */
package my.play
{
	import flash.utils.ByteArray;
	import flash.net.FileReference;
	import my.core.User;
	
	/**
	 * A PlayItem represents a single play item inside the PlayList. It has both an XML description and
	 * content or bitmap.
	 * 
	 * Following are examples of XML representation of PlayItem.
	 * <video src="http://..."/> The video is downloaded from HTTP URL "http://our-proxy?url=" + src
	 *    This is used for playing video from other video sites such as YouTube.
	 * <stream src="rtmp://..." id="sname"/> The video is stream from the given RTMP URL using streamName of id.
	 *    This is used for play back of recorded stream on our server.
	 *    One the video is stored, the URL may be changed to a HTTP URL, XML to <video/> and id removed.
	 * <image src="http://..."/> The image is downloaded from the given HTTP URL.
	 *    This is used for downloading photo from any site.
	 * <image/> and bitmap is valid: The given bitmap is displayed for the image.
	 *    This is used for displaying locally captured photos from camera.
	 *    One the resouce is uploaded, the URL is changed to a HTTP URL.
	 * <file src="file://..."/> and content is valid: The content is displayed based file extension.
	 *    This is used for displaying locally uploaded photos or videos from local computer.
	 *    Once the resource is uploaded, the URL is changed to a HTTP URL and XML to a <video/> tag.
	 * <text src="http://..."/> The text is displayed from given HTTP URL.
	 *    This is used for displaying a text file from the web.
	 * <text>This is an example text</text> The text element is displayed.
	 *    This is used for displaying inline text.
	 * <text internal="10000"><h2>heading</h2>...</text> Similar to previous one except that htmlText 
	 *    is used if the child of text starts with a tag. Also the text is displayed for the given interval.
	 * <show src="http://..."/> Another slide show elsewhere such as on slideshare.net
	 *    After resolving from the given URL, individual slides are merged into the main slide show.
	 */
	public class PlayItem
	{
		//--------------------------------------
		// CLASS CONSTANTS
		//--------------------------------------
		
		/*
		 * Various tags for XML description.
		 */ 
		public static const FILE:String  = "file";
		public static const IMAGE:String = "image";
		public static const VIDEO:String = "video";
		public static const STREAM:String = "stream";
		public static const TEXT:String = "text";
		public static const SHOW:String = "show";
		
		//--------------------------------------
		// PUBLIC PROPERTIES
		//--------------------------------------
		
		[Bindable]
		/**
		 * The XML description of this play item. 
		 */
		public var xml:XML;
		
		/**
		 * The name of the item. This is one of "file", "image", "video", "stream", "text" or
		 * "show". A "show" item gets resolved again by the play list in to child "image" items, and these
		 * children are merged to the play list. Hence a play item will not see a "show" name.
		 */
		public var name:String;
		
		/**
		 * The description attribute of the play item.
		 */
		public var description:String;
		
		[Bindable]
		/**
		 * The src attribute of the play item.
		 */
		public var source:String;
		
		/**
		 * The binary/raw content for this play item. This is useful when the play item was created by
		 * uploading content from local PC or using camera snapshot capture.
		 */
		public var content:ByteArray;
		
		//--------------------------------------
		// CONSTRUCTOR
		//--------------------------------------
		
		/**
		 * Construct a new play item using the supplied arguments. The xml argument represents the XML
		 * description. The data argument is optional content for this play item. Internally it sets the
		 * xml, name, description, content and source properties of the play item.
		 */
		public function PlayItem(xml:XML, user:User, data:Object=null)
		{
			this.xml = xml;
			this.name = String(xml.localName()).toLowerCase();
			this.description = String(xml.@description);
			this.content = null;
			
			if (this.name == FILE && data is FileReference) {
				this.name = getFileType(FileReference(data).name);
				this.content = FileReference(data).data;
			}
			else if (this.name == FILE && data is ByteArray) {
				this.name = getFileType(String(xml.@src));
				this.content = ByteArray(data);
			}
			
			var src:String = String(xml.@src);
			if (this.name == VIDEO && src.substr(0, 7) == 'http://' && src.indexOf('http://'+user.server) != 0)
				this.source = user.getProxiedURL(xml.@src);
			else
				this.source = String(xml.@src);
		}

		//--------------------------------------
		// STATIC METHODS
		//--------------------------------------
		
		/**
		 * Describe the supplied file using an XML description. If the file name is abc.flv then the returned
		 * description is <file src="file://abc.flv" description="abc.flv" />
		 */
		public static function describeFile(file:FileReference):XML
		{
			return XML('<file src="file://' + file.name.toLowerCase() + '" description="' + (file.data == null ? 'Cannot load: ' : '') + file.name + '" />');
		}
		
		/**
		 * Describe the supplied URL using an XML description. If the URL is on youtube then the description
		 * is <video src="http://www.youtube.com/..." />
		 */
		public static function describeURL(url:String, desc:String=''):XML
		{
			if (url.indexOf("http://www.youtube.com/") == 0)
				return XML('<show><video src="' + url + '" description="' + (desc == null ? 'YouTube' : desc) + '" /></show>');
			else if (url.indexOf("http://www.slideshare.net/") == 0)
				return XML('<show><show src="' + url + '" description="' + (desc == null ? 'SlideShare' : desc) + '" /></show>');
			else
				return XML('<show><file src="' + url + '" description="' + desc + '" /></show>');
		}
		
		/**
		 * Describe a recorded stream.
		 */
		public static function describeRecord(url:String, id:String, name:String):XML
		{
			if (url != null && id != null)
				return XML('<show description="Recorded video"><stream src="' + url + '" id="' + id + '" description="Recorded' + (name != null ? ' by ' + name : '') + '"/></show>');
			else
				return XML('<show/');
		}

		/**
		 * Get the file type such as "file", "image" or "video" using the file extension of the given
		 * file name. Only mpg, mpeg and flv video file extensions and jpg, jpeg, png and gif image
		 * file extensions are recognized.
		 */
		public static function getFileType(name:String):String
		{
			var type:String = FILE;
			var index:int = name.lastIndexOf('.');
			var ext:String = (index >= 0 ? name.substr(index+1).toLowerCase() : '');
			if (ext == 'jpg' || ext == 'jpeg' || ext == 'png' || ext == 'gif')
				type = IMAGE;
			else if (ext == 'avi' || ext == 'mpg' || ext == 'mpeg' || ext == 'flv')
				type = VIDEO;
			return type;
		}
	}
}