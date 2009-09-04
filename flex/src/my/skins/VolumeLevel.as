package my.skins
{
	import flash.display.Graphics;
	
	import mx.core.UIComponent;
	
	/**
	 * The volume level display component. It shows a small triangle representing the current volume.
	 * The level property indicates the currently displayed volume level.
	 */
	public class VolumeLevel extends UIComponent
	{
		//--------------------------------------
		// PRIVATE VARIABLES
		//--------------------------------------
		
		// the level of the indicator
		private var _level:Number = 0.5;
		
		//--------------------------------------
		// CONSTRUCTOR
		//--------------------------------------
		
		public function VolumeLevel()
		{
			super();
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
			if (value >= 0 && value <= 1.0) {
				_level = value;
				updateDisplayList(unscaledWidth, unscaledHeight);
			}
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
			var inactiveColor:uint   = getStyle("inactiveColor") != null ? getStyle("inactiveColor") : Math.max(fillColors[1] - 0x050505, 0x000000);
			
			ShinyButtonSkin.drawShinySkin(g, fillColors, w, h, borderThickness, borderColor, backgroundAlpha);
		
			g.lineStyle(1, color);
			for (var i:int = 0; i<(w-5); i+= 6) {
				var active:Boolean = enabled && (level > i/w);
				g.lineStyle(1, active ? color : inactiveColor);
				if (active)
					g.beginFill(level > i/w ? color : fillColors[1]);
				g.moveTo(i, h/4);
				g.lineTo(i+4, h/4);
				g.lineTo(i+4, h*3/4);
				g.lineTo(i, h*3/4);
				g.lineTo(i, h/4);
				if (active)
					g.endFill();
			}	
		}
	}
}
