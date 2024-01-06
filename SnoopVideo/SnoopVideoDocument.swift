//
//  SnoopVideoDocument.swift
//  SnoopVideo
//
//  Created by Graham Reeves on 02/01/2024.
//

import SwiftUI
import UniformTypeIdentifiers

/*
	app-defined custom type
extension UTType {
	static var quicktime: UTType {
		UTType(importedAs: "com.apple.quicktime-movie")
	}
}
*/

struct SnoopVideoDocument: FileDocument 
{
	var text: String

	init(text: String = "Snoop!") 
	{
		self.text = text
	}

	static var readableContentTypes: [UTType]
	{
		[
			UTType.appleProtectedMPEG4Video,
			UTType.mpeg4Movie,
			UTType.movie,
			UTType.quickTimeMovie
		]
	}

	
	init(configuration: ReadConfiguration) throws {
		guard let data = configuration.file.regularFileContents,
			  let string = String(data: data, encoding: .utf8)
		else {
			throw CocoaError(.fileReadCorruptFile)
		}
		text = string
	}
	
	func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
		let data = text.data(using: .utf8)!
		return .init(regularFileWithContents: data)
	}
	 
}

