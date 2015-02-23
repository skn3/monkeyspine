'see license.txt For source licenses
Strict

Import spine

Interface SpineTexture
	Method path:String() Property
	Method width:Int() Property
	Method height:Int() Property
	
	Method Load:Void(path:String)
	Method Discard:Void()
	Method Grab:SpineRenderObject(x:Int, y:Int, width:Int, height:Int, handleX:Float, handleY:Float, rotate:Bool)
End