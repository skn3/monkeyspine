'see license.txt For source licenses
Strict

Import spine

Class SpineAttachmentType'FAKE ENUM
	Const Region:= 0
	Const BoundingBox:= 1
	Const Mesh:= 2
	Const SkinnedMesh:= 3
	
	Function FromString:Int(name:String)
		Select name.ToLower()
			Case "region"
				Return Region
			Case "boundingbox"
				Return BoundingBox
			Case "mesh"
				Return Mesh
			Case "skinnedmesh"
				Return SkinnedMesh
		End
		Return -1
	End
End
