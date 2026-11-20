Set oShell = CreateObject("WScript.Shell")

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
End If

