# PQC OpenSSL Lab

Una imagen Docker pequeña para observar criptografía post-cuántica funcionando dentro de OpenSSL 3.5 LTS.

Esto puede ser útil en escenarios donde queremos enseñar que la criptografía post-cuántica (**PQC**) ya no es teoría ni un experimento de laboratorio aparte, sino algo que viaja dentro de software que la gente despliega hoy. La imagen acompaña al laboratorio de la sesión `Casos de uso` de la microcredencial de computación cuántica. El objetivo no es aprender OpenSSL a fondo, sino ver con los propios ojos qué cambia en un handshake TLS cuando entra PQC y qué se queda igual.

La guía completa de aula, con preguntas y debate, está en [LAB.md](LAB.md).

## Qué hay dentro

La imagen se construye en dos etapas (ver [Dockerfile](Dockerfile)): la primera compila OpenSSL desde el código fuente y la segunda se queda solo con los binarios, de modo que la imagen final no arrastra el compilador. La versión queda fijada en OpenSSL `3.5.6`, la primera rama LTS que trae los algoritmos post-cuánticos (**ML-KEM**, **ML-DSA**, **SLH-DSA**) integrados de serie, sin proveedores externos.

## Uso

La forma normal de usar la imagen es arrancarla de forma interactiva. Al hacerlo, caemos directamente en un menú:

```
docker run --rm -it ghcr.io/agmangas/pqc-openssl-lab:2026-06
```

```
PQC OpenSSL Lab
================
1. Ver capacidades PQC de OpenSSL
2. Comparar TLS clásico vs TLS híbrido PQC
3. Comparar tamaños de firmas
4. Salir

Elige una opción [1-4]:
```

Cada entrada del menú lanza un script. Si lo prefieres, puedes saltarte el menú y ejecutar un script directamente pasándolo como argumento:

```
docker run --rm ghcr.io/agmangas/pqc-openssl-lab:2026-06 pqc-capabilities.sh
docker run --rm ghcr.io/agmangas/pqc-openssl-lab:2026-06 pqc-tls-demo.sh
docker run --rm ghcr.io/agmangas/pqc-openssl-lab:2026-06 pqc-signatures-demo.sh
```

## Las tres demos

Cada demo responde a una pregunta concreta.

| Script                   | Pregunta que responde                                              |
| ------------------------ | ------------------------------------------------------------------ |
| `pqc-capabilities.sh`    | ¿Conoce ya este OpenSSL los algoritmos post-cuánticos?             |
| `pqc-tls-demo.sh`        | ¿Qué cambia en un handshake TLS 1.3 al pasar de clásico a híbrido? |
| `pqc-signatures-demo.sh` | ¿Cuánto más grandes son las firmas post-cuánticas?                 |

### Capacidades

`pqc-capabilities.sh` pregunta a OpenSSL qué algoritmos tiene a mano. Lista los KEM relacionados con ML-KEM y las firmas relacionadas con ML-DSA y SLH-DSA. Que aparezcan en la lista significa que el runtime criptográfico ya los conoce; no significa que todo tu tráfico pase a ser post-cuántico.

### TLS clásico vs. híbrido

`pqc-tls-demo.sh` levanta dos conexiones TLS 1.3 en local contra `openssl s_server`. El certificado y el cipher suite de datos se mantienen constantes entre las dos. Lo único que cambia es el grupo de intercambio de claves:

| Grupo            | Qué representa                               |
| ---------------- | -------------------------------------------- |
| `X25519`         | Curva elíptica clásica (intercambio moderno) |
| `X25519MLKEM768` | Híbrido: combina X25519 con ML-KEM-768       |

En el caso híbrido debe aparecer `X25519MLKEM768` como grupo negociado. La lectura que queremos que quede es que PQC actúa aquí en el handshake, en cómo se acuerda el secreto, no en el contenido de la aplicación.

### Tamaños de firma

`pqc-signatures-demo.sh` firma el mismo mensaje con tres algoritmos y compara el tamaño de la clave pública y de la firma:

| Tipo            | Algoritmo           |
| --------------- | ------------------- |
| Clásica moderna | `Ed25519`           |
| PQC (retículos) | `ML-DSA-65`         |
| PQC (hashes)    | `SLH-DSA-SHA2-128s` |

> Los bytes exactos pueden variar según la máquina, pero el patrón no: las firmas post-cuánticas saltan de decenas de bytes a varios kilobytes. Esa diferencia es la que luego se paga en certificados, handshakes, almacenamiento y sistemas de observabilidad.

## Build local

Si quieres construir la imagen tú mismo en lugar de tirar de la del registro:

```
docker build -t pqc-openssl-lab:local .
docker run --rm -it pqc-openssl-lab:local
```

La versión de OpenSSL se puede sobreescribir en tiempo de build con `--build-arg OPENSSL_VERSION=3.5.6`.

## Publicación

El workflow `.github/workflows/publish.yml` publica la imagen en GitHub Container Registry:

```
ghcr.io/agmangas/pqc-openssl-lab
```

Los tags docentes que esperamos encontrar ahí son:

| Tag           | Para qué sirve                     |
| ------------- | ---------------------------------- |
| `openssl-3.5` | Sigue la rama LTS                  |
| `2026-06`     | Fija la edición concreta del curso |
