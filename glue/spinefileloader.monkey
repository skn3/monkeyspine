'see license.txt for source licenses
Strict

Import spine

Interface SpineFileLoader
	Method Path:String() Property
	Method Path:Void(value:String) Property
	
	Method Load:Void(path:String)
	Method ReadLine:String()
	Method ReadAll:String()
	Method Eof:Bool()
	Method Close:Void()
End

Class SpineMojoFileLoader Implements SpineFileLoader
	Private
	Field path:String
	Field buffer:DataBuffer
	Field index:Int
	Field total:Int
	Field start:Int
	Public
	
	Method Path:String()
		Return path
	End
	
	Method Path:Void(value:string)
		Self.path = value
	End
	
	Method Load:Void(path:String)
		Self.path = path
		index = 0
		start = 0
		
		'create buffer
		Local data:String = LoadString(path)
		total = data.Length()
		buffer = New DataBuffer(total)
		buffer.PokeString(0, data)
	End
	
	Method ReadLine:String()
		If buffer = Null or index >= total Return ""
		
		For index = index Until total
			'check for End of line
			If buffer.PeekByte(index) = 10
				Local result:String = buffer.PeekString(start, (index - start))
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