GetNumberOfLines(Filename) {	
	FileRead File, %Filename%
	StrReplace(File, "`n", "`n", Count)
	return Count
}