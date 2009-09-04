package my.skins
{
	import flash.display.Graphics;
	
	/**
	 * The generic base class for shiny buttons. The skin is displayed with two colors extracted from the 
	 * fillColors style.
	 */
	public class ShinyButtonSkin extends BaseProgrammaticSkin
	{
		//--------------------------------------
		// PROTECTED METHODS
		//--------------------------------------
		
		/**
		 * update the display list based on the style.
		 */
		protected override function updateDisplayList(w:Number, h:Number):void
		{
			var borderThickness:uint = getDefaultStyle("borderThickness", 0) as uint;
			var borderColor:uint     = getDefaultStyle("borderColor", 0xb7babc) as uint;
			var fillColors:Array	 = getDefaultStyle("fillColors", [0xcacaca, 0xc0c0c0]) as Array;
			var backgroundAlpha:Number = getDefaultStyle("backgroundAlpha", 1.0) as Number;
			var temp:uint;
			
			switch (name) {
				case "upSkin":
				case "selectedUpSkin":
					// no change
					break;
					
				case "overSkin":
				case "selectedOverSkin":
					fillColors = getDefaultStyle("fillOverColors", [fillColors[1], fillColors[1]]) as Array;
					break;
					
				case "downSkin":
				case "selectedDownSkin":
					fillColors = getDefaultStyle("fillDownColors", [fillColors[1], fillColors[0]]) as Array;
					break;
					
				case "disabledSkin":
				case "disabledDownSkin":
				case "selectedDisabledSkin":
					fillColors = getDefaultStyle("fillDownColors", [fillColors[0], fillColors[0]]) as Array;
					break;
			}
			
			drawShinySkin(graphics, fillColors, w, h, borderThickness, borderColor, backgroundAlpha);
		}
		
		//--------------------------------------
		// STATIC METHODS
		//--------------------------------------
		
		/**
		 * The core function is public so that other styles not a sub-class can use it too.
		 */
		public static function drawShinySkin(graphics:Graphics, fillColors:Array, w:Number, h:Number, borderThickness:int, borderColor:uint, backgroundAlpha:Number):void
		{
			var lightColor:uint      = fillColors[0];
			var darkColor:uint       = fillColors[1];
			
			graphics.clear();
			
			if (borderThickness > 0) {
				graphics.beginFill(borderColor);
				graphics.drawRect(0, 0, w, h);
				graphics.endFill();
			}
			
			var half:int = Math.ceil((h-2)/2);
			graphics.beginFill(lightColor, backgroundAlpha);
			graphics.drawRect(borderThickness, borderThickness, w-2*borderThickness, half - borderThickness);
			graphics.endFill();
			
			graphics.beginFill(darkColor, backgroundAlpha);
			graphics.drawRect(borderThickness, half, w-2*borderThickness, h - half - 2*borderThickness);
			graphics.endFill();
		}
	}
}