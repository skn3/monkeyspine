'see license.txt for source licenses
Strict

Import spine

Interface SpineTexture
	Method path:String() Property
	Method width:Int() Property
	Method height:Int() Property
	
	Method Load:Void(path:String)
	Method Discard:Void()
End