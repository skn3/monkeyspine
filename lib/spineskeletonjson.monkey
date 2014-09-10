'see license.txt For source licenses
Strict

Import spine

Class SpineSkeletonJson
	Const TIMELINE_SCALE:String = "scale"
	Const TIMELINE_ROTATE:String = "rotate"
	Const TIMELINE_TRANSLATE:String = "translate"
	Const TIMELINE_ATTACHMENT:String = "attachment"
	Const TIMELINE_COLOR:String = "color"

	Const ATTACHMENT_REGION:String = "region"
	Const ATTACHMENT_REGION_SEQUENCE:String = "regionSequence"

	Private
	Field attachmentLoader:SpineAttachmentLoader
	Field file:SpineFile
	Public
	Field Scale:Float

	Method New(atlas:SpineAtlas, file:SpineFile)
		If file = Null Throw New SpineArgumentNullException("file loader cannot be Null.")
		
		'save the loader objects
		Self.attachmentLoader = New SpineAtlasAttachmentLoader(atlas)
		Self.file = file
		
		'do some final setup
		Scale = 1.0
	End
	
	Method ReadSkeletonData:SpineSkeletonData()
		'read 
		Local skeletonData:SpineSkeletonData = New SpineSkeletonData
		skeletonData.Name = SpineExtractFilenameWithoutExtension(file.path)

		Local jsonRoot:= JSONObject(JSONData.ReadJSON(file.ReadAll()))
		If jsonRoot = Null Throw New SpineException("Invalid JSON.")

		Local jsonGroupArray:JSONArray
		Local jsonGroupObject:JSONObject
		Local jsonName:String
		Local jsonObjectDataItem:JSONDataItem
		Local jsonObject:JSONObject
		Local jsonItem:JSONDataItem
		Local jsonChildObject:JSONObject
		
		Local boneName:String
		Local boneData:SpineBoneData

		'Skeleton.
		jsonItem = jsonRoot.GetItem("skeleton")
		If jsonItem <> Null
			jsonObject = JSONObject(jsonItem)
			skeletonData.Hash = jsonObject.GetItem("hash", "")
			skeletonData.Version = jsonObject.GetItem("version", "")
			skeletonData.Width = jsonObject.GetItem("width", 0.0)
			skeletonData.Height = jsonObject.GetItem("height", 0.0)
		EndIf
		
		'Bones.
		jsonGroupArray = JSONArray(jsonRoot.GetItem("bones"))
		If jsonGroupArray <> Null
			Local boneParentData:SpineBoneData
			
			'iterate over bone objects
			For jsonObjectDataItem = EachIn jsonGroupArray
				jsonObject = JSONObject(jsonObjectDataItem)
				If jsonObject = Null Continue
				
				boneParentData = Null
				
				jsonItem = jsonObject.GetItem("parent")
				If jsonItem <> Null
					boneName = jsonItem.ToString()
					boneParentData = skeletonData.FindBone(boneName)
					If boneParentData = Null Throw New SpineException("Parent not:bone found: " + boneName)
				EndIf
				
				boneData = New SpineBoneData(jsonObject.GetItem("name", ""), boneParentData)
				boneData.Length = jsonObject.GetItem("length", 0.0) * Scale
				boneData.X = jsonObject.GetItem("x", 0.0) * Scale
				boneData.Y = jsonObject.GetItem("y", 0.0) * Scale
				boneData.Rotation = jsonObject.GetItem("rotation", 0.0)
				boneData.ScaleX = jsonObject.GetItem("scaleX", 1.0)
				boneData.ScaleY = jsonObject.GetItem("scaleY", 1.0)
				boneData.InheritScale = jsonObject.GetItem("inheritScale", True)
				boneData.InheritRotation = jsonObject.GetItem("inheirtRotation", True)
				skeletonData.AddBone(boneData)
			Next
		EndIf

		'IK constraints.
		jsonGroupArray = JSONArray(jsonRoot.GetItem("ik"))
		If jsonGroupArray <> Null
			Local ikConstraintData:SpineIkConstraintData
			Local targetName:String
			
			Local bones:SpineBoneData[10]
			Local bonesCount:Int
			
			For jsonObjectDataItem = EachIn jsonGroupArray
				jsonObject = JSONObject(jsonObjectDataItem)
				If jsonObject = Null Continue
				
				ikConstraintData = New SpineIkConstraintData(jsonObject.GetItem("name", ""))
							
				jsonChildObject = JSONObject(jsonObject.GetItem("bones"))
				bonesCount = 0
				If jsonChildObject
					For boneName = EachIn jsonChildObject.Names()
						boneData = skeletonData.FindBone(boneName)
						If boneData = Null Throw New SpineException("IK bone found: " + boneName)
						
						If bonesCount = bones.Length() bones = bones.Resize(bonesCount * 2 + 10)
						bones[bonesCount] = boneData
						bonesCount += 1
					Next
				EndIf
				
				If bonesCount > 0 ikConstraintData.Bones = bones[ .. bonesCount]
			
				targetName = jsonObject.GetItem("target", "")
				ikConstraintData.Target = skeletonData.FindBone(targetName)
				If ikConstraintData.Target = Null Throw New SpineException("Target bone not found: " + targetName)
				
				'ikConstraintData.bendDirection = GetBoolean(ikMap, "bendPositive", True) ? 1 : -1
				If jsonObject.GetItem("bendPositive", True)
					ikConstraintData.BendDirection = 1
				Else
					ikConstraintData.BendDirection = -1
				EndIf
				skeletonData.AddIkConstraint(ikConstraintData)
			Next
		EndIf
		
		'slots
		Local slotName:String
		Local slotData:SpineSlotData
		Local color:String
		jsonGroupArray = JSONArray(jsonRoot.GetItem("slots"))
		If jsonGroupArray <> Null
			'iterate over bone objects
			For jsonObjectDataItem = EachIn jsonGroupArray
				'convert to correct format
				jsonObject = JSONObject(jsonObjectDataItem)
				If jsonObject = Null Continue
				
				'process this object
				slotName = jsonObject.GetItem("name", "")
				boneName = jsonObject.GetItem("bone","")
				boneData = skeletonData.FindBone(boneName)
				
				If boneData = Null Throw New SpineException("Slot bone not found: " + boneName)
				slotData = New SpineSlotData(slotName, boneData)

				jsonItem = jsonObject.GetItem("color")
				If jsonItem <> Null
					color = jsonItem.ToString()
					slotData.R = ToColor(color, 0)
					slotData.G = ToColor(color, 1)
					slotData.B = ToColor(color, 2)
					slotData.A = ToColor(color, 3)
				EndIf

				jsonItem = jsonObject.GetItem("attachment")
				If jsonItem <> Null slotData.AttachmentName = jsonItem.ToString()
				
				jsonItem = jsonObject.GetItem("additive")
				If jsonItem <> Null slotData.AdditiveBlending = jsonItem.ToBool()

				skeletonData.AddSlot(slotData)
			Next
		EndIf

		'skins
		Local skin:SpineSkin
		Local slotIndex:Int
		Local attachment:SpineAttachment
		Local attachmentName:String
		Local eventData:SpineEventData
		Local jsonSlot:JSONObject
		Local jsonAttachment:JSONObject
		
		'iterate over skins
		jsonGroupObject = JSONObject(jsonRoot.GetItem("skins"))
		If jsonGroupObject <> Null
			For jsonName = EachIn jsonGroupObject.Names()
				'get skin from name
				jsonObject = JSONObject(jsonGroupObject.GetItem(jsonName))
				skin = New SpineSkin(jsonName)
				
				'iterate over slots in skin
				For slotName = EachIn jsonObject.Names()
					jsonSlot = JSONObject(jsonObject.GetItem(slotName))
					slotIndex = skeletonData.FindSlotIndex(slotName)
					
					'iterate over attachments in slot
					For attachmentName = EachIn jsonSlot.Names()
						jsonAttachment = JSONObject(jsonSlot.GetItem(attachmentName))
						
						attachment = ReadAttachment(skin, attachmentName, jsonAttachment)
						skin.AddAttachment(slotIndex, attachmentName, attachment)
					Next
				Next
				
				skeletonData.AddSkin(skin)
				If skin.Name = "default" skeletonData.DefaultSkin = skin
			Next
		EndIf
		
		'events
		jsonGroupObject = JSONObject(jsonRoot.GetItem("events"))
		If jsonGroupObject <> Null
			For jsonName = EachIn jsonGroupObject.Names()
				'get event from name
				jsonObject = JSONObject(jsonGroupObject.GetItem(jsonName))
				eventData = New SpineEventData(jsonName)
				eventData.IntValue = jsonObject.GetItem("Int", 0)
				eventData.FloatValue = jsonObject.GetItem("Int", 0.0)
				eventData.StringValue = jsonObject.GetItem("Int", "")
				
				'add it
				skeletonData.AddEvent(eventData)
			Next
		EndIf		

		'animations.
		jsonGroupObject = JSONObject(jsonRoot.GetItem("animations"))
		If jsonGroupObject <> Null
			For jsonName = EachIn jsonGroupObject.Names()
				'get animation from name
				jsonObject = JSONObject(jsonGroupObject.GetItem(jsonName))
				ReadAnimation(jsonName, jsonObject, skeletonData)
			Next
		EndIf

		skeletonData.TrimArrays()
		
		Return skeletonData
	End

	Method ReadAttachment:SpineAttachment(skin:SpineSkin, name:String, jsonAttachment:JSONObject)
		Local jsonItem:JSONDataItem
		Local color:String
		
		jsonItem = jsonAttachment.GetItem("name")
		If jsonItem <> Null name = jsonItem.ToString()

		Local type:Int = SpineAttachmentType.Region'defaults to region aiiighhht
		jsonItem = jsonAttachment.GetItem("type")
		If jsonItem <> Null type = SpineAttachmentType.FromString(jsonItem.ToString())

		Local path:String = name
		jsonItem = jsonAttachment.GetItem("path")
		If jsonItem <> Null path = jsonItem.ToString()

		Select type
			Case SpineAttachmentType.Region
				Local region:SpineRegionAttachment = attachmentLoader.NewRegionAttachment(skin, name, path)
				If region = Null
					Return Null
				EndIf
				
				region.Path = path
				region.X = jsonAttachment.GetItem("x", 0.0) * Scale
				region.Y = jsonAttachment.GetItem("y", 0.0) * Scale
				region.ScaleX = jsonAttachment.GetItem("scaleX", 1.0)
				region.ScaleY = jsonAttachment.GetItem("scaleY", 1.0)
				region.Rotation = jsonAttachment.GetItem("rotation", 0.0)
				region.Width = jsonAttachment.GetItem("width", 32.0) * Scale
				region.Height = jsonAttachment.GetItem("height", 32.0) * Scale
				region.UpdateOffset()
				
				jsonItem = jsonAttachment.GetItem("color")
				If jsonItem <> Null
					color = jsonItem.ToString()
					region.R = ToColor(color, 0)
					region.G = ToColor(color, 1)
					region.B = ToColor(color, 2)
					region.A = ToColor(color, 3)
				EndIf
				
				Return region
				
			Case SpineAttachmentType.Mesh
				Local mesh:SpineMeshAttachment = attachmentLoader.NewMeshAttachment(skin, name, path)
				If mesh = Null
					Return Null
				EndIf
				
				mesh.Path = path
				mesh.Vertices = GetFloatArray(jsonAttachment, "vertices", Scale)
				mesh.Triangles = GetIntArray(jsonAttachment, "triangles")
				mesh.RegionUVs = GetFloatArray(jsonAttachment, "uvs", 1.0)
				mesh.UpdateUVs()
				
				jsonItem = jsonAttachment.GetItem("color")
				If jsonItem <> Null
					color = jsonItem.ToString()
					mesh.R = ToColor(color, 0)
					mesh.G = ToColor(color, 1)
					mesh.B = ToColor(color, 2)
					mesh.A = ToColor(color, 3)
				EndIf
				
				mesh.HullLength = jsonAttachment.GetItem("hull", 0) * 2
				
				jsonItem = jsonAttachment.GetItem("edges")
				If jsonItem <> Null mesh.Edges = GetIntArray(jsonAttachment, "edges")
				
				mesh.Width = jsonAttachment.GetItem("width", 0.0) * Scale
				mesh.Height = jsonAttachment.GetItem("height", 0.0) * Scale
				
				Return mesh
				
			Case SpineAttachmentType.SkinnedMesh
				Local mesh:SpineSkinnedMeshAttachment = attachmentLoader.NewSkinnedMeshAttachment(skin, name, path)
				If mesh = Null
					Return Null
				EndIf
				
				mesh.Path = path
				Local uvs:= GetFloatArray(jsonAttachment, "uvs", 1.0)
				Local vertices:= GetFloatArray(jsonAttachment, "vertices", Scale)
				Local weights:Float[uvs.Length() * 3 * 3]
				Local weightsIndex:Int
				Local bones:Int[uvs.Length() * 3]
				Local bonesIndex:Int
				
				Local boneCount:Int
				Local i:Int
				Local nn:Int
				Local n:= vertices.Length()
				
				While i < n
					boneCount = vertices[i]
					i += 1
					bones[bonesIndex] = boneCount
					bonesIndex += 1
					nn = i + boneCount * 4
					While i < nn
						bones[bonesIndex] = vertices[i]
						weights[weightsIndex] = vertices[i + 1] * Scale
						weightsIndex += 1
						weights[weightsIndex] = vertices[i + 2] * Scale
						weightsIndex += 1
						weights[weightsIndex] = vertices[i + 3] * Scale
						weightsIndex += 1
						i += 4
					Wend
				Wend
				
				mesh.Bones = bones
				mesh.Weights = weights
				mesh.Triangles = GetIntArray(jsonAttachment, "triangles")
				mesh.RegionUVs = uvs
				mesh.UpdateUVs()
				
				jsonItem = jsonAttachment.GetItem("color")
				If jsonItem <> Null
					color = jsonItem.ToString()
					mesh.R = ToColor(color, 0)
					mesh.G = ToColor(color, 1)
					mesh.B = ToColor(color, 2)
					mesh.A = ToColor(color, 3)
				EndIf
				
				mesh.HullLength = jsonAttachment.GetItem("hull", 0) * 2
				
				jsonItem = jsonAttachment.GetItem("edges")
				If jsonItem <> Null mesh.Edges = GetIntArray(jsonAttachment, "edges")
				
				mesh.Width = jsonAttachment.GetItem("width", 0.0) * Scale
				mesh.Height = jsonAttachment.GetItem("height", 0.0) * Scale
				
				Return mesh
				
			Case SpineAttachmentType.BoundingBox
				Local box:SpineBoundingBoxAttachment = attachmentLoader.NewBoundingBoxAttachment(skin, name)
				If box = Null
					Return Null
				EndIf
				
				box.Vertices = GetFloatArray(jsonAttachment, "vertices", Scale)
				Return box
		End

		Return Null
	End
	
	Method GetFloatArray:Float[] (jsonObject:JSONObject, name:String, scale:Float)
		Local list:= JSONArray(jsonObject.GetItem(name))
		If list = Null Return[]
		
		'var list = (List<Object>) map[name]
		Local total:= list.values.Count()
		Local values:Float[total]
		If scale = 1.0
			Local i:Int
			For Local listItem:= EachIn list
				values[i] = listItem.ToFloat()
				i += 1
			Next
		Else
			Local i:Int
			For Local listItem:= EachIn list
				values[i] = listItem.ToFloat() * scale
				i += 1
			Next
		EndIf
		Return values
	End
	
	Method GetIntArray:Int[] (jsonObject:JSONObject, name:String)
		Local list:= JSONArray(jsonObject.GetItem(name))
		If list = Null Return[]
		
		'var list = (List<Object>) map[name]
		Local total:= list.values.Count()
		Local values:Int[total]

		Local i:Int
		For Local listItem:= EachIn list
			values[i] = listItem.ToInt()
			i += 1
		Next
		Return values
	End

	Function ToColor:Float(hex:String, colorIndex:Int)
		If hex.Length() <> 8 Throw New SpineArgumentNullException("Color hexidecimal length must be 8, recieved: " + hex)
		
		Local val:Int = 0
		Local offset:Int = colorIndex * 2
		hex = hex.ToUpper()
		For Local i:Int = offset Until offset + 2
			val *=16	
			If hex[i] >= 48 And hex[i] <= 57
				val += (hex[i] - 48)
			Else
				val += (hex[i] - 55)
			EndIf
			
		Next
		Return val / 255.0
	End

	Private
	Method ReadAnimation:Void(name:String, jsonAnimation:JSONObject, skeletonData:SpineSkeletonData)
		Local timelines:SpineTimeline[]
		Local timelineCount:Int

		Local duration:Float = 0.0

		Local index:Int
		Local jsonGroupObject:JSONObject
		Local jsonGroupArray:JSONArray
		Local jsonBone:JSONObject
		Local jsonTimeline:JSONArray
		Local jsonTimelineFrameDataItem:JSONDataItem
		Local jsonTimelineFrame:JSONObject
		Local boneName:String
		Local boneIndex:Int
		Local timelineName:String
		Local frameIndex:Int
		Local timelineScale:Float
		Local slotIndex:Int
		Local slotName:String
		
		'slots		
		jsonGroupObject = JSONObject(jsonAnimation.GetItem("slots"))
		If jsonGroupObject <> Null
			Local jsonSlot:JSONObject
			Local c:String
			
			For slotName = EachIn jsonGroupObject.Names()
				jsonSlot = JSONObject(jsonGroupObject.GetItem(slotName))
				If jsonSlot = Null Continue
			
				slotIndex = skeletonData.FindSlotIndex(slotName)
				
				For timelineName = EachIn jsonSlot.Names()
					jsonTimeline = JSONArray(jsonSlot.GetItem(timelineName))
				
					Select timelineName
						Case TIMELINE_COLOR
							Local timeline:SpineColorTimeline = New SpineColorTimeline(jsonTimeline.values.Count())
							timeline.SlotIndex = slotIndex
	
							frameIndex = 0
							For jsonTimelineFrameDataItem = EachIn jsonTimeline
								'convert to correct object format
								jsonTimelineFrame = JSONObject(jsonTimelineFrameDataItem)
								
								'process object
								c = jsonTimelineFrame.GetItem("color", "")
								timeline.SetFrame(frameIndex, jsonTimelineFrame.GetItem("time", 0.0), ToColor(c, 0), ToColor(c, 1), ToColor(c, 2), ToColor(c, 3))
								ReadCurve(timeline, frameIndex, jsonTimelineFrame)
								frameIndex += 1
							Next
							
							If timelineCount >= timelines.Length() timelines = timelines.Resize(timelines.Length() * 2 + 10)
							timelines[timelineCount] = timeline
							timelineCount += 1
							
							duration = Max(duration, timeline.Frames[timeline.FrameCount() * 5 - 5])
							
						Case TIMELINE_ATTACHMENT
							Local timeline:SpineAttachmentTimeline = New SpineAttachmentTimeline(jsonTimeline.values.Count())
							timeline.SlotIndex = slotIndex
	
							frameIndex = 0
							For jsonTimelineFrameDataItem = EachIn jsonTimeline
								'convert to correct object format
								jsonTimelineFrame = JSONObject(jsonTimelineFrameDataItem)
								
								'process object
								timeline.SetFrame(frameIndex, jsonTimelineFrame.GetItem("time", 0.0), jsonTimelineFrame.GetItem("name", ""))
								frameIndex += 1
							Next
							
							If timelineCount >= timelines.Length() timelines = timelines.Resize(timelines.Length() * 2 + 10)
							timelines[timelineCount] = timeline
							timelineCount += 1
							
							duration = Max(duration, timeline.Frames[timeline.FrameCount() -1])
						Default
							Throw New SpineException("Invalid type:timeline For a slot: " + timelineName + " (" + slotName + ")")
					End
					
				Next
			Next
		EndIf
		
		'bones
		jsonGroupObject = JSONObject(jsonAnimation.GetItem("bones"))
		If jsonGroupObject <> Null
			For boneName = EachIn jsonGroupObject.Names()
				jsonBone = JSONObject(jsonGroupObject.GetItem(boneName))
				If jsonBone = Null Continue
				
				boneIndex = skeletonData.FindBoneIndex(boneName)
				If boneIndex = -1 Throw New SpineException("Bone not found: " + boneName)
				
				For timelineName = EachIn jsonBone.Names()
					jsonTimeline = JSONArray(jsonBone.GetItem(timelineName))
					If jsonTimeline = Null Continue
					
					Select timelineName
						Case TIMELINE_ROTATE
							Local timeline:SpineRotateTimeline = New SpineRotateTimeline(jsonTimeline.values.Count())
							timeline.BoneIndex = boneIndex
	
							frameIndex = 0
							For jsonTimelineFrameDataItem = EachIn jsonTimeline
								'convert to correct object format
								jsonTimelineFrame = JSONObject(jsonTimelineFrameDataItem)
								
								'process object
								timeline.SetFrame(frameIndex, jsonTimelineFrame.GetItem("time", 0.0), jsonTimelineFrame.GetItem("angle", 0.0))
								ReadCurve(timeline, frameIndex, jsonTimelineFrame)
								frameIndex += 1
							Next
							
							'add timeline (maybe resize array)
							If timelineCount >= timelines.Length() timelines = timelines.Resize(timelines.Length() * 2 + 10)
							timelines[timelineCount] = timeline
							timelineCount += 1
		
							duration = Max(duration, timeline.Frames[timeline.FrameCount() * 2 - 2])
							
						Case TIMELINE_TRANSLATE, TIMELINE_SCALE
							Local timeline:SpineTranslateTimeline
							timelineScale = 1.0
							
							If timelineName = TIMELINE_SCALE
								timeline = New SpineScaleTimeline(jsonTimeline.values.Count())
							Else
								timeline = New SpineTranslateTimeline(jsonTimeline.values.Count())
								timelineScale = Scale
							EndIf
							timeline.BoneIndex = boneIndex
	
							frameIndex = 0
							For jsonTimelineFrameDataItem = EachIn jsonTimeline
								'convert to correct object format
								jsonTimelineFrame = JSONObject(jsonTimelineFrameDataItem)
								
								'process object
								timeline.SetFrame(frameIndex, jsonTimelineFrame.GetItem("time", 0.0), jsonTimelineFrame.GetItem("x", 0.0) * timelineScale, jsonTimelineFrame.GetItem("y", 0.0) * timelineScale)
								ReadCurve(timeline, frameIndex, jsonTimelineFrame)
								frameIndex += 1
							Next
							
							If timelineCount >= timelines.Length() timelines = timelines.Resize(timelines.Length() * 2 + 10)
							timelines[timelineCount] = timeline
							timelineCount += 1
							
							duration = Max(duration, timeline.Frames[timeline.FrameCount() * 3 - 3])
						Default
							Throw New SpineException("Invalid type:timeline For a bone: " + timelineName + " (" + boneName + ")")
					End
				Next
			Next
		EndIf
		
		'ik
		jsonGroupArray = JSONArray(jsonAnimation.GetItem("ik"))
		If jsonGroupArray <> Null
			Local jsonIkConstraint:JSONObject
			Local bendPositive:Int

			Local timeline:SpineIkConstraintTimeline = New SpineIkConstraintTimeline(jsonGroupArray.values.Count())
			frameIndex = 0
			
			For jsonTimelineFrameDataItem = EachIn jsonGroupArray
				jsonIkConstraint = JSONObject(jsonTimelineFrameDataItem)
				
				If jsonTimelineFrame.GetItem("bendPositive", True)
					bendPositive = 1
				Else
					bendPositive = -1
				EndIf
				timeline.SetFrame(frameIndex, jsonTimelineFrame.GetItem("time", 0.0), jsonTimelineFrame.GetItem("mix", 1.0), bendPositive)
				ReadCurve(timeline, frameIndex, jsonTimelineFrame)
				frameIndex += 1
			Next
			
			If timelineCount >= timelines.Length() timelines = timelines.Resize(timelines.Length() * 2 + 10)
			timelines[timelineCount] = timeline
			timelineCount += 1
							
			duration = Max(duration, timeline.Frames[timeline.FrameCount() * 3 - 3])
		EndIf
		
		'ffd
		jsonGroupObject = JSONObject(jsonAnimation.GetItem("ffd"))
		If jsonGroupObject <> Null
			Local skin:SpineSkin
			Local jsonFfdGroup:JSONObject
			Local jsonSlotGroup:JSONObject
			Local jsonMeshArray:JSONArray
			Local jsonMeshDataItem:JSONDataItem
			Local jsonMesh:JSONObject
			Local jsonMeshVertices:JSONArray
			Local jsonMeshVerticesItem:JSONDataItem
			Local slotKey:String
			Local meshKey:String
			Local timeline:SpineFFDTimeline
			Local attachment:SpineAttachment
			Local vertexCount:Int
			Local vertices:Float[]
			Local start:Int
			Local i:Int
			
			For Local ffdKey:String = EachIn jsonGroupObject.Names()
				jsonFfdGroup = JSONObject(jsonGroupObject.GetItem(ffdKey))
				If jsonFfdGroup = Null Continue
				
				skin = skeletonData.FindSkin(ffdKey)
				
				For slotKey = EachIn jsonFfdGroup.Names()
					jsonSlotGroup = JSONObject(jsonFfdGroup.GetItem(slotKey))
					If jsonSlotGroup = Null Continue
					
					slotIndex = skeletonData.FindSlotIndex(slotKey)
					
					For meshKey = EachIn jsonSlotGroup.Names()
						jsonMeshArray = JSONArray(jsonSlotGroup.GetItem(meshKey))
						
						attachment = skin.GetAttachment(slotIndex, meshKey)
						If attachment = Null Throw New SpineException("FFD attachment not found: " + meshKey)
						
						timeline = New SpineFFDTimeline(jsonMeshArray.values.Count())
						timeline.SlotIndex = slotIndex
						timeline.Attachment = attachment
						
						If attachment.Type = SpineAttachmentType.Mesh
							vertexCount = SpineMeshAttachment(attachment).Vertices.Length()
						Else
							vertexCount = SpineSkinnedMeshAttachment(attachment).Weights.Length() / 3 * 2
						EndIf
						
						frameIndex = 0
						For jsonMeshDataItem = EachIn jsonMeshArray
							jsonMesh = JSONObject(jsonMeshDataItem)
							
							jsonMeshVertices = JSONArray(jsonMesh.GetItem("vertices"))
							If jsonMeshVertices = Null
								If attachment.Type = SpineAttachmentType.Mesh
									vertices = SpineMeshAttachment(attachment).Vertices
								Else
									vertices = New Float[vertexCount]
								EndIf
							Else
								vertices = New Float[vertexCount]
								start = jsonMesh.GetItem("offset", 0)
								
								i = 0
								If Scale = 1.0
									For jsonMeshVerticesItem = EachIn jsonMeshVertices
										vertices[i + start] = jsonMeshVerticesItem.ToFloat()
										i += 1
									Next
								Else
									For jsonMeshVerticesItem = EachIn jsonMeshVertices
										vertices[i + start] = jsonMeshVerticesItem.ToFloat() * Scale
										i += 1
									Next
								EndIf
								
								If attachment.Type = SpineAttachmentType.Mesh
									Local meshVertices:= SpineMeshAttachment(attachment).Vertices
									For i = 0 Until vertexCount
										vertices[i] += meshVertices[i]
									Next
								EndIf
							EndIf
							
							timeline.SetFrame(frameIndex, jsonMesh.GetItem("time", 0.0), vertices)
							ReadCurve(timeline, frameIndex, jsonMesh)
							frameIndex += 1
						Next
						
						If timelineCount >= timelines.Length() timelines = timelines.Resize(timelines.Length() * 2 + 10)
						timelines[timelineCount] = timeline
						timelineCount += 1
							
						duration = Max(duration, timeline.Frames[timeline.FrameCount() -1])
					Next
				Next
			Next
		EndIf
		
		'draw order		
		jsonGroupArray = JSONArray(jsonAnimation.GetItem("draworder"))
		If jsonGroupArray <> Null
			Local jsonOrder:JSONObject
			Local jsonOffsetDataItem:JSONDataItem
			Local jsonOffsetArray:JSONArray
			Local jsonOffsetTotal:Int
			Local jsonOffset:JSONObject
			Local originalIndex:Int
			Local unchangedIndex:Int
			Local offset:Int
			
			'get slot count
			'we get it from the count value as we are still reading json data
			'if we use teh array size then the code below will use teh size of the unfilled array elements
			Local slotsCount:= skeletonData.slotsCount
			
			'create this New timeline
			Local timeline:SpineDrawOrderTimeline = New SpineDrawOrderTimeline(jsonGroupArray.values.Count())
			frameIndex = 0
			
			'iterate over frame keys
			For jsonTimelineFrameDataItem = EachIn jsonGroupArray
				jsonOrder = JSONObject(jsonTimelineFrameDataItem)
				
				Local drawOrder:Int[]
				
				'get the offset array
				jsonOffsetArray = JSONArray(jsonOrder.GetItem("offsets"))
				If jsonOffsetArray <> Null
					jsonOffsetTotal = jsonOffsetArray.values.Count()
					
					'create draw order array and reset it
					drawOrder = New Int[slotsCount]
					For slotIndex = slotsCount - 1 To 0 Step - 1
						drawOrder[slotIndex] = -1
					Next
					
					'create unchanged array
					Local unchanged:= New Int[slotsCount - jsonOffsetTotal]
					
					originalIndex = 0
					unchangedIndex = 0
					
					'iterate over offsets
					For jsonOffsetDataItem = EachIn jsonOffsetArray
						jsonOffset = JSONObject(jsonOffsetDataItem)
					
						'get slot index
						slotName = jsonOffset.GetItem("slot")
						slotIndex = skeletonData.FindSlotIndex(slotName)
						
						'check slot is valid
						If slotIndex = -1 Throw New SpineException("Slot not found: " + slotName)
											
						'collect unchanges items
						While originalIndex <> slotIndex
							unchanged[unchangedIndex] = originalIndex
							unchangedIndex += 1
							originalIndex += 1
						Wend
						
						'get offset
						offset = jsonOffset.GetItem("offset", 0)
						
						'set changed items
						drawOrder[originalIndex + offset] = originalIndex
						originalIndex += 1
					Next
					
					'collect remaining unchanged items
					While originalIndex < slotsCount
						unchanged[unchangedIndex] = originalIndex
						unchangedIndex += 1
						originalIndex += 1
					Wend
					
					'fill unchanged items
					For index = slotsCount - 1 To 0 Step - 1
						If drawOrder[index] = -1
							unchangedIndex -= 1
							drawOrder[index] = unchanged[unchangedIndex]
						EndIf
					Next
				EndIf
				
				'process frame in timeline
				timeline.SetFrame(frameIndex, jsonOrder.GetItem("time", 0.0), drawOrder)
				
				'Next frame index
				frameIndex += 1
			Next
			
			'add timeline
			If timelineCount >= timelines.Length() timelines = timelines.Resize(timelines.Length() * 2 + 10)
			timelines[timelineCount] = timeline
			timelineCount += 1
			
			'update duration
			duration = Max(duration, timeline.Frames[timeline.FrameCount() -1])
		EndIf
		
		'events
		jsonGroupArray = JSONArray(jsonAnimation.GetItem("events"))
		If jsonGroupArray <> Null
			Local eventName:String
			Local jsonEvent:JSONObject
			Local event:SpineEvent
			Local eventData:SpineEventData
			
			Local timeline:SpineEventTimeline = New SpineEventTimeline(jsonGroupArray.values.Count())
			frameIndex = 0
			
			For jsonTimelineFrameDataItem = EachIn jsonGroupArray
				jsonEvent = JSONObject(jsonTimelineFrameDataItem)
				
				'lookup the event
				eventName = jsonEvent.GetItem("name")
				eventData = skeletonData.FindEvent(eventName)
				If eventData = Null Throw New SpineException("Event not found: " + eventName)
				
				'create New event
				event = New SpineEvent(eventData)
				event.IntValue = jsonEvent.GetItem("Int", eventData.IntValue)
				event.FloatValue = jsonEvent.GetItem("Float", eventData.FloatValue)
				event.StringValue = jsonEvent.GetItem("String", eventData.StringValue)
				
				'process frame in timeline
				timeline.SetFrame(frameIndex, jsonEvent.GetItem("time", 0.0), event)
				
				'Next frame index
				frameIndex += 1
			Next
			
			'add timeline
			If timelineCount >= timelines.Length() timelines = timelines.Resize(timelines.Length() * 2 + 10)
			timelines[timelineCount] = timeline
			timelineCount += 1
			
			'update duration
			duration = Max(duration, timeline.Frames[timeline.FrameCount() -1])
		EndIf

		'trim timeline
		If timelineCount < timelines.Length() timelines = timelines.Resize(timelineCount)
		
		skeletonData.AddAnimation(New SpineAnimation(name, timelines, duration))
	End

	Method ReadCurve:Void(timeline:SpineCurveTimeline, frameIndex:Int, jsonTimelineFrame:JSONObject)
		Local jsonItem:JSONDataItem
		
		jsonItem = jsonTimelineFrame.GetItem("curve")
		If jsonItem = Null Return
		
		Select jsonItem.ToString()
			Case "stepped"
				timeline.SetStepped(frameIndex)
			Default
				Local jsonArray:JSONArray = JSONArray(jsonItem)
				If jsonArray <> Null
					'bezier curve
					Local curve:= jsonArray.values.ToArray()
					timeline.SetCurve(frameIndex, Float(curve[0]), Float(curve[1]), Float(curve[2]), Float(curve[3]))
				EndIf
		End
	End
End
