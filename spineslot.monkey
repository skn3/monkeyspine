'see license.txt for source licenses
Strict

Import spine

Class SpineSlot
	Field parentIndex:Int
	Field Data:SpineSlotData
	Field Bone:SpineBone
	Field Skeleton:SpineSkeleton
	Field R:Float
	Field G:Float
	Field B:Float
	Field A:float

	' May be null.
	Private
	Field attachment:SpineAttachment
	Field attachmentTime:float
	Public
	
	Method Attachment:SpineAttachment() Property
		Return attachment
	End
	
	Method Attachment:Void(attachment:SpineAttachment) Property
		Self.attachment = attachment
		attachmentTime = Skeleton.Time
	End

	Method AttachmentTime:float() Property
		Return Skeleton.Time - attachmentTime
	End
	
	Method AttachmentTime:Void(time:Float) Property
		attachmentTime = Skeleton.Time - time
	End	

	Method New(data:SpineSlotData, skeleton:SpineSkeleton, bone:SpineBone)
		If data = Null Throw New SpineArgumentNullException("data cannot be null.")
		If skeleton = Null Throw New SpineArgumentNullException("skeleton cannot be null.")
		If bone = Null Throw New SpineArgumentNullException("bone cannot be null.")
		Data = data
		Skeleton = skeleton
		Bone = bone
		SetToBindPose()
	End

	Private
	Method SetToBindPose:Void(slotIndex:int)
		R = Data.R
		G = Data.G
		B = Data.B
		A = Data.A
		If Data.AttachmentName.Length = 0
			Attachment = Null
		Else
			Attachment = Skeleton.GetAttachment(slotIndex, Data.AttachmentName)
		EndIf
	End
	Public

	Method SetToBindPose:Void()
		For Local indexOf:= 0 Until Skeleton.Data.Slots.Length
			If Skeleton.Data.Slots[indexOf] = Data
				SetToBindPose(indexOf)
				Return
			EndIf
		Next
		SetToBindPose(-1)
	End

	Method ToString:String()
		return Data.Name
	End
End
