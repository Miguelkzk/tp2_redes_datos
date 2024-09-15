require 'socket'

def calcular_checksum(data)
  data.bytes.reduce(0) { |sum, byte| sum + byte } % 256
end

# Configuración del socket
puerto = '/dev/pts/4'  # Puerto para recibir el mensaje
ack_puerto = '/dev/pts/3'  # Puerto para enviar el ACK

receptor_socket = File.open(puerto, 'r')
ack_socket = File.open(ack_puerto, 'w')

# Forzar la codificación a ASCII-8BIT para manejar cualquier secuencia de bytes
receptor_socket.set_encoding('ASCII-8BIT')

# Variable para el número de secuencia esperado
numero_secuencia_esperado = 0

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

      if marco =~ /MARCO:(\d+):(.*):(\d+)/   # comparo el marco con una expresion regular
        numero_secuencia = $1.to_i   # Se almacena el número de secuencia
        datos = $2   # Se almacena el mensaje
        checksum_recibido = $3.to_i   # Se almacena la suma de verificación
        checksum_calculado = calcular_checksum(datos)

        # Verificar el checksum
        if checksum_calculado == checksum_recibido && numero_secuencia == numero_secuencia_esperado
          puts "Marco recibido correctamente: #{datos} (Secuencia: #{numero_secuencia})"
          ack_socket.puts "ACK:#{numero_secuencia}"
          ack_socket.flush
          puts "ACK enviado"

          # Incrementar el número de secuencia esperado
          numero_secuencia_esperado = (numero_secuencia_esperado + 1) % 256
        else
          puts "Error detectado: checksum o número de secuencia no coincide"
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
