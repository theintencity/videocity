package my.skins
{
	/**
	 * Skin to display a microphone icon. In the selected state it also puts a red no-access on top to 
	 * indicate that the microphone is muted.
	 */
	public class MicButtonSkin extends ShinyButtonSkin
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
			graphics.drawEllipse(w*5/12, h/4, w/6, h*3/8);
			graphics.endFill();
			
			graphics.moveTo(w/3, h*3/8);
			graphics.lineTo(w/3, h*2/3);
			graphics.curveTo(w/2, h*5/6, w*2/3, h*2/3);
			graphics.lineTo(w*2/3, h*3/8);
			
			if (name != null && name.substr(0, 8) != "selected") {
				graphics.lineStyle(1, 0xff0000);
				var r:Number = Math.min(w, h)/3;
				graphics.drawCircle(w/2, h/2, r);
				graphics.moveTo(w/2+r/Math.SQRT2, r/Math.SQRT2);
				graphics.lineTo(r/Math.SQRT2, h/2+r/Math.SQRT2);
			}
		}
	}
}
