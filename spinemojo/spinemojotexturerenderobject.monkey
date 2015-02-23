'see license.txt For source licenses
Strict

Import spine.spinemojo

Class SpineMojoTextureRenderObject Implements SpineRenderObject
	Private
	Field image:Image
	Field rotate:Bool
	Field texture:Image
	Public
	
	Method width:Int() Property
		Return image.Width()
	End
	
	Method height:Int() Property
		Return image.Height()
	End
	
	Method textureWidth:Int() Property
		Return texture.Width()
	End
	
	Method textureHeight:Int() Property
		Return texture.Height()
	End
	
	Method New(image:Image, x:Int, y:Int, width:Int, height:Int, handleX:Float, handleY:Float, rotate:Bool)
		Self.rotate = rotate
		texture = image
		
		#If SPINE_ATLAS_ROTATE
		If rotate
			Self.image = image.GrabImage(x, y, height, width)
			Self.image.SetHandle(handleY, handleX)
		Else
			Self.image = image.GrabImage(x, y, width, height)
			Self.image.SetHandle(handleX, handleY)
		EndIf
		#Else
		Self.image = image.GrabImage(x, y, width, height)
		Self.image.SetHandle(handleX, handleY)
		#EndIf
	End Method
			
	Method Draw:Void(verts:Float[])
		'polys are pre-rotated so we dont need to do it here
		#If SPINE_ATLAS_ROTATE
		DrawPoly(verts, texture, 0)
		#Else
		DrawPoly(verts, image, 0)
		#EndIf
	End
	
	Method Draw:Void(x:Float, y:Float, angle:Float, scaleX:Float, scaleY:Float, atlasScale:Float)
		#If SPINE_ATLAS_ROTATE
		If rotate
			DrawImage(image, x, y, angle - 90, scaleX * atlasScale, scaleY * atlasScale, 0)
		Else
			DrawImage(image, x, y, angle, scaleX * atlasScale, scaleY * atlasScale, 0)
		EndIf
		#Else
		DrawImage(image, x, y, angle, scaleX * atlasScale, scaleY * atlasScale, 0)
		#EndIf
	End
End
