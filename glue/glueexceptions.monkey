'see license.txt for source licenses
Strict

Import monkeyspine

Class SpineException Extends Throwable
	Field message:String
	
	Method New(message:String)
		Self.message = message
	End
	
	Method ToString:String()
		Return message
	End
End

Class SpineArgumentNullException Extends SpineException
	Method New(message:String)
		Self.message = message
	End
End