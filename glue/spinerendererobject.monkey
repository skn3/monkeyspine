'see license.txt for source licenses
Strict

Import spine

Interface SpineRendererObject
	Method width:Int() Property
	Method height:Int() Property
	
	'Method Draw:Void(x:Float, y:Float)
	Method Draw:Void(verts:Float[])
	Method Draw:Void(x:Float, y:Float, angle:Float, scaleX:Float, scaleY:Float)
End