require 'socket'
require_relative 'crc'  # Cargar el archivo crc.rb
require_relative 'formato.rb'

# Configuración del socket
puerto = '/dev/pts/4'  # Puerto para recibir el mensaje
ack_puerto = '/dev/pts/3'  # Puerto para enviar el ACK

receptor_socket = File.open(puerto, 'r')
ack_socket = File.open(ack_puerto, 'w')
generador = '10011'
Flag = '01111110'

# Forzar la codificacion a ASCII-8BIT para manejar cualquier secuencia de bytes
receptor_socket.set_encoding('ASCII-8BIT')
generador = '10011'  # x^4 + x + 1.
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

      # Quitar banderas
      marco_sin_banderas = quitar_banderas(marco)
      if marco_sin_banderas.nil?
        puts "Formato de marco inválido, faltan banderas."
        next
      end

      # Quitar bits de relleno
      marco_sin_relleno = quitar_relleno(marco_sin_banderas)

      # Verificar formato del marco
      if marco_sin_relleno =~ /^(........)(........)(.*)(................)$/
        direccion = $1
        control = $2
        datos = $3
        crc_recibido = $4
        puts "Control: #{control}"
        puts "Datos: #{datos}"
        puts "CRC: #{crc_recibido}"

        # Crear la trama para verificar el CRC
        trama_para_verificar = control + datos
        crc_calculado = calcular_crc(trama_para_verificar, generador).rjust(16, '0')
        puts("crc calculado: #{crc_calculado}")
        # Calcular y verificar CRC
        if crc_calculado == crc_recibido
          if control == numero_secuencia_esperado.to_s(2).rjust(8, '0')
            puts "Trama recibida correctamente: #{datos}"
            crc = calcular_crc(control, generador).rjust(16, '0')
            ack_enviar = control + crc
            ack_formateado = "#{Flag}#{agregar_relleno(ack_enviar)}#{Flag}"
            ack_socket.puts ack_formateado
            ack_socket.flush
            puts "enviando trama ack: #{ack_formateado}"
            numero_secuencia_esperado = (numero_secuencia_esperado + 1) % 256
          else
            puts "Número de secuencia incorrecto. Esperado"
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