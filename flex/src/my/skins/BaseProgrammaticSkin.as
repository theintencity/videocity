package my.skins
{
	import mx.skins.ProgrammaticSkin;
	
	public class BaseProgrammaticSkin extends ProgrammaticSkin
	{
		//--------------------------------------
		// PROTECTED METHODS
		//--------------------------------------
		
		/**
		 * Get the style or default value if not supplied.
		 */
		protected function getDefaultStyle(prop:String, def:Object):Object
		{
			var result:Object = getStyle(prop);
			return (result != null ? result : def);
		}
	}
}