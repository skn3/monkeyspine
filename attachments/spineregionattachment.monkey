'see license.txt for source licenses
Strict

Import spine

'SpineAttachment that displays a texture region. 
Class SpineRegionAttachment Extends SpineAttachment
	Const X1:= 0
	Const Y1:= 1
	Const X2:= 2
	Const Y2:= 3
	Const X3:= 4
	Const Y3:= 5
	Const X4:= 6
	Const Y4:= 7

	Field X:float
	Field Y:float
	Field ScaleX:float
	Field ScaleY:float
	Field Rotation:float
	Field Width:float
	Field Height:float

	Field Region:SpineAtlasRegion

	Field Offset:float[8]
	
	'these are so we have a place to update state at runtime
	Field Vertices:float[8]
	Field WorldX:Float
	Field WorldY:Float
	Field WorldRotation:Float
	Field WorldScaleX:Float
	Field WorldScaleY:Float
	Field WorldR:Float
	Field WorldG:Float
	Field WorldB:Float
	Field WorldAlpha:Float
	
	Field BoundingVertices:Float[8]

	'constructor
	Method New(name:string, type:Int)
		Super.New(name, type)
		Type = SpineAttachmentType.region
		ScaleX = 1.0
		ScaleY = 1.0
	End

	'api
	Method Update:Void(slot:SpineSlot)
		' --- this will perform updates on teh state of the attachment ---
		UpdateVertices(slot)
		UpdateWorldState(slot)
		UpdateColor(slot)
		UpdateBounding()
	End
	
	Method UpdateColor:Void(slot:SpineSlot)
		' --- updates color for this attachment based on current frame  ---
		'this is just a handy way to store the color for external use
		WorldR = (slot.Skeleton.R * slot.R)
		WorldG = (slot.Skeleton.G * slot.G)
		WorldB = (slot.Skeleton.B * slot.B)
		WorldAlpha = slot.Skeleton.A * slot.A
	End
	
	Method UpdateVertices:Void(slot:SpineSlot)
		' --- updates vertices for this attachment based on current frame  ---
		'this is just a handy way to store the vertices for external use
		Vertices[X1] = Offset[X1] * slot.Bone.M00 + Offset[Y1] * slot.Bone.M01 + slot.Bone.WorldX
		Vertices[Y1] = Offset[X1] * slot.Bone.M10 + Offset[Y1] * slot.Bone.M11 + slot.Bone.WorldY
		Vertices[X2] = Offset[X2] * slot.Bone.M00 + Offset[Y2] * slot.Bone.M01 + slot.Bone.WorldX
		Vertices[Y2] = Offset[X2] * slot.Bone.M10 + Offset[Y2] * slot.Bone.M11 + slot.Bone.WorldY
		Vertices[X3] = Offset[X3] * slot.Bone.M00 + Offset[Y3] * slot.Bone.M01 + slot.Bone.WorldX
		Vertices[Y3] = Offset[X3] * slot.Bone.M10 + Offset[Y3] * slot.Bone.M11 + slot.Bone.WorldY
		Vertices[X4] = Offset[X4] * slot.Bone.M00 + Offset[Y4] * slot.Bone.M01 + slot.Bone.WorldX
		Vertices[Y4] = Offset[X4] * slot.Bone.M10 + Offset[Y4] * slot.Bone.M11 + slot.Bone.WorldY
	End
	
	Method UpdateWorldState:Void(slot:SpineSlot)
		' --- updates world state based on current frame ---
		'this is just a handy way to store the world state for external use
		'do basic state
		WorldX = slot.Bone.WorldX + X * slot.Bone.M00 + Y * slot.Bone.M01
		WorldY = slot.Bone.WorldY + X * slot.Bone.M10 + Y * slot.Bone.M11
		WorldRotation = slot.Bone.WorldRotation + Rotation
		WorldScaleX = slot.Bone.WorldScaleX + ScaleX - 1.0
		WorldScaleY = slot.Bone.WorldScaleY + ScaleY - 1.0
		
		'do we need to flip it?
		If slot.Skeleton.FlipX Then
			WorldScaleX = -WorldScaleX
			WorldRotation = -WorldRotation
		end
		If slot.Skeleton.FlipY Then
			WorldScaleY = -WorldScaleY
			WorldRotation = -WorldRotation
		end
	End
	
	Method UpdateBounding:Void()
		' --- updates the bounding box ---
		SpineGetPolyBounding(Vertices, BoundingVertices)
	End
	
	Method UpdateOffset:Void()
		' --- update offsets for the region ---
		'this only really needs to be called when the the image is changed
		'Print "Region.GetOriginalWidth() = "+Region.GetOriginalWidth()
		Local regionScaleX:float = Width / Region.GetOriginalWidth() * ScaleX
		Local regionScaleY:float = Height / Region.GetOriginalHeight() * ScaleY
		Local localX:float = -Width / 2.0 * ScaleX + Region.GetOffsetX() * regionScaleX
		Local localY:float = -Height / 2.0 * ScaleY + Region.GetOffsetY() * regionScaleY
		Local localX2:float = localX + Region.GetWidth() * regionScaleX
		Local localY2:float = localY + Region.GetHeight() * regionScaleY
		Local cos:float = Cos(Rotation)
		Local sin:float = Sin(Rotation)

		Local localXCos:float = localX * cos + X
		Local localXSin:float = localX * sin
		Local localYCos:float = localY * cos + Y
		Local localYSin:float = localY * sin
		Local localX2Cos:float = localX2 * cos + X
		Local localX2Sin:float = localX2 * sin
		Local localY2Cos:float = localY2 * cos + Y
		Local localY2Sin:float = localY2 * sin

		Offset[X1] = localXCos - localYSin
		Offset[Y1] = localYCos + localXSin
		Offset[X2] = localXCos - localY2Sin
		Offset[Y2] = localY2Cos + localXSin
		Offset[X3] = localX2Cos - localY2Sin
		Offset[Y3] = localY2Cos + localX2Sin
		Offset[X4] = localX2Cos - localYSin
		Offset[Y4] = localYCos + localX2Sin
	End
End
