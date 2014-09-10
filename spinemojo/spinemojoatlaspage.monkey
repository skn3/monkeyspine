'see license.txt for source licenses
Strict

Import spine.spinemojo

Class SpineMojoAtlasPage Implements SpineAtlasPage
	Private
	Field _texture:SpineMojoTexture
	Field _name:String
	Field _format:Int
	Field _minFilter:Int
	Field _magFilter:Int
	Field _uWrap:Int
	Field _vWrap:Int
	Field _width:Int
	Field _height:Int
	Public
	
	Method texture:SpineTexture() Property
		Return _texture
	End
	
	Method texture:Void(value:SpineTexture) Property
		_texture = SpineMojoTexture(value)
	End
	
	Method name:String() Property
		Return _name
	End
	
	Method name:Void(value:String) Property
		_name = value
	End
	
	Method format:String() Property
		Return _format
	End
	
	Method format:Void(value:Int) Property
		_format = value
	End
	
	Method minFilter:Int() Property
		Return _minFilter
	End
	
	Method minFilter:Void(value:Int) Property
		_minFilter = value
	End
	
	Method magFilter:Int() Property
		Return _magFilter
	End
	
	Method magFilter:Void(value:Int) Property
		_magFilter = value
	End
	
	Method uWrap:Int() Property
		Return _uWrap
	End
	
	Method uWrap:Void(value:Int) Property
		_uWrap = value
	End
	
	Method vWrap:Int() Property
		Return _vWrap
	End
	
	Method vWrap:Void(value:Int) Property
		_vWrap = value
	End
	
	Method width:Int() Property
		Return _width
	End
	
	Method width:Void(value:Int) Property
		_width = value
	End
	
	Method height:Int() Property
		Return _height
	End
	
	Method height:Void(value:Int) Property
		_height = value
	End
End