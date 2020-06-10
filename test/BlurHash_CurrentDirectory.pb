; +----------------------------+
; | BlurHash Current Directory |
; +----------------------------+
; | 2020-05-16 : Creation (PureBasic 5.72)

;-

XIncludeFile "../BlurHash.pbi"

UsePNGImageDecoder()
UsePNGImageEncoder()

UseJPEGImageDecoder()
UseJPEG2000ImageDecoder()


#OutputFileSuffix = "-BlurHash.png"

If (ExamineDirectory(0, GetCurrentDirectory(), ""))
  
  While NextDirectoryEntry(0)
    Name.s = DirectoryEntryName(0)
    
    If (Not FindString(Name, #OutputFileSuffix))
      Select (LCase(GetExtensionPart(Name)))
        Case "bmp", "png", "jpg", "jpeg"
          
          ; Try changing these, between 1 and 9, and see the results
          xComponents = #PB_Default
          yComponents = #PB_Default
          
          ; #False = encode (and decode) all pixels at the original resolution
          ; #True  = use a small intermediate size to speed up the process
          PreShrink = #True
          
          OutName.s = Name + #OutputFileSuffix
          If (BlurHashFileToFile(Name, OutName, xComponents, yComponents, #PB_Default, #PB_Default, PreShrink))
            Debug Name + "  -->  " + OutName
          Else
            Debug "Failed to BlurHash file: " + Name
          EndIf
          
      EndSelect
    EndIf
    
  Wend
  
  FinishDirectory(0)
Else
  Debug "Could not examine directory: " + GetCurrentDirectory()
EndIf

;-
