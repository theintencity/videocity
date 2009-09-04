package my.skins
{
	/**
	 * Skin to display a right arrow button.
	 */
	public class RightButtonSkin extends ShinyButtonSkin
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
			graphics.moveTo(w*3/4+2, h/2);
			graphics.lineTo(w*3/5, h/4);
			graphics.lineTo(w*3/5, h*2/5-1);
			graphics.lineTo(w*2/5, h*2/5-1);
			graphics.lineTo(w*2/5, h*3/5);
			graphics.lineTo(w*3/5, h*3/5);
			graphics.lineTo(w*3/5, h*3/4);
			graphics.lineTo(w*3/4+2, h/2);
			graphics.endFill();
			
			graphics.moveTo(w/4+2, h/4);
			graphics.lineTo(w/4+2, h*3/4);
			graphics.moveTo(w/4, h/4);
			graphics.lineTo(w/4, h*3/4);
		}
	}
}
