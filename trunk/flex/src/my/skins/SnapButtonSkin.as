package my.skins
{
	/**
	 * Skin to represent a still camera icon.
	 */
	public class SnapButtonSkin extends ShinyButtonSkin
	{
		//--------------------------------------
		// PROTECTED METHODS
		//--------------------------------------
		
		override protected function updateDisplayList(w:Number, h:Number):void
		{
			super.updateDisplayList(w, h);
			
			var color:uint = getDefaultStyle("color", 0x000000) as uint;
			var fillColors:Array = getDefaultStyle("fillColors", [0xcacaca, 0xb8b8b8]) as Array;
			
			graphics.lineStyle(1, color);
			graphics.beginFill(color);
			graphics.moveTo(3, h/3);
			graphics.lineTo(w-4, h/3);
			graphics.lineTo(w-4, h*2/3);
			graphics.lineTo(3, h*2/3);
			graphics.lineTo(3, h/3);
			graphics.endFill();
			
			graphics.beginFill(fillColors[0]);
			graphics.drawCircle(w/2, h/2, Math.min(w, h)/4);
			graphics.drawCircle(w/2, h/2, Math.min(w, h)/4-2);
			graphics.endFill();
		}
	}
}
