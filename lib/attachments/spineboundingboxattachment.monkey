'see license.txt for source licenses
Strict

Import spine

'Attachment that has a polygon for bounds checking
class SpineBoundingBoxAttachment Extends SpineAttachment
	Field Vertices:Float[]

	Method New(name:String)
		Super.New(name)
		Type = SpineAttachmentType.boundingbox
	End
	
	'Must have at least the same length as this attachment's vertices.
	Method ComputeWorldVertices:Void(bone:SpineBone, worldVertices:Float[])
		Local x:Float = bone.skeleton.x + bone.worldX
		Local y:Float = bone.skeleton.y + bone.worldY
		Local m00:Float = bone.M00
		Local m01:Float = bone.M01
		Local m10:Float = bone.M10
		Local m11:Float = bone.M11
		
		Local px:Float
		Local py:Float
		For Local i:= 0 Until Vertices.Length() Step 2
			px = Vertices[i]
			py = Vertices[i + 1]
			worldVertices[i] = px * m00 + py * m01 + x
			worldVertices[i + 1] = px * m10 + py * m11 + y
		Next
	End
	
	Method Update:Void(slot:SpineSlot)
		'bounding
		SpineGetPolyBounding(Vertices, BoundingVertices)
	End
End