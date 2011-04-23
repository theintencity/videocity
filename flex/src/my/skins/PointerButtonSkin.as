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
			
			var color:uint = getDefaultStyle("color", 0xffffff) as uint;
			
			graphics.lineStyle(1, color);
			graphics.beginFill(color);
			
			graphics.moveTo(0, 0);
			graphics.lineTo(w*2/3, h-1);
			graphics.lineTo(w-1, h*2/3);
			graphics.lineTo(0, 0);
		}
	}
}
