'see license.txt for source licenses
Strict

Import spine

Class SpineAnimationStateData
	Field SkeletonData:SpineSkeletonData
	Private
	Field animationToMixTime:Map<SpineAnimation, Map<SpineAnimation, FloatObject>>
	Public

	Method New(skeletonData:SpineSkeletonData)
		SkeletonData = skeletonData
	End

	Method SetMix:Void(fromName:String, toName:String, duration:float)
		Local fromAnimation:SpineAnimation = SkeletonData.FindAnimation(fromName)
		If fromAnimation = Null Throw New SpineArgumentNullException("SpineAnimation not found: " + fromName)
		Local toAnimation:SpineAnimation = SkeletonData.FindAnimation(toName)
		If toAnimation = Null Throw New SpineArgumentNullException("SpineAnimation not found: " + toName)
		SetMix(fromAnimation, toAnimation, duration)
	End

	Method SetMix:Void(fromAnimation:SpineAnimation, toAnimation:SpineAnimation, duration:float)
		If fromAnimation = Null Throw New SpineArgumentNullException("from cannot be null.")
		If toAnimation = Null Throw New SpineArgumentNullException("to cannot be null.")
		
		If animationToMixTime = Null animationToMixTime = New Map<SpineAnimation, FloatMap<SpineAnimation>>
		
		Local fromMap:= animationToMixTime.ValueForKey(fromAnimation)
		If fromMap = Null
			fromMap = New FloatMap<SpineAnimation>
			animationToMixTime.Insert(fromAnimation, fromMap)
		EndIf
		
		Local floatObject:= fromMap.ValueForKey(toAnimation)
		If floatObject
			'reuse old float object
			floatObject.value = duration
		Else
			'create new float object
			fromMap.Insert(toAnimation, New FloatObject(duration))
		EndIf
	End

	Method GetMix:float(fromAnimation:SpineAnimation, ToAnimation:SpineAnimation)
		If animationToMixTime = Null Return 0.0
		Local fromMap:= animationToMixTime.ValueForKey(fromAnimation)
		If fromMap = Null Return 0.0
		Local floatObject:= fromMap.ValueForKey(ToAnimation)
		If floatObject = Null Return 0.0
		Return floatObject.value
	End
End
