package my.skins
{
	/**
	 * Skin to display a photo icon.
	 */
	public class PhotoSkin extends ShinyButtonSkin
	{
		//--------------------------------------
		// PROTECTED METHODS
		//--------------------------------------
		
		override protected function updateDisplayList(w:Number, h:Number):void
		{
			super.updateDisplayList(w, h);
			
			var color:uint = getDefaultStyle("color", 0x202020) as uint;
			var bg:uint = getDefaultStyle("backgroundColor", 0x303030) as uint;
			
			graphics.lineStyle(2, bg);
			
			graphics.beginFill(color);
			graphics.moveTo(1, h-1);
			graphics.curveTo(w/2, 0, w-1, h-1);
			graphics.lineTo(1, h-1);
			graphics.endFill();
						
			graphics.beginFill(color);
			graphics.drawCircle(w/2, h/3, Math.min(w/4, h/4));
			graphics.endFill();
			
		}
	}
}
