# DIV_PIPELINE
Este repositorio contiene dos implementaciones en Verilog para realizar la división de dos números positivos de `N` bits. El objetivo del proyecto es comparar el rendimiento entre una implementación sin técnicas de *pipelining* y una que sí las incorpora, evaluando la mejora en velocidad proporcionada por el uso de *pipelines*.

---

## Tabla de Contenido

- [1. Descripción General](#1-descripción-general)
- [2. Divider sin Pipeline](#2-divider-sin-pipeline)
  - [2.1 Descripción de Funcionamiento](#21-descripción-de-funcionamiento)
  - [2.2 Análisis Detallado del Código](#22-análisis-detallado-del-código)
- [3. Divider con Pipeline](#3-divider-con-pipeline)
  - [3.1 Arquitectura Pipeline](#31-arquitectura-pipeline)
  - [3.2 Descripción del Funcionamiento](#32-descripción-del-funcionamiento)
  - [3.3 Variables Internas](#33-variables-internas)
- [4. Comparación de Resultados](#4-comparación-de-resultados)

---

## 1. Descripción General

Ambas implementaciones utilizan el método clásico de división por resta sucesiva con desplazamientos, pero difieren en la estructura de ejecución:

- El divisor **no pipeline** es secuencial y se basa en una máquina de estados finitos (FSM).
- El divisor **con pipeline** está completamente *pipelined*, dividiendo el proceso de división en `N` etapas que operan en paralelo sobre diferentes datos.

---

## 2. Divider sin Pipeline

### 2.1 Descripción de Funcionamiento

Este módulo realiza la división mediante un proceso iterativo basado en una máquina de estados. El algoritmo sigue el método clásico de resta sucesiva con desplazamiento a la izquierda del dividendo. Durante `N` ciclos de reloj, el módulo va evaluando bit a bit si es posible restar el divisor del residuo parcial acumulado, y construye el cociente desplazando los bits a medida que avanza.

El flujo básico es:
- Cargar valores iniciales (dividendo y divisor).
- Evaluar bit por bit.
- Al finalizar, entregar cociente y residuo.

### 2.2 Análisis Detallado del Código

#### Definición de parámetros y puertos
```verilog
parameter N = 32
```
Define el ancho de los operandos (dividendo y divisor), así como del cociente y residuo.

#### Variables internas
```verilog
reg [N-1:0] quot_reg;        // Cociente acumulado
reg [N:0] rem_reg;           // Residuo con un bit adicional para evitar overflow
reg [N-1:0] div_reg;         // Copia del divisor
reg [N-1:0] dividend_reg;    // Copia del dividendo
reg [5:0] bit_counter;       // Contador para las iteraciones
reg [1:0] state;             // Estado actual de la máquina de estados
```

#### Máquina de estados
```verilog
localparam IDLE = 2'b00;
localparam INIT = 2'b01;
localparam CALC = 2'b10;
localparam FINISH = 2'b11;
```

- **IDLE**: Espera el inicio (`start`).
- **INIT**: Carga los operandos y resetea registros.
- **CALC**: Realiza la división bit a bit.
- **FINISH**: Transfiere el resultado a las salidas y vuelve al estado IDLE.

#### Lógica secuencial principal

```verilog
always @(posedge clk or posedge rst) begin
```
Manejo del flanco positivo del reloj y reinicio asincrónico.

##### Estado INIT
```verilog
quot_reg <= 0;
rem_reg <= 0;
div_reg <= divisor;
dividend_reg <= dividend;
bit_counter <= N;
state <= CALC;
```
Inicializa los registros antes de comenzar la operación.

##### Estado CALC
```verilog
if (bit_counter > 0) begin
    rem_reg <= {rem_reg[N-1:0], dividend_reg[N-1]};
    dividend_reg <= {dividend_reg[N-2:0], 1'b0};
```
Desplaza el dividendo y actualiza el residuo.

```verilog
if ({rem_reg[N-1:0], dividend_reg[N-1]} >= {1'b0, div_reg}) begin
    rem_reg <= {rem_reg[N-1:0], dividend_reg[N-1]} - {1'b0, div_reg};
    quot_reg <= {quot_reg[N-2:0], 1'b1};
end else begin
    quot_reg <= {quot_reg[N-2:0], 1'b0};
end
```
Verifica si se puede restar el divisor del residuo actual:
- Si es posible, actualiza el residuo restando el divisor y añade 1 al cociente.
- Si no, simplemente añade un 0 al cociente.

```verilog
bit_counter <= bit_counter - 1;
```
Reduce el contador para pasar al siguiente bit.

##### Estado FINISH
```verilog
quotient <= quot_reg;
remainder <= rem_reg[N-1:0];
done <= 1;
state <= IDLE;
```
Entrega el resultado final y vuelve a esperar un nuevo inicio.

---

## 3. Divider con Pipeline

### 3.1 Arquitectura Pipeline

Este divisor divide el proceso en `N` etapas, cada una ejecutando una operación parcial de la división. En cada etapa:

- Se calcula un nuevo residuo parcial.
- Se evalúa si se puede restar el divisor.
- Se desplaza el cociente y se agrega un bit.

Esto permite que se empiece una nueva operación de división en cada ciclo de reloj (una vez llenado el pipeline).

### 3.2 Descripción del Funcionamiento

- En el ciclo 0, los datos iniciales se cargan en la etapa 0.
- En cada ciclo, las operaciones parciales pasan a la siguiente etapa.
- Cuando los datos llegan a la etapa `N`, se obtienen `quotient` y `remainder` finales.

### 3.3 Variables Internas

- `remainder_reg[i]`: Residuo parcial en la etapa `i`.
- `divisor_reg[i]`: Divisor propagado en la etapa `i`.
- `quotient_reg[i]`: Cociente parcial acumulado.
- `dividend_reg[i]`: Registro del dividendo con bits desplazados.
- `ready_flag[i]`: Señal de habilitación de datos válidos por etapa.

---

## 4. Comparación de Resultados

| Característica                      | Sin Pipeline              | Con Pipeline             |
| ----------------------------------- | ------------------------- | ------------------------ |
| Latencia total                      | \~N ciclos                | \~N ciclos               |
| Throughput (una división por ciclo) | No                        | Sí (después del llenado) |
| Complejidad de diseño               | Baja                      | Alta                     |
| Uso de recursos                     | Bajo                      | Alto                     |
| Ideal para                          | Simplicidad, bajo consumo | Alto rendimiento         |

---

## Autores y Licencia

Trabajo realizado para la asignatura de **Sistemas Digitales**.

Licencia: MIT

