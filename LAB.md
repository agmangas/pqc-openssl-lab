# Laboratorio: TLS híbrido con PQC

El objetivo de este laboratorio es comprobar, con las manos, que la criptografía post-cuántica ya se puede negociar en TLS 1.3. No vamos a montar una web ni a capturar tráfico: nos basta con dos handshakes en local, hechos con la propia imagen del repositorio, uno clásico y otro híbrido con `X25519MLKEM768`.

Esto puede ser útil para fijar tres ideas que suelen costar al principio:

* PQC no reemplaza TLS entero. Actúa en piezas concretas del handshake.
* La aplicación no se toca. Lo que cambia es el grupo de intercambio de claves que se negocia por debajo.
* El coste operativo no desaparece: aparece en bytes, en compatibilidad y en las pruebas que toca hacer antes de desplegar.

Si al cerrar el ejercicio puedes explicar esas tres ideas con tus propias palabras, el laboratorio ha cumplido.

## Arrancar el entorno

Lo primero es levantar el contenedor de forma interactiva:

```
docker run --rm -it ghcr.io/agmangas/pqc-openssl-lab:2026-06
```

Al arrancar caemos en un menú con tres demos y una salida:

```
PQC OpenSSL Lab
================
1. Ver capacidades PQC de OpenSSL
2. Comparar TLS clásico vs TLS híbrido PQC
3. Comparar tamaños de firmas
4. Salir

Elige una opción [1-4]:
```

> Si Docker no está disponible en clase, usa la salida que comparta el profesor. Lo importante es leer qué cambia en pantalla, no memorizar comandos.

Vamos a recorrer las tres demos en orden.

## Parte 1: qué soporta OpenSSL

La opción `1` pregunta a OpenSSL qué algoritmos tiene disponibles. En OpenSSL 3.5.x deberían aparecer tres familias post-cuánticas:

| Algoritmo | Para qué sirve                                                      | Nota                                |
| --------- | ------------------------------------------------------------------- | ----------------------------------- |
| `ML-KEM`  | Encapsulación de claves; en TLS participa en el acuerdo de secretos | Es un KEM, no una firma             |
| `ML-DSA`  | Firmas basadas en retículos                                         | Firma de tamaño moderado            |
| `SLH-DSA` | Firmas basadas en hashes                                            | En la práctica, las más voluminosas |

Que estos nombres aparezcan en la lista significa una sola cosa: que el runtime criptográfico ya los conoce. Conviene pararse aquí antes de seguir.

> **Pregunta de control.** Si `ML-KEM` aparece en la lista, ¿quiere decir que todo el tráfico HTTP va cifrado con ML-KEM?

No. `ML-KEM` interviene en el handshake para acordar claves. El tráfico de aplicación sigue protegido con los cifrados simétricos de siempre (`AES-GCM`, `ChaCha20-Poly1305`…).

## Parte 2: el mismo TLS, distinto intercambio de claves

La opción `2` abre dos conexiones TLS 1.3 en local. El truco del ejercicio es que casi todo se mantiene fijo entre las dos —el certificado, la versión de TLS, el cipher suite de datos— y solo cambiamos el grupo de intercambio de claves:

| Modo        | Grupo TLS        | Qué representa                       |
| ----------- | ---------------- | ------------------------------------ |
| Clásico     | `X25519`         | Curva elíptica (intercambio moderno) |
| Híbrido PQC | `X25519MLKEM768` | X25519 combinado con ML-KEM-768      |

En ambos casos deberías ver TLS 1.3 y un cipher de datos habitual. El detalle en el que hay que fijarse es el grupo negociado. En el caso híbrido aparece así:

```
Grupo TLS negociado:       Negotiated TLS1.3 group: X25519MLKEM768
```

La demo también estima el tamaño del `ClientHello`. En un OpenSSL 3.5/3.6 local, el `ClientHello` híbrido suele ser bastante más grande que el clásico. No es un veredicto de calidad: simplemente hay más material criptográfico viajando en el handshake.

> **Pregunta de control.** El cipher de datos es el mismo en los dos casos. Entonces, ¿qué ha cambiado realmente?

Ha cambiado cómo se deriva el secreto inicial. La aplicación y el cifrado simétrico pueden quedarse exactamente igual.

## Parte 3: firmas y tamaños

La opción `3` firma el mismo mensaje con tres algoritmos y compara longitudes de la clave pública y de la firma. La salida tiene esta forma:

```
Tipo                   Algoritmo                   Pública        Firma
----                   ---------                   -------        -----
Clásica moderna        ED25519                          ...           64
PQC retículos          ML-DSA-65                        ...         3309
PQC hashes             SLH-DSA-SHA2-128s                ...         7856
```

| Algoritmo           | Tipo                      | Qué verás      |
| ------------------- | ------------------------- | -------------- |
| `Ed25519`           | Clásica                   | Firma pequeña  |
| `ML-DSA-65`         | Post-cuántica (retículos) | Bastante mayor |
| `SLH-DSA-SHA2-128s` | Post-cuántica (hashes)    | Aún mayor      |

Los bytes exactos pueden variar entre máquinas, pero el patrón que importa no cambia: las firmas PQC viven en el rango de los kilobytes, no en el de las decenas de bytes.

> **Pregunta de control.** ¿Por qué importa esa diferencia de tamaño en producción?

Porque ese sobrecoste lo acaban absorbiendo los certificados, los handshakes, el almacenamiento, la MTU, los equipos antiguos y la observabilidad. No es un simple flag que se activa en la configuración.

## Debate final

Para cerrar, vale la pena discutir en grupo:

* ¿Qué tramo de TLS ha cambiado en el laboratorio y cuál se ha quedado igual?
* Entre rendimiento, compatibilidad y operación, ¿dónde duele primero?
* ¿Qué inventario tendría que hacer tu organización antes de activar PQC?
* ¿Por qué hablamos de *crypto agility* y no solo de «activar PQC»?

## Cierre

PQC ya está en OpenSSL 3.5 y en otros componentes que despliegas hoy. El primer impacto suele notarse en el handshake, tanto en el KEM como en las firmas. La aplicación muchas veces ni se entera; las operaciones, sí. La conclusión práctica es la de siempre: mide, prueba con clientes viejos y planifica el despliegue antes de tocar producción.
