package my.skins
{
	import flash.display.Graphics;
	
	/**
	 * Skin to represent a text icon with three horizontal lines.
	 */
	public class TextButtonSkin extends ShinyButtonSkin
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
			
			g.moveTo(w/4, h/3);
			g.lineTo(w*3/4, h/3);
			g.moveTo(w/4, h/3+3);
			g.lineTo(w*3/4, h/3+3);
			g.moveTo(w/4, h/3+6);
			g.lineTo(w*3/4, h/3+6);
		}
	}
}
