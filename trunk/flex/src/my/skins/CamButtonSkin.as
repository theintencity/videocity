package my.skins
{
	import flash.display.Graphics;
	
	/**
	 * Skin to display a video camera icon. In the selected state, a red colored no-access is drawn on top
	 * to indicate that the camera is off.
	 */
	public class CamButtonSkin extends ShinyButtonSkin
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
			g.moveTo(w/4, h/3);
			g.lineTo(w*2/3, h/3);
			g.lineTo(w*2/3, h/2);
			g.lineTo(w*5/6, h/3);
			g.lineTo(w*5/6, h*2/3);
			g.lineTo(w*2/3, h/2);
			g.lineTo(w*2/3, h*2/3);
			g.lineTo(w/4, h*2/3);
			g.lineTo(w/4, h/3);
			g.endFill();
			
			if (name != null && name.substr(0, 8) != "selected") {
				g.lineStyle(1, 0xff0000);
				var r:Number = Math.min(w, h)/3;
				g.drawCircle(w/2, h/2, r);
				g.moveTo(w/2+r/Math.SQRT2, r/Math.SQRT2);
				g.lineTo(r/Math.SQRT2, h/2+r/Math.SQRT2);
			}
		}
	}
}
