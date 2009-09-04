package my.core {
	
	import flash.utils.Proxy;
	import flash.utils.flash_proxy;
	import my.controls.Prompt;
	
	/**
	 * The object assigned to NetConnection's client property, so that the server can invoke callbacks
	 * such as added and removed on the client.
	 */
	dynamic public class CallbackObject extends Proxy
	{
		//--------------------------------------
		// PRIVATE VARIABLES
		//--------------------------------------
		
		private var target:Object;
		private var methods:Array;
		
		//--------------------------------------
		// CONSTRUCTOR
		//--------------------------------------
		
		public function CallbackObject(target:Object, methods:Array=null)
		{
			this.target = target;
			this.methods = methods;
		}
		
		//--------------------------------------
		// PUBLIC METHODS
		//--------------------------------------
		
		public function close():void
		{
			this.target = null;
		}
		
		override flash_proxy function callProperty(methodName:*, ... args):* 
		{
			if (target != null) {
				if (methods == null || methods.indexOf(methodName.toString()) >= 0) {
					try {
						target[methodName.toString()].apply(target, args);
					}
					catch (e:Error) {
						Prompt.show(e.toString(), "Exception in RPC");
						trace("Exception in method invokation " + e.toString());
					}
				}
				else {
					trace("cannot invoke " + methodName + " as it is not supported in target's methods");
				}
			}
			else {
				trace("cannot invoke " + methodName + " as target is null");
			}
		}

		override flash_proxy function getProperty(name:*):* 
		{
			if (target != null && (methods == null || methods.indexOf(name.toString()) >= 0))
				return target[name];
			else
				return undefined;
		}
	}
}
