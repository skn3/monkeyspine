'see license.txt for source licenses
Strict

Import monkeyspine

Class SpineAttachmentType'FAKE ENUM
	Const region:= 0
	Const regionSequence:= 1
	
	Function FromString:Int(name:String)
		Select name.ToLower()
			Case "region"
				Return region
			Case "regionsequence"
				Return regionSequence
		End
		Return -1
	End
End
