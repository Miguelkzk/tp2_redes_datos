# Función para realizar la división binaria módulo 2
def division_modulo_2(bits, generador)
  bits = bits.dup  # se duplica para no modificar el original
  generador_length = generador.length
  # Realizar la división binaria (XOR) hasta que el tamaño de bits sea menor que el generador
  while bits.length >= generador_length
    if bits[0] == '1'
      (0...generador_length).each do |i|
        bits[i] = (bits[i].to_i ^ generador[i].to_i).to_s  # XOR bit a bit
      end
    end
    bits = bits[1..-1]  # Desplazar a la izquierda
  end

  bits  # Retorna el residuo de la división
end

# Función para calcular el CRC
def calcular_crc(trama, generador)
  r = generador.length - 1  # Grado del polinomio generador
  trama_con_zeros = trama + '0' * r  # Anexar r ceros

  # Dividir la trama con los ceros entre el generador
  residuo = division_modulo_2(trama_con_zeros, generador)

  # El residuo es la suma de verificación (CRC)
  puts "Residuo calculado: #{residuo}"  # Depuración
  residuo.rjust(r, '0')  # Asegúrate de que tenga r bits
end

# Función para verificar el CRC en el receptor
def verificar_crc(trama_con_crc, generador)
  residuo = division_modulo_2(trama_con_crc, generador)
  puts ("residuo calculado: #{residuo}")
  residuo == '0' * (generador.length - 1)  # Verificar si el residuo es cero
end
