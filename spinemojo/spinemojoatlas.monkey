'see license.txt For source licenses
Strict

Import spine.spinemojo

Class SpineMojoAtlas Implements SpineAtlas
	Private
	Field pages:SpineMojoAtlasPage[]
	Field regions:= New StringMap<SpineMojoAtlasRegion>
	Field textureLoader:SpineMojoTextureLoader
	Public
	
	Method Load:Void(file:SpineFile, imagesDir:String, textureLoader:SpineTextureLoader)
		'load routine taken from official csharp api
		If textureLoader = Null Throw New SpineArgumentNullException("textureLoader cannot be Null.")

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
				
				'Repeat
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
				ReadTuple(file, tuple)
				region.rotate = (tuple[0] = "true")
				
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
	
				'grab the mojo image
				region.rendererObject = page.texture.Grab(region.x, region.y, region.width, region.height, region.width / 2.0, region.height / 2.0, region.rotate)
				
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
		
		'strip slash from End of path 1
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