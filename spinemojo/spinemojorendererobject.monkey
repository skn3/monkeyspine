'see license.txt For source licenses
Strict

Import spine.spinemojo

Class SpineMojoRendererObject Implements SpineRendererObject
	Private
	Field image:Image
	Field rotate:Bool
	Public
	
	Method width:Int() Property
		Return image.Width()
	End
	
	Method height:Int() Property
		Return image.Height()
	End
	
	Method New(image:Image, x:Int, y:Int, width:Int, height:Int, handleX:Float, handleY:Float, rotate:Bool)
		Self.rotate = rotate
		
		If rotate
			Self.image = image.GrabImage(x, y, height, width)
			Self.image.SetHandle(handleY, handleX)
		Else
			Self.image = image.GrabImage(x, y, width, height)
			Self.image.SetHandle(handleX, handleY)
		EndIf
		
	End Method
			
	Method Draw:Void(verts:Float[])
		'polys are pre-rotated so we dont need to do it here
		DrawPoly(verts, image, 0)
	End
	
	Method Draw:Void(x:Float, y:Float, angle:Float, scaleX:Float, scaleY:Float)
		If rotate
			DrawImage(image, x, y, angle - 90, scaleX, scaleY, 0)
		Else
			DrawImage(image, x, y, angle, scaleX, scaleY, 0)
		EndIf
	End
End