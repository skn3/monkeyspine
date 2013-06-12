#rem
/*******************************************************************************
 * Copyright (c) 2013, Esoteric Software
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 * 
 * 1. Redistributions of source code must retain the above copyright notice, this
 *    list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
 * ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES
 * LOSS OF USE, DATA, OR PROFITS OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 ******************************************************************************/
#end
Strict

Import spine

Class SpineAnimationState
	Field Data:SpineAnimationStateData
	Field Animation:SpineAnimation
	Field Time:float
	Field Loop:bool
	
	Private
	Field previous:SpineAnimation
	Field previousTime:float
	Field previousLoop:bool
	Field mixTime:float
	Field mixDuration:float
	Public

	Method New(data:SpineAnimationStateData)
		If data = Null Throw New SpineArgumentNullException("data cannot be null.")
		Data = data
	End

	Method Update:Void(delta:float)
		Time += delta
		previousTime += delta
		mixTime += delta
	End

	Method Apply:Void(skeleton:SpineSkeleton)
		If Animation = Null Return
		If previous <> Null
			previous.Apply(skeleton, previousTime, previousLoop)
			Local alpha:float = mixTime / mixDuration
			If alpha >= 1
				alpha = 1
				previous = null
			EndIf
			Animation.Mix(skeleton, Time, Loop, alpha)
		Else
			Animation.Apply(skeleton, Time, Loop)
		EndIf
	End

	Method SetAnimation:Void(animationName:String, loop:bool)
		Local animation:SpineAnimation = Data.SkeletonData.FindAnimation(animationName)
		If animation = Null Throw New SpineArgumentNullException("SpineAnimation not found: " + animationName)
		SetAnimation(animation, loop)
	End

	Method SetAnimation:Void(animation:SpineAnimation, loop:bool)
		previous = null
		If animation <> Null And Animation <> Null
			mixDuration = Data.GetMix(Animation, animation)
			If mixDuration > 0
				mixTime = 0
				previous = Animation
				previousTime = Time
				previousLoop = Loop
			EndIf
		EndIf
		Animation = animation
		Loop = loop
		Time = 0
	End

	Method ClearAnimation:Void()
		previous = null
		Animation = null
	End

	' Returns true if no is:animation set or if the current time is greater than the duration:animation, regardless of looping. 
	Method isComplete:bool()
		return Animation = null Or Time >= Animation.Duration
	End

	Method ToString:String()
        If Animation <> Null And Animation.Name <> ""
            Return Animation.Name
        Else
            'Return Super.ToString() '--> Super class does not have a ToString method so....
            Return ""       'Maybe this could be changed to something like "n/a" or "void" or the like... ?
        EndIf
    End
	
	Method ToString:String()
		If Animation <> Null Return Animation.Name
		Return ""
	End
End
