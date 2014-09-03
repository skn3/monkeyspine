'see license.txt for source licenses
Strict

Import spine

Class SpineAttachmentType'FAKE ENUM
	Const region:= 0
	Const boundingbox:= 1
	Const mesh:= 2
	Const skinnedmesh:= 3
	
	Function FromString:Int(name:String)
		Select name.ToLower()
			Case "region"
				Return region
			Case "regionsequence"
				Return boundingbox
			Case "mesh"
				Return mesh
			Case "skinnedmesh"
				Return skinnedmesh
		End
		Return -1
	End
End
