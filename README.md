# Trabajo práctico número 2, REDES DE DATOS
## Integrantes: 
* Juan Manuel Valdivia
* Leonardo Secotaro
* Miguel Kruzliak
* Tomás Via
* Santino Giovannini
* Lucio Malgioglio
* Luciana Maldonado
* Juan Fransisco Vazquez 
###
## Pasaos para ejecutar
### Abrir puertos
* socat -d -d pty,raw,echo=0 pty,raw,echo=0
### Ejecutar emisor en una terminal
* ruby emisor.rb
### Ejecutar receptor en una terminal
* ruby receptor.rb