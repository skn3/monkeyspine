'see license.txt for source licenses
Strict

Import spine

Class SpineBoneData
	' May be null. 
	Field Parent:SpineBoneData
	Field Name:String
	Field Length:Float
	Field X:Float
	Field Y:Float
	Field Rotation:Float
	Field ScaleX:= 1.0
	Field ScaleY:= 1.0
	Field InheritScale:= True
	Field InheirtRotation:= True

	'param parent May be null. 
	Method New(name:String, parent:SpineBoneData)
		If name.Length() = 0 Throw New SpineArgumentNullException("name cannot be null.")
		Name = name
		Parent = parent
	End

	Method ToString:String()
		return Name
	End
End
