package my.skins
{
	import flash.display.Graphics;
	
	import mx.controls.HSlider;
	
	/**
	 * The highlight portion of the volume skin.
	 */
	public class VolumeHighlightSkin extends BaseProgrammaticSkin
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
			g.clear();
			
			var r:Number = w/HSlider(parent.parent).width;
			var color:uint = getDefaultStyle("color", 0x000000) as uint;
			g.beginFill(color);
			g.lineStyle(1, color);
			g.moveTo(2, h*3/4);
			g.lineTo(w-2, h/2*(1-r));
			g.lineTo(w-2, h*3/4);
			g.lineTo(2, h*3/4);
			g.endFill();
		}
	}
}
