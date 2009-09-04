package my.skins
{
	import flash.display.Graphics;
	
	/**
	 * The thumb skin of the volume slider is displayed as a small line.
	 */
	public class VolumeThumbSkin extends BaseProgrammaticSkin
	{
		//--------------------------------------
		// PROTECTED METHODS
		//--------------------------------------
		
		override protected function updateDisplayList(w:Number, h:Number):void
		{
			var g:Graphics = graphics;
			
			g.clear();
			var color:uint = getDefaultStyle("color", 0x000000) as uint;
			g.lineStyle(1, color);
			g.moveTo(w/2, 0);
			g.lineTo(w/2, h);
		}
		
		//--------------------------------------
		// PUBLIC METHODS
		//--------------------------------------
		
		override public function get measuredHeight():Number
		{
			return 20;
		}
		override public function get measuredWidth():Number
		{
			return 1;
		}
	}
}
