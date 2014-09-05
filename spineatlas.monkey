'see license.txt for source licenses

Strict

Import spine

Interface SpineAtlasLoader
	Method Load:Void(fileLoader:SpineFileLoader, imagedDir:String, textureLoader:SpineTextureLoader)
End

Interface SpineAtlas
	Method pages:SpineAtlasPage[] () Property
	Method pages:Void(value:SpineAtlasPage[]) Property
	Method regions:SpineAtlasRegion[] () Property
	Method regions:Void(value:SpineAtlasRegion[]) Property
	Method textureLoader:SpineTextureLoader() Property
	Method textureLoader:Void(value:SpineTextureLoader) Property
	
	Method Discard:Void()
End

Interface SpineAtlasPage
	Method name:String() Property
	Method name:Void(value:String) Property
	Method format:String() Property
	Method format:Void(value:Int) Property
	Method minFilter:Int() Property
	Method minFilter:Void(value:Int) Property
	Method magFilter:Int() Property
	Method magFilter:Void(value:Int) Property
	Method uWrap:Int() Property
	Method uWrap:Void(value:Int) Property
	Method vWrap:Int() Property
	Method vWrap:Void(value:Int) Property
	Method width:Int() Property
	Method width:Void(value:Int) Property
	Method height:Int() Property
	Method height:Void(value:Int) Property
	'Method Object rendererObject;
End

Interface SpineAtlasRegion
	Method page:String() Property
	Method page:Void(value:SpineAtlasPage) Property
	Method name:String() Property
	Method name:Void(value:string) Property
	Method x:Int() Property
	Method x:Void(value:Int) Property
	Method y:Int() Property
	Method y:Void(value:Int) Property
	Method width:Int() Property
	Method width:Void(value:Int) Property
	Method height:Int() Property
	Method height:Void(value:Int) Property
	Method u:Float() Property
	Method u:Void(value:Float) Property
	Method v:Float() Property
	Method v:Void(value:Float) Property
	Method u2:Float() Property
	Method u2:Void(value:Float) Property
	Method v2:Float() Property
	Method v2:Void(value:Float) Property
	Method offsetX:Float() Property
	Method offsetX:Void(value:Float) Property
	Method offsetY:Float() Property
	Method offsetY:Void(value:Float) Property
	Method originalWidth:Int() Property
	Method originalWidth:Void(value:Int) Property
	Method originalHeight:Int() Property
	Method originalHeight:Void(value:Int) Property
	Method index:Int() Property
	Method index:Void(value:Int) Property
	Method rotate:Bool() Property
	Method rotate:Void(value:Bool) Property
	Method splits:int[] () Property
	Method splits:Void(value:int[]) Property
	Method pads:int[] () Property
	Method pads:Void(value:int[]) Property
End

#rem
Class SpineAtlas222
	List<SpineAtlasPage> pages = new List<SpineAtlasPage>();
	List<SpineAtlasRegion> regions = new List<SpineAtlasRegion>();
	SpineTextureLoader textureLoader;

	Method New(path:String, textureLoader:SpineTextureLoader)
		'use default file loader
		'StreamReader fileLoader = new StreamReader(path)
		'try
		'	Load(fileLoader, Path.GetDirectoryName(path), textureLoader);
		'Catch(Exception ex)
		'	Throw New SpineException("Error reading atlas file: " + path, ex);
		'End
	End

	Method SpineAtlas(fileLoader:SpineFileLoader, dir:String, textureLoader:SpineTextureLoader)
		Load(fileLoader, dir, textureLoader)
	End

	Private
	Method Load:Void(fileLoader:SpineFileLoader, imagesDir:String, textureLoader:SpineTextureLoader)
		If textureLoader = Null Throw New SpineArgumentNullException("textureLoader cannot be null.");
		Self.textureLoader = textureLoader;

		Local tuple:String[4]
		SpineAtlasPage page = null;
		while (true)
			String line = fileLoader.ReadLine();
			if (line == null) break;
			if (line.Trim().Length == 0)
				page = null;
			else if (page == null)
				page = new SpineAtlasPage();
				page.name = line;

				if (readTuple(fileLoader, tuple) == 2)  // size is only optional for an atlas packed with an old TexturePacker.
				page.width = int.Parse(tuple[0]);
				page.height = int.Parse(tuple[1]);
				readTuple(fileLoader, tuple);
				}
				page.format = (Format)Enum.Parse(typeof(Format), tuple[0], false);

				readTuple(fileLoader, tuple);
				page.minFilter = (TextureFilter)Enum.Parse(typeof(TextureFilter), tuple[0], false);
				page.magFilter = (TextureFilter)Enum.Parse(typeof(TextureFilter), tuple[1], false);

				String direction = readValue(fileLoader);
				page.uWrap = TextureWrap.ClampToEdge;
				page.vWrap = TextureWrap.ClampToEdge;
				if (direction == "x")
					page.uWrap = TextureWrap.Repeat;
				else if (direction == "y")
					page.vWrap = TextureWrap.Repeat;
				else if (direction == "xy")
					page.uWrap = page.vWrap = TextureWrap.Repeat;

					textureLoader.Load(page, Path.Combine(imagesDir, line));

					pages.Add(page);

					} else
					SpineAtlasRegion region = new SpineAtlasRegion();
					region.name = line;
					region.page = page;

					region.rotate = Boolean.Parse(readValue(fileLoader));

					readTuple(fileLoader, tuple);
					int x = int.Parse(tuple[0]);
					int y = int.Parse(tuple[1]);

					readTuple(fileLoader, tuple);
					int width = int.Parse(tuple[0]);
					int height = int.Parse(tuple[1]);

					region.u = x / (float)page.width;
					region.v = y / (float)page.height;
					if (region.rotate)
						region.u2 = (x + height) / (float)page.width;
						region.v2 = (y + width) / (float)page.height;
						} else
						region.u2 = (x + width) / (float)page.width;
						region.v2 = (y + height) / (float)page.height;
						}
						region.x = x;
						region.y = y;
						region.width = Math.Abs(width);
						region.height = Math.Abs(height);

						if (readTuple(fileLoader, tuple) == 4)  // split is optional
						region.splits = new int[] int.Parse(tuple[0]), int.Parse(tuple[1]),
							int.Parse(tuple[2]), int.Parse(tuple[3])};

						if (readTuple(fileLoader, tuple) == 4)  // pad is optional, but only present with splits
						region.pads = new int[] int.Parse(tuple[0]), int.Parse(tuple[1]),
							int.Parse(tuple[2]), int.Parse(tuple[3])};

						readTuple(fileLoader, tuple);
						}
						}

						region.originalWidth = int.Parse(tuple[0]);
						region.originalHeight = int.Parse(tuple[1]);

						readTuple(fileLoader, tuple);
						region.offsetX = int.Parse(tuple[0]);
						region.offsetY = int.Parse(tuple[1]);

						region.index = int.Parse(readValue(fileLoader));

						regions.Add(region);
						}
						}
					End

	Function String readValue (TextReader fileLoader)
		String line = fileLoader.ReadLine();
		int colon = line.IndexOf(':');
			if (colon == -1) throw new Exception("Invalid line: " + line);
		return line.Substring(colon + 1).Trim();
	End

	'<summary>Returns the number of tuple values read (1, 2 or 4).</summary>
	Function int readTuple (TextReader fileLoader, String[] tuple)
		String line = fileLoader.ReadLine();
		int colon = line.IndexOf(':');
			if (colon == -1) throw new Exception("Invalid line: " + line);
		int i = 0, lastMatch = colon + 1;
		for (; i < 3; i++)
			int comma = line.IndexOf(',', lastMatch);
				if (comma == -1) break;
			tuple[i] = line.Substring(lastMatch, comma - lastMatch).Trim();
			lastMatch = comma + 1;
			}
			tuple[i] = line.Substring(lastMatch).Trim();
			return i + 1;
		End

	Method void FlipV ()
		for (int i = 0, n = regions.Count; i < n; i++)
			SpineAtlasRegion region = regions[i];
			region.v = 1 - region.v;
			region.v2 = 1 - region.v2;
			}
		End

		'<summary>Returns the first region found with the specified name. This method uses string comparison to find the region, so the result
		'should be cached rather than calling this method multiple times.</summary>
	'<returns>The region, or null.</returns>
	Method SpineAtlasRegion FindRegion (String name)
		for (int i = 0, n = regions.Count; i < n; i++)
			if (regions[i].name == name) return regions[i];
			return null;
		End

	Method void Dispose ()
		if (textureLoader == null) return;
		for (int i = 0, n = pages.Count; i < n; i++)
			textureLoader.Unload(pages[i].rendererObject);
		End
	End

Class SpineFormat
	Alpha,
		Intensity,
		LuminanceAlpha,
		RGB565,
		RGBA4444,
		RGB888,
		RGBA8888
End

Class SpineTextureFilter
	Nearest,
		Linear,
		MipMap,
		MipMapNearestNearest,
		MipMapLinearNearest,
		MipMapNearestLinear,
		MipMapLinearLinear
End

Class SpineTextureWrap
	MirroredRepeat,
		ClampToEdge,
		Repeat
End
#end