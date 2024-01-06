import SwiftUI

struct PopMp4Error : LocalizedError
{
	let description: String

	init(_ description: String) {
		self.description = description
	}

	var errorDescription: String? {
		description
	}
}

//	based on public class CondenseStream
public class PopMp4Instance
{
	var Instance : CInt = 0
	
	//	these will come out of CAPI calls
	var AtomTree : [String] = ["Hello"]
	var AtomTreeCounter = 0
	
	init(Filename:String) throws
	{
		/*
		self.Instance = PopMp4Decoder_AllocWithOption(Filename, "{}" )
		if ( self.Instance == 0 )
		{
		 throw PopMp4Error("Failed to allocate stream")
		}
		*/
		print("Allocated instance \(self.Instance)")
	}
	
	//	returns null when finished/eof
	func WaitForMetaChange() async throws -> [String]?
	{
		//	gr: replace this will call to CAPI to get new meta
		var SleepMs = 1000
		var SleepNano = (SleepMs * 1_000_000)
		try await Task.sleep(nanoseconds: UInt64(SleepNano) )
		
		AtomTreeCounter += 1
		
		//	send eof
		if ( AtomTreeCounter >= 1000 )
		{
			return nil
		}
		
		var NewAtom = "Atom #\(AtomTreeCounter)"
		AtomTree.append(NewAtom)
			
		return AtomTree
	}
			
}


class Mp4ViewModel : ObservableObject
{
	enum LoadingStatus
	{
		case Init, Loading, Finished
	}
	@Published var AtomTree : [String]
	@Published var LoadingState = LoadingStatus.Init
	var Mp4Decoder : PopMp4Instance?
	
	init()
	{
		self.Mp4Decoder = nil
		self.AtomTree = ["Model's initial Tree"]
	}
	
	@MainActor // as we change published variables, we need to run on the main thread
	func Load(filename: String) async throws
	{
		self.LoadingState = LoadingStatus.Loading
		try self.Mp4Decoder = PopMp4Instance(Filename: filename)
		
		while ( true )
		{
			//	todo: return struct with error, tree, other meta
			var NewTree = try await self.Mp4Decoder!.WaitForMetaChange()
			
			//	eof
			if ( NewTree == nil )
			{
				break
			}
			AtomTree = NewTree!
		}
		self.LoadingState = LoadingStatus.Finished
	}
}
