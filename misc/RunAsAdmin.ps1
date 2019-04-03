# Run as admin in powershell
Start-Process -FilePath "openvpn.exe" -ArgumentList "C:\Path\To\Your\config.ovpn" -verb RunAs
