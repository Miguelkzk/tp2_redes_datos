require 'socket'
require 'timeout'
require_relative 'crc'  # Cargar el archivo crc.rb

# Introducción de errores aleatorios
def errors(mensaje)
  return mensaje if rand > 0 # Probabilidad de que el mensaje no tenga errores (80% de éxito)
  bytes = mensaje.bytes
  bytes[rand(bytes.length)] ^= 0xFF # Se corrompe un byte aleatorio
  bytes.pack('C*') # Reconstituye el mensaje
end

# Configuración del socket
puerto = '/dev/pts/3'  # Puerto para el emisor
ack_puerto = '/dev/pts/4'  # Puerto para recibir el ACK

emisor_socket = File.open(puerto, 'w')
ack_socket = File.open(ack_puerto, 'r')

# Inicialización del número de secuencia
numero_secuencia = 0

# Configuración del polinomio generador
generador = '10011'

# Bucle infinito para enviar mensajes
begin
  while true
    print "Introduce el mensaje a transmitir (Ctrl+C para salir, máx. 2 caracteres): "
    mensaje = gets.chomp

    # Validar la longitud del mensaje
    unless mensaje.match?(/^[01]+$/)
      puts "Error: El mensaje debe consistir en bits (0 o 1)."
      next
    end

    # Calcular el CRC y obtener la trama con la suma de verificación
    trama_con_crc = calcular_crc(mensaje, generador)
    puts "Trama con CRC: #{trama_con_crc}"

    marco = "MARCO:#{numero_secuencia}:#{mensaje}:#{trama_con_crc}"

    ack_recibido = false # Para controlar si se recibe el ACK

    begin
      # Introducir ruido en cada intento de retransmisión
      marco_con_ruido = errors(marco)

      # Enviar el marco con ruido
      puts "Enviando marco: #{marco_con_ruido}"
      emisor_socket.puts marco_con_ruido
      emisor_socket.flush  # Asegurarse de que el marco se envíe

      # Esperar el ACK con un temporizador
      Timeout::timeout(2) do
        ack = ack_socket.gets&.chomp # Leer el ACK
        puts "ACK recibido: #{ack}"

        if ack == "ACK:#{numero_secuencia}"
          puts "ACK recibido correctamente para secuencia #{numero_secuencia}. Transmisión exitosa."
          ack_recibido = true
        else
          puts "Número de secuencia en ACK no coincide. Retransmitiendo..."
        end
      end
    rescue Timeout::Error
      puts "Tiempo de espera agotado, retransmitiendo..."
    end until ack_recibido # Retransmitir si no se recibe el ACK

    # Incrementar el número de secuencia después de un ACK exitoso
    numero_secuencia = (numero_secuencia + 1) % 256

  end
rescue Interrupt
  puts "\nInterrupción detectada. Cerrando el emisor."
ensure
  emisor_socket.close
  ack_socket.close
end
