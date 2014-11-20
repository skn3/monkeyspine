'see license.txt For source licenses
Strict

Import spine

Class SpineEvent
	Field Data:SpineEventData
	Field IntValue:Int
	Field FloatValue:Float
	Field StringValue:String

	Method New(data:SpineEventData)
		Self.Data = data
	End

	Method ToString:String()
		Return Data.Name
	End
End