'see license.txt For source licenses
Strict

Import spine

'file system
Function SpineExtractDir:String(path:String)
	'extract the dir path portion of a path
	Local i:= path.FindLast("/")
	If i=-1 i=path.FindLast( "\" )
	If i <> - 1 Return path[ .. i]
	Return ""
End

Function SpineExtractFilenameWithoutExtension:String(path:String)
	'extract just filename without extension
	'get rid of extension
	Local i:= path.FindLast(".")
	If i <> - 1 And path.Find("/", i + 1) = -1 And path.Find("\", i + 1) = -1 path = path[ .. i]
	
	'get rid of dir path
	i = path.FindLast("/")
	If i=-1 i=path.FindLast( "\" )
	If i <> - 1 path = path[i + 1 ..]
	
	'Return result
	Return path
End

Function SpineCombinePaths:String(path1:String, path2:String)
	'combine 2 paths And take into account slashes
	Local index:Int
	Local length1:Int = path1.Length()
	Local start2:Int = 0
	Local slash:Bool
	
	'look For End of slash in path 1
	For index = path1.Length() - 1 To 0 Step - 1
		If slash = False
			'havn't found first slash
			If path1[index] = 47 or path1[index] = 92
				'slash
				length1 -= 1
				slash = True
			ElseIf path1[index] = 32
				'space
				length1 -= 1
			Else
				'char
				Exit
			EndIf
		Else
			'look For no more slashes
			If path1[index] = 47 or path1[index] = 92
				'slash
				length1 -= 1
			Else
				'char
				Exit
			EndIf
		EndIf
	Next
	
	'look For start of slash in part 2
	slash = False
	For index = 0 Until path2.Length()
		If slash = False
			'havn't found first slash
			If path2[index] = 47 or path2[index] = 92
				'slash
				start2 += 1
				slash = True
			ElseIf path2[index] = 32
				'space
				start2 += 1
			Else
				'char
				Exit
			EndIf
		Else
			'look For no more slashes
			If path2[index] = 47 or path2[index] = 92
				'slash
				start2 += 1
			Else
				'char
				Exit
			EndIf
		EndIf
	Next
	
	'combine two paths
	'do more effecient combination to avoid creating wasted strings
	If length1 > 0 And start2 < path2.Length()
		'two paths
		If length1 < path1.Length() And start2 > 0
			Return path1[0 .. length1] + "/" + path2[start2 ..]
		ElseIf length1 < path1.Length()
			Return path1[0 .. length1] + "/" + path2
		ElseIf start2 > 0
			Return path1 + "/" + path2[start2 ..]
		Else
			Return path1 + "/" + path2
		EndIf
	ElseIf length1 > 0
		'only first path
		If length1 < path1.Length()
			Return path1[0 .. length1]
		Else
			Return path1
		EndIf
	ElseIf start2 < path2.Length()
		'only second path
		If start2 > 0
			Return path2[start2 ..]
		Else
			Return path2
		EndIf
	EndIf
	
	'no path to Return
	Return ""
End

'atlas
Function SpineLoadAtlas:SpineAtlas(path:String = "")
	' --- helper to load an atlas outside of creating a spine entity ---
	Local atlas:= SpineDefaultAtlasLoader.instance.LoadAtlas(path, SpineDefaultFileLoader.instance)
	
	'increase reference count on atlas
	atlas.Use()
	
	'Return it
	Return atlas
End

Function SpineLoadAtlas:SpineAtlas(path:String = "", atlasLoader:SpineAtlasLoader)
	' --- helper to load an atlas outside of creating a spine entity ---
	Local atlas:= atlasLoader.LoadAtlas(path, SpineDefaultFileLoader.instance)
	
	'increase reference count on atlas
	atlas.Use()
	
	'Return it
	Return atlas
End

Function SpineLoadAtlas:SpineAtlas(path:String = "", fileLoader:SpineFileLoader)
	' --- helper to load an atlas outside of creating a spine entity ---
	Local atlas:= SpineDefaultAtlasLoader.instance.LoadAtlas(path, fileLoader)
	
	'increase reference count on atlas
	atlas.Use()
	
	'Return it
	Return atlas
End

Function SpineLoadAtlas:SpineAtlas(path:String = "", atlasLoader:SpineAtlasLoader, fileLoader:SpineFileLoader)
	' --- helper to load an atlas outside of creating a spine entity ---
	Local atlas:= atlasLoader.LoadAtlas(path, fileLoader)
	
	'increase reference count on atlas
	atlas.Use()
	
	'Return it
	Return atlas
End

'collisions / geometry
Function SpineGetQuad:Int(axisX:Float, axisY:Float, vertX:Float, vertY:Float)
	If vertX<axisX
		If vertY<axisY
			Return 1
		Else
			Return 4
		EndIf
	Else
		If vertY<axisY
			Return 2
		Else
			Return 3
		EndIf	
	EndIf

End Function

Function SpineLinesCross:Bool(x0:Float, y0:Float, x1:Float, y1:Float, x2:Float, y2:Float, x3:Float, y3:Float)
	'Adapted from Fredborg's code
	Local n:Float = (y0 - y2) * (x3 - x2) - (x0 - x2) * (y3 - y2)
	Local d:Float=(x1-x0)*(y3-y2)-(y1-y0)*(x3-x2)
	
	If Abs(d) < 0.0001 
		' Lines are parallel!
		Return False
	Else
		' Lines might cross!
		Local Sn:Float=(y0-y2)*(x1-x0)-(x0-x2)*(y1-y0)

		Local AB:Float=n/d
		If AB>0.0 And AB<1.0
			Local CD:Float=Sn/d
			If CD>0.0 And CD<1.0
				' Intersection Point
				Local X:= x0 + AB * (x1 - x0)
		       	Local Y:= y0 + AB * (y1 - y0)
				Return True
			End If
		End If
	
		' Lines didn't cross, because the intersection was beyond the End points of the lines
	EndIf

	' Lines do Not cross!
	Return False

End Function

Function SpinePointInRect:Bool(pointX:Float, pointY:Float, rectX:Float, rectY:Float, rectWidth:Float, rectHeight:Float)
	' --- returns True if point is inside rect ---
	Return pointX >= rectX And pointX < rectX + rectWidth And pointY >= rectY And pointY < rectY + rectHeight
End Function

Function SpinePointInRect:Bool(pointX:Float, pointY:Float, vertices:Float[])
	' --- returns True if point is inside rect (made of vertices) ---
	'this assumes that the vertices are in order top left, top right, bottom right, bottom left
	Return pointX >= vertices[0] And pointX <= vertices[4] And pointY >= vertices[1] And pointY <= vertices[5]
End Function

Function SpineRectsOverlap:Bool(x1:Float, y1:Float, width1:Float, height1:Float, x2:Float, y2:Float, width2:Float, height2:Float)
	' --- Return True if rects overlap ---
	If x1 > (x2 + width2) Or (x1 + width1) < x2 Then Return False
	If y1 > (y2 + height2) Or (y1 + height1) < y2 Then Return False
	Return True
End Function

Function SpineRectsOverlap:Bool(x:Float, y:Float, width:Float, height:Float, vertices:Float[])
	' --- Return True if rects overlap ---
	'this assumes that the vertices are in order top left, top right, bottom right, bottom left
	If x > vertices[2] Or (x + width) < vertices[0] Then Return False
	If y > vertices[5] Or (y + height) < vertices[1] Then Return False
	Return True
End Function

Function SpinePointInPoly:Bool(pointX:Float, pointY:Float, xy:Float[])
	If xy.Length() < 6 Or (xy.Length() & 1) Return False
	
	Local x1:Float=xy[xy.Length()-2]
	Local y1:Float=xy[xy.Length()-1]
	Local curQuad:Int = SpineGetQuad(pointX, pointY, x1, y1)
	Local nextQuad:Int
	Local total:Int
	
	For Local i:= 0 Until xy.Length() Step 2
		Local x2:Float=xy[i]
		Local y2:Float=xy[i+1]
		nextQuad = SpineGetQuad(pointX, pointY, x2, y2)
		Local diff:Int=nextQuad-curQuad
		
		Select diff
		Case 2,-2
			If ( x2 - ( ((y2 - pointY) * (x1 - x2)) / (y1 - y2) ) )<pointX
				diff=-diff
			EndIf
		Case 3
			diff=-1
		Case -3
			diff=1
		End Select
		
		total+=diff
		curQuad = nextQuad
		x1=x2
		y1=y2
	Next
	
	If Abs(total)=4 Then Return True Else Return False
End Function

Function SpinePolyToPoly:Bool(p1Xy:Float[], p2Xy:Float[])
	
	If p1Xy.Length()<6 Or (p1Xy.Length()&1) Return False
	If p2Xy.Length()<6 Or (p2Xy.Length()&1) Return False
	
	For Local i:Int=0 Until p1Xy.Length() Step 2
		If SpinePointInPoly(p1Xy[i], p1Xy[i + 1], p2Xy) Then Return True
	Next
	For Local i:Int=0 Until p2Xy.Length() Step 2
		If SpinePointInPoly(p2Xy[i], p2Xy[i + 1], p1Xy) Then Return True
	Next
	
	Local l1X1:Float=p1Xy[p1Xy.Length()-2]
	Local l1Y1:Float=p1Xy[p1Xy.Length()-1]
	For Local i1:Int=0 Until p1Xy.Length() Step 2
		Local l1X2:= p1Xy[i1]
		Local l1Y2:= p1Xy[i1 + 1]
		
		Local l2X1:Float=p2Xy[p2Xy.Length()-2]
		Local l2Y1:Float=p2Xy[p2Xy.Length()-1]
		For Local i2:Int=0 Until p2Xy.Length() Step 2
			Local l2X2:= p2Xy[i2]
			Local l2Y2:= p2Xy[i2 + 1]
			
			If SpineLinesCross(l1X1, l1Y1, l1X2, l1Y2, l2X1, l2Y1, l2X2, l2Y2)
				Return True
			EndIf
			
			l2X1=l2X2
			l2Y1=l2Y2
		Next
		l1X1=l1X2
		l1Y1=l1Y2
	Next
	Return False
End Function

Function SpineGetPolyBounding:Void(poly:Float[], out:Float[])
	' --- calculate teh dimensions of the given polygon ---
	Local total:= poly.Length()
	If total < 6
		'no poly (well not one that has area)
		out[0] = 0
		out[1] = 0
		out[2] = 0
		out[3] = 0
	Else
		'calculate min/max
		Local index:Int
		
		'get starting min max from first vector
		Local minX:Float = poly[0]
		Local minY:Float = poly[1]
		Local maxX:Float = poly[0]
		Local maxY:Float = poly[1]
		
		'skip the first point
		For index = 2 Until total Step 2
			If poly[index] < minX minX = poly[index]
			If poly[index] > maxX maxX = poly[index]
			If poly[index+1] < minY minY = poly[index+1]
			If poly[index+1] > maxY maxY = poly[index+1]
		Next
		
		'final calculation
		out[0] = minX
		out[1] = minY
		out[2] = maxX
		out[3] = minY
		out[4] = maxX
		out[5] = maxY
		out[6] = minX
		out[7] = maxY
	EndIf
End Function

'drawing
Function SpineDrawLineRect:Void(x:Float, y:Float, width:Float, height:Float)
	' --- draw a line rect ---
	DrawLine(x, y, x + width, y)
	DrawLine(x + width, y, x + width, y + height)
	DrawLine(x + width, y + height, x, y + height)
	DrawLine(x, y + height, x, y)
End

Function SpineDrawLinePoly:Void(vertices:Float[])
	' --- draw a lined poly ---
	Local total:= vertices.Length()
	
	'draw none
	If total < 2 Return
	
	'draw point
	If total < 4
		DrawPoint(vertices[0], vertices[1])
		Return
	EndIf
	
	'draw 1 line
	If total < 6
		DrawLine(vertices[0], vertices[1], vertices[2], vertices[3])
		Return
	EndIf
	
	'draw 2 lines
	If total < 8
		DrawLine(vertices[0], vertices[1], vertices[2], vertices[3])
		DrawLine(vertices[2], vertices[3], vertices[4], vertices[5])
		Return		
	EndIf
	
	'draw poly
	Local lastX:Float
	Local lastY:Float
	For Local index:= 2 Until total Step 2
		lastX = vertices[index]
		lastY = vertices[index + 1]
		DrawLine(vertices[index - 2], vertices[index - 1], lastX, lastY)
	Next
	DrawLine(lastX, lastY, vertices[0], vertices[1])
End
