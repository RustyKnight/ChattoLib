//
//  LogUtilities.swift
//  ChattoLib
//
//  Created by Shane Whitehead on 17/11/2016.
//  Copyright © 2016 Beam Communications. All rights reserved.
//

import Foundation

//
//  LogService.swift
//  Cioffi_Core
//
//  Created by Janidu Wanigasuriya on 3/02/2016.
//  Copyright © 2016 Beam Communications. All rights reserved.
//

import Foundation

enum LogLevel: String, CustomStringConvertible {
	case debug = "🐞"
	case info = "💡"
	case error = "☠️"
	case warning = "⚠️"
	
	var description: String {
		return self.rawValue
	}
}

fileprivate func log(_ message: String, level: LogLevel, file: String = #file, function: String = #function, line: UInt = #line) {
	let url = URL(fileURLWithPath: file)
	let name = url.lastPathComponent
	print("\(level)| [\(name) \(function)] #\(line): \(message)")
}

/**
Logs info messages
- Parameters:
- message: Message
*/
func log(info message: String, file: String = #file, function: String = #function, line: UInt = #line) {
	log(message,
	    level: .info,
	    file: file,
	    function: function,
	    line: line)
}

func log(debug message: String, file: String = #file, function: String = #function, line: UInt = #line) {
	log(message,
	    level: .debug,
	    file: file,
	    function: function,
	    line: line)
}

func log(error message: String, file: String = #file, function: String = #function, line: UInt = #line) {
	log(message,
	    level: .error,
	    file: file,
	    function: function,
	    line: line)
}

func log(error: Error, file: String = #file, function: String = #function, line: UInt = #line) {
	log("\(error)",
		level: .error,
		file: file,
		function: function,
		line: line)
}

func log(warning message: String, file: String = #file, function: String = #function, line: UInt = #line) {
	log(message,
	    level: .warning,
	    file: file,
	    function: function,
	    line: line)
}

func log(warning: Error, file: String = #file, function: String = #function, line: UInt = #line) {
	log("\(warning)",
		level: .warning,
		file: file,
		function: function,
		line: line)
}
	
