package my.skins
{
	/**
	 * Skin to display a lock icon. In the selected state it also puts a red no-access on top to 
	 * indicate that the lock is locked. Default is unlocked.
	 */
	public class LockButtonSkin extends ShinyButtonSkin
	{
		//--------------------------------------
		// PROTECTED METHODS
		//--------------------------------------
		
		override protected function updateDisplayList(w:Number, h:Number):void
		{
			super.updateDisplayList(w, h);
			
			var color:uint = getDefaultStyle("color", 0x000000) as uint;
			
			graphics.lineStyle(1, color);
			
			graphics.moveTo(w/3, h*1/2);
			graphics.curveTo(w/2, 0, w*2/3, h*1/2);

			graphics.beginFill(color);
			graphics.moveTo(w*3/4-1, h/2);
			graphics.lineTo(w/4, h/2);
			graphics.lineTo(w/4, h*3/4);
			graphics.lineTo(w*3/4-1, h*3/4);
			graphics.lineTo(w*3/4-1, h/2);
			graphics.endFill();
			
			if (name != null && name.substr(0, 8) == "selected") {
				graphics.lineStyle(1, 0xff0000);
				var r:Number = Math.min(w, h)/3;
				graphics.drawCircle(w/2, h/2, r);
				graphics.moveTo(w/2+r/Math.SQRT2, r/Math.SQRT2);
				graphics.lineTo(r/Math.SQRT2, h/2+r/Math.SQRT2);
			}
		}
	}
}
