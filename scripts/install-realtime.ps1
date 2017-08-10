$name = 'RTE-' + (pwd).path.split('\')[-1]
new-service -name $name -binaryPathName "$(pwd)\shared\realtimequalifications.exe"