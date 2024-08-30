require 'socket'

# Configuración del socket
puerto = '/dev/pts/3'  # Puerto virtual asignado por socat para el emisor
emisor_socket = File.open(puerto, 'w')

# Datos a enviar
datos = "Datos para la transmisión"
marco = "MARCO:#{datos}:CHECKSUM"

# Enviar datos
puts "Enviando marco: #{marco}"
emisor_socket.puts marco

emisor_socket.close
