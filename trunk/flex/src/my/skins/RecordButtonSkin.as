package my.skins
{
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	
	/**
	 * Skin to display a record button, using a circle. The color of the button changes based on the 
	 * selection state. The button also blinks in the selected state.
	 */
	public class RecordButtonSkin extends ShinyButtonSkin
	{
		private var _timer:Timer;
		
		//--------------------------------------
		// PROTECTED METHODS
		//--------------------------------------
		
		override protected function updateDisplayList(w:Number, h:Number):void
		{
			super.updateDisplayList(w, h);
			
			var color:uint = getDefaultStyle("color", 0x000000) as uint;
			var draw:Boolean = false;
			if (name != null && name.substr(0, 8) == "selected") {
				color = getDefaultStyle("selectedColor", 0xff0000) as uint;
				if (_timer == null) {
//					_timer = new Timer(1000, 0);
//					_timer.addEventListener(TimerEvent.TIMER, timerHandler, false, 0, true);
//					_timer.start();
					draw = true;
				}
			}
			else {
				draw = true;
//				if (_timer != null) {
//					_timer.stop();
//					_timer = null;
//				}
			}
			
			if (draw) {
				graphics.lineStyle(1, color);
				graphics.beginFill(color);
				graphics.drawCircle(w/2, h/2, Math.min(w, h)/4);
				graphics.endFill();
			}
		}
		
//		private function timerHandler(event:TimerEvent):void
//		{
//			if (_timer != null) {
//				graphics.clear();
//				super.updateDisplayList(width, height);
//				if (_timer.currentCount % 2) {
//					var color:uint = getDefaultStyle("selectedColor", 0xff0000) as uint;
//					graphics.lineStyle(1, color);
//					graphics.beginFill(color);
//					graphics.drawCircle(width/2, height/2, Math.min(width, height)/4);
//					graphics.endFill();
//				}
//			}
//		}
	}
}
