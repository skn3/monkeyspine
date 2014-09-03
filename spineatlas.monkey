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

#rem
Import spine

Class SpineAtlas
	Field pages:SpineAtlasPage[]
	Field regions:SpineAtlasRegion[]
	Field imageLoader:SpineImageLoader

	'constructor / destructor
	Method New(path:String = "", fileLoader:SpineFileLoader = SpineDefaultFileLoader.instance, atlasLoader:SpineAtlasLoader = SpineMakeAtlasJSONAtlasLoader.instance, imageLoader:SpineImageLoader = SpineDefaultImageLoader.instance)
		' --- load a new atlas using the provided loaders ---
		If path.Length() = 0 Throw New SpineArgumentNullException("atlas path cannot be empty.")
		If atlasLoader = Null Throw New SpineArgumentNullException("file loader cannot be null.")
		If atlasLoader = Null Throw New SpineArgumentNullException("atlas loader cannot be null.")
		If imageLoader = Null Throw New SpineArgumentNullException("image loader cannot be null.")
		
		'load in the file
		Local fileStream:= fileLoader.OnLoadFile(path)
		
		'let the extendable atlas loader deal with loading the atlas
		'let the extendable image loader deal with loading the image
		atlasLoader.OnLoadAtlas(Self, fileStream, imageLoader)
	End

	Method FindRegion:SpineAtlasRegion(name:String)
		For Local i:= 0 Until regions.Length()
			If regions[i].name = name Return regions[i]
		Next
		Return Null
	End

	Method Free:Void()
		' --- dispose of this atlas ---
		'unlink all regions from their pointers
		For index = 0 Until regions.Length()
			regions[index].page = Null
			regions[index].image = Null
			regions[index] = Null
		Next
		
		'free each page image using the initial image loader
		Local index:= 0
		For index = 0 Until pages.Length()
			imageLoader.OnFreeImage(pages[index].image, pages[index].path)
			pages[index].image = Null
		Next
		
		'cleanup other links
		imageLoader = Null
	End
End

Class SpineFormat'FAKE ENUM
	Const Alpha:= 0
	Const Intensity:= 1
	Const LuminanceAlpha:= 2
	Const RGB565:= 3
	Const RGBA4444:= 4
	Const RGB888:= 5
	Const RGBA8888:= 6
	
	Function FromString:Int(name:String)
		Select name.ToLower()
			Case "alpha"
				Return Alpha
			Case "intensity"
				Return Intensity
			Case "luminancealpha"
				Return LuminanceAlpha
			Case "rgb565"
				Return RGB565
			Case "Rrgba4444"
				Return RGBA4444
			Case "rgb888"
				Return RGB888
			Case "rgba8888"
				Return RGBA8888
		End
	End
End

Class SpineTextureFilter'FAKE ENUM
	Const Nearest:= 0
	Const Linear:= 1
	Const MipMap:= 2
	Const MipMapNearestNearest:= 3
	Const MipMapLinearNearest:= 4
	Const MipMapNearestLinear:= 5
	Const MipMapLinearLinear:= 6
	
	Function FromString:Int(name:String)
		Select name.ToLower()
			Case "nearest"
				Return Nearest
			Case "linear"
				Return Linear
			Case "mipmap"
				Return MipMap
			Case "mipmapnearestnearest"
				Return MipMapNearestNearest
			Case "mipmaplinearnearest"
				Return MipMapLinearNearest
			Case "mipmapnearestlinear"
				Return MipMapNearestLinear
			Case "mipmaplinearlinear"
				Return MipMapLinearLinear
		End
	End
End

Class SpineTextureWrap'FAKE ENUM
	Const MirroredRepeat:= 0
	Const ClampToEdge:= 1
	Const RepeatTexture:= 2
	
	Function FromString:Int(name:String)
		Select name.ToLower()
			Case "MirroredRepeat"
				Return MirroredRepeat
			Case "clamptoedge"
				Return ClampToEdge
			Case "repeat"
				Return RepeatTexture
		End
	End
End

Class SpineAtlasPage
	Field path:String
	Field name:String
	Field format:Int
	Field minFilter:Int
	Field magFilter:Int
	Field uWrap:Int
	Field vWrap:Int
	Field image:Image
	Field width:int
	Field height:Int
End

Class SpineAtlasRegion
	Field page:SpineAtlasPage
	Field image:Image
	Field name:String
	Field x:int
	Field y:Int
	Field width:Int
	Field height:Int
	Field offsetX:float
	Field offsetY:float
	Field originalWidth:int
	Field originalHeight:Int
	Field index:int
	Field rotate:bool
End
#end