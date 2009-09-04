package my.skins
{
	import mx.skins.ProgrammaticSkin;
	
	/**
	 * Skin to display a no-access button.
	 */
	public class NoAccessSkin extends ShinyButtonSkin // ProgrammaticSkin
	{
		//--------------------------------------
		// PROTECTED METHODS
		//--------------------------------------
		
		override protected function updateDisplayList(w:Number, h:Number):void
		{
			super.updateDisplayList(w, h);
			
			var color:uint = getStyle("color") != null ? getStyle("color") as uint : 0xff0000;
			var alpha:Number = getStyle("alpha") != null ? getStyle("alpha") as Number : 1.0;
			var r:int = Math.max(Math.min(w, h)/2.5-3, 1);
			var t:int = Math.max(2*(r/3-r/4), 2);
			
			//graphics.clear();
			graphics.lineStyle(t, color, alpha);
			graphics.drawCircle(w/2, h/2, r);
			graphics.moveTo(w/2+(r-t)/Math.SQRT2, h/2-(r-t)/Math.SQRT2);
			graphics.lineTo(w/2-(r-t)/Math.SQRT2, h/2+(r-t)/Math.SQRT2);
		}
	}
}
