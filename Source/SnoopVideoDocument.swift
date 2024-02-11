//
//  SnoopVideoDocument.swift
//  SnoopVideo
//
//  Created by Graham Reeves on 02/01/2024.
//

import SwiftUI
import UniformTypeIdentifiers

//	app-defined custom type
extension UTType
{
	static var RawVideoStream: UTType {
		UTType(importedAs: "com.newchromantics.rawvideostream")
	}
}


struct SnoopVideoDocument: FileDocument 
{
	static var readableContentTypes: [UTType]
	{
		[
			UTType.appleProtectedMPEG4Video,
			UTType.mpeg4Movie,
			UTType.movie,
			UTType.quickTimeMovie,
			UTType.RawVideoStream
		]
	}

	init()
	{
	}
	
	init(configuration: ReadConfiguration) throws 
	{
		do
		{
			let fileContents = configuration.file.regularFileContents
			if ( fileContents == nil )
			{
				throw CocoaError(.fileReadUnknown)
			}
			let fileContentsString = String(data: fileContents!, encoding: .utf8)
		}
		catch
		{
			throw CocoaError(.fileReadCorruptFile)
		}
	}

	func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper 
	{
		//let data = text.data(using: .utf8)!
		//return .init(regularFileWithContents: data)
		throw CocoaError(.fileWriteUnknown)
	}
}

