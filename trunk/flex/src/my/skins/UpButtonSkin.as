package my.skins
{
	/**
	 * Skin to represent an upward sign using a small triangle.
	 */
	public class UpButtonSkin extends ShinyButtonSkin
	{
		//--------------------------------------
		// PROTECTED METHODS
		//--------------------------------------
		
		override protected function updateDisplayList(w:Number, h:Number):void
		{
			super.updateDisplayList(w, h);
			
			var color:uint = getDefaultStyle("color", 0x000000) as uint;
			
			graphics.lineStyle(1, color);
			graphics.beginFill(color);
			graphics.moveTo(w/4, h*3/4);
			graphics.lineTo(w/2, h/4);
			graphics.lineTo(w*3/4, h*3/4);
			graphics.lineTo(w/4, h*3/4);
			graphics.endFill();
		}
	}
}
