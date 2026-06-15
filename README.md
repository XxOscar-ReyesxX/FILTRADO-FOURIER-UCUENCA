# FILTRADO-FOURIER-UCUENCA

![Logo UCuenca](logo_ucuenca.png)

Filtrado de señales en MATLAB usando la Transformada de Fourier

## Funcionamiento general

El proceso realizado es el siguiente:

1. Cargar una señal de audio en formato `.wav`.
2. Representar la señal en el dominio del tiempo.
3. Aplicar la Transformada de Fourier.
4. Analizar el espectro de frecuencias.
5. Eliminar componentes no deseadas mediante filtrado.
6. Reconstruir la señal usando la Transformada Inversa de Fourier.
7. Comparar el audio original con el audio filtrado.

## Imágen de la interfas gráfica

![interfaz](Interfaz_MatlabGUI.png)

### Señal original

<audio controls>
  <source src="Se%C3%B1al%20limpia.wav" type="audio/wav">
  Tu navegador no soporta el elemento de audio.
</audio>

### Señal con filtros

<audio controls>
  <source src="y(t)_pasa-altas_fc1_750Hz.wav" type="audio/wav">
  Tu navegador no soporta el elemento de audio.
</audio>

