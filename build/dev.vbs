''
' Dev
' (c) Tim Hall - https://github.com/timhall/Excel-REST
'
' Development steps for Excel-REST
' Run: cscript dev.vbs
'
' @author: tim.hall.engr@gmail.com
' @license: MIT (http://www.opensource.org/licenses/mit-license.php)
' ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ '
Option Explicit

Dim Args
Set Args = WScript.Arguments

Dim FSO
Set FSO = CreateObject("Scripting.FileSystemObject")

Dim Excel
Dim ExcelWasOpen
Set Excel = Nothing
Dim Workbook
Dim WorkbookWasOpen
Set Workbook = Nothing

Dim SrcFolder
Dim AuthenticatorsFolder
Dim SpecsFolder
SrcFolder = ".\src\"
AuthenticatorsFolder = ".\authenticators\"
SpecsFolder = ".\specs\"

Dim BlankWorkbookPath
Dim ExampleWorkbookPath
Dim SpecsWorkbookPath
BlankWorkbookPath = "./Excel-REST - Blank.xlsm"
ExampleWorkbookPath = "./examples/Excel-REST - Example.xlsm"
SpecsWorkbookPath = "./specs/Excel-REST - Specs.xlsm"

Dim Src
Src = Array( _
  "RestHelpers.bas", _
  "IAuthenticator.cls", _
  "RestClient.cls", _
  "RestRequest.cls", _
  "RestResponse.cls" _
)

Dim Authenticators
Authenticators = Array( _
  "EmptyAuthenticator.cls", _
  "HttpBasicAuthenticator.cls", _
  "OAuth1Authenticator.cls", _
  "OAuth2Authenticator.cls", _
  "GoogleAuthenticator.cls", _
  "TwitterAuthenticator.cls", _
  "FacebookAuthenticator.cls", _
  "DigestAuthenticator.cls" _
)

Dim Specs
Specs = Array( _
  "RestClientSpecs.bas", _
  "RestClientAsyncSpecs.bas", _
  "RestRequestSpecs.bas", _
  "RestHelpersSpecs.bas", _
  "AuthenticatorSpecs.bas", _
  "DigestAuthenticatorSpecs.bas", _
  "GoogleAuthenticatorSpecs.bas", _
  "OAuth1AuthenticatorSpecs.bas", _
  "SpecAuthenticator.cls" _
)

Main

Sub Main()
  ' On Error Resume Next

  PrintLn "Excel-REST v3.1.3 Development"
  
  ExcelWasOpen = OpenExcel(Excel)

  If Not Excel Is Nothing Then
    Development

    CloseExcel Excel, ExcelWasOpen
  ElseIf Err.Number <> 0 Then
    PrintLn vbNewLine & "ERROR: Failed to open Excel" & vbNewLine & Err.Description
  End If

  Input vbNewLine & "Done! Press any key to exit..."
End Sub

Sub Development
  PrintLn vbNewLine & _
    "Options:" & vbNewLine & _
    "- import [src/auth/specs/all] to [blank/specs/example/all/path...]" & vbNewLine & _
    "- export [src/auth/specs/all] from [blank/specs/example/all/path...]" & vbNewLine & _
    "- release"

  Dim Action
  Action = Input(vbNewLine & "What would you like to do? <")

  If Action = "" Then
    Exit Sub
  End If

  Dim Parts
  Parts = Split(Action, " ")

  ' Dim PartIndex
  ' For PartIndex = LBound(Parts) To UBound(Parts)
  '   PrintLn "Parts: " & PartIndex & ", " & Parts(PartIndex)
  ' Next

  IF (UCase(Parts(0)) = "RELEASE") Then
    Execute "import", "src", "all"
    Execute "import", "auth", "example"
    Execute "import", "auth", "specs"
    Execute "import", "specs", "specs"
  ElseIf UBound(Parts) < 3 Or (UCase(Parts(0)) <> "IMPORT" And UCase(Parts(0)) <> "EXPORT") Then
    PrintLn vbNewLine & "Error: Unrecognized action"
  Else
    If UBound(Parts) > 3 Then
      ' Combine path (in case there were spaces in name) and remove quotes
      Dim CustomPath
      Dim i
      For i = 3 To UBound(Parts)
        If CustomPath = "" Then
          CustomPath = Parts(i)
        Else
          CustomPath = CustomPath & " " & Parts(i)
        End If
      Next
      CustomPath = Replace(CustomPath, """", "")

      Execute Parts(0), Parts(1), CustomPath
    Else
      Execute Parts(0), Parts(1), Parts(3)
    End If
  End If

  If UCase(Left(Input(vbNewLine & "Would you like to do anything else? [yes/no] <"), 1)) = "Y" Then
    Development
  End If
End Sub

Sub Execute(Name, ModulesDescription, WorkbookDescription)
  ' PrintLn "Execute: " & Name & ", " & ModulesDescription & ", " & WorkbookDescription

  Dim Paths
  Select Case UCase(WorkbookDescription)
  Case "BLANK"
    Paths = Array(BlankWorkbookPath)
  Case "SPECS"
    Paths = Array(SpecsWorkbookPath)
  Case "EXAMPLE"
    Paths = Array(ExampleWorkbookPath)
  Case "ALL"
    Paths = Array(BlankWorkbookPath, SpecsWorkbookPath, ExampleWorkbookPath)
  Case Else
    Paths = Array(WorkbookDescription)
  End Select

  Dim i
  For i = LBound(Paths) To UBound(Paths)
    ' PrintLn "Open: " & FullPath(Paths(i))
    WorkbookWasOpen = OpenWorkbook(Excel, FullPath(Paths(i)), Workbook)

    If Not Workbook Is Nothing Then
      If Not VBAIsTrusted(Workbook) Then
        PrintLn vbNewLine & _
          "ERROR: In order to install Excel-REST," & vbNewLine & _
          "access to the VBA project object model needs to be trusted in Excel." & vbNewLine & vbNewLine & _
          "To enable:" & vbNewLine & _
          "Options > Trust Center > Trust Center Settings > Macro Settings > " & vbnewLine & _
          "Trust access to the VBA project object model"
      Else
        If UCase(Name) = "IMPORT" Then
          Import ModulesDescription, Workbook
        ElseIf UCase(Name) = "EXPORT" Then
          Export ModulesDescription, Workbook
        End If
      End If

      CloseWorkbook Workbook, WorkbookWasOpen
    ElseIf Err.Number <> 0 Then
      PrintLn vbNewLine & "ERROR: Failed to open Workbook" & vbNewLine & Err.Description
      Err.Clear
    End If
  Next
End SUb

Sub Import(ModulesDescription, Workbook)
  Dim Modules
  Dim Folder

  Select Case UCase(ModulesDescription)
  Case "SRC"
    Modules = Src
    Folder = SrcFolder
  Case "AUTH"
    Modules = Authenticators
    Folder = AuthenticatorsFolder
  Case "SPECS"
    Modules = Specs
    Folder = SpecsFolder
  Case "ALL"
    Import "src", Workbook
    Import "auth", Workbook
    Import "specs", Workbook
    Exit Sub
  Case Else
    PrintLn "ERROR: Unknown modules description, " & ModulesDescription
    Exit Sub
  End Select

  Print vbNewLine & "Importing " & ModulesDescription & " to " & Workbook.Name

  Dim i
  For i = LBound(Modules) To UBound(Modules)
    ImportModule Workbook, Folder, Modules(i)
    Print "."
  Next

  Print "Done!"
End Sub

Sub Export(ModulesDescription, Workbook)
  Dim Modules
  Dim Folder

  Select Case UCase(ModulesDescription)
  Case "SRC"
    Modules = Src
    Folder = SrcFolder
  Case "AUTH"
    Modules = Authenticators
    Folder = AuthenticatorsFolder
  Case "SPECS"
    Modules = Specs
    Folder = SpecsFolder
  Case "ALL"
    Export "src", Workbook
    Export "auth", Workbook
    Export "specs", Workbook
    Exit Sub
  Case Else
    PrintLn "ERROR: Unknown modules description, " & ModulesDescription
    Exit Sub
  End Select

  Print vbNewLine & "Exporting " & ModulesDescription & " from " & Workbook.Name

  Dim i
  Dim Module
  For i = LBound(Modules) To UBound(Modules)
    Set Module = GetModule(Workbook, RemoveExtension(Modules(i)))

    If Not Module Is Nothing Then
      Module.Export FullPath(Folder & Modules(i))
      Print "."
    End If
  Next

  Print "Done!"
End Sub

''
' Excel helpers
' ------------------------------------ '

''
' Open Workbook and return whether Workbook was already open
'
' @param {Object} Excel
' @param {String} Path
' @param {Object} Workbook object to load Workbook into
' @return {Boolean} Workbook was already open
Function OpenWorkbook(Excel, Path, ByRef Workbook)
  On Error Resume Next

  Path = FullPath(Path)
  Set Workbook = Excel.Workbooks(GetFilename(Path))

  If Workbook Is Nothing Or Err.Number <> 0 Then
    Err.Clear

    If FileExists(Path) Then
      Set Workbook = Excel.Workbooks.Open(Path)
    Else
      Path = Input(vbNewLine & _
        "Workbook not found at " & Path & vbNewLine & _
        "Would you like to try another location? [path.../cancel] <")

      If UCase(Path) <> "CANCEL" And Path <> "" Then
        OpenWorkbook = OpenWorkbook(Excel, Path, Workbook)
      End If
    End If
    OpenWorkbook = False
  Else
    OpenWorkbook = True
  End If
End Function

''
' Close Workbook and save changes 
' (keep open without saving changes if previously open)
'
' @param {Object} Workbook
' @param {Boolean} KeepWorkbookOpen
Sub CloseWorkbook(ByRef Workbook, KeepWorkbookOpen)
  If Not KeepWorkbookOpen And Not Workbook Is Nothing Then
    Workbook.Close True
  End If

  Set Workbook = Nothing
End Sub

''
' Open Excel and return whether Excel was already open
'
' @param {Object} Excel object to load Excel into
' @return {Boolean} Excel was already open
Function OpenExcel(ByRef Excel)
  On Error Resume Next

  Set Excel = GetObject(, "Excel.Application")

  If Excel Is Nothing Or Err.Number <> 0 Then
    Err.Clear

    Set Excel = CreateObject("Excel.Application")
    OpenExcel = False
  Else
    OpenExcel = True
  End If
End Function

''
' Close Excel (keep open if previously open)
'
' @param {Object} Excel
' @param {Boolean} KeepExcelOpen
Sub CloseExcel(ByRef Excel, KeepExcelOpen)
  If Not KeepExcelOpen And Not Excel Is Nothing Then
    Excel.Quit  
  End If

  Set Excel = Nothing
End Sub

''
' Check if VBA is trusted
'
' @param {Object} Workbook
' @param {Boolean}
Function VBAIsTrusted(Workbook)
  On Error Resume Next
  Dim Count
  Count = Workbook.VBProject.VBComponents.Count

  If Err.Number <> 0 Then
    Err.Clear
    VBAIsTrusted = False
  Else
    VBAIsTrusted = True
  End If
End Function

''
' Get module
'
' @param {Object} Workbook
' @param {String} Name
Function GetModule(Workbook, Name)
  Dim Module
  Set GetModule = Nothing

  For Each Module In Workbook.VBProject.VBComponents
    If Module.Name = Name Then
      Set GetModule = Module
      Exit Function
    End If
  Next
End Function

''
' Import module
'
' @param {Object} Workbook
' @param {String} Folder
' @param {String} Filename
Sub ImportModule(Workbook, Folder, Filename)
  Dim Module
  If Not Workbook Is Nothing Then
    ' Check for existing and remove
    Set Module = GetModule(Workbook, RemoveExtension(Filename))
    If Not Module Is Nothing Then
      Workbook.VBProject.VBComponents.Remove Module
    End If

    ' Import module
    Workbook.VBProject.VBComponents.Import FullPath(Folder & Filename)
  End If
End Sub

''
' Get module and backup (if found)
'
' @param {Object} Workbook
' @param {String} Name
' @param {String} Prefix
Function BackupModule(Workbook, Name, Prefix)
  Dim Backup
  Dim Existing
  Set Backup = GetModule(Workbook, Name)

  If Not Backup Is Nothing Then
    ' Remove any previous backups
    Set Existing = GetModule(Workbook, Prefix & Name)
    If Not Existing Is Nothing Then
      Workbook.VBProject.VBComponents.Remove Existing
    End If

    Backup.Name = Prefix & Name
  End If

  Set BackupModule = Backup
End Function

''
' Restore module from backup (if found)
'
' @param {Object} Workbook
' @param {String} Name
' @param {String} Prefix
Sub RestoreModule(Workbook, Name, Prefix)
  Dim Backup
  Dim Module
  Set Backup = GetModule(Workbook, Prefix & Name)

  If Not Backup Is Nothing Then
    ' Find upgraded module (and remove if found)
    Set Module = GetModule(Workbook, Name)
    If Not Module Is Nothing Then
      Workbook.VBProject.VBComponents.Remove Module
    End If

    ' Restore backup
    Backup.Name = Name
  End If
End Sub

''
' Filesystem helpers
' ------------------------------------ '

Function FullPath(Path)
  FullPath = FSO.GetAbsolutePathName(Path)
End Function

Function GetFilename(Path)
  Dim Parts
  Parts = Split(Path, "\")

  GetFilename = Parts(UBound(Parts))
End Function

Function RemoveExtension(Name)
    Dim Parts
    Parts = Split(Name, ".")
    
    If UBound(Parts) > LBound(Parts) Then
        ReDim Preserve Parts(UBound(Parts) - 1)
    End If
    
    RemoveExtension = Join(Parts, ".")
End Function

Function FileExists(Path)
  FileExists = FSO.FileExists(Path)
End Function

''
' General helpers
' ------------------------------------ '

Sub Print(Message)
  WScript.StdOut.Write Message
End Sub

Sub PrintLn(Message)
  Wscript.Echo Message
End Sub

Function Input(Prompt)
  If Prompt <> "" Then
    Print Prompt & " "
  End If

  Input = WScript.StdIn.ReadLine 
End Function