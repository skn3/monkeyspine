'see license.txt for source licenses
Strict

Import spine

'mojo imports
Import mojo
Import brl.filepath
Import brl.databuffer
Import monkey.map

'globals
Private
Global spineMojoFileLoader:SpineFileLoader = New SpineMojoFileLoader
Global spineMojoTextureLoader:SpineTextureLoader = New SpineMojoTextureLoader
Global spineMojoAtlasLoader:SpineAtlasLoader = New SpineMojoAtlasLoader
Public

'files
Class SpineMojoFileLoader Implements SpineFileLoader
	Method Load:SpineFile(path:String)
		Local file:= New SpineMojoFile
		file.Load(path)
		Return file
	End
End

Class SpineMojoFile Implements SpineFile
	Private
	Field _path:String
	Field buffer:DataBuffer
	Field index:Int
	Field total:Int
	Field start:Int
	Public
	
	Method path:String()
		Return _path
	End
	
	Method path:Void(value:string)
		_path = value
	End
	
	Method Load:Void(path:String)
		_path = path
		index = 0
		start = 0
		
		'create buffer
		buffer = DataBuffer.Load(_path)
		If buffer = Null Throw SpineException("invalid file: " + path)
		total = buffer.Length()
	End
	
	Method ReadLine:String()
		If buffer = Null or index >= total Return ""
		
		For index = index Until total
			'check for End of line
			If buffer.PeekByte(index) = 10
				Local result:String = buffer.PeekString(start, (index - start))
				index = index + 1
				start = index
				Return result
			EndIf
		Next
		
		Return ""
	End
	
	Method ReadAll:String()
		If buffer = Null Return ""
		
		Local result:= buffer.PeekString(start)
		start = total
		Return result
	End
	
	Method Eof:Bool()
		Return index >= total
	End
	
	Method Close:Void()
		If buffer
			buffer.Discard()
			buffer = Null
		EndIf
	End
End

'textures
Class SpineMojoTextureLoader Implements SpineTextureLoader
	Method Load:SpineTexture(path:String)
		Local texture:= New SpineMojoTexture
		texture.Load(path)
		Return texture
	End
End

Class SpineMojoTexture Implements SpineTexture
	Private
	Field _path:string
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
End

'atlas
Class SpineMojoAtlasLoader Implements SpineAtlasLoader
	Method Load:SpineAtlas(file:SpineFile, dir:String, textureLoader:SpineTextureLoader)
		Local atlas:= New SpineMojoAtlas
		atlas.Load(file, dir, textureLoader)
		Return atlas
	End
End

Class SpineMojoAtlas Implements SpineAtlas
	Private
	Field pages:SpineMojoAtlasPage[]
	Field regions:= New StringMap<SpineMojoAtlasRegion>
	Field textureLoader:SpineMojoTextureLoader
	Public
	
	Method Load:Void(file:SpineFile, imagesDir:String, textureLoader:SpineTextureLoader)
		'load routine taken from official csharp api
		If textureLoader = Null Throw New SpineArgumentNullException("textureLoader cannot be null.")

		Local pages:SpineMojoAtlasPage[1]
		Local pagesCount:Int
		
		Local tuple:String[4]
		Local page:SpineMojoAtlasPage
		Local region:SpineMojoAtlasRegion
		Local line:String
		
		While file.Eof() = False
			line = file.ReadLine()
			
			If line.Trim().Length() = 0
				page = Null
			ElseIf page = Null
				page = New SpineMojoAtlasPage()
				page.name = line

				'size
				ReadTuple(file, tuple)
				page.width = Int(tuple[0])
				page.height = Int(tuple[1])
				
				'format
				ReadTuple(file, tuple)
				page.format = SpineFormat.FromString(tuple[0])

				'filter
				ReadTuple(file, tuple)
				page.minFilter = SpineTextureFilter.FromString(tuple[0])
				page.magFilter = SpineTextureFilter.FromString(tuple[1])
				
				'repeat
				ReadTuple(file, tuple)
				Select tuple[0]
					Case "none"
						page.uWrap = SpineTextureWrap.ClampToEdge
						page.vWrap = SpineTextureWrap.ClampToEdge
					Case "xy"
						page.uWrap = SpineTextureWrap.RepeatTexture
						page.vWrap = SpineTextureWrap.RepeatTexture
					Case "x"
						page.uWrap = SpineTextureWrap.RepeatTexture
						page.vWrap = SpineTextureWrap.ClampToEdge
					Case "y"
						page.uWrap = SpineTextureWrap.ClampToEdge
						page.vWrap = SpineTextureWrap.RepeatTexture
				End
				
				'load texture
				page.texture = textureLoader.Load(PathCombine(imagesDir, page.name))

				'add to pages
				If pagesCount = pages.Length() pages = pages.Resize(pagesCount * 2 + 10)
				pages[pagesCount] = page
				pagesCount += 1
			Else
				'we are scanning regions now
				region = New SpineMojoAtlasRegion()
				region.name = line
				region.page = page

				'rotate
				region.rotate = Bool(Int(ReadValue(file)))

				'xy
				ReadTuple(file, tuple)
				region.x = Int(tuple[0])
				region.y = Int(tuple[1])

				'size
				ReadTuple(file, tuple)
				region.width = Int(tuple[0])
				region.height = Int(tuple[1])

				'uvs
				region.u = region.x / page.width
				region.v = region.y / page.height
				If region.rotate
					region.u2 = (region.x + region.height) / page.width
					region.v2 = (region.y + region.width) / page.height
				Else
					region.u2 = (region.x + region.width) / page.width
					region.v2 = (region.y + region.height) / page.height
				EndIf
				
				'fix size???
				'region.width = Abs(region.width)
				'region.height = Abs(region.height)

				'splits/pads
				If ReadTuple(file, tuple) = 4 'split is optional
					region.splits =[Int(tuple[0]), Int(tuple[1]), Int(tuple[2]), Int(tuple[3])]

					If ReadTuple(file, tuple) = 4 'pad is optional, but only present with splits
						region.pads =[Int(tuple[0]), Int(tuple[1]), Int(tuple[2]), Int(tuple[3])]
						
						ReadTuple(file, tuple)
					EndIf
				EndIf
			
				'original size
				region.originalWidth = Int(tuple[0])
				region.originalHeight = Int(tuple[1])
	
				'offset
				ReadTuple(file, tuple)
				region.offsetX = Int(tuple[0])
				region.offsetY = Int(tuple[1])
	
				'index
				region.index = Int(ReadValue(file))
	
				'add teh region
				regions.Insert(region.name, region)
			EndIf
		Wend
	End
	
	Method Discard:Void()
	End
	
	Private
	Function ReadValue:String(file:SpineFile)
		Local line:String = file.ReadLine()
		Local colon:Int = line.Find(":")
		If colon = -1
			Throw New SpineException("Invalid line: " + line)
		EndIf
		Return line[colon + 1 ..].Trim()
	End

	'<summary>Returns the number of tuple values read (1, 2 or 4).</summary>
	Function ReadTuple:Int(file:SpineFile, tuple:String[])
		Local line:String = file.ReadLine()
		Print "line = " + line
		Local colon:Int = line.Find(":")
		If colon = -1
			Throw New SpineException("Invalid line: " + line)
		EndIf
		
		Local i:Int
		Local lastMatch:Int = colon + 1
		Local comma:Int
		
		For i = 0 Until 3
			comma = line.Find(",", lastMatch)
			If comma = -1 Exit
			tuple[i] = line[lastMatch .. comma].Trim()
			lastMatch = comma + 1
		Next
		tuple[i] = line[lastMatch ..].Trim()
		Return i + 1
	End
	
	Function PathCombine:String(path1:String, path2:String)
		path1 = path1.Replace("\", "/")
		path2 = path2.Replace("\", "/")
		
		'strip slash from start of path 2
		Local index:= 0
		Local length:= path2.Length()
		While path2 < length and path2[index] = "/"
			index += 1
		Wend
		If index = length
			path2 = ""
		ElseIf index > 0
			path2 = path2[index ..]
		EndIf
		
		'strip slash from end of path 1
		index = path1.Length() -1
		While index > - 1 and path1[index] = "/"
			index -= 1
		Wend
		If index = -1
			path1 = ""
		ElseIf index < path1.Length() -1
			path1 = path1[0 .. index]
		EndIf
		
		If path1.Length() and path2.Length()
			Return path1 + "/" + path2
		ElseIf path1.Length()
			Return path1
		ElseIf path2.Length()
			Return path2
		EndIf
		
		Return ""
	End
	Public
	
	'api
	Method FindRegion:SpineAtlasRegion(name:String)
		' --- get the region ---
		Return SpineAtlasRegion(regions.ValueForKey(name))
	End
End

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

Class SpineMojoAtlasRegion Implements SpineAtlasRegion
	Private
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

'fuintions
Function LoadMojoSpineEntity:SpineEntity(skeletonPath:String, atlasPath:String)
	Return New SpineEntity(skeletonPath, atlasPath, ExtractDir(atlasPath), spineMojoFileLoader, spineMojoAtlasLoader, spineMojoTextureLoader)
End

Function LoadMojoSpineEntity:SpineEntity(skeletonPath:String, atlasPath:String, atlasDir:String)
	Return New SpineEntity(skeletonPath, atlasPath, atlasDir, spineMojoFileLoader, spineMojoAtlasLoader, spineMojoTextureLoader)
End