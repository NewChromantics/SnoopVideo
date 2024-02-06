import SwiftUI
import PopMp4
import PopH264

enum RuntimeError: Error
{
	case runtimeError(String)
}

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
	public var				decoder : FileDecoder? = nil
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
		//	gr: change this so if it fails, revert to h264 stream decoder.
		//		possibly we want some header probe functions.
		//		it would also be good to get file type from document opener.
		//		But for now, hacky file extension check
		if ( filename.lowercased().hasSuffix(".h264") )
		{
			decoder = H264FileDecoder(filename: filename)
		}
		else
		{
			decoder = Mp4FileDecoder(filename: filename)
		}
			
		loadingStatus = LoadingStatus.Loading

		while ( true )
		{
			//try await Task.sleep(nanoseconds: 10_000_000)	//	10_000_000ns = 10ms
			try await Task.sleep(nanoseconds: 1000)	//	10_000_000ns = 10ms

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



public protocol FileDecoder
{
	init(filename:String)
	
	func WaitForNewMeta() async throws -> Mp4Meta
}






public class StreamingFileDecoder : FileDecoder
{
	var readFileError : String?
	var readFileFinished = false
	var decodedFrames : [AtomMeta] = []
	var pushCounter : Int32=0	//	used as a frame number
	var outputFrameCounter : Int32=0
	var AutoFrameCounterFirstFrame = 0
	//	put all decoded frames into a track
	var Track = TrackMeta(codec:"avc1")
	
	required public init(filename:String)
	{
		Task.init
		{
			do
			{
				try await ReadFileThread(filename: filename)
				readFileFinished = true
			}
			catch
			{
				readFileError = error.localizedDescription
			}
		}
	}
	
	func OnFileData(data:Data) throws
	{
		throw fatalError("OnFileData Not overloaded")
	}
	

	func OnFileEnd() throws
	{
		throw fatalError("OnFileEnd Not overloaded")
	}

	
	func ReadFileThread(filename:String) async throws
	{
		//let fileHandle = FileHandle(forReadingAtPath: filename)
		let fileHandle = try FileHandle(forReadingFrom: URL(string:filename)! )
		if ( fileHandle == nil )
		{
			throw RuntimeError.runtimeError("Failed to open file handle")
		}
		let BufferSizeMb = 1
		let BufferSizeKb = BufferSizeMb * 1024
		let BufferSize = BufferSizeKb * 1024

		while ( true )
		{
			let readData = fileHandle.readData(ofLength: BufferSize)
		
			//	EOF or read error.
			if ( readData.isEmpty )
			{
				break;
			}
			
			//	push data
			try OnFileData(data: readData)
		}
		
		try OnFileEnd()
		fileHandle.closeFile()
	}
	
	
	@MainActor // as we change published variables, we need to run on the main thread
	public func WaitForNewMeta() async throws -> PopMp4.Mp4Meta
	{
		 throw fatalError("WaitForNewMeta Not overloaded")
	}
}






public class H264FileDecoder : StreamingFileDecoder
{
	var decoder : PopH264Instance
	
	required public init(filename:String)
	{
		decoder = PopH264Instance()
		super.init(filename: filename)
	}
	
	override func OnFileData(data:Data) throws
	{
		decoder.PushData(data:data,frameNumber:pushCounter)
		pushCounter += 1
	}
	
	override func OnFileEnd()
	{
		decoder.PushEndOfFile()
	}
	
	
	@MainActor // as we change published variables, we need to run on the main thread
	override public func WaitForNewMeta() async throws -> PopMp4.Mp4Meta
	{
		//	this peeks the decoder
		//	then, if data, add to list of "atoms" (frames)
		//	pop frame & move on to next
		let NextFrameMeta = await decoder.PeekNextFrame()
		
		if ( NextFrameMeta.QueuedFrames ?? 0 > 0 )
		{
			//	throw away frame from decoder
			var FrameNumber = try await decoder.PopNextFrame()
			
			//	gr: use framenumber from meta
			FrameNumber = NextFrameMeta.FrameNumber ?? 0
			
			//	detect un-numbered frames and auto add them (poph264 should do this!)
			//	we've already had a frame 0, we're getting more than one
			if ( FrameNumber == 0 && outputFrameCounter > 0 )
			{
				FrameNumber = AutoFrameCounterFirstFrame + Int(outputFrameCounter*10)
			}
			outputFrameCounter += 1
			
			Track.SampleDecodeTimes.append(FrameNumber)

			
			//	save this frame
			var HwAccell = NextFrameMeta.HardwareAccelerated ?? false;
			var label = "Frame \(FrameNumber) (Hardware Accellerated=\(HwAccell))";
			var frameMeta = AtomMeta(fourcc:label)
			frameMeta.Children = []
			//frameMeta.ContentSizeBytes = NextFrameMeta.TotalPlaneBytes
			for plane in NextFrameMeta.Planes ?? []
			{
				var label = "\(plane.Width)x\(plane.Height) \(plane.Format)"
				var child = AtomMeta(fourcc:label)
				child.ContentSizeBytes = plane.DataSize
				frameMeta.Children?.append(child)
			}
			
			decodedFrames.append(frameMeta)
		}

		//	if meta hasn't updated, loop
		//	if finished, stop
		
		var convertedMeta = PopMp4.Mp4Meta()
		convertedMeta.Error = NextFrameMeta.Error
		convertedMeta.IsFinished = false
		convertedMeta.AtomTree = decodedFrames
		
		if ( outputFrameCounter > 100 )
		{
			convertedMeta.Tracks = [Track]
		}
		
		if ( readFileError != nil )
		{
			convertedMeta.Error = readFileError
		}
		
		return convertedMeta
	}
}



public class Mp4FileDecoder : StreamingFileDecoder
{
	var decoder : PopMp4Instance
	
	
	required public init(filename:String)
	{
		decoder = PopMp4Instance()
		super.init(filename: filename)
	}
	
	override func OnFileData(data:Data) throws
	{
		decoder.PushData(data:data)
	}
	
	override func OnFileEnd()
	{
		decoder.PushEndOfFile()
	}
	
	@MainActor // as we change published variables, we need to run on the main thread
	override public func WaitForNewMeta() async throws -> Mp4Meta
	{
		let NewMeta = await decoder.WaitForMetaChange()
		
		//	if meta hasn't updated, loop
		//	if finished, stop
		
		return NewMeta
	}
}
