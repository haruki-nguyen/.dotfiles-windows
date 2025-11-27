Set WshShell = CreateObject("WScript.Shell")
WshShell.CurrentDirectory = "C:\Users\nmdex\scoop\apps\syncthing\current"
WshShell.Run """C:\Users\nmdex\scoop\apps\syncthing\current\syncthing.exe"" --no-console", 0
