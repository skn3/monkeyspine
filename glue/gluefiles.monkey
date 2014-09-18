'see license.txt for source licenses
Strict

Import spine

'file interfaces
Interface SpineFileLoader
	Method LoadFile:SpineFileStream(path:String)
End

Interface SpineFileStream
	Method GetPath:String()
	Method Load:Bool(path:String)
	Method ReadLine:String()
	Method ReadAll:String()
	Method Eof:Bool()
End

'default file implementation
Class SpineDefaultFileLoader Implements SpineFileLoader
	Global instance:= New SpineDefaultFileLoader
	
	'callbacks
	Method LoadFile:SpineFileStream(path:String)
		' --- load a new stream object ---
		Local stream:= New SpineDefaultFileStream()
		stream.Load(path)
		Return stream
	End
End

Class SpineDefaultFileStream Implements SpineFileStream
	Field originalString:String
	Field path:String
	Field index:Int
	Field total:Int
	Field start:Int
	
	Method Load:Bool(path:String)
		'convert string into buffer
		Self.path = path
		index = 1
		start = 1
		
		'create buffer
		originalString = LoadString(path)

		total = originalString.Length
		
		'return success
		Return True
	End
	
	Method GetPath:String()
		Return path
	End
	
	Method ReadLine:String()
		If originalString = "" or index >= total Return ""
		
		For index = index Until total			
			'check for end of line
			If originalString[index] = 10
				Local result:String = originalString[start..index]
				index += 1
				start = index
				Return result
			End
		Next
		
		Return ""
	End
	
	Method ReadAll:String()
		'just return the entire contents in a string
		start = total
		Return originalString
	End
	
	Method Eof:Bool()
		Return index >= total
	End
End
