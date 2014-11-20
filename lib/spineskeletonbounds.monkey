'see license.txt For source licenses
Strict

Import spine

Class SpineSkeletonBounds
	Private
	Field polygonPool:SpinePolygon[]
	Field polygonPoolTotal:Int

	Field boundingBoxesTotal:Int
	Field polygonsTotal:Int
	
	Public
	Field BoundingBoxes:SpineBoundingBoxAttachment[]
	Field Polygons:SpinePolygon[]
	Field MinX:Float
	Field MinY:Float
	Field MaxX:Float
	Field MaxY:Float
	
	Method Width:Float() Property
		Return MaxX - minX
	End
	
	Method Height:Float() Property
		Return MaxY - MinY
	End

	Method Update:Void(skeleton:SpineSkeleton, updateAabb:Bool)
		Local i:Int
		Local slots:= skeleton.slots
		Local slotCount:= slots.Length()
		Local slot:SpineSlot
		Local boundingBox:SpineBoundingBoxAttachment
		Local polygon:SpinePolygon

		For i = 0 Until boundingBoxesTotal
			BoundingBoxes[i] = Null
		Next
		boundingBoxesTotal = 0
		
		If polygonPoolTotal + polygonsTotal > polygonPool.Length() polygonPool = polygonPool.Resize(polygonPoolTotal + polygonsTotal * 2 + 10)
		For i = 0 Until polygonsTotal
			polygonPool[polygonPoolTotal] = Polygons[i]
			polygonPoolTotal += 1
		Next
		polygonsTotal = 0

		For i = 0 Until slotCount
			slot = slots[i]
			boundingBox = SpineBoundingBoxAttachment(slot.Attachment)
			If boundingBox = Null Continue
			
			If boundingBoxesTotal = BoundingBoxes.Length() BoundingBoxes = BoundingBoxes.Resize(boundingBoxesTotal * 2 + 10)
			boundingBoxes[boundingBoxesTotal] = boundingBox
			boundingBoxesTotal += 1
	
			If polygonPoolTotal > 0
				polygonPoolTotal -= 1
				polygon = polygonPool[polygonPoolTotal]
				polygonPool[polygonPoolTotal] = Null
			Else
				polygon = New SpinePolygon()
			EndIf
			
			If polygonsTotal = Polygons.Length() Polygons = Polygons.Resize(polygonsTotal * 2 + 10)
			Polygons[polygonsTotal] = polygon
			polygonsTotal += 1
	
			polygon.Count = boundingBox.Vertices.Length()
			if polygon.Vertices.Length() < polygon.Count polygon.Vertices = New Float[polygon.Count]
			boundingBox.ComputeWorldVertices(slot.Bone, polygon.Vertices)
		Next

		If updateAabb AabbCompute()
	End

	Method AabbCompute:Void()
		Local minX:Float = SPINE_MAX_FLOAT
		Local minY:Float = SPINE_MAX_FLOAT
		Local maxX:Float = SPINE_MIN_FLOAT
		Local maxY:Float = SPINE_MIN_FLOAT
		
		Local polygon:SpinePolygon
		Local vertices:Float[]
		Local ii:Int
		Local nn:Int
		Local x:Float
		Local y:Float
		For Local i:= 0 Until polygonsTotal
			polygon = Polygons[i]
			vertices = polygon.Vertices
			nn = polygon.Count
			For ii = 0 Until nn Step 2
				x = vertices[ii]
				y = vertices[ii + 1]
				minX = Min(minX, x)
				minY = Min(minY, y)
				maxX = Max(maxX, x)
				maxY = Max(maxY, y)
			Next
		Next
		
		Self.MinX = minX
		Self.MinY = minY
		Self.MaxX = maxX
		Self.MaxY = maxY
	End

	
	'<summary>Returns True if the axis aligned bounding box contains the point.</summary>
	Method AabbContainsPoint:Bool(x:Float, y:Float)
		Return x >= MinX And x <= MaxX And y >= MinY And y <= MaxY
	End

	'<summary>Returns True if the axis aligned bounding box intersects the line segment.</summary>
	Method AabbIntersectsSegment:Bool(x1:Float, y1:Float, x2:Float, y2:Float)
		Local minX:Float = Self.minX
		Local minY:Float = Self.minY
		Local maxX:Float = Self.maxX
		Local maxY:Float = Self.maxY
		
		If (x1 <= minX And x2 <= minX) Or (y1 <= minY And y2 <= minY) Or (x1 >= maxX And x2 >= maxX) Or (y1 >= maxY And y2 >= maxY) Return False
		
		Local m:Float = (y2 - y1) / (x2 - x1)
		Local y:Float = m * (minX - x1) + y1
		If y > minY And y < maxY Return True
		y = m * (maxX - x1) + y1
		If y > minY And y < maxY Return True
		Local x:Float = (minY - y1) / m + x1
		If x > minX And x < maxX Return True
		x = (maxY - y1) / m + x1
		If x > minX And x < maxX Return True
		
		Return False
	End

	'<summary>Returns True if the axis aligned bounding box intersects the axis aligned bounding box of the specified bounds.</summary>
	Method AabbIntersectsSkeleton:Bool(bounds:SpineSkeletonBounds)
		Return minX < bounds.MaxX And maxX > bounds.MinX And minY < bounds.MaxY And maxY > bounds.MinY
	End
	
	'<summary>Returns True if the polygon contains the point.</summary>
	Method ContainsPoint:Bool(polygon:SpinePolygon, x:Float, y:Float)
		Local vertices:= polygon.Vertices
		Local nn:Int = polygon.Count
	
		Local prevIndex:= nn - 2
		Local inside:= False
		Local vertexX:Float
		Local vertexY:Float
		Local prevY:Float
		For Local ii:= 0 Until nn Step 2
			vertexY = vertices[ii + 1]
			prevY = vertices[prevIndex + 1]
			If (vertexY < y And prevY >= y) Or (prevY < y And vertexY >= y)
				vertexX = vertices[ii]
				If vertexX + (y - vertexY) / (prevY - vertexY) * (vertices[prevIndex] - vertexX) < x inside = Not inside
			EndIf
			prevIndex = ii
		Next
		
		Return inside
	End
	
	'<summary>Returns the first bounding box attachment that contains the point, or Null. When doing many checks, it is usually more
	'efficient to only call this method if @link #aabbContainsPoint(Float, Float)} returns True.</summary>
	Method ContainsPoint:SpineBoundingBoxAttachment(x:Float, y:Float)
		For Local i:= 0 Until polygonsTotal
			If ContainsPoint(polygons[i], x, y) Return BoundingBoxes[i]
		Next
		Return Null
	End
	
	'<summary>Returns the first bounding box attachment that contains the line segment, or Null. When doing many checks, it is usually
	'more efficient to only call this method if @link #aabbIntersectsSegment(Float, Float, Float, Float)} returns True.</summary>
	Method IntersectsSegment:SpineBoundingBoxAttachment(x1:Float, y1:Float, x2:Float, y2:Float)
		For Local i:= 0 Until polygonsTotal
			If IntersectsSegment(polygons[i], x1, y1, x2, y2) Return BoundingBoxes[i]
		Next
			
		Return Null
	End
	
	'<summary>Returns True if the polygon contains the line segment.</summary>
	Method IntersectsSegment:Bool(polygon:SpinePolygon, x1:Float, y1:Float, x2:Float, y2:Float)
		Local vertices:= polygon.Vertices
		Local width12:Float = x1 - x2
		Local height12:Float = y1 - y2
		Local det1:Float = x1 * y2 - y1 * x2
		Local x3:Float = vertices[nn - 2]
		Local y3:Float = vertices[nn - 1]
		Local x4:Float
		Local y4:Float
		Local det2:Float
		Local width34:Float
		Local height34:Float
		Local det3:Float
		Local x:Float
		Local y:Float
		
		For Local ii:= 0 Until polygonsTotal Step 2
			x4 = vertices[ii]
			y4 = vertices[ii + 1]
			
			det2 = x3 * y4 - y3 * x4
			width34 = x3 - x4
			height34 = y3 - y4
			det3 = width12 * height34 - height12 * width34
			x = (det1 * width34 - width12 * det2) / det3
			
			If ( (x >= x3 And x <= x4) Or (x >= x4 And x <= x3)) And ( (x >= x1 And x <= x2) Or (x >= x2 And x <= x1))
				y = (det1 * height34 - height12 * det2) / det3
				If ( (y >= y3 And y <= y4) Or (y >= y4 And y <= y3)) And ( (y >= y1 And y <= y2) Or (y >= y2 And y <= y1)) Return True
			EndIf
			x3 = x4
			y3 = y4
		Next
		
		Return False
	End
	
	Method GetPolygon:SpinePolygon(attachment:SpineBoundingBoxAttachment)
		For Local index:= 0 Until boundingBoxesTotal
			If BoundingBoxes[index] = attachment Return Polygons[index]
		Next
		Return Null
	End
End