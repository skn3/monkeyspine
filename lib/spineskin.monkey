'see license.txt For source licenses
Strict

Import spine

' Stores attachments by index:slot and attachment name. 
Class SpineSkin
	Field Name:String
	'Field attachments:IntMap<StringMap<SpineAttachment>>
	Field attachments:StringMap<SpineAttachment>[]

	Method New(name:String)
		If name.Length() = 0 Throw New SpineArgumentNullException("name cannot be empty.")
		Name = name
	End

	Method AddAttachment:Void(slotIndex:Int, name:String, attachment:SpineAttachment)
		If attachment = Null Throw New SpineArgumentNullException("attachment cannot be Null.")
		
		If slotIndex >= attachments.Length() attachments = attachments.Resize(slotIndex + 1)
		
		If attachments[slotIndex] = Null attachments[slotIndex] = New StringMap<SpineAttachment>
		
		attachments[slotIndex].Insert(name, attachment)
	End

	'Return May be Null. 
	Method GetAttachment:SpineAttachment(slotIndex:Int, name:String)
		If attachments.Length() <= slotIndex or attachments[slotIndex] = Null Return Null
		Return attachments[slotIndex].ValueForKey(name)
	End

	Method FindNamesForSlot:String[] (slotIndex:Int)
		If attachments.Length() <= slotIndex or attachments[slotIndex] = Null Return New String[0]
		
		Local results:String[attachments[slotIndex].Count()]
		Local index:= 0
		For Local name:= EachIn attachments[slotIndex].Keys()
			results[index] = name
			index += 1
		Next
		Return results
	End

	Method FindAttachmentsForSlot:SpineAttachment[] (slotIndex:Int)
		If attachments.Length() <= slotIndex or attachments[slotIndex] = Null Return New SpineAttachment[0]
		
		Local results:SpineAttachment[attachments[slotIndex].Count()]
		Local index:= 0
		For Local attachment:= EachIn attachments[slotIndex].Values()
			results[index] = attachment
			index += 1
		Next
		Return results
	End

	Method ToString:String()
		Return Name
	End

	' Attach all attachments from this if the corresponding attachment from the old is currently attached. 
	Method AttachAll:Void(skeleton:SpineSkeleton, oldSkin:SpineSkin)
		Local name:String
		Local slot:SpineSlot
		Local attachment:SpineAttachment
				
		For Local slotIndex:= 0 Until oldSkin.attachments.Length()
			slot = skeleton.Slots[slotIndex]
			For name = EachIn oldSkin.attachments[slotIndex].Keys()
				attachment = oldSkin.attachments[slotIndex].ValueForKey(name)
				If slot.Attachment = attachment
					attachment = GetAttachment(slotIndex, name)
					If attachment slot.Attachment = attachment
				EndIf
			Next
		Next
	End
End
