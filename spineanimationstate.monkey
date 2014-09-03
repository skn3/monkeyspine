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
	Field Tracks:SpineTrackEntry[]
	Field tracksTotal:Int
	Field Events:= New List<SpineEvent>
	Field TimeScale:Float = 1.0
	
	Field StartDelegate:SpineAnimationStateStartDelegate
	Field EndDelegate:SpineAnimationStateEndDelegate
	Field EventDelegate:SpineAnimationStateEventDelegate
	Field CompleteDelegate:SpineAnimationStateCompleteDelegate

	Method New(data:SpineAnimationStateData)
		If data = Null Throw New SpineArgumentNullException("data cannot be null.")
		Data = data
	End

	Method Update:Void(delta:Float)
		delta *= TimeScale
		
		Local current:SpineTrackEntry
		Local _next:SpineTrackEntry
		Local count:Int
		
		For Local i:= 0 Until tracksTotal
			current = Tracks[i]
			If current = Null Continue

			Local trackDelta:Float = delta * current.TimeScale
			Local time:Float = current.Time + trackDelta
			Local endTime:Float = current.EndTime

			current.Time = time
			if current._previous <> null
				current._previous.Time += trackDelta
				current.mixTime += trackDelta
			EndIf

			'Check if completed the animation or a loop iteration.
			If (current.Loop And current.lastTime Mod endTime > time Mod endTime) or ( Not current.Loop And current.LastTime < endTime And time >= endTime)
				count = time / endTime
				current.OnComplete(this, i, count)
				If CompleteDelegate <> Null CompleteDelegate.OnSpineAnimationStateComplete(Self, i, count)
			EndIf

			_next = current._next
			If _next <> Null
				_next.Time = current.LastTime - _next.Delay
				If _next.Time >= 0 SetCurrent(i, _next)
			Else
				'End non-looping animation when it reaches its end time and there is no _next entry.
				If Not current.Loop And current.LastTime >= current.EndTime ClearTrack(i)
			EndIf
		Next
	End

	Method Apply:Void(skeleton:SpineSkeleton)
		Local current:SpineTrackEntry
		Local previous:SpineTrackEntry
		Local time:Float
		Local previousTime:Float
		Local loop:Bool
		Local alpha:Float
		
		For Local i:= 0 Until tracksTotal
			current = tracks[i]
			If current = Null Continue

			Events.Clear()

			time = current.Time
			loop = current.Loop
			If Not loop And time > current.EndTime time = current.EndTime

			previous = current.previous
			If previous = Null
				If current.Mix = 1.0
					current.animation.Apply(skeleton, current.LastTime, time, loop, Events)
				else
					current.animation.Mix(skeleton, current.LastTime, time, loop, Events, current.Mix)
				EndIf
			Else
				previousTime = previous.Time
				If not previous.Loop And previousTime > previous.EndTime
					previousTime = previous.EndTime
				EndIf
				
				previous.animation.Apply(skeleton, previousTime, previousTime, previous.Loop, Null)
	
				alpha = current.mixTime / current.mixDuration * current.Mix
				If alpha >= 1
					alpha = 1.0
					current._previous = Null
				EndIf
				current.animation.Mix(skeleton, current.lastTime, time, loop, events, alpha)
			EndIf
	
			'for (Int ii = 0, nn = events.Count ii < nn ii++) {
			'	Event e = events[ii]
			'	current.OnEvent(this, i, e)
			'	if (Event != null) Event(this, i, e)
			'}
			Local node:= Events.First()
			Local e:SpineEvent
			While node
				e = node.Value()
				node = node.NextNode()
				current.OnEvent(this, i, e)
				If EventDelegate EventDelegate.OnSpineAnimationStateEvent(this, i, e)
			Wend
	
			current.lastTime = current.time
		Next
	End

	Method ClearTracks:Void()
		For Local i:= 0 Until tracksTotal
			ClearTrack(i)
		Next
		tracksTotal = 0
	End
	
	Method ClearTrack:Void(trackIndex:Int)
		If trackIndex >= tracksTotal Return
		Local current:= Tracks[trackIndex]
		If current = Null Return
		current.OnEnd(Self, trackIndex)
		If EndDelegate EndDelegate.OnSpineAnimationStateEnd(Self, trackIndex)
		Tracks[trackIndex] = Null
	End
	
	Private
	Method ExpandToIndex:SpineTrackEntry(trackIndex:Int)
		If trackIndex < tracksTotal Return Tracks[trackIndex]
		
		tracksTotal = trackIndex + 1
		If tracksTotal > Tracks.Length() Tracks = Tracks.Resize(tracksTotal)
		Return Null
	End
	Public
	
	Method SetCurrent:Void(index:Int, entry:SpineTrackEntry)
		Local current:= ExpandToIndex(index)
	
		if current
			Local previous:SpineTrackEntry = current._previous
			current._previous = null

			current.OnEnd(Self, index)
			If EndDelegate EndDelegate.OnSpineAnimationStateEnd(Self, index)

			entry.mixDuration = data.GetMix(current.Animation, entry.Animation)
			If entry.mixDuration > 0 entry.mixTime = 0
			
			'If a mix is in progress, mix from the closest animation.
			If previous And current.mixTime / current.mixDuration < 0.5
				entry._previous = previous
			else
				entry._previous = current
			EndIf
		EndIf

		Tracks[index] = entry
		
		entry.OnStart(Self, index)
		If StartDelegate StartDelegate.OnSpineAnimationStateStart(Self, index)
	End
	
	Method SetAnimation:Void(trackIndex:Int, animationName:String, loop:Bool)
		Local animation:SpineAnimation = Data.SkeletonData.FindAnimation(animationName)
		If animation = Null Throw New SpineArgumentNullException("SpineAnimation not found: " + animationName)
		SetAnimation(trackIndex, animation, loop)
	End
	
	'<summary>Set the current animation. Any queued animations are cleared.</summary>
	Method SetAnimation:Void(trackIndex:Int, animation:SpineAnimation, loop:Bool)
		Local entry:= New SpineTrackEntry
		entry.Animation = animation
		entry.Loop = loop
		entry.Time = 0.0
		entry.EndTime = animation.Duration
		SetCurrent(trackIndex, entry)
		Return entry
	End
	
	Method AddAnimation:SpineTrackEntry(trackIndex:Int, animationName:String, loop:Bool, delay:Float)
		Local animation:= Data.SkeletonData.FindAnimation(animationName)
		If animation = Null Throw New SpineArgumentNullException("SpineAnimation not found: " + animationName)
		Return AddAnimation(trackIndex, animation, loop, delay)
	End
	
	'<summary>Adds an animation to be played delay seconds after the current or last queued animation.</summary>
	'<param name="delay">May be <= 0 to use duration of previous animation minus any mix duration plus the negative delay.</param>
	Method AddAnimation:SpineTrackEntry(trackIndex:Int, animation:SpineAnimation, loop:Bool, delay:Float)
		Local entry:= New SpineTrackEntry
		entry.Animation = animation
		entry.Loop = loop
		entry.Time = 0.0
		entry.EndTime = animation.Duration

		Local last:= ExpandToIndex(trackIndex)
		If last
			While last._next
				last = last._next
			Wend
			last._next = entry
		Else
			Tracks[trackIndex] = entry
		EndIf

		If delay <= 0
			If last
				delay += last.EndTime - Data.GetMix(last.Animation, animation)
			else
				delay = 0
			EndIf
		EndIf
		entry.Delay = delay

		Return entry
	End

	' Returns true if no is:animation set or if the current time is greater than the duration:animation, regardless of looping. 
	Method ToString:String()
		Local buffer:String
		Local entry:SpineTrackEntry
		For Local i:= 0 Until tracksTotal
			entry = Tracks[i]
			If entry = Null Continue
			If buffer.Length() buffer += ", "
			buffer += entry
		Next
        If buffer.Length() = 0 Return "<none>"
        Return buffer
    End
End

Interface SpineAnimationStateStartDelegate
	Method OnSpineAnimationStateStart:Void(state:SpineAnimationState, trackIndex:Int)
End

Interface SpineAnimationStateEndDelegate
	Method OnSpineAnimationStateEnd:Void(state:SpineAnimationState, trackIndex:Int)
End

Interface SpineAnimationStateEventDelegate
	Method OnSpineAnimationStateEvent:Void(state:SpineAnimationState, trackIndex:Int, event:SpineEvent)
End

Interface SpineAnimationStateCompleteDelegate
	Method OnSpineAnimationStateComplete:Void(state:SpineAnimationState, trackIndex:Int, loopIndex:Int)
End

Class SpineTrackEntry
	Field _next:SpineTrackEntry
	Field _previous:SpineTrackEntry
	
	Field Animation:SpineAnimation
	Field Loop:Bool
	Field Delay:Float
	Field Time:Float
	Field LastTime:Float = -1
	Field EndTime:Float
	Field TimeScale:Float = 1
	Field mixTime:Float
	Field mixDuration:Float
	Field Mix:Float = 1
	
	Field StartDelegate:SpineAnimationStateStartDelegate
	Field EndDelegate:SpineAnimationStateEndDelegate
	Field EventDelegate:SpineAnimationStateEventDelegate
	Field CompleteDelegate:SpineAnimationStateCompleteDelegate
	
	Method OnStart:Void(state:SpineAnimationState, index:Int)
		If StartDelegate StartDelegate.OnSpineAnimationStateStart(state, index)
	End
	
	Method OnEnd:Void(state:SpineAnimationState, index:Int)
		If EndDelegate EndDelegate.OnSpineAnimationStateEnd(state, index)
	End
	
	Method OnEvent:Void(state:SpineAnimationState, index:Int, event:SpineEvent)
		If EventDelegate EventDelegate.OnSpineAnimationStateEvent(state, index, event)
	End
	
	Method OnComplete:Void(state:SpineAnimationState, index:Int, loopCount:Int)
		If CompleteDelegate CompleteDelegate.OnSpineAnimationStateComplete(state, index, loopCount)
	End
	
	Method ToString:String()
		If Animation = null return "<none>"
		return animation.Name
	End
End