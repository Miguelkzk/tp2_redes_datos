require 'socket'
require 'timeout'
require_relative 'crc'  # Cargar el archivo crc.rb

# Configuración del socket
puerto = '/dev/pts/3'  # Puerto para el emisor
ack_puerto = '/dev/pts/4'  # Puerto para recibir el ACK

emisor_socket = File.open(puerto, 'w')
ack_socket = File.open(ack_puerto, 'r')

# Inicialización del número de secuencia
numero_secuencia = 0

# Configuración del polinomio generador
generador = '10011'  # x^4 + x + 1.
Flag = '01111110'

# relleno de bits del mensaje
def agregar_relleno (mensaje)
  contador = 0
  mensaje_con_relleno = ''
  mensaje.each_char do |bit|
    mensaje_con_relleno += bit
    if bit == '1'
      contador += 1
      if contador == 5
        mensaje_con_relleno += '0'
        contador = 0
      end
    else
      contador = 0
    end
  end
  mensaje_con_relleno
end

# Introducción de errores aleatorios
def errors(mensaje)
  return mensaje if rand > 0 # Probabilidad de que el mensaje no tenga errores (80% de éxito)
  bytes = mensaje.bytes
  bytes[rand(bytes.length)] ^= 0xFF # Se corrompe un byte aleatorio
  bytes.pack('C*') # Reconstituye el mensaje
end


# Bucle infinito para enviar mensajes
begin
  while true
    print "Introduce la trama a transmitir en binario (Ctrl+C para salir): "
    mensaje = gets.chomp

    # Validar la trama
    unless mensaje.match?(/^[01]+$/)
      puts 'Error: La trama debe consistir en bits (0 o 1).'
      next
    end


    ack_recibido = false # Para controlar si se recibe el ACK

    direccion = '00000001' 
    control = numero_secuencia.to_s(2).rjust(8, '0')  # Convertir el número de secuencia a binario de 8 bits
    
    # Calcular el CRC y obtener la trama con la suma de verificación
    crc = calcular_crc(control + mensaje, generador).rjust(16, '0')
    
    marco = "#{direccion}#{control}#{mensaje}#{crc}"
    marco_con_relleno = "#{Flag}#{agregar_relleno(marco)}#{Flag}"
    begin
      # Introducir ruido en cada intento de retransmisión
      marco_con_ruido = errors(marco_con_relleno)
      # Enviar el marco con ruido
      puts "Enviando marco: #{marco_con_relleno}"
      emisor_socket.puts marco_con_ruido
      emisor_socket.flush  # Asegurarse de que el marco se envíe

      # Esperar el ACK con un temporizador
      Timeout::timeout(2) do
        ack = ack_socket.gets&.chomp # Leer el ACK

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
