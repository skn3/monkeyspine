'see license.txt For source licenses
Strict

Import spine.spinemojo

Class SpineMojoFileLoader Implements SpineFileLoader
	Method Load:SpineFile(path:String)
		Local file:= New SpineMojoFile
		file.Load(path)
		Return file
	End
End