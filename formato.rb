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

def quitar_banderas(mensaje)
  # Buscar la primera y la ultima aparicion de la bandera
  inicio = mensaje.index(Flag)
  fin = mensaje.rindex(Flag)
  if inicio && fin && inicio != fin
    return mensaje[inicio + Flag.length...fin] #retorna el marco sin banderas
  end
  nil # si no se encuentran banderas retorna vacio
end

def quitar_relleno(mensaje)
  contador = 0
  mensaje_sin_relleno = ''
  i = 0
  while i < mensaje.length
    mensaje_sin_relleno += mensaje[i]
    if mensaje[i] == '1'
      contador += 1
      if contador == 5
        i += 1 # salta el bit de relleno
        contador = 0
      end
    else
      contador = 0
    end
    i += 1
  end
  mensaje_sin_relleno
end