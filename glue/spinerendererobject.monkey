'see license.txt For source licenses
Strict

Import spine

Interface SpineRenderObject
	Method width:Int() Property
	Method height:Int() Property
	Method textureWidth:Int() Property
	Method textureHeight:Int() Property
	
	'Method Draw:Void(x:Float, y:Float)
	Method Draw:Void(verts:Float[])
	Method Draw:Void(x:Float, y:Float, angle:Float, scaleX:Float, scaleY:Float, atlasScale:Float)
End