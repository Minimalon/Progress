#!/usr/bin/env python3.4

import os, re
import zipfile
import json


def get_error_logs(days):
    result_error = []
    count = 1
    while count <= days:
        if count == 1:
            with open('/linuxcash/logs/current/terminal.log', 'r', encoding='utf-8', errors='ignore') as terminal:
                error_start = [line.split("ERROR")[1].strip() for line in terminal.readlines() if
                               re.search('ERROR', line)]
                result_error += error_start
        elif count > 1:
            os.chdir('/linuxcash/logs/archive/logs')
            zip_files = [ zipdir for zipdir in os.listdir('.') if re.search(r'.*\.zip', zipdir)]
            zip_files.sort()
            try:
                with zipfile.ZipFile(zip_files[-count + 1], 'r') as archive:
                    print(zip_files[-count + 1])
                    error_start = [line.decode('UTF-8').split("ERROR")[1].strip() for line in
                                   archive.read("terminal.log").split(b"\n") if
                                   re.search("ERROR", line.decode('UTF-8'))]
            except Exception as ex:
                continue
                print(ex)
            result_error += error_start
        count += 1
    return result_error


def get_unique_errors(logs):
    result = []
    for line in logs:
        line = regex_clear_log(line)
        result.append(line)
    return list(set(result))


def regex_clear_log(text):
    if re.search(r'\([A-Z0-9]{150}\)', text):
        text = re.sub(r'\([A-Z0-9]{150}\)', r'', text)
    xml_errors = r'<A>|' \
                 r'<error>|' \
                 r'<error>1: |' \
                 r'<ver>2|' \
                 r'[ ]+<\/error>|' \
                 r'<\/error>|' \
                 r'<\/A>|' \
                 r'<\/ver>'
    if re.search(xml_errors, text):
        text = re.sub(xml_errors, '', text)
    if re.search(r'1: П', text):
        text = re.sub(r'1: Проверка', 'Проверка', text)
    return text


def filter_logs():
    type_logs = list(set([line.split()[0] for line in get_error_logs(30)]))
    for type in type_logs:
        if not os.path.exists(os.path.join("/root/flags/log_errors", type)):
            os.makedirs(os.path.join("/root/flags/log_errors", type))

    for type in type_logs:  # Перебираем тип ошибки за один день
        print("day")
        list_logs = get_error_logs(1)
        unique_logs = get_unique_errors(list_logs)
        result_error_json = []
        open(os.path.join("/root/flags/log_errors/" + type + '/day.txt'), 'w')
        with open(os.path.join("/root/flags/log_errors/" + type + '/day.txt'), 'a+') as log_file:  # Логируем файл
            for error in get_unique_errors(1):
                count = 0
                for line in list_logs:
                    if error == regex_clear_log(line) and error.split("  - ")[0] == type:
                        count += 1
                if count > 0:
                    result_error_json.append({regex_clear_log(error.split("  - ")[1]): count})
            log_file.write(json.dumps(result_error_json, sort_keys=True, indent=4, ensure_ascii=False))

    for type in type_logs:  # Перебираем тип ошибки за неделю
        print("week")
        list_logs = get_error_logs(7)
        unique_logs = get_unique_errors(list_logs)
        result_error_json = []
        open(os.path.join("/root/flags/log_errors/" + type + '/week.txt'), 'w')
        with open(os.path.join("/root/flags/log_errors/" + type + '/week.txt'), 'a+') as log_file:  # Логируем файл
            for error in unique_logs:
                count = 0
                for line in list_logs:
                    if error == regex_clear_log(line) and error.split("  - ")[0] == type:
                        count += 1
                if count > 0:
                    result_error_json.append({regex_clear_log(error.split("  - ")[1]): count})
            log_file.write(json.dumps(result_error_json, sort_keys=True, indent=4, ensure_ascii=False))

        for type in type_logs:  # Перебираем тип ошибки за месяц
            print("month")
            list_logs = get_error_logs(30)
            unique_logs = get_unique_errors(list_logs)
            result_error_json = []
            open(os.path.join("/root/flags/log_errors/" + type + '/month.txt'), 'w')
            with open(os.path.join("/root/flags/log_errors/" + type + '/month.txt'), 'a+') as log_file:  # Логируем файл
                for error in unique_logs:
                    count = 0
                    for line in list_logs:
                        if error == regex_clear_log(line) and error.split("  - ")[0] == type:
                            count += 1
                    if count > 0:
                        result_error_json.append({regex_clear_log(error.split("  - ")[1]): count})
                log_file.write(json.dumps(result_error_json, sort_keys=True, indent=4, ensure_ascii=False))



def main(days):
    filter_logs()
    # with open('/root/t.txt', "w"):
    #     with open('/root/t.txt', "a") as file:
    #         for line in get_unique_errors(log):
    #             file.write(line + '\n')


if __name__ == '__main__':
    main(7)

 