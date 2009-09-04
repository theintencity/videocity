package my.skins
{
	
	import mx.controls.Button;
	import mx.skins.ProgrammaticSkin;
	
	/**
	 * Skin to display the drag button on the bottom right corner of a draggable component.
	 */
	public class DragButtonSkin extends ProgrammaticSkin
	{
		//--------------------------------------
		// PROTECTED VARIABLES
		//--------------------------------------
		
		protected var _button:Button;

		//--------------------------------------
		// PROTECTED METHODS
		//--------------------------------------
		
		protected override function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			graphics.clear();
			
			graphics.beginFill(0xFFFFFF, 0);
			graphics.drawRect(0, 0, unscaledWidth, unscaledHeight);
			graphics.endFill();
			
			graphics.lineStyle(1, 0x818181, 1, true);
			
			graphics.moveTo(0, unscaledHeight);
			graphics.lineTo(unscaledWidth, 0);
			
			graphics.moveTo(unscaledWidth * (1/3), unscaledHeight);
			graphics.lineTo(unscaledWidth, unscaledHeight * (1/3));
			
			graphics.moveTo(unscaledWidth * (2/3), unscaledHeight);
			graphics.lineTo(unscaledWidth, unscaledHeight * (2/3));
		}
	}
}