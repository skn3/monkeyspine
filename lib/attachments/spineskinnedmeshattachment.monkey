'see license.txt for source licenses
Strict

Import spine

'Attachment that displays a texture region.
Class SpineSkinnedMeshAttachment Extends SpineAttachment
	Field Bones:Int[]
	Field Weights:Float[]
	Field UVs:Float[]
	
	Field RegionUVs:Float[]
	Field RegionU:Float
	Field RegionV:Float
	Field RegionU2:Float
	Field RegionV2:Float
	Field RegionRotate:Bool
	Field RegionOffsetX:Float
	Field RegionOffsetY:Float
	Field RegionWidth:Float
	Field RegionHeight:Float
	Field RegionOriginalWidth:Float
	Field RegionOriginalHeight:Float
	
	Field R:Float = 1.0
	Field G:Float = 1.0
	Field B:Float = 1.0
	Field A:Float = 1.0

	Field HullLength:Int
	
	Field Triangles:Int[]

	Field Path:String
	Field RenderObject:Object

	'Nonessential.
	Field Edges:Int[]
	Field Width:Float
	Field Height:Float

	Method New(name:String)
		Super.New(name)
		Type = SpineAttachmentType.skinnedmesh
	End

	Method UpdateUVs:Void()
		Local width:Float = RegionU2 - RegionU
		Local height:Float = RegionV2 - RegionV
		
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
		Local skeleton := slot.Bone.Skeleton
		Local skeletonBones:= skeleton.Bones
		Local x:= skeleton.x
		Local y:= skeleton.y
		
		Local bone:SpineBone
		Local vx:Float
		Local vy:Float
		Local weight:Float
		Local wx:Float
		Local wy:Float
		Local nn:Int
		Local w:= 0
		Local v:= 0
		Local b:= 0
		Local n:= Bones.Length()
		
		If slot.attachmentVerticesCount = 0
			'for (Int w = 0, v = 0, b = 0, n = bones.Length() v < n w += 2) {
			While v < n
				wx = 0
				wy = 0

				nn = Bones[v]
				v += 1
				nn += v
				
				While v < nn
					bone = skeletonBones[Bones[v]]
					vx = Weights[b]
					vy = Weights[b + 1]
					weight = Weights[b + 2]
					wx += (vx * bone.M00 + vy * bone.M01 + bone.WorldX) * weight
					wy += (vx * bone.M10 + vy * bone.M11 + bone.WorldY) * weight
					
					'next increment
					v += 1
					b += 3
				Wend
				
				worldVertices[w] = wx + x
				worldVertices[w + 1] = wy + y
				
				'next increment
				w += 2
			Wend
		Else
			Local ffd:= slot.AttachmentVertices
			Local f:= 0
			
			'for (Int w = 0, v = 0, b = 0, f = 0, n = bones.Length() v < n w += 2) {
			While v < n
				wx = 0
				wy = 0
				
				nn = Bones[v]
				v += 1
				nn += v
				
				'for ( v < nn v++, b += 3, f += 2) {
				While v < nn
					bone = skeletonBones[Bones[v]]
					vx = Weights[b] + ffd[f]
					vy = Weights[b + 1] + ffd[f + 1]
					weight = Weights[b + 2]
					wx += (vx * bone.M00 + vy * bone.M01 + bone.WorldX) * weight
					wy += (vx * bone.M10 + vy * bone.M11 + bone.WorldY) * weight
					
					'next increment
					v += 1
					b += 3
					f += 2
				Wend
					
				worldVertices[w] = wx + x
				worldVertices[w + 1] = wy + y
					
				'next increment
				w += 2
			Wend
		EndIf
	End
End
		