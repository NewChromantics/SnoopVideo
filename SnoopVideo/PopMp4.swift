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

struct Mp4Meta: Decodable
{
	let Error: String?
	let AtomTree : [String]?
	let EndOfFile: Bool
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
		//self.Instance = PopMp4Decoder_AllocWithOption(Filename, "{}" )
		if ( self.Instance == 0 )
		{
			//throw PopMp4Error("Failed to allocate MP4 decoder for \(Filename)")
		}
		print("Allocated instance \(self.Instance)")
	}
	
	//	returns null when finished/eof
	func WaitForMetaChange() async -> Mp4Meta
	{
		//	gr: replace this will call to CAPI to get new meta
		var SleepMs = 10
		var SleepNano = (SleepMs * 1_000_000)
		do
		{
			try await Task.sleep(nanoseconds: UInt64(SleepNano) )
		}
		catch let error as Error
		{
			return Mp4Meta( Error:error.localizedDescription, AtomTree:nil, EndOfFile:true )
		}
		AtomTreeCounter += 1
		
		//	send eof
		if ( AtomTreeCounter >= 1000 )
		{
			return Mp4Meta( Error:nil, AtomTree:nil, EndOfFile:true )
		}
		
		var NewAtom = "Atom #\(AtomTreeCounter)"
		AtomTree.append(NewAtom)
			
		return Mp4Meta( Error:nil, AtomTree:AtomTree, EndOfFile:false )
	}
			
}


class Mp4ViewModel : ObservableObject
{
	enum LoadingStatus : CustomStringConvertible
	{
		case Init, Loading, Finished, Error

		var description: String
		{
			switch self 
			{
				case .Init: return "Init"
				case .Loading: return "Loading"
				case .Finished: return "Finished"
				case .Error: return "Error"
			}
		}
	}


	@Published var atomTree : [String]
	@Published var loadingStatus = LoadingStatus.Init
	var mp4Decoder : PopMp4Instance?
	
	
	init()
	{
		self.mp4Decoder = nil
		self.atomTree = ["Model's initial Tree"]
	}
	
	@MainActor // as we change published variables, we need to run on the main thread
	func Load(filename: String) async throws
	{
		self.loadingStatus = LoadingStatus.Loading
		try self.mp4Decoder = PopMp4Instance(Filename: filename)
		
		while ( true )
		{
			//	todo: return struct with error, tree, other meta
			var NewMeta = try await self.mp4Decoder!.WaitForMetaChange()
			
			//	todo: do something with error
			if ( NewMeta.Error != nil )
			{
				self.atomTree = [NewMeta.Error!]
				self.loadingStatus = LoadingStatus.Error
				return
			}
			
			//	update data
			if ( NewMeta.AtomTree != nil )
			{
				self.atomTree = NewMeta.AtomTree!
			}
			
			//	eof
			if ( NewMeta.EndOfFile )
			{
				break
			}
		}
		self.loadingStatus = LoadingStatus.Finished
	}
}
