'see license.txt for source licenses
Strict

Import monkeyspine

Class SpineSkeletonData
	Field Name:String
	Field Bones:SpineBoneData[]
	Field Slots:SpineSlotData[]
	Field Skins:SpineSkin[]
	' May be null. 
	Field DefaultSkin:SpineSkin
	Field Animations:SpineAnimation[]

	Private
	Field bonesCount:Int
	Field slotsCount:Int
	Field skinsCount:Int
	Field animationsCount:Int
	Public

	'glue
	Method TrimArrays:Void()
		' --- this repalces the TrimExcess ported and will trim all arrays to their proper capacity ---
		If bonesCount < Bones.Length Bones = Bones.Resize(bonesCount)
		If slotsCount < Slots.Length Slots = Slots.Resize(slotsCount)
		If skinsCount < Skins.Length Skins = Skins.Resize(skinsCount)
		If animationsCount < Animations.Length Animations = Animations.Resize(animationsCount)
	End
	
	' --- Bones.
	Method AddBone:Void(bone:SpineBoneData)
		If bone = Null Throw New SpineArgumentNullException("bone cannot be null.")
		
		'check resize array
		If bonesCount >= Bones.Length Bones = Bones.Resize(Bones.Length * 2 + 10)
		
		'set it
		Bones[bonesCount] = bone
		bonesCount += 1
	End

	'return May be null. 
	Method FindBone:SpineBoneData(boneName:String)
		If boneName.Length = 0 Return Null
		For Local i:= 0 Until bonesCount
			If Bones[i].Name = boneName Return Bones[i]
		Next
		return null
	End

	'return -1 if the was:bone not found. 
	Method FindBoneIndex:int(boneName:String)
		If boneName.Length = 0 Return - 1
		For Local i:= 0 Until bonesCount
			If Bones[i].Name = boneName Return i
		Next
		Return -1
	End

	' --- Slots.
	Method AddSlot:Void(slot:SpineSlotData)
		If slot = Null Throw New SpineArgumentNullException("slot cannot be null.")
		
		'check resize array
		If slotsCount >= Slots.Length Slots = Slots.Resize(Slots.Length * 2 + 10)
		
		'set it
		Slots[slotsCount] = slot
		slotsCount += 1
	End

	'return May be null. 
	Method FindSlot:SpineSlotData(slotName:String)
		If slotName.Length = 0 Return Null
		For Local i:= 0 Until slotsCount
			If Slots[i].Name = slotName Return Slots[i]
		Next
		Return Null
	End

	'return -1 if the was:bone not found. 
	Method FindSlotIndex:int(slotName:String)
		If slotName.Length = 0 Return - 1
		For Local i:= 0 Until slotsCount
			If Slots[i].Name = slotName Return i
		Next
		Return -1
	End

	' --- Skins.
	Method AddSkin:Void(skin:SpineSkin)
		If skin = Null Throw New SpineArgumentNullException("skin cannot be null.")
		
		'check resize array
		If skinsCount >= Skins.Length Skins = Skins.Resize(Skins.Length * 2 + 10)
		
		'set it
		Skins[skinsCount] = skin
		skinsCount += 1
	End

	'return May be null. 
	Method FindSkin:SpineSkin(skinName:String)
		If skinName.Length = 0 Return Null
		For Local i:= 0 Until skinsCount
			If Skins[i].Name = skinName Return Skins[i]
		Next
		Return Null
	End

	' --- Animations.
	Method AddAnimation:Void(animation:SpineAnimation)
		If animation = Null Throw New SpineArgumentNullException("animation cannot be null.")
		
		'check resize array
		If animationsCount >= Animations.Length Animations = Animations.Resize(Animations.Length * 2 + 10)
		
		'set it
		Animations[animationsCount] = animation
		animationsCount += 1
	End

	'return May be null. 
	Method FindAnimation:SpineAnimation(animationName:String)
		If animationName.Length = 0 Return Null
		For Local i:= 0 Until animationsCount
			If Animations[i].Name = animationName Return Animations[i]
		Next
		Return Null
	End

	' ---
	Method ToString:String()
		Return Name
	End
End
