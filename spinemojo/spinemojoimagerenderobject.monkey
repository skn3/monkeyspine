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
		Self.image = Image.Load(path)
		Self.image.SetHandle(handleX, handleY)
	End Method
			
	Method Draw:Void(target:DrawList, verts:Float[], uvs:Float[], count:Int)
		target.DrawPrimitives(3, count, verts, uvs, image.Material)
	End
	
	Method Draw:Void(target:DrawList,x:Float, y:Float, angle:Float, scaleX:Float, scaleY:Float, atlasScale:Float)
		target.DrawImage(image, x, y, angle, scaleX * atlasScale, scaleY * atlasScale)
	End
End