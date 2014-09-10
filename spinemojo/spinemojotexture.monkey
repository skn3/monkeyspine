'see license.txt For source licenses
Strict

Import spine.spinemojo

Class SpineMojoTexture Implements SpineTexture
	Private
	Field _path:String
	Field _width:Int
	Field _height:Int
	Field image:Image
	Public
		
	Method path:String() Property
		Return _path
	End
	
	Method width:Int() Property
		Return _width
	End
	
	Method height:Int() Property
		Return _height
	End
	
	Method Load:Void(path:String)
		_path = path
		image = mojo.LoadImage(path)
		If image
			_width = image.Width()
			_height = image.Height()
		EndIf
	End
	
	Method Discard:Void()
		If image
			image.Discard()
			image = Null
			_path = ""
			_width = 0
			_height = 0
		EndIf
	End
	
	Method Grab:SpineRendererObject(x:Int, y:Int, width:Int, height:Int, handleX:Float, handleY:Float, rotate:Bool)
		Local subImage:Image
		If rotate
			subImage = image.GrabImage(x, y, height, width)
			subImage.SetHandle(handleY, handleX)
		Else
			subImage = image.GrabImage(x, y, width, height)
			subImage.SetHandle(handleX, handleY)
		EndIf
		
		Return New SpineMojoRendererObject(subImage, rotate)
	End
End