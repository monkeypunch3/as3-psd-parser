package com.durej.PSDParser {
	
	import com.durej.PSDParser.Descriptor;
	
	import flash.utils.ByteArray;
	
	public class TextElement {
		
		public function TextElement(stream:ByteArray) {
			var i:int;
			var index:int;
			var len:int;
			var name:String;
			var results:Array;
			
			version = stream.readShort();
			parseTransformInfo(stream);
			
			textVersion = stream.readShort();
			descriptorVersion = stream.readInt();
			textData = new Descriptor(stream).parse();
			textValue = textData['Txt '];
			engineData = parseEngineData(textData.EngineData);
			
			warpVersion = stream.readShort();
			descriptorVersion = stream.readInt();
			warpData = new Descriptor(stream).parse();
			results = [];
			
			for (index = i = 0, len = COORDS_VALUE.length; i < len; index = ++i) {
				name = COORDS_VALUE[index];
				results.push(coords[name] = stream.readInt());
			}
		}
		
		public var version:int; // 1
		public var transform:Object = {};
		public var textVersion:int; // 50
		public var descriptorVersion:int; // 16
		public var textData:Object;
		public var textValue:Object;
		public var engineData:Object;
		public var warpVersion:int;
		public var warpData:Object;
		public var coords:Object = {};
		
		public var TRANSFORM_VALUE:Array = ['xx', 'xy', 'yx', 'yy', 'tx', 'ty'];
		public var COORDS_VALUE:Array = ['left', 'top', 'right', 'bottom'];
		
		
		public function parseTransformInfo(stream:ByteArray):Array {
			var i:int;
			var index:int;
			var len:int;
			var name:String;
			var results:Array;
			
			results = [];
			
			for (index = i = 0, len = TRANSFORM_VALUE.length; i < len; index = ++i) {
				name = TRANSFORM_VALUE[index];
				results.push(transform[name] = stream.readDouble());
			}
			
			return results;
		}
		
		/**
		 * TODO: Parse text markup
		 **/
		public function parseEngineData(object:Object):Object {
			return object;
		}
	}

}