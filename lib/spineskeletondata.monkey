'see license.txt for source licenses
Strict

Import spine

Class SpineSkeletonData
	Field Name:String
	Field Bones:SpineBoneData[]
	Field Slots:SpineSlotData[]
	Field Skins:SpineSkin[]
	Field DefaultSkin:SpineSkin
	Field Events:SpineEventData[]
	Field Animations:SpineAnimation[]
	Field IkConstraints:SpineIkConstraintData[]
	Field Width:Float
	Field Height:Float
	Field Version:String
	Field Hash:String

	'Private
	Field bonesCount:Int
	Field slotsCount:Int
	Field eventsCount:Int
	Field skinsCount:Int
	Field animationsCount:Int
	Field ikConstraintsCount:Int
	'Public

	' --- bones
	
	'Return May be Null. 
	Method FindBone:SpineBoneData(boneName:String)
		If boneName.Length() = 0 Throw New SpineArgumentNullException("boneName cannot be Null.")
		
		Local bone:SpineBoneData
		For Local i:= 0 Until bonesCount
			bone = Bones[i]
			If bone.Name = boneName Return bone
		Next
		Return Null
	End

	'Return -1 if the was:bone not found. 
	Method FindBoneIndex:Int(boneName:String)
		If boneName.Length() = 0 Throw New SpineArgumentNullException("boneName cannot be Null.")
		
		Local bone:SpineBoneData
		For Local i:= 0 Until bonesCount
			bone = Bones[i]
			If bone.Name = boneName Return i
		Next
		Return -1
	End

	' --- Slots.

	'Return May be Null. 
	Method FindSlot:SpineSlotData(slotName:String)
		If slotName.Length() = 0 Throw New SpineArgumentNullException("slotName cannot be Null.")
		
		Local slot:SpineSlotData
		For Local i:= 0 Until slotsCount
			slot = Slots[i]
			If slot.Name = slotName Return slot
		Next
		Return Null
	End

	'Return -1 if the was:bone not found. 
	Method FindSlotIndex:Int(slotName:String)
		If slotName.Length() = 0 Throw New SpineArgumentNullException("slotName cannot be Null.")
		
		Local slot:SpineSlotData
		For Local i:= 0 Until slotsCount
			slot = Slots[i]
			If slot.Name = slotName Return i
		Next
		Return -1
	End

	' --- Skins.

	'Return May be Null.
	Method FindSkin:SpineSkin(skinName:String)
		If skinName.Length() = 0 Throw New SpineArgumentNullException("skinName cannot be Null.")
		
		Local skin:SpineSkin
		For Local i:= 0 Until skinsCount
			skin = Skins[i]
			If skin.Name = skinName Return skin
		Next
		Return Null
	End
		
	' --- Events.

	'Return May be Null. 
	Method FindEvent:SpineEventData(eventDataName:String)
		If eventDataName.Length() = 0 Throw New SpineArgumentNullException("eventDataName cannot be Null.")
		
		Local event:SpineEventData
		For Local i:= 0 Until eventsCount
			event = Events[i]
			If event.Name = eventDataName Return event
		Next
		Return Null
	End

	' --- Animations.

	'Return May be Null. 
	Method FindAnimation:SpineAnimation(animationName:String)
		If animationName.Length() = 0 Throw New SpineArgumentNullException("animationName cannot be Null.")
		
		Local animation:SpineAnimation
		For Local i:= 0 Until animationsCount
			animation = Animations[i]
			If animation.Name = animationName Return animation
		Next
		Return Null
	End

	' --- IK
	
	Method FindIkConstraint:IkConstraintData(ikConstraintName:String)
		If ikConstraintName.Length() = 0 Throw New SpineArgumentNullException("ikConstraintName cannot be null.")
		
		Local ikConstraint:SpineIkConstraintData
		For Local i:= 0 Until ikConstraintsCount
			ikConstraint = ikConstraints[i]
			If ikConstraint.Name = ikConstraintName Return ikConstraint
		Next
		return null
	End
	
	' --- 
	
	Method ToString:String()
		Return Name
	End
	
	' --- glue
	
	Method TrimArrays:Void()
		If bonesCount < Bones.Length() Bones = Bones.Resize(bonesCount)
		If slotsCount < Slots.Length() Slots = Slots.Resize(slotsCount)
		If skinsCount < Skins.Length() Skins = Skins.Resize(skinsCount)
		If eventsCount < Events.Length() Events = Events.Resize(eventsCount)
		If animationsCount < Animations.Length() Animations = Animations.Resize(animationsCount)
		If ikConstraintsCount < IkConstraints.Length() IkConstraints = IkConstraints.Resize(ikConstraintsCount)
	End
	
	Method AddBone:Void(bone:SpineBoneData)
		If bone = Null Throw New SpineArgumentNullException("bone cannot be Null.")
		
		'check resize array
		If bonesCount >= Bones.Length() Bones = Bones.Resize(Bones.Length() * 2 + 10)
		
		'set it
		Bones[bonesCount] = bone
		bonesCount += 1
	End
	
	Method AddSlot:Void(slot:SpineSlotData)
		If slot = Null Throw New SpineArgumentNullException("slot cannot be Null.")
		
		'check resize array
		If slotsCount >= Slots.Length() Slots = Slots.Resize(Slots.Length() * 2 + 10)
		
		'set it
		Slots[slotsCount] = slot
		slotsCount += 1
	End
	
	Method AddEvent:Void(event:SpineEventData)
		If event = Null Throw New SpineArgumentNullException("event cannot be Null.")
		
		'check resize array
		If eventsCount >= Events.Length() Events = Events.Resize(Events.Length() * 2 + 10)
		
		'set it
		Events[eventsCount] = event
		eventsCount += 1
	End
	
	Method AddSkin:Void(skin:SpineSkin)
		If skin = Null Throw New SpineArgumentNullException("skin cannot be Null.")
		
		'check resize array
		If skinsCount >= Skins.Length() Skins = Skins.Resize(Skins.Length() * 2 + 10)
		
		'set it
		Skins[skinsCount] = skin
		skinsCount += 1
	End
	
	Method AddAnimation:Void(animation:SpineAnimation)
		If animation = Null Throw New SpineArgumentNullException("animation cannot be Null.")
		
		'check resize array
		If animationsCount >= Animations.Length() Animations = Animations.Resize(Animations.Length() * 2 + 10)
		
		'set it
		Animations[animationsCount] = animation
		animationsCount += 1
	End
	
	Method AddIkConstraint:Void(ikConstraint:SpineIkConstraintData)
		If ikConstraint = Null Throw New SpineArgumentNullException("ikConstraint cannot be Null.")
		
		'check resize array
		If ikConstraintsCount >= IkConstraints.Length() IkConstraints = IkConstraints.Resize(IkConstraints.Length() * 2 + 10)
		
		'set it
		IkConstraints[ikConstraintsCount] = ikConstraint
		ikConstraintsCount += 1
	End
End
