package my.skins
{
	import flash.display.Graphics;
	
	/**
	 * Skin to display a layout button.
	 */
	public class LayoutButtonSkin extends ShinyButtonSkin
	{
		//--------------------------------------
		// PROTECTED METHODS
		//--------------------------------------
		
		override protected function updateDisplayList(w:Number, h:Number):void
		{
			super.updateDisplayList(w, h);
			
			var color:uint = getDefaultStyle("color", 0x000000) as uint;
			
			var g:Graphics = graphics;
			g.lineStyle(1, color);
			
			g.drawRect(w/4, h/4, w/6, h/6);
			g.drawRect(w/2, h/4, w/6, h/6);
			g.drawRect(w/4, h/2, w/6, h/6);
			g.drawRect(w/2, h/2, w/6, h/6);
		}
	}
}
