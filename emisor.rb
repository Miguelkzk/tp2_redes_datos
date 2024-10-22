require 'socket'
require 'timeout'
require_relative 'crc'
require_relative 'formato'

# Configuración del socket
puerto = '/dev/pts/3'
ack_puerto = '/dev/pts/4'

emisor_socket = File.open(puerto, 'w') # Abrir el socket en modo escritura
ack_socket = File.open(ack_puerto, 'r') # Abrir el socket en modo lectura

# Inicialización del número de secuencia
numero_secuencia = 0
# Polinomio generador para el cálculo del CRC
generador = '10011' # x^4 + x + 1
# Bandera de inicio y fin de trama
Flag = '01111110'

def errors(mensaje) # funcion para introducir errores en el mensaje
  return mensaje if rand > 0.8 # probabilidad que se corrompa el mensaje
  bytes = mensaje.bytes # convertir el mensaje a bytes
  bytes[rand(bytes.length)] ^= 0xFF # en base a la probabilidad se cambia un bit
  bytes.pack('C*') # convertir los bytes a string
end

begin
  while true # ciclo infinito para no tener que reiniciar el programa
    print "Introduce la trama a transmitir en binario (Ctrl+C para salir): "
    mensaje = gets.chomp # Leer la trama a transmitir desde la consola

    unless mensaje.match?(/^[01]+$/) #sino es un mensaje de 0 y 1, muestra el error
      puts 'Error: La trama debe consistir en bits (0 o 1).'
      next
    end

    # inicializacion de variables
    ack_recibido = false
    direccion = '00000001'
    control = numero_secuencia.to_s(2).rjust(8, '0')

    crc = calcular_crc(control + mensaje, generador).rjust(16, '0') # se calcula el crc y se rellena con 0 para alcanzar 16 bits
    puts("crc :#{crc}")
    marco = "#{direccion}#{control}#{mensaje}#{crc}" # se concatena la direccion, control, mensaje y crc
    marco_con_relleno = "#{Flag}#{agregar_relleno(marco)}#{Flag}" # se agrega el relleno y las banderas

    while !ack_recibido # mientras no se reciba el ack
      marco_con_ruido = errors(marco_con_relleno) # se introduce ruido en el mensaje
      puts "Enviando marco: #{marco_con_relleno}"
      emisor_socket.puts marco_con_ruido # Enviar la trama al receptor
      emisor_socket.flush

      begin # se espera el ack
        Timeout::timeout(2) do # se espera 2 segundos
          ack = ack_socket.gets&.chomp # Leer el ACK del receptor
          puts "ack recibido: #{ack}"

          if ack.nil? || ack.empty? #si el ack es null o vacio, lanza error
            puts "No se recibió ACK, retransmitiendo..."
            next
          end

          ack_sin_banderas = quitar_banderas(ack) # se llama la funcion para quitar las banderas

          if ack_sin_banderas.nil?
            puts 'ACK con formato invalido, retransmitiendo....'
            next
          end

          ack_sin_relleno = quitar_relleno(ack_sin_banderas)
          crc_calculado = calcular_crc(ack_sin_relleno, generador) # se calcula el crc del ack
          puts "ack sin relleno: #{ack_sin_relleno}"

          if ack_sin_relleno =~ /^(........)(................)$/ # se verifica que el ack tenga el formato correcto con la expresion regular
            control_ack = $1
            crc_ack = $2
            puts "crc del ack: #{crc_ack}"
            puts "crc calculado: #{crc_calculado}"

            if crc_ack == crc_calculado.rjust(16, '0') # se verifica que el crc del ack sea igual al crc calculado
              if control_ack == numero_secuencia.to_s(2).rjust(8, '0') # se verifica que el numero de secuencia del ack sea igual al numero de secuencia del mensaje
                puts "ACK recibido correctamente para secuencia #{numero_secuencia}. Transmisión exitosa."
                ack_recibido = true
              else # si el numero de secuencia no coincide, se retransmite
                puts "Número de secuencia en ACK no coincide. Retransmitiendo..."
              end
            else # si el crc no coincide, se retransmite
              puts "Error detectado: CRC no coincide"
            end
          end
        end
      rescue Timeout::Error # si se agota el tiempo de espera, se retransmite
        puts "Tiempo de espera agotado, retransmitiendo..."
      end
    end

    # Incrementar el número de secuencia después de un ACK exitoso
    numero_secuencia = (numero_secuencia + 1) % 256
  end
rescue Interrupt # Manejar la interrupción de Ctrl+C
  puts "\nInterrupción detectada. Cerrando el emisor."
ensure # Cerrar los sockets al finalizar
  emisor_socket.close
  ack_socket.close
end
