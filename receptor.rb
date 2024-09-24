require 'socket'
require_relative 'crc'  # Cargar el archivo crc.rb

# Configuración del socket
puerto = '/dev/pts/2'  # Puerto para recibir el mensaje
ack_puerto = '/dev/pts/1'  # Puerto para enviar el ACK

receptor_socket = File.open(puerto, 'r')
ack_socket = File.open(ack_puerto, 'w')
generador = '10011'
Flag = 01111110
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
      puts "Marco recibido: #{marco}"

      if marco =~ /MARCO:(\d+):(.*):(\d+)/
        numero_secuencia = $1.to_i
        datos = $2
        crc_recibido = $3


        # Crear la trama para verificar el CRC
        trama_para_verificar = datos + crc_recibido

        # Calcular y verificar CRC

        if verificar_crc(trama_para_verificar, generador)

          if numero_secuencia == numero_secuencia_esperado
            puts "Trama recibida correctamente: #{datos} (Secuencia: #{numero_secuencia})"
            ack_socket.puts "ACK:#{numero_secuencia}"
            ack_socket.flush
            numero_secuencia_esperado = (numero_secuencia_esperado + 1) % 256
          else
            puts "Número de secuencia incorrecto. Esperado: #{numero_secuencia_esperado}, Recibido: #{numero_secuencia}"
          end
        else
          puts "Error detectado: CRC no coincide"
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
