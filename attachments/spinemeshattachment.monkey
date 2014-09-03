'see license.txt for source licenses
Strict

Import spine

'Attachment that displays a texture region.
Class SpineMeshAttachment Extends SpineAttachment
	Field Vertices:float[]
	Field UVs:Float[]
	Field RegionUVs:Float[]
	Field Triangles:int[]
	Field regionOffsetX:Float
	Field regionOffsetY:Float
	Field regionWidth:Float
	Field regionHeight:Float
	Field regionOriginalWidth:Float
	Field regionOriginalHeight:Float
	Field R:Float = 1.0
	Field G:Float = 1.0
	Field B:Float = 1.0
	Field A:Float = 1.0

	Field HullLength:Int

	Field Path:String
	Field RendererObject:Object
	Field RegionU:Float
	Field RegionV:Float
	Field RegionU2:Float
	Field RegionV2:Float
	Field RegionRotate:Bool
	Field RegionOffsetX:Float
	Field RegionOffsetY:Float 'Pixels stripped from the bottom left, unrotated.
	Field RegionWidth:Float
	Field RegionHeight:Float 'Unrotated, stripped size.
	Field RegionOriginalWidth:Float
	Field RegionOriginalHeight:Float 'Unrotated, unstripped size.

	'Nonessential.
	Field Edges:int[]
	Field Width:Float
	Field Height:Float

	Method New(name:String)
	End

	Method UpdateUVs:Void()
		Local width:float = RegionU2 - RegionU
		Local height:float = RegionV2 - RegionV
		
		If UVs.Length() <> RegionUVs.Length()
			UVs = New Float[RegionUVs.Length()]
		EndIf
		
		If RegionRotate
			For Local i:= 0 Until UVs.Length() Step 2
				UVs[i] = RegionU + RegionUVs[i + 1] * width
				UVs[i + 1] = RegionV + height - RegionUVs[i] * height
			Next
		Else
			For Local i:= 0 Until UVs.Length() Step 2
				UVs[i] = RegionU + RegionUVs[i] * width
				UVs[i + 1] = RegionV + RegionUVs[i + 1] * height
			Next
		EndIf
	End
			
	Method ComputeWorldVertices:Void(slot:SpineSlot, worldVertices:Float[])
		'get locals for speed!
		Local x:Float = slot.Bone.Skeleton.X + slot.Bone.WorldX
		Local y:Float = slot.Bone.Skeleton.y + slot.Bone.WorldY
		Local m00:Float = slot.Bone.M00
		Local m01:Float = slot.Bone.M01
		Local m10:Float = slot.Bone.M10
		Local m11:Float = slot.Bone.M11
		
		Local verticesCount:Int = Vertices.Length()
		
		If slot.AttachmentVerticesCount = verticesCount
			Vertices = slot.AttachmentVertices
		EndIf
		
		Local vx:Float
		Local vy:Float
		For Local i:= 0 Until verticesCount Step 2
			vx = Vertices[i]
			vy = Vertices[i + 1]
			worldVertices[i] = vx * m00 + vy * m01 + x
			worldVertices[i + 1] = vx * m10 + vy * m11 + y
		Next
	End
End
		