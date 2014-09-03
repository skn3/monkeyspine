'see license.txt for source licenses
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
		return Data.Name
	End
End