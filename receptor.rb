require 'socket' #socket es una libreria para usar facilitar el uso de los puertos
# Configuración del socket
puerto = '/dev/pts/4'  # Puerto virtual asignado por socat para el receptor
receptor_socket = File.open(puerto, 'r') # la r indica que es de lectura

# Esperar y procesar mensajes continuamente
#begin es una especie de try catch en otros lenguajes
# se hace un bucle infinito para que el receptor se mantenga 'atento' esperando mensajes
begin
  while true
    marco = receptor_socket.gets.chomp
    if marco.empty?
      # Si no hay datos disponibles, esperar un poco antes de volver a intentarlo
      sleep(0.1)
    else
      puts "Marco recibido: #{marco}"

      # Verificar el marco (simplificación)
      if marco.include?("CHECKSUM")
        puts "Marco recibido correctamente"
      else
        puts "Marco corrupto"
      end
    end
  end
rescue Interrupt
  # Permitir detener el script con Ctrl+C
  puts "\nInterrupción detectada. Cerrando el receptor."
ensure
  receptor_socket.close
end
