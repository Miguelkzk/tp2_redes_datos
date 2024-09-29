require 'socket'
require 'timeout'
require_relative 'crc'
require_relative 'formato'

# Configuración del socket
puerto = '/dev/pts/3'
ack_puerto = '/dev/pts/4'

emisor_socket = File.open(puerto, 'w')
ack_socket = File.open(ack_puerto, 'r')

# Inicialización del número de secuencia
numero_secuencia = 0
generador = '10011'
Flag = '01111110'

def errors(mensaje)
  return mensaje if rand > 0.8 # probabilidad que se corrompa el mensaje
  bytes = mensaje.bytes
  bytes[rand(bytes.length)] ^= 0xFF
  bytes.pack('C*')
end

begin
  while true
    print "Introduce la trama a transmitir en binario (Ctrl+C para salir): "
    mensaje = gets.chomp

    unless mensaje.match?(/^[01]+$/)
      puts 'Error: La trama debe consistir en bits (0 o 1).'
      next
    end

    ack_recibido = false
    direccion = '00000001'
    control = numero_secuencia.to_s(2).rjust(8, '0')

    crc = calcular_crc(control + mensaje, generador).rjust(16, '0')
    puts("crc :#{crc}")
    marco = "#{direccion}#{control}#{mensaje}#{crc}"
    marco_con_relleno = "#{Flag}#{agregar_relleno(marco)}#{Flag}"

    while !ack_recibido
      marco_con_ruido = errors(marco_con_relleno)
      puts "Enviando marco: #{marco_con_relleno}"
      emisor_socket.puts marco_con_ruido
      emisor_socket.flush

      begin
        Timeout::timeout(2) do
          ack = ack_socket.gets&.chomp
          puts "ack recibido: #{ack}"

          if ack.nil? || ack.empty?
            puts "No se recibió ACK, retransmitiendo..."
            next
          end

          ack_sin_banderas = quitar_banderas(ack)

          if ack_sin_banderas.nil?
            puts 'ACK con formato invalido, retransmitiendo....'
            next
          end

          ack_sin_relleno = quitar_relleno(ack_sin_banderas)
          crc_calculado = calcular_crc(ack_sin_relleno, generador)
          puts "ack sin relleno: #{ack_sin_relleno}"

          if ack_sin_relleno =~ /^(........)(................)$/
            control_ack = $1
            crc_ack = $2
            puts "crc del ack: #{crc_ack}"
            puts "crc calculado: #{crc_calculado}"

            if crc_ack == crc_calculado.rjust(16, '0')
              if control_ack == numero_secuencia.to_s(2).rjust(8, '0')
                puts "ACK recibido correctamente para secuencia #{numero_secuencia}. Transmisión exitosa."
                ack_recibido = true
              else
                puts "Número de secuencia en ACK no coincide. Retransmitiendo..."
              end
            else
              puts "Error detectado: CRC no coincide"
            end
          end
        end
      rescue Timeout::Error
        puts "Tiempo de espera agotado, retransmitiendo..."
      end
    end

    # Incrementar el número de secuencia después de un ACK exitoso
    numero_secuencia = (numero_secuencia + 1) % 256
  end
rescue Interrupt
  puts "\nInterrupción detectada. Cerrando el emisor."
ensure
  emisor_socket.close
  ack_socket.close
end
