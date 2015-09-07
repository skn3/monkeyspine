'see license.txt For source licenses
Strict

Import spine.spinemojo

Class SpineMojoTexture Implements SpineTexture
	Private
	Field _path:String
	Field _width:Int
	Field _height:Int
	Field material:Material
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
	
	Method Load:Void(path:String, flags:Int = Image.Filter | Image.Mipmap, shader:Shader = Null)
		_path = path
		
		'uses default shader when shader = null
		material = material.Load(path, flags, shader)
		
		If material
			_width = material.Width()
			_height = material.Height()
		EndIf
	End
	
	Method Discard:Void()
		If material
			material.Destroy()
			material = Null
		EndIf
		
		_path = ""
		_width = 0
		_height = 0
	End
	
	Method Grab:SpineRenderObject(x:Int, y:Int, width:Int, height:Int, handleX:Float, handleY:Float, rotate:Bool)
		Return New SpineMojoTextureRenderObject(material, x, y, width, height, handleX, handleY, rotate)
	End
End