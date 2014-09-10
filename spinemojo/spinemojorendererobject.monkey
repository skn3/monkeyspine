'see license.txt for source licenses
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
	
	Method New(image:Image, rotate:Bool)
		Self.image = image
		Self.rotate = rotate
	End Method
			
	Method Draw:Void(verts:Float[])
		'polys are already rotated so we dont need to do it
		DrawPoly(verts, image, 0)
	End
	
	Method Draw:Void(x:Float, y:Float, angle:Float, scaleX:Float, scaleY:Float)
		If rotate
			DrawImage(image, x, y, angle + 90.0, scaleX, scaleY, 0)
		Else
			DrawImage(image, x, y, angle, scaleX, scaleY, 0)
		EndIf
	End
End