require 'socket'
# pensar si se pierde el ack, ver el codigo de verificacion y ver de quien emisor es
def calcular_checksum(data)
  data.bytes.reduce(0) { |sum, byte| sum + byte } % 256
end

# Configuración del socket
puerto = '/dev/pts/3'  # Puerto para recibir el mensaje
ack_puerto = '/dev/pts/2'  # Puerto para enviar el ACK

receptor_socket = File.open(puerto, 'r')
ack_socket = File.open(ack_puerto, 'w')

# Forzar la codificación a ASCII-8BIT para manejar cualquier secuencia de bytes
receptor_socket.set_encoding('ASCII-8BIT')

# Esperar y procesar mensajes continuamente
begin
  while true
    marco = receptor_socket.gets&.chomp
    if marco.nil? || marco.empty?
      sleep(0.1)
    else
      # Ignorar los mensajes de ACK
      next if marco == "ACK"

      puts "Marco recibido: #{marco}"

      if marco =~ /MARCO:(.*):(\d+)/   # comparo el marco con una expresion regular y lo divido en 2 partes
        datos = $1   #Se almacena el mensaje
        checksum_recibido = $2.to_i   # se almacena la la suma de verificacion
        checksum_calculado = calcular_checksum(datos)

        # Verificar el checksum
        if checksum_calculado == checksum_recibido
          puts "Marco recibido correctamente: #{datos}"
          ack_socket.puts "ACK"
          ack_socket.flush
          puts "ACK enviado"
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
  ack_socket.close
end
