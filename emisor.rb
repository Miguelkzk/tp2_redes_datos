# emisor.rb
require 'socket'

# Configuración del socket
puerto = '/dev/pts/3'  # Puerto virtual asignado por socat para el emisor

# Abrir el archivo del puerto en modo de escritura, por eso la 'w'
emisor_socket = File.open(puerto, 'w')

# Bucle infinito para enviar mensajes
begin
  while true
    # Solicitar al usuario que ingrese el mensaje
    print "Introduce el mensaje a transmitir (Ctrl+C para salir): "
    mensaje = gets.chomp

    # Crear el marco con el mensaje
    marco = "MARCO:#{mensaje}:CHECKSUM"

    # Enviar el marco
    puts "Enviando marco: #{marco}"
    emisor_socket.puts marco
  end
rescue Interrupt
  # Permitir detener el script con Ctrl+C
  puts "\nInterrupción detectada. Cerrando el emisor."
ensure
  emisor_socket.close
end
