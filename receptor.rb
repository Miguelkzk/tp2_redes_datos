require 'socket'

def calcular_checksum(data)
  data.bytes.reduce(0) { |sum, byte| sum + byte } % 256
end

# Configuración del socket
puerto = '/dev/pts/4'  # Puerto virtual asignado por socat para el receptor
receptor_socket = File.open(puerto, 'r')

# Forzar la codificación a ASCII-8BIT para manejar cualquier secuencia de bytes
receptor_socket.set_encoding('ASCII-8BIT')

# Esperar y procesar mensajes continuamente
begin
  while true
    marco = receptor_socket.gets&.chomp
    if marco.nil? || marco.empty?
      sleep(0.1)
    else
      puts "Marco recibido: #{marco}"

      if marco =~ /MARCO:(.*):(\d+)/
        datos = $1
        checksum_recibido = $2.to_i
        checksum_calculado = calcular_checksum(datos)

        # Verificar el checksum
        if checksum_calculado == checksum_recibido
          puts "Marco recibido correctamente: #{datos}"
        else
          puts "Error detectado: checksum no coincide"
        end
      else
        puts "Formato de marco inválido"
      end
    end
  end
rescue Interrupt
  puts "\nInterrupción detectada. Cerrando el receptor."
ensure
  receptor_socket.close
end
