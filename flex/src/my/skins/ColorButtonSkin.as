package my.skins
{
	/**
	 * Skin to display a color button. It shows 3-4 color boxes in the button.
	 */
	public class ColorButtonSkin extends ShinyButtonSkin
	{
		//--------------------------------------
		// PROTECTED METHODS
		//--------------------------------------
		
		override protected function updateDisplayList(w:Number, h:Number):void
		{
			super.updateDisplayList(w, h);
			
			var color:uint = getDefaultStyle("color", 0x000000) as uint;
			
			graphics.lineStyle(1, color);
			graphics.drawRect(w/4, h/4, w/2, h/2);
			
			graphics.beginFill(0xff0000);
			graphics.drawRect(w/4, h/4, w/4, h/4);
			graphics.endFill();
			
			graphics.beginFill(0x00ff00);
			graphics.drawRect(w/2, h/4, w/4, h/4);
			graphics.endFill();
			
			graphics.beginFill(0x0000ff);
			graphics.drawRect(w/4, h/2, w/4, h/4);
			graphics.endFill();
		}
	}
}
