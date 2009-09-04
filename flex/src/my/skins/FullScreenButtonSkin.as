package my.skins
{
	/**
	 * Skin to display a full screen button. In the selected state the view changes to indicate restore 
	 * of full screen.
	 */
	public class FullScreenButtonSkin extends ShinyButtonSkin
	{
		//--------------------------------------
		// PROTECTED METHODS
		//--------------------------------------
		
		override protected function updateDisplayList(w:Number, h:Number):void
		{
			super.updateDisplayList(w, h);
			
			var color:uint = getDefaultStyle("color", 0x000000) as uint;
			graphics.lineStyle(1, color);
			
			graphics.moveTo(w*3/4-3, h/4+1);
			graphics.lineTo(w/4, h/4+1);
			graphics.lineTo(w/4, h*3/4);
			graphics.lineTo(w*3/4-1, h*3/4);
			graphics.lineTo(w*3/4-1, h/4+3);
			graphics.moveTo(w*3/4-5, h/4+5);
			graphics.lineTo(w*3/4+1, h/4-1);
			
			if (name != null && name.substr(0, 8) != "selected") {
				graphics.moveTo(w*3/4-3, h/4-1);
				graphics.lineTo(w*3/4+1, h/4-1);
				graphics.lineTo(w*3/4+1, h/4+3);
			}
			else {
				graphics.moveTo(w*3/4-5, h/4+2);
				graphics.lineTo(w*3/4-5, h/4+5);
				graphics.lineTo(w*3/4-2, h/4+5);
			}
		}
	}
}
