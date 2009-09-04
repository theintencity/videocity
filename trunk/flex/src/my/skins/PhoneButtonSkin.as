package my.skins
{
	import flash.display.Graphics;
	
	/**
	 * Skin to display a phone.
	 */
	public class PhoneButtonSkin extends ShinyButtonSkin
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
			
			g.beginFill(color);
			g.moveTo(w/2, h/4);
			g.curveTo(w/4, h/4, w/4, h/2);
			g.curveTo(w/4, h*3/4, w/2, h*3/4);
			g.lineTo(w/2, h*3/4-3);
			g.lineTo(w/2-3, h*3/4-3);
			g.lineTo(w/2-3, h/4+3);
			g.lineTo(w/2, h/4+3);
			g.endFill();
		}
	}
}
