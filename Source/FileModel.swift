import SwiftUI
import PopMp4

public enum LoadingStatus : CustomStringConvertible
{
	case Init, Loading, Finished

	public var description: String
	{
		switch self
		{
			case .Init: return "Init"
			case .Loading: return "Loading"
			case .Finished: return "Finished"
		}
	}
}


//	we can't have a nullable FileDecoder as a @StateObject, but we may want to swap it, or allocate late
//	so we wrap it
public class FileDecoderWrapper : ObservableObject
{
	public var				decoder : Mp4FileDecoder? = nil
	@Published public var	lastMeta = Mp4Meta()
	@Published public var	loadingStatus = LoadingStatus.Init
	public var				error : String?
	{
		return lastMeta.Error
	}

	init()
	{
		
	}
	
	@MainActor // as we change published variables, we need to run on the main thread
	public func Load(filename: String) async throws
	{
		decoder = Mp4FileDecoder(filename: filename)
		loadingStatus = LoadingStatus.Loading

		while ( true )
		{
			try await Task.sleep(nanoseconds: 10_000_000)	//	10_000_000ns = 10ms
			
			lastMeta = try await decoder!.WaitForNewMeta()
			
			if ( lastMeta.Error != nil )
			{
				break
			}
			
			//	eof - if it's missing, we'll have to assume processing has failed (eg. just an error present)
			if ( lastMeta.IsFinished ?? true )
			{
				break
			}
		}

		loadingStatus = LoadingStatus.Finished
	}
}



public class Mp4FileDecoder : ObservableObject
{
	var mp4Decoder : PopMp4Instance
	
	
	public init(filename:String)
	{
		mp4Decoder = PopMp4Instance(Filename: filename)
		print("new Mp4ViewModel")
	}
	
	@MainActor // as we change published variables, we need to run on the main thread
	public func WaitForNewMeta() async throws -> Mp4Meta
	{
		let NewMeta = await mp4Decoder.WaitForMetaChange()
		
		//	if meta hasn't updated, loop
		//	if finished, stop
		
		return NewMeta
	}
}

