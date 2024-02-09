import SwiftUI


func bytesToHexString(_ input: Data) -> String
{
	var Hex = String(NSMutableString(capacity: input.count * 3) )
	var Char = ""
	for v in input
	{
		Char = String(format: "%02x", v )
		Hex += "\(Char) "
	}
	return Hex
}

class BytesAsHexString : ObservableObject
{
	@Published var transformed: String

	init(input: Data)
	{
		self.transformed = bytesToHexString(input)
	}
}


struct HexView: View
{
	@StateObject var cachedBytesAsHexString: BytesAsHexString

	init(input: Data)
	{
		//	gr: I have no idea why _ prefix solves this compile error
		_cachedBytesAsHexString = StateObject(wrappedValue: BytesAsHexString(input: input))
	}

	var body: some View
	{
		ScrollView 
		{
			Text(cachedBytesAsHexString.transformed)
				.textSelection(.enabled)
		}
	}
}
