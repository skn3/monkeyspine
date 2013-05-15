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
	Field path:String
	Field buffer:DataBuffer
	Field index:Int
	Field total:Int
	Field start:Int
	
	Method Load:Bool(path:String)
		'convert string into buffer
		Self.path = path
		index = 0
		start = 0
		
		'create buffer
		Local data:String = LoadString(path)
		total = data.Length
		buffer = New DataBuffer(total)
		buffer.PokeString(0, data)
		
		'return success
		Return True
	End
	
	Method GetPath:String()
		Return path
	End
	
	Method ReadLine:String()
		If buffer = Null or index >= total Return ""
		
		For index = index Until total
			'check for end of line
			If buffer.PeekByte(index) = 10
				Local result:String = buffer.PeekString(start, (index - start) + 1)
				index = index + 1
				start = index
				Return result
			EndIf
		Next
		
		Return ""
	End
	
	Method ReadAll:String()
		'just return the entire contents in a string
		Local result:= buffer.PeekString(start)
		start = total
		Return result
	End
	
	Method Eof:Bool()
		Return index < total
	End
End