/* Copyright (c) 2009-2011, Kundan Singh. See LICENSING for details. */
package my.core
{
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.StatusEvent;
	import flash.events.TimerEvent;
	import flash.media.Camera;
	import flash.media.Microphone;
	import flash.media.SoundMixer;
	import flash.media.SoundTransform;
	import flash.system.Capabilities;
	import flash.system.Security;
	import flash.system.SecurityPanel;
	import flash.utils.Timer;
	
	import mx.controls.Alert;
	import mx.core.Application;
	import mx.events.PropertyChangeEvent;
	import mx.events.PropertyChangeEventKind;
	
	import my.controls.Prompt;
	import my.video.Record;
	
	/**
	 * Dispatched when the camera active state changes.
	 */
	[Event(name="cameraChange", type="flash.events.Event")]
	
	/**
	 * Dispatched when the microphone active state changes.
	 */
	[Event(name="micChange", type="flash.events.Event")]
	
	/**
	 * The base class for User. I separated the User class into this base so that the device related
	 * functions and properties can be implemented in the base class, whereas other rooms and target
	 * related ones in actual User class.
	 */
	public class UserBase extends EventDispatcher
	{
		//--------------------------------------
		// PRIVATE VARIABLES
		//--------------------------------------
		
		private var _playing:Boolean = true;
		private var _recording:Boolean = false;
		private var _camActive:Boolean = false;
		private var _micActive:Boolean = false;

		private var _micVolume:Number = 0.5;
		private var _micLevel:Number = 0;
		private var _micRate:int = 8;
		private var _micCodec:String = "NellyMoser";
		private var _micEncodeQuality:int = 6;
		private var _micFramesPerPacket:int = 2;
		 
		private var _speakerActive:Boolean = true;
		private var _speakerVolume:Number = 0.5;
		
		private var _camera:Camera = null;
		private var _mic:Microphone = null;
		private var _micLevelTimer:Timer;
		private var _smoothing:Boolean = true;
		
		private var _camWidth:int = 320; // 640; // 240;
		private var _camHeight:int = 240; // 480; // 180;
		private var _camFPS:int = 12; // 30; // 12;
		private var _camBandwidth:int = 0;
		private var _camQuality:int = 0; // 100; // 0;
		private var _camKeyFrameInterval:int = 15;
		private var _camLoopback:Boolean = false;
		
		private var resetCamAfterRecording:Boolean = false;
		private var resetMicAfterRecording:Boolean = false;
		
		//--------------------------------------
		// CONSTRUCTOR
		//--------------------------------------
		
		/*
		 * Empty constructor.
		 */
		public function UserBase()
		{
		}

		//--------------------------------------
		// GETTERS/SETTERS
		//--------------------------------------
		
		/**
		 * The camera object.
		 */
		public function get camera():Camera
		{
			return _camera;
		}
		
		/**
		 * The microphone object.
		 */
		public function get mic():Microphone
		{
			return _mic;
		}
		
		/**
		 * The record object if any.
		 */
		public function get record():Record
		{
			return _record;
		}
		
		[Bindable]
		/**
		 * Whether we are playing or paused?
		 */
		public function get playing():Boolean
		{
			return _playing;
		}
		public function set playing(value:Boolean):void
		{
			var oldValue:Boolean = _playing;
			_playing = value;
			if (oldValue != value) {
				// TODO: pause everything
			}
		}
		
		[Bindable]
		/**
		 * Whether we are recording or not?
		 */
		public function get recording():Boolean
		{
			return _recording;
		}
		public function set recording(value:Boolean):void
		{
			var oldValue:Boolean = _recording;
			_recording = value;
			if (oldValue != value) {
				if (value) {
					resetCamAfterRecording = resetMicAfterRecording = false;
					if (!camActive) {
						camActive = true;
						resetCamAfterRecording = true;
					}
					if (!micActive) {
						micActive = true;
						resetMicAfterRecording = true;
					}
				}
				else {
					if (resetCamAfterRecording)
						camActive = false;
					if (resetMicAfterRecording)
						micActive = false;
					resetCamAfterRecording = resetMicAfterRecording = false;
				}
				if (value)
					startRecording();
				else
					stopRecording();
			}
		}
		
		[Bindable]
		/**
		 * Whether camera is active or not?
		 */
		public function get camActive():Boolean
		{
			return _camActive;
		}
		public function set camActive(value:Boolean):void
		{
			var oldValue:Boolean = _camActive;
			if (value != oldValue) {
				if (!value) {
					_camActive = value;
					if (_camera != null) {
						_camera = null;
						dispatchEvent(new Event("cameraChange"));
					}
				}
				else {
					if (_camera == null) {
						var index:int = Camera.names.indexOf("USB Video Class Video");
						if (index >= 0 && Capabilities.os.indexOf("Mac") >= 0) 
							_camera = Camera.getCamera(index.toString());
						else
							_camera = Camera.getCamera();
						if (_camera == null) {
							Alert.show("No camera installed!", "Warning");
						}
						else {
							_camera.setLoopback(_camLoopback);
							_camera.setMode(_camWidth, _camHeight, _camFPS);
							_camera.setQuality(_camBandwidth, _camQuality);
							dispatchEvent(new Event("cameraChange"));
						}
					}
					if (_camera != null) {
						if (_camera.muted) {
							Security.showSettings(SecurityPanel.PRIVACY);
							_camera.addEventListener(StatusEvent.STATUS, cameraStatusHandler, false, 0, true);
						}
						else {
							_camActive = value;
						}
					}
				}
			}
		}
		
		[Bindable]
		/**
		 * Whether microphone is active or not?
		 */
		public function get micActive():Boolean
		{
			return _micActive;
		}
		public function set micActive(value:Boolean):void
		{
			var oldValue:Boolean = _micActive;
			if (value != oldValue) {
				if (!value) {
					stopMicLevelTimer();
					_micActive = value;
					if (_mic != null) {
						_mic = null;
						dispatchEvent(new Event("micChange"));
					}
				}
				else {
					if (_mic == null) {
						_mic = Microphone.getMicrophone(-1);
						if (_mic == null) {
							Alert.show("No mic installed!", "Warning");
						}
						else {
							_mic.codec = micCodec;
							_mic.rate = micRate;
							_mic.encodeQuality = micEncodeQuality;
							_mic.framesPerPacket = micFramesPerPacket;
							micVolume = _mic.gain / 100;
							dispatchEvent(new Event("micChange"));
						}
					}
					if (_mic != null) {
						if (_mic.muted) {
							Security.showSettings(SecurityPanel.PRIVACY);
							_mic.addEventListener(StatusEvent.STATUS, micStatusHandler, false, 0, true);
						}
						else {
							_micActive = value;
							startMicLevelTimer();
						}
					}
				}
			}
		}
		
		[Bindable]
		/**
		 * The microphone volume is a number between 0.0 and 1.0. When set, it updates the microphone
		 * gain.
		 */
		public function get micVolume():Number
		{
			return _micVolume;
		}
		public function set micVolume(value:Number):void
		{
			_micVolume = value;
			if (_mic != null)
				_mic.gain = value * 100;
		}
		
		[Bindable]
		/**
		 * The microphone level is the current activity level of the microphone.
		 */
		public function get micLevel():Number
		{
			return _micLevel;
		}
		public function set micLevel(value:Number):void
		{
			_micLevel = value;
		}
		
		[Bindable]
		/**
		 * The sampling rate property of the microphone.
		 */
		public function get micRate():Number
		{
			return _micRate;
		}
		public function set micRate(value:Number):void
		{
			_micRate = value;
			if (_mic != null)
				_mic.rate = value;
		}
		
		[Bindable]
		/**
		 * The codec property of the microphone.
		 */
		public function get micCodec():String
		{
			return _micCodec;
		}
		public function set micCodec(value:String):void
		{
			_micCodec = value;
			if (_mic != null)
				_mic.codec = value;
		}
		
		[Bindable]
		/**
		 * The encodeQuality property of the microphone.
		 */
		public function get micEncodeQuality():Number
		{
			return _micEncodeQuality;
		}
		public function set micEncodeQuality(value:Number):void
		{
			_micEncodeQuality = value;
			if (_mic != null)
				_mic.encodeQuality = value;
		}
		
		[Bindable]
		/**
		 * The framesPerPacket property of the microphone.
		 */
		public function get micFramesPerPacket():Number
		{
			return _micFramesPerPacket;
		}
		public function set micFramesPerPacket(value:Number):void
		{
			_micFramesPerPacket = value;
			if (_mic != null)
				_mic.framesPerPacket = value;
		}
		
		[Bindable]
		/**
		 * Whether the speaker is active or not (muted)?
		 */
		public function get speakerActive():Boolean
		{
			return _speakerActive;
		}
		public function set speakerActive(value:Boolean):void
		{
			_speakerActive = value;
			updateMixer();
		}
		
		[Bindable]
		/**
		 * The speaker volume property controls the volume level of the global SoundMixer.
		 */
		public function get speakerVolume():Number
		{
			return _speakerVolume;
		}
		public function set speakerVolume(value:Number):void
		{
			_speakerVolume = value;
			updateMixer();
		}
		
		[Bindable]
		/**
		 * The smoothing property controls the smoothing of various Video objects in the application.
		 */
		public function get smoothing():Boolean
		{
			return _smoothing;
		}
		public function set smoothing(value:Boolean):void
		{
			_smoothing = value;
		}
		
		[Bindable]
		/**
		 * The camera capture width.
		 */
		public function get camWidth():Number
		{
			return _camWidth;
		}
		public function set camWidth(value:Number):void
		{
			_camWidth = value;
			_camHeight = value*3/4;
			if (_camera != null)
				_camera.setMode(_camWidth, _camHeight, _camFPS);
		}
		
		[Bindable]
		/**
		 * The camera capture height.
		 */
		public function get camHeight():Number
		{
			return _camHeight;
		}
		public function set camHeight(value:Number):void
		{
			_camHeight = value;
			_camWidth = value*4/3;
			if (_camera != null)
				_camera.setMode(_camWidth, _camHeight, _camFPS);
		}
		
		[Bindable]
		/**
		 * The fps (frames-per-second) property of the camera.
		 */
		public function get camFPS():Number
		{
			return _camFPS;
		}
		public function set camFPS(value:Number):void
		{
			_camFPS = value;
			if (_camera != null)
				_camera.setMode(_camWidth, _camHeight, _camFPS);
		}
		
		[Bindable]
		/**
		 * The bandwidth property of the camera.
		 */
		public function get camBandwidth():Number
		{
			return _camBandwidth;
		}
		public function set camBandwidth(value:Number):void
		{
			_camBandwidth = value;
			if (_camera != null)
				_camera.setQuality(_camBandwidth, _camQuality);
		}
		
		[Bindable]
		/**
		 * The quality property of the camera.
		 */
		public function get camQuality():Number
		{
			return _camQuality;
		}
		public function set camQuality(value:Number):void
		{
			_camQuality = value;
			if (_camera != null)
				_camera.setQuality(_camBandwidth, _camQuality);
		}

		[Bindable]
		/**
		 * The keyFrameInterval property of the camera.
		 */
		public function get camKeyFrameInterval():Number
		{
			return _camKeyFrameInterval;
		}
		public function set camKeyFrameInterval(value:Number):void
		{
			_camKeyFrameInterval = value;
			if (_camera != null)
				_camera.setKeyFrameInterval(value);
		}
		
		[Bindable]
		/**
		 * The loopback property of the camera.
		 */
		public function get camLoopback():Boolean
		{
			return _camLoopback;
		}
		public function set camLoopback(value:Boolean):void
		{
			_camLoopback = value;
			if (_camera != null)
				_camera.setLoopback(value);
		}
		
		//--------------------------------------
		// PRIVATE METHODS
		//--------------------------------------
		
		// update the global soundmixer based on the current speaker volume.
		private function updateMixer():void
		{
			var transform:SoundTransform = new SoundTransform();
			transform.volume = (_speakerActive ? _speakerVolume : 0);
			SoundMixer.soundTransform = transform;
		}
		
		private function cameraStatusHandler(event:StatusEvent):void
		{
			var oldValue:Boolean = _camActive;
			if (event.code != null && event.code.toLowerCase().indexOf("unmuted") >= 0) {
				_camActive = true;
			}
			else {
				_camActive = false;
			}
			if (oldValue != _camActive) {
				dispatchEvent(new PropertyChangeEvent(PropertyChangeEvent.PROPERTY_CHANGE, false, false, PropertyChangeEventKind.UPDATE, "camActive", oldValue, _camActive, this)); 
			}
		}
		
		private function micStatusHandler(event:StatusEvent):void
		{
			var oldValue:Boolean = _micActive;
			if (event.code != null && event.code.toLowerCase().indexOf("unmuted") >= 0) {
				startMicLevelTimer();
				_micActive = true;
			}
			else {
				stopMicLevelTimer();
				_micActive = false;
			}
			if (oldValue != _micActive) {
				dispatchEvent(new PropertyChangeEvent(PropertyChangeEvent.PROPERTY_CHANGE, false, false, PropertyChangeEventKind.UPDATE, "micActive", oldValue, _micActive, this)); 
			}
		}
		
		private function startMicLevelTimer():void
		{
			if (_micLevelTimer == null) {
				_micLevelTimer = new Timer(100, 0);
				_micLevelTimer.addEventListener(TimerEvent.TIMER, micLevelTimerHandler, false, 0, true);
				_micLevelTimer.start();
			}
		}
		
		private function stopMicLevelTimer():void
		{
			if (_micLevelTimer != null) {
				_micLevelTimer.stop();
				_micLevelTimer = null;
			}
		}
		
		private function micLevelTimerHandler(event:TimerEvent):void
		{
			micLevel =  (_mic != null && !_mic.muted && _mic.activityLevel >= 0) ? _mic.activityLevel / 100 : 0;
		}
		
		//
		// Recording related code
		//
		
		private var _record:Record = null;
		
		private function startRecording():void
		{
			if (_record != null)
				_record.close();
			_record = new Record();
			_record.user = this as User;
			_record.addEventListener("open", recordOpenHandler, false, 0, true);
			_record.addEventListener("close", recordCloseHandler, false, 0, true);
			_record.open();
		}
		
		private function stopRecording():void
		{
			if (_record != null)
				_record.close();
		}
		
		private function recordOpenHandler(event:Event):void
		{
			// nothing
		}
		
		private function recordCloseHandler(event:ErrorEvent):void
		{
			if (_record != null)
				_record.close();
			if (recording) 
				recording = false;
		}
	}
}
