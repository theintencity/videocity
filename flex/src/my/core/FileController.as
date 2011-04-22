package my.core
{
	import flash.events.Event;
	import flash.events.DataEvent;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.FileFilter;
	import flash.net.FileReference;
	import flash.net.FileReferenceList;
	import flash.utils.ByteArray;

	import mx.events.DynamicEvent;
	
	import my.controls.Prompt;
	import my.core.card.VisitingCard;
	import my.core.card.CardEditor;
	
	public class FileController
	{
		//--------------------------------------
		// CLASS CONSTANTS
		//--------------------------------------
		
		// file extensions for cards.
		private static var cardTypes:FileFilter = new FileFilter("Card (*.png)", "*.png");
		
		// file extensions for uploading local files.
		private static var fileTypes:FileFilter = new FileFilter("Files (*.png, *.jpg, *.jpeg, *.gif, *.flv, *.avi, *.mpg, *.mpeg)", "*.png;*.jpg;*.jpeg;*.gif;*.flv;*.avi;*.mpg;*.mpeg");
		
		//--------------------------------------
		// PRIVATE VARIABLES
		//--------------------------------------
		
		// associated user object
		private var _user:User;
		
		// only one file operation can be in progress at any instant
		private var file:FileReference;
		private var files:FileReferenceList;
		
		
		//--------------------------------------
		// GETTERS/SETTERS
		//--------------------------------------
		
		/**
		 * The associated user object must be set by the application, so that this controller can listen 
		 * for various events such as menu click, control button click, etc.
		 */
		public function get user():User
		{
			return _user;
		}
		public function set user(value:User):void
		{
			var oldValue:User = _user;
			_user = value;
			if (oldValue != value) {
				if (oldValue != null) {
					oldValue.removeEventListener(Constant.CONTROL_BAR, controlHandler);
					oldValue.removeEventListener(Constant.DOWNLOAD_CARD, downloadHandler);
				}
				if (value != null) {
					value.addEventListener(Constant.CONTROL_BAR, controlHandler, false, 0, true);
					value.addEventListener(Constant.DOWNLOAD_CARD, downloadHandler, false, 0, true);
				}
			}
		}
		
		//--------------------------------------
		// PRIVATE METHODS
		//--------------------------------------
		
		private function controlHandler(event:DataEvent):void
		{
			switch (event.data) {
			case Constant.UPLOAD_CARD:
				uploadCard();
				break;
			case Constant.UPLOAD_FILES:
				uploadFiles();
				break;
			}
		}
		
		private function uploadCard():void
		{
			if (file == null && files == null) {
				file = new FileReference();
				file.addEventListener(Event.SELECT, uploadSelectHandler);
				file.addEventListener(Event.CANCEL, fileCancelHandler);
				file.addEventListener(Event.COMPLETE, uploadCompleteHandler);
				try {
					file.browse([cardTypes]);
				}
				catch (error:Error) {
					file = null;
					Prompt.show(error.message, "Error opening file");
				}
			}
			else {
				Prompt.show("Another file operation in progress", "Error uploading file");
			}
		}
		
		private function uploadSelectHandler(event:Event):void
		{
			file.load();
		}
		private function fileCancelHandler(event:Event):void
		{
			file = null;
		}
		
		private function uploadCompleteHandler(event:Event):void
		{
			trace("loaded " + file.data.length);
			var card:VisitingCard = VisitingCard.load(file.data);
			file = null;
			//card.popup();
			var error:String = card.validate();
			if (error != null) {
				Prompt.show(error, "Cannot load the card");
			}
			else {
				if (card.isLoginCard) {
					user.login(card);
				}
				else {
					user.addRoom(card);
				}
			}
		}

		/**
		 * Following are used for uploading files such as photos in a room.
		 */
		private function uploadFiles():void
		{
			if (file == null && files == null) {
				files = new FileReferenceList();
				files.addEventListener(Event.SELECT, filesSelectHandler);
				files.addEventListener(Event.CANCEL, filesCancelHandler);
				try {
					files.browse([fileTypes]);
				}
				catch (error:Error) {
					files = null;
					Prompt.show(error.message, "Error opening files");
				}
			}
			else {
				Prompt.show("Another file operation in progress", "Error uploading file");
			}
		}
		
		private var pendingFiles:Array = [];
		
		private function filesSelectHandler(event:Event):void
		{
			for (var i:int=0; i<files.fileList.length; ++i) {
				var file:FileReference = FileReference(files.fileList[i]);
				pendingFiles.push(file);
				file.addEventListener(Event.COMPLETE, loadCompleteHandler);
				file.addEventListener(IOErrorEvent.IO_ERROR, loadErrorHandler);
				file.addEventListener(SecurityErrorEvent.SECURITY_ERROR, loadErrorHandler);
				file.load();
			}
		}
		
		private function filesCancelHandler(event:Event):void
		{
			files = null;
		}
		
		private function loadErrorHandler(event:Event):void
		{
			var file:FileReference = event.currentTarget as FileReference;
			var index:int = pendingFiles.indexOf(file);
			if (index >= 0) pendingFiles.splice(index, 1);
			if (files != null) {
				for (var i:int=0; i<files.fileList.length; ++i) {
					if (files.fileList[i] == file) {
						files.fileList.splice(i, 1);
						break;
					}
				}
			}
			if (files != null && pendingFiles.length == 0) {
				if (user.selected != null && files.fileList.length > 0) {
					user.selected.load(files);
				}
				files = null;
			}
		}
		
		private function loadCompleteHandler(event:Event):void
		{
			var file:FileReference = event.currentTarget as FileReference;
			var index:int = pendingFiles.indexOf(file);
			if (index >= 0) pendingFiles.splice(index, 1);
			
			
			var isCard:Boolean = false; // if loaded file is a card, don't display as image in playlist
			
			trace("loaded name=" + file.name + " type=" + file.type + " size=" + file.size);
			index = String(file.name).lastIndexOf('.');
			var ext:String = index >= 0 ? String(file.name).substr(index) : '';
			if (ext.toLowerCase() == '.png') {
				// this could be a visiting card.
				var card:VisitingCard = VisitingCard.load(file.data);
				var error:String = card.validate();
				if (error == null) {
					if (card.isLoginCard)
						user.login(card);
					else
						user.addRoom(card);
					isCard = true;
				}
			}

			if (isCard && files != null) {
				for (var i:int=0; i<files.fileList.length; ++i) {
					if (files.fileList[i] == file) {
						files.fileList.splice(i, 1);
						break;
					}
				}
			}
			
			if (files != null && pendingFiles.length == 0) {
				if (user.selected != null && files.fileList.length > 0) {
					user.selected.load(files);
				}
				files = null;
			}
		}
		
		private function downloadHandler(event:DynamicEvent):void
		{
			var card:* = event.card;
			var name:String = event.name != undefined ? event.name : null;
			
			if (!(card is CardEditor) && !(card is VisitingCard))
				throw new Error("must supply either a VisitingCard or a CardEditor object");
			if (file == null && files == null) {
				file = new FileReference();
				file.addEventListener(Event.SELECT, downloadSelectHandler);
				file.addEventListener(Event.CANCEL, fileCancelHandler);
				file.addEventListener(Event.COMPLETE, downloadCompleteHandler);
				
				var bytes:ByteArray = card.rawData;
				if (name == null)
					name = (card is CardEditor) ? (CardEditor(card).name.split(' ').join('.') + '.png') : 'visitingCard.png';
				file.save(bytes, name);
			}
			else {
				Prompt.show("Another file operation in progress", "Error downloading file");
			}
			
		}
		
		private function downloadSelectHandler(event:Event):void
		{
		}
		
		private function downloadCompleteHandler(event:Event):void
		{
			file = null;
		}
	}
}