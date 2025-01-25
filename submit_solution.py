import socket
import argparse
import sys
import os

def parse_tests(tests_file_path):
    """
    Парсит файл с тестами и возвращает список тестов.
    Каждый тест — это словарь с 'input' и 'output'.
    """
    tests = []
    current_test = {}
    with open(tests_file_path, 'r', encoding='utf-8') as f:
        for line in f:
            line = line.strip()
            if line.startswith('INPUT:'):
                current_test['input'] = line[len('INPUT:'):].strip()
            elif line.startswith('OUTPUT:'):
                current_test['output'] = line[len('OUTPUT:'):].strip()
                if 'input' in current_test:
                    tests.append(current_test)
                    current_test = {}
    return tests

def build_request(language, command, tests, solution_code):
    """
    Формирует запрос в формате, ожидаемом сервером.
    """
    request_lines = []
    request_lines.append(f"LANGUAGE: {language}")
    request_lines.append(f"COMMAND: {command}")
    request_lines.append("TEST_START")
    for test in tests:
        request_lines.append(f"INPUT:{test['input']}")
        request_lines.append(f"OUTPUT:{test['output']}")
    request_lines.append("TEST_END")
    request_lines.append("CODE_START")
    request_lines.append(solution_code)
    request_lines.append("CODE_END")
    request_str = "\n".join(request_lines) + "\n"
    return request_str

def send_request(host, port, request):
    """
    Устанавливает TCP-соединение с сервером, отправляет запрос и получает ответ.
    """
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
        try:
            sock.connect((host, port))
        except ConnectionRefusedError:
            print(f"Не удалось подключиться к серверу на {host}:{port}", file=sys.stderr)
            sys.exit(1)
        
        # Отправляем запрос
        sock.sendall(request.encode('utf-8'))
        
        # Получаем ответ
        response = ""
        while True:
            data = sock.recv(4096)
            if not data:
                break
            response += data.decode('utf-8')
        
        return response

def extract_result(response):
    """
    Извлекает результаты между RESULT_START и RESULT_END.
    """
    start_marker = "RESULT_START"
    end_marker = "RESULT_END"
    start_idx = response.find(start_marker)
    end_idx = response.find(end_marker)
    if start_idx == -1 or end_idx == -1:
        return "Не удалось найти результаты в ответе сервера."
    # Извлекаем содержимое между маркерами
    result = response[start_idx + len(start_marker):end_idx].strip()
    return result

def main():
    parser = argparse.ArgumentParser(description="Отправка решения и тестов на сервер для проверки.")
    parser.add_argument('solution_file', help="Путь к файлу с решением (например, solution.py)")
    parser.add_argument('tests_file', help="Путь к файлу с тестами (например, tests.txt)")
    parser.add_argument('--host', default='localhost', help="Адрес сервера (по умолчанию: localhost)")
    parser.add_argument('--port', type=int, default=4000, help="Порт сервера (по умолчанию: 4000)")
    
    args = parser.parse_args()
    
    # Проверяем существование файлов
    if not os.path.isfile(args.solution_file):
        print(f"Файл с решением не найден: {args.solution_file}", file=sys.stderr)
        sys.exit(1)
    if not os.path.isfile(args.tests_file):
        print(f"Файл с тестами не найден: {args.tests_file}", file=sys.stderr)
        sys.exit(1)
    
    # Читаем решение
    with open(args.solution_file, 'r', encoding='utf-8') as f:
        solution_code = f.read()
    
    # Читаем тесты
    tests = parse_tests(args.tests_file)
    if not tests:
        print("Не найдено ни одного теста в файле с тестами.", file=sys.stderr)
        sys.exit(1)
    
    # Формируем запрос
    language = "python:3.11"
    command = "python /app/solution_file.code"
    request = build_request(language, command, tests, solution_code)
    
    # Отправляем запрос и получаем ответ
    response = send_request(args.host, args.port, request)
    
    # Извлекаем и выводим результат
    result = extract_result(response)
    print("Результаты тестирования:")
    print(result)

if __name__ == "__main__":
    main()
