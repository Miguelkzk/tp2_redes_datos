# emisor.rb
require 'socket'

# Explicacion de la suma de verificacion
# se toma la cadena de entrada y con el metodo reduce se hace un solo numero (que es la suma de todos los bytes
# caracteres) y se le hace modulo 256

def calcular_checksum(data)
  data.bytes.reduce(0) { |sum, byte| sum + byte } % 256
end

def errors(mensaje)
  return mensaje if rand > 0.2 # Probabilidad de un 20% de error
  bytes = mensaje.bytes # se parte el mensaje en un array de bytes
  bytes[rand(bytes.length)] ^= 0xFF # se selecciona un byte a la azar y se aplica "^= 0xFF" equivalente a XOR (inverte todos los bits)
  bytes.pack('C*') # se vuelve a armar el mensaje
end


# Configuración del socket
puerto = '/dev/pts/3'  # Puerto virtual asignado por socat para el emisor

# Abrir el archivo del puerto en modo de escritura, por eso la 'w'
emisor_socket = File.open(puerto, 'w')

# Bucle infinito para enviar mensajes
begin
  while true
    # Solicitar al usuario que ingrese el mensaje
    print "Introduce el mensaje a transmitir (Ctrl+C para salir): "
    mensaje = gets.chomp
    checksum = calcular_checksum(mensaje)
    marco = "MARCO:#{mensaje}:#{checksum}"

    # se intruduce "ruido"
    marco_con_ruido = errors(marco)
    puts "Enviando marco: #{marco_con_ruido}"
    emisor_socket.puts marco_con_ruido

  end
rescue Interrupt
  # Permitir detener el script con Ctrl+C
  puts "\nInterrupción detectada. Cerrando el emisor."
ensure
  emisor_socket.close
end
