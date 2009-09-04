package my.skins
{
	/**
	 * Skin to represent a speaker icon. The level style controls the speaker level as well.
	 */
	public class SpeakerButtonSkin extends ShinyButtonSkin
	{
		//--------------------------------------
		// PROTECTED METHODS
		//--------------------------------------
		
		override protected function updateDisplayList(w:Number, h:Number):void
		{
			super.updateDisplayList(w, h);
			
			var color:uint = getDefaultStyle("color", 0x000000) as uint;
			
			graphics.lineStyle(1, color);
			
			graphics.beginFill(color);
			graphics.moveTo(w/4, h*4/10);
			graphics.lineTo(w/2, h*3/10);
			graphics.lineTo(w/2, h*7/10);
			graphics.lineTo(w/4, h*6/10);
			graphics.lineTo(w/4, h*4/10);
			graphics.endFill();
			
			if (name != null && name.substr(0, 8) != "selected") {
				graphics.lineStyle(1, 0xff0000);
				var r:Number = Math.min(w, h)/3;
				graphics.drawCircle(w/2, h/2, r);
				graphics.moveTo(w/2+r/Math.SQRT2, r/Math.SQRT2);
				graphics.lineTo(r/Math.SQRT2, h/2+r/Math.SQRT2);
			}
			else {
				// level is 0, 1, 2, 3
				var level:int = Math.round((getDefaultStyle("level", 0.5) as Number) * 3);
				if (level >= 1) {
					graphics.moveTo(w*6/10, h*4/10);
					graphics.curveTo(w*6/10+3, h/2, w*6/10, h*6/10);
				}
				if (level >= 2) {
					graphics.moveTo(w*7/10, h*3/10);
					graphics.curveTo(w*7/10+5, h/2, w*7/10, h*7/10);
				}
				if (level >= 3) {
					graphics.moveTo(w*8/10, h*2/10);
					graphics.curveTo(w*8/10+6, h/2, w*8/10, h*8/10);
				}
			}
		}
	}
}
