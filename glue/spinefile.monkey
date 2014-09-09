'see license.txt for source licenses
Strict

Import spine

Interface SpineFile
	Method path:String() Property
	Method path:Void(value:String) Property
	
	Method Load:Void(path:String)
	Method ReadLine:String()
	Method ReadAll:String()
	Method Eof:Bool()
	Method Close:Void()
End