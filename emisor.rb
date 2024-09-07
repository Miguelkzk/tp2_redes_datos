require 'socket'
require 'timeout'

# Explicación de la suma de verificación
def calcular_checksum(data)
  data.bytes.reduce(0) { |sum, byte| sum + byte } % 256
end

def errors(mensaje)
  return mensaje if rand > 0.20 # Probabilidad de que el mensaje no tenga errores (80% de éxito)
  bytes = mensaje.bytes
  bytes[rand(bytes.length)] ^= 0xFF # Se corrompe un byte aleatorio
  bytes.pack('C*') # Reconstituye el mensaje
end

# Configuración del socket
puerto = '/dev/pts/2'  # Puerto para el emisor
ack_puerto = '/dev/pts/3'  # Puerto para recibir el ACK

emisor_socket = File.open(puerto, 'w')
ack_socket = File.open(ack_puerto, 'r')

# Bucle infinito para enviar mensajes
begin
  while true
    print "Introduce el mensaje a transmitir (Ctrl+C para salir): "
    mensaje = gets.chomp
    checksum = calcular_checksum(mensaje)
    marco = "MARCO:#{mensaje}:#{checksum}"

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
        if ack == "ACK"
          puts "ACK recibido, transmisión exitosa."
          ack_recibido = true
        else
          puts "ACK incorrecto, retransmitiendo..."
        end
      end
    rescue Timeout::Error
      puts "Tiempo de espera agotado, retransmitiendo..."
    end until ack_recibido # Retransmitir si no se recibe el ACK

  end
rescue Interrupt
  # Permitir detener el script con Ctrl+C
  puts "\nInterrupción detectada. Cerrando el emisor."
ensure
  emisor_socket.close
  ack_socket.close
end
