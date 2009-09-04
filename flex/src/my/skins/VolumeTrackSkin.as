package my.skins
{
	import flash.display.Graphics;
	
	/**
	 * The track skin of the volume control slider.
	 */
	public class VolumeTrackSkin extends ShinyButtonSkin
	{
		//--------------------------------------
		// PUBLIC METHODS
		//--------------------------------------
		
		override public function get height():Number
		{
			return 20;
		}
		
		//--------------------------------------
		// PROTECTED METHODS
		//--------------------------------------
		
		override protected function updateDisplayList(w:Number, h:Number):void
		{
			var g:Graphics = graphics;
			super.updateDisplayList(w, h);
			
			trace(w, h);
			var color:uint = getDefaultStyle("color", 0x000000) as uint;
			g.lineStyle(1, color);
			g.moveTo(2, h*3/4);
			g.lineTo(w-2, h/4);
			g.lineTo(w-2, h*3/4);
			g.lineTo(2, h*3/4);
		}
	}
}
