package com.durej.PSDParser 
{
	 import flash.display.BitmapData;
	 import flash.utils.ByteArray;
	 
	 
	 /**
	 * com.durej.PSDParser  
	 *  
	 * @author       Copyright (c) 2010 Slavomir Durej
	 * @version      0.1
	 *  
	 * @link         http://durej.com/
	 *
	 * Licensed under the Apache License, Version 2.0 (the "License"); 
	 * you may not use this file except in compliance with the License. 
	 * You may obtain a copy of the License at 
	 *  
	 * http://www.apache.org/licenses/LICENSE-2.0 
	 *  
	 * Unless required by applicable law or agreed to in writing, software 
	 * distributed under the License is distributed on an "AS IS" BASIS, 
	 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,  
	 * either express or implied. See the License for the specific language 
	 * governing permissions and limitations under the License. 
	 * 
	 * 
	 * 
	 * Source:
	 *  http://durej.com/?p=128
	 
	PSD FILE : 

	    Parsing canvas width x height
	    parsing file color information (number of color channels, color depth, color mode)
	    parsing file’s composite bitmap snapshot
	    parsing all layers and layer folders
	
	Layers :
	
	    parsing layer bitmap data
	    parsing layers bounds and position
	    parsing layer name
	    parsing layer ID
	    parsing layer blend mode
	    parsing layer colour channels
	    parsing layer alpha
	    parsing layer filters
	    parsing layer extra  properties such as : isLocked, isVisible, clipping applied
	    parsing layer type (normal, folder)
	
	What is not supported but planned for the future :
	
	    layer  masks
	    layer paths
	    layer vector shapes
	    parsing text layers as formatted string
	    parsing layers with zip (with or without prediction) compression
	
	As photshop != flash, there are , and will be some necessary incompatibilities. Although I tried to support all the crossover features, not everything will look the same  after import
	here are some gotchas :
	
	    Layer alpha in flash is layer opacity in Photoshop..Layer Fill values are ignored.
	    Incompatible photoshop layer blend modes are interpreted as Normal blend mode
	    Only 4 filters / layer effects are currently supported (drop shadow , inner drop shadow , glow, inner glow) but even these need to have to be applied with normal blend mode, as flash doesn’t support a filters with a different blend mode as the display object they are applied to. For example it’s perfectly possible to have an photoshop layer in screen mode with drop shadow applied in multiply mode, but it flash you don’t have a blend mode settings for a filter..
	    only layers with RAW or RLE compression are being parsed at the moment.. So if you don’t see the layer bitmap data it’s probably compressed with zip compression.
	
	Note on the layer folders / layer groups :
	Layer groups are being parsed and they are also PSDLayer class type.
	
	To identify them you need to check for the layer type:
	
	There are 4 layer types :LayerType_FOLDER_OPEN, LayerType_FOLDER_CLOSED , LayerType_HIDDEN and LayerType_NORMAL.
	
	Layer folder hidden is marker for the end of the layer group. So if you want to parse the folder structure, check where the layer type folder starts and then every layer that follows is inside of that folder, until you reach layer type hidden.
	
	How to use this parser
	
	Very simple.  You just create instance of PSDParser (it is Singleton) and then call “parse” method , passing the content of your psd file in byte array format.
	
	The parsing is synchronous so after that line, you will already have all the file/layers info available..
	
	I’ve made 2 apps that should help you get started.
	
	PSD Viewer is a simple flex app that allows you to load and view psd files and reads the supported layers, while showing their blend modes, visibility , lock, alpha , layer effect etc, in “Photoshop-esque” style. View source is enabled so you can get the source code from here. (If you don’t have the psd file to test use the “testPSD1.psd” file from flex project’s “assets” subfolder).
	
	Simple example is a basic single class as3 app that just loads the psd file and then on click cycles through the layers, bringing the one in the back to the top.
	
	Enjoy!
	
	PS:  As this is still early beta, some PSD files may/will break the parser (especially those with unsupported features (see above) or those not saved in compatibility mode…
	 * 
	 */
	public class PSDParser {
		
		public function PSDParser(blocker:Blocker, fromSingleton:Boolean):void {
			if (!fromSingleton || blocker == null) throw new Error("use getInstance");
		}
		
		public static var instance 			: PSDParser;
		
		//compression types
		private const COMP_RAW 				: int = 0;		//Raw image data
		private const COMP_RLE 				: int = 1;		//RLE compressed the image
		private const COMP_ZIP_W			: int = 2;		//ZIP without prediction
		private const COMP_ZIP_P			: int = 3;		//ZIP with prediction.
		
		private var fileData				: ByteArray;
		public var numChannels				: int;
		public var canvas_height			: int;
		public var canvas_width				: int;
		public var colorChannelDepth		: int;
		public var colorMode				: int;
		public var colorModeStr				: String;
		public var allLayers				: Array; 	//array of all layer objects
		public var allBitmaps				: Array; 	//array of all bitmap objects
		public var composite_bmp			: BitmapData;
		
		
		public function parse(fileData:ByteArray):void {
			this.fileData = fileData;
			
			readHeader();
			readImageResources();
			readLayerAndMaskInfo();
			readCompositeData();
		}

		private function readHeader() : void 
		{
			//check signatue
			
			// monkeypunch - adding check for bytes available - 
			// if called twice on same data it will throw error unless we reset the position
			if (fileData.bytesAvailable==0 && fileData.position!=0) {
				fileData.position = 0;
			}
			
			/*
				Signature: always equal to '8BPS'. Do not try to read the file if the
				signature does not match this value.
			 */
			var sig:String = fileData.readUTFBytes( 4 );
			if (sig!= "8BPS" ) throw new Error("invalid signature: " + sig );
			
			//version
			/*
			 * 	Version: always equal to 1. Do not try to read the file if the version does
				not match this value. (**PSB** version is 2.)
			 */
			var version: int = fileData.readUnsignedShort();
			if (version!= 1) throw new Error("invalid version: " + version );
			
			//Reserved, must be zero
			fileData.position += 6;
			
			//chanels
			/*
				The number of channels in the image, including any alpha channels.
				Supported range is 1 to 56.
			 */
			numChannels = fileData.readUnsignedShort();
			
			//The height of the image in pixels. Supported range is 1 to 30,000.
			canvas_height = fileData.readInt();
			
			//The width of the image in pixels. Supported range is 1 to 30,000.
			canvas_width = fileData.readInt();
			
			//Depth: the number of bits per channel. Supported values are 1, 8, and 16.
			colorChannelDepth = fileData.readUnsignedShort();
			
			//document color mode
			/*		
				The color mode of the file. Supported values are: Bitmap = 0; Grayscale =
				1; Indexed = 2; RGB = 3; CMYK = 4; Multichannel = 7; Duotone = 8; Lab = 9. 
 			*/
			colorMode = fileData.readUnsignedShort();

			switch (colorMode)
			{
				case 0 	: colorModeStr =  "BITMAP";			break;
				case 1 	: colorModeStr =  "GRAYSCALE";		break;
				case 2 	: colorModeStr =  "INDEXED";		break;
				case 3 	: colorModeStr =  "RGB";			break;
				case 4 	: colorModeStr =  "CMYK";			break;
				case 7 	: colorModeStr =  "MULTICHANNEL";	break;
				case 8 	: colorModeStr =  "DUOTONE";		break;
				case 9 	: colorModeStr =  "LAB";			break;
			}
			
			//color mode section
			/*
			 Only indexed color and duotone (see the mode field in Table 1.2) have color mode
			data. For all other modes, this section is just the 4-byte length field, which is set to zero. 
			 */
			var size:int = fileData.readInt();
			fileData.position += size;
		
		}
		

		private function readImageResources():void 
		{
			//Length of image resource section.
			var size:uint = fileData.readUnsignedInt();
			
			// how much was read
			var read:uint = 0;

			while ( read < size ) 
			{
				var sig:String = fileData.readUTFBytes(4); 
				if ( sig != "8BIM") throw new Error("Invalid signature: " + sig );
				read += 4;
				
				//Unique identifier for the resource.
				var resourceID:int = fileData.readUnsignedShort();
				read += 2;
				
				//Name: Pascal string, padded to make the size even (a null name consists of two bytes of 0)
				var nameObj	: Object	= readPascalStringObj();
				var name	: String	= nameObj.str;
				read += nameObj.length;
				
				//Actual size of resource data that follows
				var resourceSize:uint = fileData.readUnsignedInt();
				read += 4;
				
				//readResourceBlock(resourceSize, resourceID);
				fileData.position += resourceSize;
				read += resourceSize;
				
				if ( resourceSize % 2 == 1 ) {
					fileData.readByte();
					read++;
				}
			}
		}

		private function readLayerAndMaskInfo() : void
		{
			//Length of the layer and mask information section.
			var size 	: uint = fileData.readUnsignedInt();
			
			//current read position
			var pos 	: uint = fileData.position;
			
			if ( size > 0 ) 
			{
				parseLayerInfo();
				parseMaskInfo();
				
				fileData.position += pos + size - fileData.position;
			}			
		}

		//loop throigh the layers and get all the layer info
		private function parseLayerInfo( ) : void 
		{
			//Length of the layers info section, rounded up to a multiple of 2.
			var layerInfoSize 	: uint = fileData.readUnsignedInt();
			
			//current read position
			var pos 			: int = fileData.position;
			
			//all layers init
			allLayers = new Array(numLayers);
			
			//all bitmaps init
			allBitmaps = new Array(numLayers);
			
			if ( layerInfoSize > 0 ) 
			{
				//get total nu of layers
				var nLayers : int = fileData.readShort();
				
				/*
					Layer count. If it is a negative number, its absolute value is the number of
					layers and the first alpha channel contains the transparency data for the
					merged result.				  
				 */
				var numLayers : int = Math.abs(nLayers);
				
				//loop through all layers to retrieve layer object info and image data				
				for (var i:int = 0; i < numLayers;++i ) 
				{
					allLayers[i] = new PSDLayer(fileData);
				}
				
				for ( i = 0;i < numLayers;++i ) 
				{
					var layer_psd : PSDLayer = allLayers[i];
					var layer_bmp : PSDLayerBitmap = new PSDLayerBitmap(layer_psd, fileData); 
					allBitmaps[i] = layer_bmp;
					layer_psd.bmp = layer_bmp.image;
				}
			} 
			fileData.position += pos + layerInfoSize - fileData.position;
		}


		private function parseMaskInfo() : void 
		{
			//TODO implement proper mask parsing
			var size 		: uint = fileData.readUnsignedInt();
			var overlay 	: uint = fileData.readUnsignedShort();
			var color1 		: uint = fileData.readUnsignedInt();
			var color2 		: uint = fileData.readUnsignedInt();
			var opacity 	: uint = fileData.readUnsignedShort();
			var kind 		: uint = fileData.readUnsignedByte();
			
			fileData.position += 1; // padding
		}		
		
		
		private function readCompositeData() :void
		{
			//identify the compression
			var compression 		: int 	= fileData.readUnsignedShort();
			var channelsData_arr 	: Array = new Array();
			
			switch (compression) 
			{
				case COMP_RAW: //get raw data
				
					for ( var channel:int = 0; channel < numChannels; ++channel )
					{
						var data:ByteArray = new ByteArray();
						fileData.readBytes( data, 0, canvas_width * canvas_height);
						channelsData_arr[channel] = data;
					}
					break;
				
				case COMP_RLE:
					var lines:Array = new Array( canvas_height * numChannels );
					var i:int;
					
					for ( i = 0; i < canvas_height * numChannels; ++i ) 
					{
						lines[i] = fileData.readUnsignedShort();
					}
					
					for ( channel = 0; channel < numChannels; ++channel )
					{
						data = new ByteArray();
						
						for ( i = 0; i < canvas_height; ++i ) 
						{
							var line:ByteArray = new ByteArray();
							fileData.readBytes( line, 0, lines[channel*canvas_height+i] );
							data.writeBytes( unpack( line ) );
						}
						channelsData_arr[channel] = data;
					}				
					break;
				
				default:
					throw new Error("invalid compression: " + compression );
					break;
			}
			
			//create composite bitmap out of byte array channels
			composite_bmp = new BitmapData( canvas_width, canvas_height, false, 0x000000 );
			
			var r:ByteArray = channelsData_arr[0];
			var g:ByteArray = channelsData_arr[1];
			var b:ByteArray = channelsData_arr[2];
			
			r.position = 0;
			
			// g and b are null in a specific grayscale image
			if (g) {
				g.position = 0;
			}
			
			if (b) {
				b.position = 0;
			}
			
			var isGreyScale:Boolean = colorModeStr=="GRAYSCALE";
			
			var rgb:uint;
			
			for ( var y:int = 0; y < canvas_height; ++y ) {
				for ( var x:int = 0; x < canvas_width; ++x ) {
					
					if (r && g && b) {
						rgb = r.readUnsignedByte() << 16 | g.readUnsignedByte() << 8 | b.readUnsignedByte();
					}
					else if (r && g) {
						rgb = r.readUnsignedByte() << 16 | g.readUnsignedByte() << 8;
					}
					else {
						if (isGreyScale) {
							rgb = r.readUnsignedByte() << 16;
							//rgb = Math.floor(0.3 * rgb + 0.59 * rgb + 0.11 * rgb);
						}
						else {
							rgb = r.readUnsignedByte() << 16;
							
						}
					}
					
					composite_bmp.setPixel( x, y, rgb );
				}
			}
		}
		
		//unpack byte array data
		public function unpack( packed:ByteArray ):ByteArray 
		{
			var i:int;
			var n:int;
			var byte:int;
			var unpacked:ByteArray = new ByteArray();
			var count:int;
			
			while ( packed.bytesAvailable ) 
			{
				n = packed.readByte();
				
				if ( n >= 0 ) 
				{
					count = n + 1;
					for ( i = 0; i < count; ++i ) 
					{
						unpacked.writeByte( packed.readByte() );
					}
				} 
				else {
					
					// monkeypunch - added check when no bytes available
					if (packed.bytesAvailable) {
						byte = packed.readByte();
					}
					
					count = 1 - n;
					for ( i = 0; i < count; ++i ) 
					{
						unpacked.writeByte( byte );
					}
				}
			}
			
			return unpacked;
		}	

		//returns the read value and its length in format {str:value, length:size}
		private function readPascalStringObj():Object
		{
			var size:uint = fileData.readUnsignedByte();
			size += 1 - size % 2;
			return  {str:fileData.readMultiByte( size, "shift-jis").toString(), length:size + 1};
		}
		
		public static function getInstance() : PSDParser 
		{ 
			if (instance == null) instance = new PSDParser(new Blocker, true);
			return instance;
		}				
	}
}

class Blocker
{
}