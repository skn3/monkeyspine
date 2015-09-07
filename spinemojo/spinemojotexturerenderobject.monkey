'see license.txt For source licenses
Strict

Import spine.spinemojo

Class SpineMojoTextureRenderObject Implements SpineRenderObject
	Private
	Field image:Image
	Field rotate:Bool
	Field material:Material
	Public
	
	Method width:Int() Property
		Return image.Width()
	End
	
	Method height:Int() Property
		Return image.Height()
	End
	
	Method textureWidth:Int() Property
		Return material.Width()
	End
	
	Method textureHeight:Int() Property
		Return material.Height()
	End
	
	Method New(material:Material, x:Int, y:Int, width:Int, height:Int, handleX:Float, handleY:Float, rotate:Bool)
		Self.rotate = rotate
		Self.material = material
		
		'create an image so we can use it
		#If SPINE_ATLAS_ROTATE
		If rotate
			image = New Image(material, x, y, height, width, handleY, handleX)
		Else
			image = New Image(material, x, y, width, height, handleX, handleY)
		EndIf
		#Else
		image = New Image(material, x, y, width, height, handleX, handleY)
		#EndIf
	End Method
			
	Method Draw:Void(target:DrawList, verts:Float[], uvs:Float[], count:Int)
		target.DrawPrimitives(3, count, verts, uvs, material)
	End
	
	Method Draw:Void(target:DrawList, x:Float, y:Float, angle:Float, scaleX:Float, scaleY:Float, atlasScale:Float)
		#If SPINE_ATLAS_ROTATE
		If rotate
			target.DrawImage(image, x, y, angle - 90, scaleX * atlasScale, scaleY * atlasScale)
		Else
			target.DrawImage(image, x, y, angle, scaleX * atlasScale, scaleY * atlasScale)
		EndIf
		#Else
		target.DrawImage(image, x, y, angle, scaleX * atlasScale, scaleY * atlasScale)
		#EndIf
	End
End
