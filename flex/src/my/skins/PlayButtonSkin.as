package my.skins
{
	/**
	 * Skin to display a play/pause button. Depending on the selected state it displays a play (unselected)
	 * or pause (selected) icon.
	 */
	public class PlayButtonSkin extends ShinyButtonSkin
	{
		//--------------------------------------
		// PROTECTED METHODS
		//--------------------------------------
		
		override protected function updateDisplayList(w:Number, h:Number):void
		{
			super.updateDisplayList(w, h);
			
			var color:uint = getDefaultStyle("color", 0x000000) as uint;
			
			if (name != null && name.substr(0, 8) != "selected") {
				graphics.lineStyle(1, color);
				graphics.beginFill(color);
				graphics.moveTo(w/4, h/4);
				graphics.lineTo(w*3/4, h/2);
				graphics.lineTo(w/4, h*3/4);
				graphics.lineTo(w/4, h/4);
				graphics.endFill();
			}
			else {
				graphics.lineStyle(1, color);
				graphics.beginFill(color);
				graphics.moveTo(w/4, h/4);
				graphics.lineTo(w*4/10, h/4);
				graphics.lineTo(w*4/10, h*3/4);
				graphics.lineTo(w/4, h*3/4);
				graphics.lineTo(w/4, h/4);
				graphics.endFill();
				
				graphics.beginFill(color);
				graphics.moveTo(w*5/8, h/4);
				graphics.lineTo(w*3/4, h/4);
				graphics.lineTo(w*3/4, h*3/4);
				graphics.lineTo(w*6/10, h*3/4);
				graphics.lineTo(w*6/10, h/4);
				graphics.endFill();
			}
		}
	}
}
