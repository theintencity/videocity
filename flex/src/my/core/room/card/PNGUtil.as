package my.core.room.card
{
	import flash.utils.ByteArray;
	
	/**
	 * Utility class to edit PNG files.
	 */
	public class PNGUtil
	{
		public function PNGUtil()
		{
			initializeCRCTable();
		}

	    /**
	     *  @private
		 *  Used for computing the cyclic redundancy checksum
		 *  at the end of each chunk.
	     */
	    private var crcTable:Array;
	    /**
		 *  @private
		 */
		private function initializeCRCTable():void
		{
	        crcTable = [];
	
	        for (var n:uint = 0; n < 256; n++)
	        {
	            var c:uint = n;
	            for (var k:uint = 0; k < 8; k++)
	            {
	                if (c & 1)
	                    c = uint(uint(0xedb88320) ^ uint(c >>> 1));
					else
	                    c = uint(c >>> 1);
	             }
	            crcTable[n] = c;
	        }
		}

	    /**
		 *  @private
		 */
		public function writeChunk(png:ByteArray, type:uint, data:ByteArray):void
	    {
	        // Write length of data.
	        var len:uint = 0;
	        if (data)
	            len = data.length;
			png.writeUnsignedInt(len);
	        
			// Write chunk type.
			var typePos:uint = png.position;
			png.writeUnsignedInt(type);
	        
			// Write data.
			if (data)
	            png.writeBytes(data);
	
	        // Write CRC of chunk type and data.
			var crcPos:uint = png.position;
	        png.position = typePos;
	        var crc:uint = 0xFFFFFFFF;
	        for (var i:uint = typePos; i < crcPos; i++)
	        {
	            crc = uint(crcTable[(crc ^ png.readUnsignedByte()) & uint(0xFF)] ^
						   uint(crc >>> 8));
	        }
	        crc = uint(crc ^ uint(0xFFFFFFFF));
	        png.position = crcPos;
	        png.writeUnsignedInt(crc);
	    }
	}
}