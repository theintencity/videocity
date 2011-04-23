package my.skins
{
	/**
	 * Skin to display a pointer icon.
	 */
	public class PointerButtonSkin extends BaseProgrammaticSkin
	{
		//--------------------------------------
		// PROTECTED METHODS
		//--------------------------------------
		
		override protected function updateDisplayList(w:Number, h:Number):void
		{
			super.updateDisplayList(w, h);
			
			var borderColor:uint = getDefaultStyle("borderColor", 0xffffff) as uint;
			var color:uint = getDefaultStyle("color", 0x000000) as uint;
			var borderThickness:uint = getDefaultStyle("borderThickness", 2) as uint;
			
			if (borderThickness > 0)
				graphics.lineStyle(borderThickness, borderColor);
			
			graphics.beginFill(color);
			
			graphics.moveTo(0, 0);
			graphics.lineTo(w*2/3, h-1);
			graphics.lineTo(w*2/3, h*2/3);
			graphics.lineTo(w-1, h*2/3);
			graphics.lineTo(0, 0);
		}
	}
}
