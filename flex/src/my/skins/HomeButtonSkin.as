package my.skins
{
	/**
	 * Skin to display a home icon.
	 */
	public class HomeButtonSkin extends ShinyButtonSkin
	{
		//--------------------------------------
		// PROTECTED METHODS
		//--------------------------------------
		
		override protected function updateDisplayList(w:Number, h:Number):void
		{
			super.updateDisplayList(w, h);
			
			var color:uint = getDefaultStyle("color", 0x000000) as uint;
			var bg:uint = getDefaultStyle("backgroundColor", 0xd1d7d8) as uint;
			
			graphics.lineStyle(1, color);
			
			graphics.moveTo(w/2, h/4);
			graphics.lineTo(w/5, h/2);
			graphics.lineTo(w/4, h/2);
			graphics.lineTo(w/4, h*3/4);
			graphics.lineTo(w*3/4, h*3/4);
			graphics.lineTo(w*3/4, h/2);
			graphics.lineTo(w*4/5+1, h/2);
			graphics.lineTo(w/2, h/4);
			
			graphics.moveTo(w/3+1, h*3/4);
			graphics.lineTo(w/3+1, h/2);
			graphics.lineTo(w*2/3, h/2);
			graphics.lineTo(w*2/3, h*3/4);
		}
	}
}
