import SwiftUI



struct HexConversionData
{
	public var renderedBytes : Int = 0
	public var totalBytes : Int = 0
	public var hexRendered : String = ""
	
	var sizeMessage : String
	{
		if ( renderedBytes != totalBytes )
		{
			return "Clipped to \(renderedBytes)/\(totalBytes) bytes"
		}
		else
		{
			return "\(totalBytes) bytes"
		}
	}
}

func bytesToHexString(_ input: Data,lineBreakEveryXBytes:Int=1024) -> HexConversionData
{
	print("Converting x\(input.count) bytes to string...")
	
	var output = HexConversionData()
	
	//	add a few extra bytes to show clipping
	let renderMax = min( input.count, (1024*10)+4 )
	let renderInput = input.count <= renderMax ? input : input[0...renderMax-1]
	
	output.renderedBytes = renderInput.count
	output.totalBytes = input.count
	
	var Hex = String(NSMutableString(capacity: renderInput.count * 3) )
	var Char = ""
	var bytesWritten = 0
	for v in renderInput
	{
		Char = String(format: "%02x", v )
		Hex += "\(Char) "
		if ( lineBreakEveryXBytes > 0 && (bytesWritten % lineBreakEveryXBytes)==lineBreakEveryXBytes-1 )
		{
			Hex += "\n\n"
		}
		bytesWritten += 1
	}
	
	//	add elpsis to show clipping (gr; maybe dont do this here, but we should also not do line breaks here?
	if ( output.renderedBytes != output.totalBytes )
	{
		Hex += " ..."
	}
	
	print("Converting x\(input.count) bytes to string... done")
	
	output.hexRendered = Hex
	return output
}

class HexConversionDataCache : ObservableObject
{
	public var conversion: HexConversionData

	init(input: Data)
	{
		self.conversion = bytesToHexString(input)
	}
}


struct HexView: View
{
	@StateObject var conversionCache: HexConversionDataCache
	/*@State */var conversion: HexConversionData	//	making this state, also doesnt update view...
	var inputBytes: Data?

	let monospacedFont = Font
		.system(size: 12)
		.monospaced()
	
	var renderConversion : HexConversionData
	{
		//	cached version never updated view
		//return conversionCache.conversion
		return conversion
	}
	
	init(input: Data?)
	{
		inputBytes = input

		if ( inputBytes == nil )
		{
			conversion = HexConversionData()
			//conversion.hexRendered = "null"
			_conversionCache = StateObject(wrappedValue: HexConversionDataCache(input: Data()))
			return
		}


		conversion = bytesToHexString(inputBytes!)
		
		//	gr: in order to cache properly, the object MUST be contructed inside the wrappedValue: param
		//	gr: I have no idea why _ prefix solves this compile error
		_conversionCache = StateObject(wrappedValue: HexConversionDataCache(input: input!))
	}


	
	var body: some View
	{
		if ( inputBytes == nil )
		{
			EmptyView()
		}
		else
		{			
			ScrollView
			{
				Text(renderConversion.sizeMessage)
					.textSelection(.enabled)
					.frame(maxWidth: .infinity,alignment: .leading)
				
				//Text(cachedBytesAsHexString.transformed)
				Text(renderConversion.hexRendered)
					.font(monospacedFont)
					.textSelection(.enabled)
					.padding(5)
					.frame(maxWidth: .infinity,maxHeight: .infinity,alignment: .leading)
			}
		}
	}
}
