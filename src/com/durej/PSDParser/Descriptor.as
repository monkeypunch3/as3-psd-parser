package com.durej.PSDParser
{
	import flash.utils.ByteArray;

	public class Descriptor {

		public function Descriptor(file:ByteArray) {
			this.file = file;
			this.data = {};
		}
		
		public var file:ByteArray;
		public var data:Object;
		public var position:int;
		
		public function parse():Object {
			var i:int;
			var j:int;
			var id:String;
			var numItems:int;
			var ref:Object;
			var ref1:Object;
			var value:String;
			
			data["class"] = parseClass();
			numItems = file.readInt();
			
			for (i = j = 0, ref = numItems; 0 <= ref ? j < ref : j > ref; i = 0 <= ref ? ++j : --j) {
				ref1 = parseKeyItem();
				id = ref1[0];
				value = ref1[1];
				data[id] = value;
			}
			return data;
		}
		
		public function parseClass():Object {
			return {
				name: readUnicodeString(),
				id: parseId()
			}
		}
		
		public function parseId():String {
			var len:int;
			
			len = file.readInt();
			if (len === 0) {
				return readString(4);
			} else {
				return readString(len);
			}
		}
		
		public function parseKeyItem():Array {
			var id, value;
			id = parseId();
			value = parseItem();
			return [id, value];
		}
		
		public function parseItem(type:String = null):Object {
			if (type == null) {
				type = null;
			}
			if (type == null) {
				type = readString(4);
			}
			
			switch (type) {
				case 'bool':
					return parseBoolean();
				case 'type':
				case 'GlbC':
					return parseClass();
				case 'Objc':
				case 'GlbO':
					return new Descriptor(file).parse();
				case 'doub':
					return parseDouble();
				case 'enum':
					return parseEnum();
				case 'alis':
					return parseAlias();
				case 'Pth':
					return parseFilePath();
				case 'long':
					return parseInteger();
				case 'comp':
					return parseLargeInteger();
				case 'VlLs':
					return parseList();
				case 'ObAr':
					return parseObjectArray();
				case 'tdta':
					return parseRawData();
				case 'obj ':
					return parseReference();
				case 'TEXT':
					return readUnicodeString();
				case 'UntF':
					return parseUnitDouble();
				case 'UnFl':
					return parseUnitFloat();
			}
			
			return null;
		}
		
		public function parseBoolean():Boolean {
			return file.readBoolean();
		}
		
		public function parseDouble():Object {
			return file.readDouble();
		}
		
		public function parseInteger():int {
			return file.readInt();
		}
		
		public function parseLargeInteger():Object {
			return readLongLong();
		}
		
		public function parseIdentifier():Object {
			return file.readInt();
		}
		
		public function parseIndex():Object {
			return file.readInt();
		}
		
		public function parseOffset():Object {
			return file.readInt();
		}
		
		public function parseProperty():Object {
			return {
				"class": parseClass(),
					id: parseId()
			}
		}
		
		public function parseEnum():Object {
			return {
				type: parseId(),
					value: parseId()
			}
		}
		
		public function parseEnumReference():Object {
			return {
				"class": parseClass(),
					type: parseId(),
					value: parseId()
			}
		}
		
		public function parseAlias():String {
			var len;
			len = file.readInt();
			return readString(len);
		}
		
		public function parseFilePath():Object {
			var len, numChars, path, pathSize, sig;
			len = file.readInt();
			sig = readString(4);
			pathSize = read('<i');
			numChars = read('<i');
			path = readUnicodeString(numChars);
			return {
				sig: sig,
				path: path
			}
		}
		
		public function parseList():Array {
			var count; 
			var i;
			var items; 
			var j;
			var ref;
			count = file.readInt();
			items = [];
			for (i = j = 0, ref = count; 0 <= ref ? j < ref : j > ref; i = 0 <= ref ? ++j : --j) {
				items.push(parseItem());
			}
			return items;
		}
		
		public function parseObjectArray():Object {
			throw "Descriptor object array not implemented yet @ " + (tell());
		}
		
		public function parseRawData():Object {
			var len;
			len = file.readInt();
			return read(len);
		}
		
		public function parseReference():Object {
			var i, items, j, numItems, ref, type, value;
			numItems = file.readInt();
			items = [];
			
			for (i = j = 0, ref = numItems; 0 <= ref ? j < ref : j > ref; i = 0 <= ref ? ++j : --j) {
				type = readString(4);
				value = (function() {
					switch (type) {
						case 'prop':
							return parseProperty();
						case 'Clss':
							return parseClass();
						case 'Enmr':
							return parseEnumReference();
						case 'Idnt':
							return parseIdentifier();
						case 'indx':
							return parseIndex();
						case 'name':
							return readUnicodeString();
						case 'rele':
							return parseOffset();
					}
				}).call(this);
				
				items.push({
					type: type,
					value: value
				});
			}
			return items;
		}
		
		public function parseUnitDouble() {
			var unit;
			var unitId;
			var value;
			
			unitId = readString(4);
			
			unit = (function() {
				switch (unitId) {
					case '#Ang':
						return 'Angle';
					case '#Rsl':
						return 'Density';
					case '#Rlt':
						return 'Distance';
					case '#Nne':
						return 'None';
					case '#Prc':
						return 'Percent';
					case '#Pxl':
						return 'Pixels';
					case '#Mlm':
						return 'Millimeters';
					case '#Pnt':
						return 'Points';
				}
			})();
			
			value = file.readDouble();
			
			return {
				id: unitId,
				unit: unit,
				value: value
			}
		}
		
		public function parseUnitFloat() {
			var unit;
			var unitId;
			var value;
			
			unitId = readString(4);
			
			unit = (function() {
				switch (unitId) {
					case '#Ang':
						return 'Angle';
					case '#Rsl':
						return 'Density';
					case '#Rlt':
						return 'Distance';
					case '#Nne':
						return 'None';
					case '#Prc':
						return 'Percent';
					case '#Pxl':
						return 'Pixels';
					case '#Mlm':
						return 'Millimeters';
					case '#Pnt':
						return 'Points';
				}
			})();
			
			value = file.readFloat();
			
			return {
				id: unitId,
				unit: unit,
				value: value
			}
		}
		
		public function tell():int {
			return position;
		}
		
		public function readLongLong():Number {
			var result:Number = 0;
			
			result += file.readUnsignedInt();
			result += file.readUnsignedInt() << 32;
			
			return result;
		}
		
		// ATTEMPT TO MATCH existing FUNCTION CALLS 
		
		public var useJSCalls:Boolean = true;
		
		public function read(length):Array {
			var i:int;
			var j:int;
			var ref;
			var results:Array;
			
			results = [];
			var cur:int = file.position;
			//var val = file.readUTFBytes(length);
			//file.position = cur;
			
			if (useJSCalls) {
				for (i = j = 0, ref = length; 0 <= ref ? j < ref : j > ref; i = 0 <= ref ? ++j : --j) {
					results.push(file[position++]);
					//results.push(file.readByte());
					//results.push(file.readByte());
					//results.push(file.position++);
					//results.push(data[position++]);
				}
			}
			else {
				for (i = j = 0, ref = length; 0 <= ref ? j < ref : j > ref; i = 0 <= ref ? ++j : --j) {
					results.push(file[position++]);
					//results.push(file.readByte());
					//results.push(file.readByte());
					//results.push(file.position++);
					//results.push(data[position++]);
				}
			}
			
			return results;
		}
		
		public function readString(length:int = -1):String {
			if (useJSCalls) {
				var val = read(length);
				val = String.fromCharCode.apply(null, val);
				//val = String.fromCharCode(val).replace(/\u0000/g, "");
				return val;
			}
			
			if (length==-1) {
				length = 1;
			}
			
			//var value = file.readMultiByte(length, "utf-8");
			var value = file.readMultiByte(length, "unicode");
			
			return value;
		}
		
		/**
		 * 
		 * http://help.adobe.com/en_US/FlashPlatform/reference/actionscript/3/charset-codes.html
		 **/
		public function readUnicodeString(length:int = -1):String {
			var currentPosition:uint = file.position;
			var value:String;
			
			if (useJSCalls) {
				if (length == -1) {
					length = file.readInt();
				}
				
				//return iconv.decode(new Buffer(this.read(length * 2)), 'utf-16be').replace(/\u0000/g, "");
				//var array:Array = read(length * 2);
				var array:Array = read(length * 4);
				value = String.fromCharCode.apply(null, array);
				value = value.replace(/\u0000/g, "");
				
				//var newPosition:uint = file.position;
				//file.position = currentPosition;
				
				//var value2 = file.readMultiByte(length, "utf-8");
				// 'utf-16be'?
				//var value2 = file.readMultiByte(length, "unicode");
				
				//value = file.readUTFBytes(int(length));
				//file.position = newPosition;
				
				return value;
			}
			
			
			value = file.readMultiByte(length, "unicode");
			//value = file.readUTFBytes(int(length));
			return value;
			/*
			if (length==-1) {
				return file.readInt() + "";
			}
			
			return file.readUTFBytes(length);
			*/
		}
		
		/*
		
		File.prototype.pos = 0;
		
		function File(data) {
			this.data = data;
		}
		
		File.prototype.tell = function() {
			return this.pos;
		};
		
		File.prototype.read = function(length) {
			var i, j, ref, results;
			results = [];
			for (i = j = 0, ref = length; 0 <= ref ? j < ref : j > ref; i = 0 <= ref ? ++j : --j) {
				results.push(this.data[this.pos++]);
			}
			return results;
		}

		File.prototype.readString = function(length) {
			return String.fromCharCode.apply(null, this.read(length)).replace(/\u0000/g, "");
		}
		
		File.prototype.readUnicodeString = function(length) {
			if (length == null) {
				length = null;
			}
			length || (length = this.readInt());
			return iconv.decode(new Buffer(this.read(length * 2)), 'utf-16be').replace(/\u0000/g, "");
		}
		*/
	}
}