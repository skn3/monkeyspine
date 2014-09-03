'see license.txt for source licenses
Strict

Import spine

'these interfaces and classes allow 3rd party developers to extend the monkey spine runtime

'atlas interfaces
Interface SpineAtlasLoader
	Method LoadAtlas:SpineAtlas(path:String, fileLoader:SpineFileLoader = SpineDefaultFileLoader.instance)
End

Interface SpineAtlas
	Method Use:Void()
	Method Free:Void(force:Bool = False)
	Method Lock:Void()
	Method AddRegion:SpineAtlasRegion(page:SpineAtlasPage, name:String, x:Int, y:Int, width:Int, height:Int, offsetX:Int, offsetY:Int, originalWidth:Int, originalHeight:Int)
	Method UnLock:Void()
	Method GetRegion:SpineAtlasRegion(name:String)
End

Interface SpineAtlasPage
	Method GetWidth:Int()
	Method GetHeight:Int()
End

Interface SpineAtlasRegion
	Method Draw:Void(x:Float, y:Float, rotation:Float, scaleX:Float, scaleY:Float, handleX:Float, handleY:Float, vertices:Float[])

	Method GetX:Int()
	Method GetY:Int()
	Method GetWidth:Int()
	Method GetHeight:Int()
	Method GetOffsetX:Int()
	Method GetOffsetY:Int()
	Method GetOriginalWidth:Int()
	Method GetOriginalHeight:Int()
End

'atlas loaders
Class SpineDefaultAtlasLoader Implements SpineAtlasLoader
	Global instance:= New SpineDefaultAtlasLoader
	
	Method LoadAtlas:SpineAtlas(path:String, fileLoader:SpineFileLoader = SpineDefaultFileLoader.instance)
		' --- load an atlas using the MakeAtlas JSON format ---
		'http://monkeycoder.co.nz/Community/posts.php:?topic=5088
		
		'attempt to load atlas json
		Local fileStream:= fileLoader.LoadFile(path)
				
		Local token1:String
		
		Local line:String
		Local pos1:Int
		Local pos2:Int
		
		Local imagesDir:String = SpineExtractDir(path)
		
		Local page:SpineDefaultAtlasPage
		Local pageIndex:= 0
		Local pageNew:= True
		Local pageHasStart:= False
		Local pageHasHeader:= False
		Local pageFilePath:String
		Local pageFormat:String
		Local pageFilterMin:String
		Local pageFilterMag:String
		Local pageRepeat:String
		
		Local region:SpineDefaultAtlasRegion
		Local regionNew:Bool
		Local regionSave:Bool
		Local regionName:String
		Local regionNextName:String
		Local regionIndex:Int
		Local regionRotate:Bool
		Local regionX:Int
		Local regionY:Int
		Local regionWidth:Int
		Local regionHeight:Int
		Local regionFrameX:Int
		Local regionFrameY:Int
		Local regionFrameWidth:Int
		Local regionFrameHeight:Int
		
		'create the atlas
		Local atlas:= New SpineDefaultAtlas
		
		'prepare atlas for loading
		atlas.Lock()
		
		'read in the file
		While fileStream.Eof() = False
			'get line from stream
			line = fileStream.ReadLine()
			'are we starting a new page ?
			If pageNew = True
				'ignore blank lines
				If line.Length() > 0
					If pageHasStart = False
						'first line has no ':' it states the image file
						'get image path
						pageFilePath = SpineCombinePaths(imagesDir, line)
						
						'create new page
						page = SpineDefaultAtlasPage(atlas.AddPage(pageFilePath))
						
						'check that page was loaded
						If page = Null Throw New SpineException("Invalid Image '" + pageFilePath + "' For Page '" + pageIndex + "' In Atlas '" + path + "'")
						
						'image loaded woohoo continue
						pageHasStart = True
					Else
						'reading in properties
						pos1 = line.Find(":")
						If pos1 >= 0
							'this is a property
							token1 = line[0 .. pos1]
							
							Select token1
								Case "format"
									'ignored
									pageFormat = line[pos1 + 2 ..]
								Case "filter"
									'ignored
									pos2 = line.Find(",", pos1 + 1)
									If pos2 = -1
										pageFilterMin = line[pos1 + 2 ..]
										pageFilterMag = ""
									Else
										pageFilterMin = line[pos1 + 2 .. pos2]
										pageFilterMag = line[pos2 + 2 ..]
									EndIf
								Case "repeat"
									'ignored
									pageRepeat = line[pos1 + 2 ..]
							End
						Else
							'so we now on to defining items
							pageHasHeader = True
							pageNew = False
							
							'new region
							regionNew = True
							regionNextName = line
						EndIf
					EndIf
				EndIf
			Else
				'need to check for end of page
				If line.Length() = 0
					'page is finished
					pageNew = True
					pageHasHeader = False
				Else
					'do reset of values
					If regionNew
						regionNew = False
						
						regionName = regionNextName
						regionIndex = -1
						regionRotate = False
						regionX = 0
						regionY = 0
						regionWidth = 0
						regionHeight = 0
						regionFrameX = 0
						regionFrameY = 0
						regionFrameWidth = 0
						regionFrameHeight = 0
					EndIf
					
					pos1 = line.Find(":")
					If pos1 = -1
						'this is a new region
						
						'setup control flags
						regionSave = True
						regionNew = True
						regionNextName = line
					Else
						'this is a property
						token1 = line[2 .. pos1]
						
						Select token1
							Case "rotate"
								If line[pos1 + 2 ..] = "true"
									'Not supported yet
									regionRotate = True
									Throw New SpineException("Invalid Region (rotation not supported)'" + regionName + "' For Page '" + pageIndex + "' In Atlas '" + path + "'")
								Else
									regionRotate = False
								EndIf
							Case "xy"
								pos2 = line.Find(",", pos1 + 1)
								If pos2 = -1
									regionX = Int(line[pos1 + 2 ..])
									regionY = 0
								Else
									regionX = Int(line[pos1 + 2 .. pos2])
									regionY = Int(line[pos2 + 2 ..])
								EndIf
							Case "size"
								pos2 = line.Find(",", pos1 + 1)
								If pos2 = -1
									regionWidth = Int(line[pos1 + 2 ..])
									regionHeight = 0
								Else
									regionWidth = Int(line[pos1 + 2 .. pos2])
									regionHeight = Int(line[pos2 + 2 ..])
								EndIf
							Case "orig"
								pos2 = line.Find(",", pos1 + 1)
								If pos2 = -1
									regionFrameWidth = Int(line[pos1 + 2 ..])
									regionFrameHeight = 0
								Else
									regionFrameWidth = Int(line[pos1 + 2 .. pos2])
									regionFrameHeight = Int(line[pos2 + 2 ..])
								EndIf
							Case "offset"
								pos2 = line.Find(",", pos1 + 1)
								If pos2 = -1
									regionFrameX = Int(line[pos1 + 2 ..])
									regionFrameY = 0
								Else
									regionFrameX = Int(line[pos1 + 2 .. pos2])
									regionFrameY = Int(line[pos2 + 2 ..])
								EndIf
							Case "index"
								regionIndex = Int(line[pos1 + 2 ..])
						End
					EndIf
				EndIf
			EndIf
			
			'if we are at teh end of the file lets force region to save
			If fileStream.Eof() And pageHasHeader And regionNew = False
				'force save the region as eof
				regionSave = True
			EndIf
			
			'do we need to process adding the region?
			If regionSave
				regionSave = False
				
				'add the region
				region = SpineDefaultAtlasRegion(atlas.AddRegion(page, regionName, regionX, regionY, regionWidth, regionHeight, regionFrameX, regionFrameY, regionFrameWidth, regionFrameHeight))
				
				'check to see if we failed to create this region?
				If region = Null
					Throw New SpineException("Invalid Region '" + regionName + "' For Page '" + pageIndex + "' In Atlas '" + path + "'")
				EndIf
			EndIf
		Wend
		
		'finalise atlas loading
		atlas.UnLock()
		
		'return the loaded atlas
		Return atlas
	End
End

Class SpineMakeAtlasLoader Implements SpineAtlasLoader
	Global instance:= New SpineMakeAtlasLoader
	
	Method LoadAtlas:SpineAtlas(path:String, fileLoader:SpineFileLoader = SpineDefaultFileLoader.instance)
		' --- load an atlas using the MakeAtlas JSON format ---
		'http://monkeycoder.co.nz/Community/posts.php:?topic=5088
		
		'attempt to load atlas json
		Local jsonPages:JSONArray
		Local fileStream:= fileLoader.LoadFile(path)
		If fileStream jsonPages = JSONArray(JSONData.ReadJSON(fileStream.ReadAll()))
		If jsonPages = Null Throw New SpineException("Invalid Atlas '" + path + "'")
		
		'get images directory
		Local imagesDir:String = SpineExtractDir(path)
		
		'create the atlas
		Local atlas:= New SpineDefaultAtlas
		
		'prepare atlas for loading
		atlas.Lock()
		
		'iterate over the pages
		Local jsonPageDataItem:JSONDataItem
		Local jsonPageObject:JSONObject
		Local jsonDataItem:JSONDataItem
		Local jsonItemsObject:JSONObject
		Local jsonItemObject:JSONObject
		
		Local page:SpineDefaultAtlasPage
		Local pageIndex:Int = -1
		Local pageFileName:String
		Local pageFilePath:String
		
		Local region:SpineDefaultAtlasRegion
		Local regionName:String
		Local regionValid:Bool
		Local regionX:Int
		Local regionY:Int
		Local regionWidth:Int
		Local regionHeight:Int
		Local regionFrameX:Int
		Local regionFrameY:Int
		Local regionFrameWidth:Int
		Local regionFrameHeight:Int
		
		For jsonPageDataItem = EachIn jsonPages
			jsonPageObject = JSONObject(jsonPageDataItem)
			
			'reset page
			pageFileName = ""
			pageFilePath = ""
			page = Null
			pageIndex += 1
			
			'check page has items
			jsonItemsObject = JSONObject(jsonPageObject.GetItem("items"))
			If jsonItemsObject = Null Continue
			
			'check the page has file defined
			jsonDataItem = JSONString(jsonPageObject.GetItem("file"))
			If jsonDataItem <> Null pageFileName = jsonDataItem
			
			'add the page if correct details are there
			If pageFileName.Length() > 0
				'build valid path for image
				pageFilePath = SpineCombinePaths(imagesDir, pageFileName)
				
				'attempt to load the page
				page = SpineDefaultAtlasPage(atlas.AddPage(pageFilePath))
			EndIf
			
			'check that page was loaded
			If page = Null Throw New SpineException("Invalid Image '" + pageFilePath + "' For Page '" + pageIndex + "' In Atlas '" + path + "'")
			
			'iterate over regions
			For regionName = EachIn jsonItemsObject.Names()
				'get the region item
				jsonItemObject = JSONObject(jsonItemsObject.GetItem(regionName))
				
				'reset values
				regionValid = True
				region = Null
				
				'validate data
				'region x
				If regionValid
					jsonDataItem = JSONInteger(jsonItemObject.GetItem("x"))
					If jsonDataItem = Null
						regionValid = False
					Else
						regionX = jsonDataItem
						If regionX < 0 or regionX >= page.GetWidth() regionValid = False
					EndIf
				EndIf
				
				'region y
				If regionValid
					jsonDataItem = JSONInteger(jsonItemObject.GetItem("y"))
					If jsonDataItem = Null
						regionValid = False
					Else
						regionY = jsonDataItem.ToInt()
						If regionY < 0 or regionY >= page.GetHeight() regionValid = False
					EndIf
				EndIf
				
				'region width
				If regionValid
					jsonDataItem = JSONInteger(jsonItemObject.GetItem("width"))
					If jsonDataItem = Null
						regionValid = False
					Else
						regionWidth = jsonDataItem.ToInt()
						If regionWidth > 0 and regionX + regionWidth > page.GetWidth() regionValid = False
					EndIf
				EndIf
				
				'region height
				If regionValid
					jsonDataItem = JSONInteger(jsonItemObject.GetItem("height"))
					If jsonDataItem = Null
						regionValid = False
					Else
						regionHeight = jsonDataItem.ToInt()
						If regionHeight > 0 and regionY + regionHeight > page.GetHeight() regionValid = False
					EndIf
				EndIf
				
				'create the region
				If regionValid
					'get optional frame data (from trimmed atlas items)
					'region frame x
					jsonDataItem = JSONInteger(jsonItemObject.GetItem("frameX"))
					If jsonDataItem = Null
						regionFrameX = 0
					Else
						regionFrameX = jsonDataItem.ToInt()
					EndIf
					
					'region frame y
					jsonDataItem = JSONInteger(jsonItemObject.GetItem("frameY"))
					If jsonDataItem = Null
						regionFrameY = 0
					Else
						regionFrameY = jsonDataItem.ToInt()
					EndIf
					
					'region frame width
					jsonDataItem = JSONInteger(jsonItemObject.GetItem("frameWidth"))
					If jsonDataItem = Null
						regionFrameWidth = regionWidth
					Else
						regionFrameWidth = jsonDataItem.ToInt()
					EndIf
					
					'region frame height
					jsonDataItem = JSONInteger(jsonItemObject.GetItem("frameHeight"))
					If jsonDataItem = Null
						regionFrameHeight = regionHeight
					Else
						regionFrameHeight = jsonDataItem.ToInt()
					EndIf
					
					'create the region now that it has validated
					region = SpineDefaultAtlasRegion(atlas.AddRegion(page, regionName, regionX, regionY, regionWidth, regionHeight, regionFrameX, regionFrameY, regionFrameWidth, regionFrameHeight))
				EndIf
				
				'check to see if we failed to create this region?
				If region = Null
					Throw New SpineException("Invalid Region '" + regionName + "' For Page '" + pageIndex + "' In Atlas '" + path + "'")
				EndIf
			Next
		Next
		
		'finalise atlas loading
		atlas.UnLock()
		
		'return the loaded atlas
		Return atlas
	End
End

Class SpineSeperateImageLoader Implements SpineAtlasLoader
	Global instance:= New SpineSeperateImageLoader
	
	Method LoadAtlas:SpineAtlas(path:String, fileLoader:SpineFileLoader = SpineDefaultFileLoader.instance)
		' --- load the images path ---
		'create atlas and set images path
		Local atlas:= New SpineSeperateImageAtlas
		atlas.path = path
		
		'return it
		Return atlas
	End
End

Private
'default atlas implementation
Class SpineDefaultAtlas Implements SpineAtlas
	Field refCount:Int
	Field pages:SpineDefaultAtlasPage[]
	Field pagesCount:Int
	Field regions:SpineDefaultAtlasRegion[]
	Field regionsCount:Int
	
	Method Use:Void()
		' --- increase reference count of atlas ---
		refCount += 1
	End
	
	Method Free:Void(force:Bool = False)
		' --- free teh atlas ---
		'decrease reference count
		refCount -= 1
		
		'only free if reference count says so
		If force or refCount <= 0
			Local index:Int
			
			For index = 0 Until regions.Length()
				regions[index].page = Null
				regions[index].image = Null
			Next
			
			For index = 0 Until pages.Length()
				pages[index].image.Discard()
				pages[index].image = Null
			Next
		EndIf
	End
	
	Method Lock:Void()
		' --- atlas is about to be created ---
		'do nothing
	End
	
	Method AddPage:SpineAtlasPage(path:String)
		' --- add page to atlas ---
		'create new page
		Local page:= New SpineDefaultAtlasPage
		page.index = pagesCount
		
		'load the page image
		page.image = LoadImage(path)
		If page.image = Null Throw New SpineException("Invalid atlas page image '" + path + "'")
		
		'add to pages
		If pagesCount >= pages.Length() pages = pages.Resize(pages.Length() * 2 + 10)
		pages[pagesCount] = page
		pagesCount += 1
		
		'return page
		Return page
	End
	
	Method AddRegion:SpineAtlasRegion(page:SpineAtlasPage, name:String, x:Int, y:Int, width:Int, height:Int, offsetX:Int, offsetY:Int, originalWidth:Int, originalHeight:Int)
		' --- add a new region to atlas ---
		'create new region
		Local region:= New SpineDefaultAtlasRegion
		
		'setup the details for the region
		region.Name = name
		region.page = SpineDefaultAtlasPage(page)
		region.x = x
		region.y = y
		region.width = width
		region.height = height
		region.offsetX = offsetX
		region.offsetY = offsetY
		region.originalWidth = originalWidth
		region.originalHeight = originalHeight
		
		'grab image from the page image
		region.image = region.page.image.GrabImage(x, y, width, height)
		
		'figure out correct mid handle
		region.image.SetHandle(0, 0)'offsetX + (originalWidth / 2.0), offsetY + (originalHeight / 2.0))
		
		'add to regions
		If regionsCount >= regions.Length() regions = regions.Resize(regions.Length() * 2 + 10)
		regions[regionsCount] = region
		regionsCount += 1
		
		'return it
		Return region
	End
	
	Method UnLock:Void()
		' --- atlas has finished being created ---
		'trim arrays
		If pagesCount < pages.Length() pages = pages.Resize(pagesCount)
		If regionsCount < regions.Length() regions = regions.Resize(regionsCount)
	End
	
	Method GetRegion:SpineAtlasRegion(name:String)
		' --- lookup region by name ---
		For Local index:= 0 Until regions.Length()
			If regions[index].Name = name Return regions[index]
		Next
		Return Null
	End
End

Class SpineDefaultAtlasPage Implements SpineAtlasPage
	Field index:Int
	Field image:Image
	
	Method GetWidth:Int()
		' --- return page info ---
		Return image.Width()
	End
	
	Method GetHeight:Int()
		' --- return page info ---
		Return image.Height()
	End
End

Class SpineDefaultAtlasRegion Implements SpineAtlasRegion
	Field name:String
	Field page:SpineDefaultAtlasPage
	Field image:Image
	Field x:Int
	Field y:Int
	Field width:Int
	Field height:Int
	Field offsetX:Int
	Field offsetY:Int
	Field originalWidth:Int
	Field originalHeight:Int
	
	Method ToString:String()
		Return "name: " + name + ", x: " + x + ", y: " + y + ", width: " + width + ", height: " + height + ", offsetx: " + offsetX + ", offsety: " + offsetY + ", originalwidth: " + originalWidth + ", originalheight: " + originalHeight
	End
	
	Method Draw:Void(x:Float, y:Float, rotation:Float, scaleX:Float, scaleY:Float, handleX:Float, handleY:Float, vertices:Float[])
		' --- draw the region using the provided details ---
		'both sets of details are provided so it is upto the implementation to choose how to render
		PushMatrix()
		Translate(x, y)
		Rotate(rotation)
		Scale(scaleX, scaleY)
		Translate(handleX, handleY)
		DrawImage(image, 0, 0)
		PopMatrix()
	End

	Method GetX:Int()
		' --- return info about region ---
		Return x
	End
	
	Method GetY:Int()
		' --- return info about region ---
		Return y
	End
		
	Method GetWidth:Int()
		' --- return info about region ---
		Return width
	End
	
	Method GetHeight:Int()
		' --- return info about region ---
		Return height
	End
	
	Method GetOffsetX:Int()
		' --- return info about region ---
		Return offsetX
	End
	
	Method GetOffsetY:Int()
		' --- return info about region ---
		Return offsetY
	End
	
	Method GetOriginalWidth:Int()
		' --- return info about region ---
		Return originalWidth
	End
	
	Method GetOriginalHeight:Int()
		' --- return info about region ---
		Return originalHeight
	End
End

'seperate image atlas implementation
Class SpineSeperateImageAtlas Implements SpineAtlas
	Field refCount:Int
	Field locked:Bool
	Field path:String
	Field regions:SpineSeperateImageAtlasRegion[]
	Field regionsCount:Int
	
	Method Use:Void()
		' --- increase reference count of atlas ---
		refCount += 1
	End
	
	Method Free:Void(force:Bool = False)
		' --- free ---
		'decrease reference count
		refCount -= 1
		
		'only free if reference count says so
		If force or refCount <= 0
			For Local index:Int = 0 Until regions.Length()
				regions[index].image.Discard()
				regions[index].image = Null
			Next
		EndIf
	End
	
	Method Lock:Void()
		' --- atlas is about to be created ---
		locked = True
	End
	
	Method AddPage:SpineAtlasPage(path:String)
		' --- add page to atlas ---
		'do nothing
		Return Null
	End
	
	Method AddRegion:SpineAtlasRegion(page:SpineAtlasPage, name:String, x:Int, y:Int, width:Int, height:Int, offsetX:Int, offsetY:Int, originalWidth:Int, originalHeight:Int)
		' --- add a new region to atlas ---
		'create new region
		Local region:= New SpineSeperateImageAtlasRegion
		
		'setup the details for the region
		region.Name = name
		
		'load the image
		Local regionPath:String = SpineCombinePaths(path, name + ".png")
		region.image = LoadImage(regionPath)
		'If region.image = Null
		'	Throw New SpineException("Invalid image path '" + regionPath + "'")
		'EndIf
		If region.image
			region.image.SetHandle(0, 0)'region.image.Width() / 2.0, region.image.Height() / 2.0)
		EndIf
		
		'add to regions
		If regionsCount >= regions.Length() regions = regions.Resize(regions.Length() * 2 + 10)
		regions[regionsCount] = region
		regionsCount += 1
		
		'return it
		Return region
	End
	
	Method UnLock:Void()
		' --- atlas has finished being created ---
		'trim arrays
		If regionsCount < regions.Length() regions = regions.Resize(regionsCount)
		locked = False
	End
	
	Method GetRegion:SpineAtlasRegion(name:String)
		' --- lookup region by name ---
		If locked
			'adding region to atlas
			Return AddRegion(Null, name, 0, 0, 0, 0, 0, 0, 0, 0)
		Else
			'gettting region at runtime
			For Local index:= 0 Until regions.Length()
				If regions[index].Name = name Return regions[index]
			Next
		EndIf
		Return Null
	End
End

Class SpineSeperateImageAtlasRegion Implements SpineAtlasRegion
	Field name:String
	Field image:Image
	
	Method Draw:Void(x:Float, y:Float, rotation:Float, scaleX:Float, scaleY:Float, handleX:Float, handleY:Float, vertices:Float[])
		' --- draw the region using the provided details ---
		'both sets of details are provided so it is upto the implementation to choose how to render
		If image
			PushMatrix()
			Translate(x, y)
			Rotate(rotation)
			Scale(scaleX, scaleY)
			Translate(handleX, handleY)
			DrawImage(image, 0, 0)
			PopMatrix()
		EndIf
	End

	Method GetX:Int()
		' --- return info about region ---
		Return 0
	End
	
	Method GetY:Int()
		' --- return info about region ---
		Return 0
	End
		
	Method GetWidth:Int()
		' --- return info about region ---
		If image = Null Return 0
		Return image.Width()
	End
	
	Method GetHeight:Int()
		' --- return info about region ---
		If image = Null Return 0
		Return image.Height()
	End
	
	Method GetOffsetX:Int()
		' --- return info about region ---
		Return 0
	End
	
	Method GetOffsetY:Int()
		' --- return info about region ---
		Return 0
	End
	
	Method GetOriginalWidth:Int()
		' --- return info about region ---
		If image = Null Return 0
		Return image.Width()
	End
	
	Method GetOriginalHeight:Int()
		' --- return info about region ---
		If image = Null Return 0
		Return image.Height()
	End
End

Public