package my.skins
{
	import flash.display.Graphics;
	import flash.events.Event;
	import flash.events.MouseEvent;
	
	import mx.core.UIComponent;
	
	/**
	 * Dispatched when the user clicks on the component to request a change in volume level property.
	 * The level property of the VolumeSlider is used to represent the level.
	 */
	[Event(name="change", type="flash.events.Event")]
	
	/**
	 * The VolumeSlider component displays a volume slider. This should be moved to the controls directory
	 * but since other Volume components are Skins, I have kept it here.
	 */
	public class VolumeSlider extends UIComponent
	{
		//--------------------------------------
		// PRIVATE VARIABLES
		//--------------------------------------
		
		// the level of the slider
		private var _level:Number = 0.5;
		
		//--------------------------------------
		// CONSTRUCTOR
		//--------------------------------------
		
		public function VolumeSlider()
		{
			super();
			addEventListener(MouseEvent.CLICK, mouseClickHandler, false, 0, true);
		}
		
		//--------------------------------------
		// GETTERS/SETTERS
		//--------------------------------------
		
		[Bindable]
		/**
		 * The volume level property is updated when user clicks on the component.
		 * It can also be set by the application. The value is between 0 and 1.
		 */
		public function get level():Number
		{
			return _level;
		}
		public function set level(value:Number):void
		{
			if (value >= 0 && value <= 1.0)
				_level = value;
		}
		
		//--------------------------------------
		// PROTECTED METHODS
		//--------------------------------------
		
		override protected function updateDisplayList(w:Number, h:Number):void
		{
			
			var g:Graphics = graphics;
			g.clear();
			
			var borderThickness:uint = getStyle("borderThickness") != null ? getStyle("borderThickness") : 0;
			var borderColor:uint     = getStyle("borderColor") != null ? getStyle("borderColor") : 0xb7babc;
			var fillColors:Array	 = getStyle("fillColors") != null ? getStyle("fillColors") : [0xcacaca, 0xc0c0c0];
			var backgroundAlpha:Number = getStyle("backgroundAlpha") != null ? getStyle("backgroundAlpha") : 1.0;
			var color:uint = getStyle("color") != null ? getStyle("color") : 0x000000;
			if (!enabled) 
				color = getStyle("disabledColor") != null ? getStyle("disabledColor") : 0x202020;
				
			ShinyButtonSkin.drawShinySkin(g, fillColors, w, h, borderThickness, borderColor, backgroundAlpha);
			
			g.lineStyle(1, color);
			g.moveTo(2, h*3/4);
			g.lineTo(w-2, h/4);
			g.lineTo(w-2, h*3/4);
			g.lineTo(2, h*3/4);
			
			g.beginFill(color);
			g.moveTo(2, h*3/4);
			g.lineTo(2+(w-4)*level, h*3/4-h/2*level);
			g.lineTo(2+(w-4)*level, h*3/4);
			g.lineTo(2, h*3/4);
			g.endFill();
		}
		
		//--------------------------------------
		// PRIVATE METHODS
		//--------------------------------------
		
		private function mouseClickHandler(event:MouseEvent):void
		{
			if (this.enabled && this.width > 0) {
				level = this.mouseX / this.width;
				updateDisplayList(this.unscaledWidth, this.unscaledHeight);
				dispatchEvent(new Event(Event.CHANGE));
			}
		}
	}
}
