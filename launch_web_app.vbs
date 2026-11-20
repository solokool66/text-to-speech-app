Set oShell = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")

Function IsServerRunning()
    Dim oHttp
    IsServerRunning = False
    On Error Resume Next
    Set oHttp = CreateObject("MSXML2.ServerXMLHTTP.6.0")
    oHttp.open "GET", "http://localhost:5050/health", False
    oHttp.send
    If Err.Number = 0 Then
        If oHttp.status = 200 Then
            IsServerRunning = True
        End If
    End If
    Err.Clear
    On Error Goto 0
End Function

If Not IsServerRunning() Then
    oShell.CurrentDirectory = "C:\MY DEV\text-speech"
    oShell.Run """C:\MY DEV\text-speech\tts_server.exe""", 0, False
    
    ' Poll health check for up to 6 seconds until server is ready
    For i = 1 To 30
        WScript.Sleep 200
        If IsServerRunning() Then Exit For
    Next
End If

chromePath = "C:\Program Files\Google\Chrome\Application\chrome.exe"
edgePath = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"

If fso.FileExists(chromePath) Then
    oShell.Run """" & chromePath & """ --app=http://localhost:5050"
ElseIf fso.FileExists(edgePath) Then
    oShell.Run """" & edgePath & """ --app=http://localhost:5050"
Else
    oShell.Run "http://localhost:5050"
End If

