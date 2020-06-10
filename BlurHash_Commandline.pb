; +----------------------+
; | BlurHash Commandline |
; +----------------------+
; | 2020-05-30 : Creation (PureBasic 5.72)

; ==============================================================================
; A quick and simple commandline program for encoding an image (from file)
; to a BlurHash string, and/or generating a decoded (blurred) output image.
; 
; Usage:
;   blurhash encode <inFile> [xComps] [yComps] [outFile]")
;   blurhash decode <hashString> <outFile> [width] [height]")
;
; Notes:
;   - This is just an example program. The commandline args are not fully
;     validated. For example, [xComps] is not checked for non-numeric chars.
;   - When passing a BlurHash string from a terminal, be careful to escape
;     control characters according to your OS (eg. escape ^ on Windows)
; ==============================================================================

;-

CompilerIf (#PB_Compiler_ExecutableFormat <> #PB_Compiler_Console)
  CompilerError "Compile to 'Console' executable format"
CompilerEndIf


;- Includes
XIncludeFile "BlurHash.pbi"


;- Codecs
UsePNGImageDecoder()
UsePNGImageEncoder()
UseJPEGImageDecoder()
UseJPEGImageEncoder()
UseJPEG2000ImageDecoder()


;- Macros

Macro SmartSaveImage(Image, File, Free)
  _BH_ImageToFile((Image), (File), (Free))
EndMacro


;- Procedures

Procedure.i ParamMatch(String.s, Expected.s)
  ProcedureReturn Bool(LCase(String) = LCase(Left(Expected, Len(String))))
EndProcedure

Procedure.i ParamInt(Index.i, DefaultValue.i = 0)
  String.s = ProgramParameter(Index)
  If (String)
    ProcedureReturn (Val(String))
  Else
    ProcedureReturn (DefaultValue)
  EndIf
EndProcedure



;-
;- Parse commandline

PrintHelp = #True
Error.s = ""

If (CountProgramParameters() > 0)
  
  
  ;- - Parse Encode parameters
  If (ParamMatch(ProgramParameter(0), "encode"))
    Decoding = #False
    InFile.s = ProgramParameter(1)
    If (InFile)
      PrintHelp = #False
      y = ParamInt(3, #PB_Default)
      If ((y <> #PB_Default) And ((y < 1) Or (y > 9)))
        Error = "yComponents must be between 1 and 9 (inclusive)"
      EndIf
      x = ParamInt(2, #PB_Default)
      If ((x <> #PB_Default) And ((x < 1) Or (x > 9)))
        Error = "xComponents must be between 1 and 9 (inclusive)"
      EndIf
      OutFile.s = ProgramParameter(4)
    EndIf
  
  ;- - Parse Decode parameters
  ElseIf (ParamMatch(ProgramParameter(0), "decode"))
    Decoding = #True
    Hash.s = ProgramParameter(1)
    If (Hash)
      OutFile.s = ProgramParameter(2)
      If (OutFile)
        PrintHelp = #False
        height = ParamInt(4, #PB_Default)
        If ((height <> #PB_Default) And (height <= 0))
          Error = "Output height must be greater than 0"
        EndIf
        width = ParamInt(3, #PB_Default)
        If ((width <> #PB_Default) And (width <= 0))
          Error = "Output width must be greater than 0"
        EndIf
      EndIf
    EndIf
  EndIf
EndIf



;-
;- Execute
If (OpenConsole())
  If (Error)
    ConsoleError("Error: " + Error)
  ElseIf (PrintHelp)
    PrintN("Usage: blurhash encode <inFile> [xComps] [yComps] [outFile]")
    PrintN("       blurhash decode <hashString> <outFile> [width] [height]")
  Else
    
    If (Decoding)
      ;- - Encode
      Print("Decoding to image... ")
      If (BlurHashDecodeToImage(Hash, 0, width, height, #True))
        PrintN("OK")
        Print("Saving to " + GetFilePart(OutFile) + "... ")
        If (SmartSaveImage(0, OutFile, #True))
          PrintN("OK")
        Else
          PrintN("failed!")
        EndIf
      Else
        PrintN("failed!")
      EndIf
    
    Else
      ;- - Decode
      Print("Loading " + GetFilePart(InFile) + "... ")
      If (LoadImage(0, InFile))
        PrintN("OK")
        Print("Encoding BlurHash... ")
        Hash = BlurHashEncodeFromImage(0, x, y, #True)
        If (Hash)
          PrintN("OK")
          PrintN("BlurHash: " + Hash)
          If (OutFile)
            Print("Decoding to " + GetFilePart(OutFile) + "... ")
            If (BlurHashDecodeToFile(Hash, OutFile, ImageWidth(0), ImageHeight(0), #True))
              PrintN("OK")
            Else
              PrintN("failed!")
            EndIf
          EndIf
        Else
          PrintN("failed!")
        EndIf
        FreeImage(0)
      Else
        PrintN("failed!")
      EndIf
    EndIf
  EndIf
  
  CloseConsole()
EndIf

;-
