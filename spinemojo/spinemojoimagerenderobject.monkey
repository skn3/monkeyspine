'see license.txt For source licenses
Strict

Import spine.spinemojo

Class SpineMojoImageRenderObject Implements SpineRenderObject
	Private
	Field image:Image
	Public
	
	Method width:Int() Property
		Return image.Width()
	End
	
	Method height:Int() Property
		Return image.Height()
	End
	
	Method textureWidth:Int() Property
		Return image.Width()
	End
	
	Method textureHeight:Int() Property
		Return image.Height()
	End
	
	Method New(image:Image, handleX:Float = 0.0, handleY:Float = 0.0)
		Self.image = image
		Self.image.SetHandle(handleX, handleY)
	End Method
	
	Method New(path:String, handleX:Float = 0.0, handleY:Float = 0.0)
		Self.image = LoadImage(path)
		Self.image.SetHandle(handleX, handleY)
	End Method
			
	Method Draw:Void(verts:Float[])
		'polys are pre-rotated so we dont need to do it here
		DrawPoly(verts, image, 0)
	End
	
	Method Draw:Void(x:Float, y:Float, angle:Float, scaleX:Float, scaleY:Float, atlasScale:Float)
		DrawImage(image, x, y, angle, scaleX * atlasScale, scaleY * atlasScale, 0)
	End
End