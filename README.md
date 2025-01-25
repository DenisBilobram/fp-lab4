# Лабораторная работа №4

* Студент: `Билобрам Денис Андреевич`
* Группа: `P3319`
* ИСУ: `367893`

## Содержание

1. [Требования к Разработанному ПО](#требования-к-разработанному-по)
    - [Функциональные Требования](#функциональные-требования)
    - [Нефункциональные Требования](#нефункциональные-требования)
    - [Описание Алгоритма](#описание-алгоритма)
2. [Реализация](#реализация)
    - [Структура Приложения](#структура-приложения)
    - [Основные Модули](#основные-модули)
3. [Ввод/Вывод Программы](#вводвывод-программы)
    - [Формат Входных Данных](#формат-входных-данных)
    - [Формат Выходных Данных](#формат-выходных-данных)
    - [Примеры Взаимодействия](#примеры-взаимодействия)
4. [Выводы](#выводы)
    - [Отзыв об Использованных Приёмах Программирования](#отзыв-об-использованных-приёмах-программирования)

---

## Требования к Разработанному ПО

### Функциональные Требования

1. **Приём Запросов:**
   - Приложение должно принимать запросы от клиентов через TCP-соединение на заданном порту.
   - Запросы должны содержать информацию о языке программирования, команде запуска, тестовых кейсах и коде решения.

2. **Запуск Тестов:**
   - Приложение должно запускать предоставленный код решения внутри Docker-контейнера, соответствующего указанному языку программирования.
   - Для каждого тестового кейса должно выполняться сравнение вывода решения с ожидаемым результатом.

3. **Возврат Результатов:**
   - После выполнения всех тестов приложение должно отправлять клиенту сводку результатов, включая количество пройденных тестов и детализированную информацию по каждому тесту.

4. **Логирование:**
   - Приложение должно вести подробные логи о своей работе, включая информацию о подключениях клиентов, выполнении тестов и возникновении ошибок.

### Описание Алгоритма

1. **Инициализация Серверного Сокета:**
   - Сервер запускается на указанном порту и начинает слушать входящие TCP-соединения.

2. **Приём и Парсинг Запроса:**
   - При подключении клиента сервер отправляет приветственное сообщение.
   - Сервер читает строки запроса, извлекая язык программирования, команду запуска, тестовые кейсы и код решения.

3. **Запуск Тестов:**
   - Создаётся временная директория для хранения файлов решения и ввода.
   - Для каждого тестового кейса запускается Docker-контейнер с соответствующим образом.
   - Входные данные теста передаются в стандартный ввод решения, а вывод решения сравнивается с ожидаемым результатом.

4. **Сбор и Форматирование Результатов:**
   - После выполнения всех тестов собираются результаты, включая информацию о каждом тесте (пройден/не пройден, входные данные, ожидаемый и фактический вывод).
   - Формируется сводка результатов.

5. **Отправка Результатов Клиенту:**
   - Сервер отправляет клиенту форматированные результаты тестирования.
   - Закрывает соединение с клиентом.

## Реализация

### Структура Приложения

Приложение состоит из следующих основных модулей:

1. **`DockerTestService.Server`**: Управляет TCP-сервером, принимает запросы и обрабатывает клиентов.
2. **`DockerTestService.TestRunner`**: Запускает серию тестов, используя Docker-контейнеры для выполнения кода решений.
3. **`DockerTestService.DockerRunner`**: Отвечает за взаимодействие с Docker — запуск контейнеров, монтирование директорий и выполнение команд.
4. **`DockerTestService.CLI`**: Предоставляет интерфейс командной строки для запуска приложения.
5. **`DockerTestService.Application`**: Определяет точку входа приложения и запускает супервизоры.

### Основные Модули

#### 1. `DockerTestService.Server`

**Функциональность:**

- Запускает TCP-сервер на указанном порту.
- Принимает и парсит запросы от клиентов.
- Передаёт запросы в `TestRunner` для выполнения тестов.
- Отправляет результаты обратно клиенту.

**Ключевые Функции:**

- `start_link/1`: Запускает GenServer на заданном порту.
- `init/1`: Инициализирует слушающий сокет и запускает цикл приёма подключений.
- `accept_loop/1`: Принимает входящие соединения и создаёт процессы для их обработки.
- `handle_client/1`: Обрабатывает соединение с клиентом — чтение запроса, запуск тестов, отправка результатов.
- `read_request/1`: Читает и парсит запрос от клиента.
- `read_tests_block/1`: Читает блок тестов из запроса.
- `collect_tests/2`: Сбор тестовых кейсов.
- `read_code_block/1`: Читает код решения из запроса.

#### 2. `DockerTestService.TestRunner`

**Функциональность:**

- Управляет запуском тестов для предоставленного решения.
- Для каждого тестового кейса запускает Docker-контейнер, выполняет код решения и сравнивает результаты.

**Ключевые Функции:**

- `run_tests/4`: Запускает серию тестов, управляет временными директориями и собирает результаты.
- `run_single_test/5`: Выполняет отдельный тестовый кейс, запускает Docker и сравнивает вывод.
- `format_results/1`: Форматирует результаты тестирования для отправки клиенту.
- `create_tmp_dir/0`: Создаёт уникальную временную директорию для тестов.
- `cleanup_tmp_dir/1`: Удаляет временную директорию после выполнения тестов.

#### 3. `DockerTestService.DockerRunner`

**Функциональность:**

- Обеспечивает запуск Docker-контейнеров с необходимыми параметрами.
- Монтирует локальные директории в контейнеры.
- Передаёт входные данные в стандартный ввод контейнера и собирает вывод.

**Ключевые Функции:**

- `run_in_docker/4`: Запускает Docker-контейнер, выполняет команду внутри него и возвращает вывод.
- `convert_windows_path_to_docker/1`: Преобразует пути для корректной работы Docker на Windows.

#### 4. `DockerTestService.CLI`

**Функциональность:**

- Предоставляет интерфейс командной строки для запуска приложения.
- Настраивает логирование и запускает основное приложение.

**Ключевые Функции:**

- `main/1`: Точка входа CLI, настраивает логирование, запускает приложение и поддерживает его работу.

#### 5. `DockerTestService.Application`

**Функциональность:**

- Определяет точку входа приложения.
- Запускает супервизоры и основные процессы приложения.

## Пример работы
### Client
- test/tests1
```
INPUT:1 2 3
OUTPUT:6
INPUT:4 5 6
OUTPUT:15
INPUT:10 20 30
OUTPUT:60
```
- test/solution.py
```
print(sum(map(int, input().split())))
```
- example of usage
```
PS C:\Users\denis\Documents\fp-lab4> python submit_solution.py test/solution.py test/tests1
Результаты тестирования:
Passed 3 / 3 tests.

Test #0: OK
Test #1: OK
Test #2: OK
```

### Server
```
18:55:00.270 [info] Client connected: #Port<0.15>

18:55:00.270 [debug] Received line: "LANGUAGE: python:3.11"

18:55:00.270 [debug] Received line: "COMMAND: python /app/solution_file.code"

18:55:00.270 [debug] Received line: "TEST_START"

18:55:00.270 [info] TEST_START found

18:55:00.270 [debug] Received line: "INPUT:1 2 3"

18:55:00.270 [debug] Parsed INPUT: "1 2 3"

18:55:00.270 [debug] Received line: "OUTPUT:6"

18:55:00.270 [debug] Parsed OUTPUT: "6"

18:55:00.270 [debug] Received line: "INPUT:4 5 6"

18:55:00.270 [debug] Parsed INPUT: "4 5 6"

18:55:00.270 [debug] Received line: "OUTPUT:15"

18:55:00.270 [debug] Parsed OUTPUT: "15"

18:55:00.270 [debug] Received line: "INPUT:10 20 30"

18:55:00.270 [debug] Parsed INPUT: "10 20 30"

18:55:00.270 [debug] Received line: "OUTPUT:60"

18:55:00.270 [debug] Parsed OUTPUT: "60"

18:55:00.270 [debug] Received line: "TEST_END"

18:55:00.270 [info] TEST_END found

18:55:00.270 [debug] Received line: "CODE_START"

18:55:00.270 [info] CODE_START found

18:55:00.270 [debug] Received line: "print(sum(map(int, input().split())))"

18:55:00.270 [debug] Received line: ""

18:55:00.270 [debug] Received line: "CODE_END"

18:55:00.270 [info] CODE_END found

18:55:00.270 [info] Received request: Language=python:3.11, Command=python /app/solution_file.code, Tests=3

18:55:00.270 [debug] Starting test runner for language: python:3.11

18:55:00.270 [debug] Created temp dir: C:\Users\denis\AppData\Local\Temp/docker_test_service_1737820500270, wrote solution code at C:\Users\denis\AppData\Local\Temp/docker_test_service_1737820500270/solution_file.code

18:55:00.270 [debug] Running test #0 with input: "1 2 3" and expected output: "6"

18:55:00.270 [debug] Original path: C:\Users\denis\AppData\Local\Temp/docker_test_service_1737820500270

18:55:00.270 [debug] Converted path to Docker format: /c//Users/denis/AppData/Local/Temp/docker_test_service_1737820500270

18:55:00.270 [debug] Written input to file: C:\Users\denis\AppData\Local\Temp/docker_test_service_1737820500270/input.txt

18:55:00.270 [debug] Running Docker: docker run --rm -i -v /c//Users/denis/AppData/Local/Temp/docker_test_service_1737820500270:/app -w /app python:3.11 sh -c cat /app/input.txt | python /app/solution_file.code

18:55:01.436 [debug] Docker output: "6\n"

18:55:01.436 [debug] Docker exit code: 0

18:55:01.437 [debug] Test #0 passed: true | Actual Output: "6"

18:55:01.437 [debug] Running test #1 with input: "4 5 6" and expected output: "15"

18:55:01.437 [debug] Original path: C:\Users\denis\AppData\Local\Temp/docker_test_service_1737820500270

18:55:01.437 [debug] Converted path to Docker format: /c//Users/denis/AppData/Local/Temp/docker_test_service_1737820500270

18:55:01.437 [debug] Written input to file: C:\Users\denis\AppData\Local\Temp/docker_test_service_1737820500270/input.txt

18:55:01.437 [debug] Running Docker: docker run --rm -i -v /c//Users/denis/AppData/Local/Temp/docker_test_service_1737820500270:/app -w /app python:3.11 sh -c cat /app/input.txt | python /app/solution_file.code

18:55:02.641 [debug] Docker output: "15\n"

18:55:02.641 [debug] Docker exit code: 0

18:55:02.641 [debug] Test #1 passed: true | Actual Output: "15"

18:55:02.641 [debug] Running test #2 with input: "10 20 30" and expected output: "60"

18:55:02.641 [debug] Original path: C:\Users\denis\AppData\Local\Temp/docker_test_service_1737820500270

18:55:02.641 [debug] Converted path to Docker format: /c//Users/denis/AppData/Local/Temp/docker_test_service_1737820500270

18:55:02.641 [debug] Written input to file: C:\Users\denis\AppData\Local\Temp/docker_test_service_1737820500270/input.txt

18:55:02.641 [debug] Running Docker: docker run --rm -i -v /c//Users/denis/AppData/Local/Temp/docker_test_service_1737820500270:/app -w /app python:3.11 sh -c cat /app/input.txt | python /app/solution_file.code

18:55:03.872 [debug] Docker output: "60\n"

18:55:03.872 [debug] Docker exit code: 0

18:55:03.873 [debug] Test #2 passed: true | Actual Output: "60"

18:55:03.874 [debug] Finished running tests, formatting results

18:55:03.874 [info] Client disconnected: #Port<0.15>
```