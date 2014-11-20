'see license.txt For source licenses
Strict

Import spine.spinemojo

Class SpineMojoFile Implements SpineFile
	Private
	Field _path:String
	Field buffer:DataBuffer
	Field index:Int
	Field total:Int
	Field start:Int
	Public
	
	Method path:String()
		Return _path
	End
	
	Method path:Void(value:String)
		_path = value
	End
	
	Method Load:Void(path:String)
		_path = path
		index = 0
		start = 0
		
		'create buffer
		buffer = DataBuffer.Load(_path)
		If buffer = Null Throw SpineException("invalid file: " + path)
		total = buffer.Length()
	End
	
	Method ReadLine:String()
		If buffer = Null or index >= total Return ""
		
		For index = index Until total
			'check For End of line
			If buffer.PeekByte(index) = 10
				Local stringEndIndex:= index
				
				'remove ~r as well?
				If index > 0 And buffer.PeekByte(index - 1) = 13
					stringEndIndex -= 1
				EndIf
				
				'grab the string
				Local result:String = buffer.PeekString(start, (stringEndIndex - start))
				index = index + 1
				start = index
				Return result
			EndIf
		Next
		
		Return ""
	End
	
	Method ReadAll:String()
		If buffer = Null Return ""
		
		Local result:= buffer.PeekString(start)
		start = total
		Return result
	End
	
	Method Eof:Bool()
		Return index >= total
	End
	
	Method Close:Void()
		If buffer
			buffer.Discard()
			buffer = Null
		EndIf
	End
End