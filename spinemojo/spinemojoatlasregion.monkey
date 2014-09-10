'see license.txt for source licenses
Strict

Import spine.spinemojo

Class SpineMojoAtlasRegion Implements SpineAtlasRegion
	Private
	Field _rendererObject:SpineMojoRendererObject
	Field _page:SpineMojoAtlasPage
	Field _name:String
	Field _x:Int
	Field _y:Int
	Field _width:Int
	Field _height:Int
	Field _u:Float
	Field _v:Float
	Field _u2:Float
	Field _v2:Float
	Field _offsetX:Float
	Field _offsetY:Float
	Field _originalWidth:Int
	Field _originaHeight:Int
	Field _index:Int
	Field _rotate:Bool
	Field _splits:Int[]
	Field _pads:Int[]
	Public

	Method rendererObject:SpineRendererObject() Property
		Return _rendererObject
	End
	
	Method rendererObject:Void(value:SpineRendererObject) Property
		_rendererObject = SpineMojoRendererObject(value)
	End
	
	Method page:SpineAtlasPage() Property
		Return _page
	End
	
	Method page:Void(value:SpineAtlasPage) Property
		_page = SpineMojoAtlasPage(value)
	End
	
	Method name:String() Property
		Return _name
	End
	
	Method name:Void(value:string) Property
		_name = value
	End
	
	Method x:Int() Property
		Return _x
	End
	
	Method x:Void(value:Int) Property
		_x = value
	End
	
	Method y:Int() Property
		Return _y
	End
	
	Method y:Void(value:Int) Property
		_y = value
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
	
	Method u:Float() Property
		Return _u
	End
	
	Method u:Void(value:Float) Property
		_u = value
	End
	
	Method v:Float() Property
		Return _v
	End
	
	Method v:Void(value:Float) Property
		_v = value
	End
	
	Method u2:Float() Property
		Return _u2
	End
	
	Method u2:Void(value:Float) Property
		_u2 = value
	End
	
	Method v2:Float() Property
		Return _v2
	End
	
	Method v2:Void(value:Float) Property
		_v2 = value
	End
	
	Method offsetX:Float() Property
		Return _offsetX
	End
	
	Method offsetX:Void(value:Float) Property
		_offsetX = value
	End
	
	Method offsetY:Float() Property
		Return _offsetY
	End
	
	Method offsetY:Void(value:Float) Property
		_offsetY = value
	End
	
	Method originalWidth:Int() Property
		Return _originalWidth
	End
	
	Method originalWidth:Void(value:Int) Property
		_originalWidth = value
	End
	
	Method originalHeight:Int() Property
		Return _originaHeight
	End
	
	Method originalHeight:Void(value:Int) Property
		_originaHeight = value
	End
	
	Method index:Int() Property
		Return _index
	End
	
	Method index:Void(value:Int) Property
		_index = value
	End
	
	Method rotate:Bool() Property
		Return _rotate
	End
	
	Method rotate:Void(value:Bool) Property
		_rotate = value
	End
	
	Method splits:int[] () Property
		Return _splits
	End
	
	Method splits:Void(value:int[]) Property
		_splits = value
	End
	
	Method pads:int[] () Property
		Return _pads
	End
	
	Method pads:Void(value:int[]) Property
		_pads = value
	End
End