# Установка Packmate
Ссылки:
https://gitlab.com/packmate/Packmate

1. Cначала был клонирован репозиторий
   ```bash
   git clone https://gitlab.com/packmate/starter.git packmate-starter
   ```
2. Далее:
	1. Изменить настройки в файле `.env` по [инструкции](https://gitlab.com/packmate/Packmate/-/blob/master/docs/SETUP.md)
	2. `sudo docker compose up -d`
	3. Начать пользоваться Packmate по [инструкции](https://gitlab.com/packmate/Packmate/-/blob/master/docs/USAGE.md)
3. Настройки были следующие:
	1. PACKMATE_LOCAL_IP=192.168.0.108 (IP hosta)
	2. Пользователь и пароль (User, verystrong)
	3. PACKMATE_INTERFACE=ens33
	   Интерфейс, который будет отслеживать packmate
# example-python
## Разворачивание
На сервер debian был установлен docker.
Проект переброшен по ssh через MobaXTerm. Можно и по другому, клонировать гит репо.
Заходим в корень проекта, запускаем контейнер. Yaml файл присутствует, используем compose. 
`docker compose up`
Сервис доступен по адресу хоста на порту 5000.
В моем случае `192.168.0.108:5000` (debian в режиме bridge)
## Первичный осмотр
```python
from flask import request, render_template_string, Flask, render_template
import sqlite3

app = Flask('Birthdays')

@app.get("/")
def hello():
    return render_template("index.html")

@app.route("/search")
def search():
    value = request.args.get("value")
    if value is not None:
        con = sqlite3.connect("tutorial.db")
        cur = con.cursor()
        cur.execute("select * from birthdays where name like '%" + value + "%'")
        data = cur.fetchall()
        con.close()
        if len(data) > 0:
            a = ''            
            for i in data:
                a += "<p>date: "+ i[1] + ", name: " + i[0]+"</p>"
            app.logger.info(a)
            return render_template_string(a)
    return render_template("search.html")

@app.route("/add")
def add():
    name = request.args.get("name")
    date = request.args.get("date")
    if name is not None and date is not None:
        con = sqlite3.connect("tutorial.db")
        cur = con.cursor()
        cur.execute(f"insert into birthdays(name,date) values('{name}', '{date}')")
        con.commit()
        con.close()
    return render_template("add.html")

if __name__ == "__main__":
    con = sqlite3.connect("tutorial.db")
    cur = con.cursor()
    cur.execute("create table if not exists birthdays(name,date)")
    con.commit()
    con.close()
    app.run(host='0.0.0.0', port=5000, debug=True)
```

## 1. SQL Injection
### Проблема
Изначально, бросается в глаза [[SQL-injection]].
```python
cur.execute("select * from birthdays where name like '%" + value + "%'")
cur.execute(f"insert into birthdays(name,date) values('{name}', '{date}')")
```
Однако не получиться дропнуть таблицу
SQLite имеет защиту против выполнения 2 запросов одновременно(в одной строке)
`%'; DROP TABLE birthdays`
Вывод(небольшая часть) при попытке запроса.
```html
<p class="errormsg">sqlite3.ProgrammingError: You can only execute one statement at a time.  
</p>  
</div>  
<h2 class="traceback">Traceback <em>(most recent call last)</em></h2>  
<div class="traceback">
```
Однако UNION запросы, запросы данных о других таблицах, запросы через `1 = 1` будут работать.
1. `x' UNION SELECT name,sql FROM sqlite_master --`
2. 
``
### Решение
В целом, решить достаточно просто.
Нужно параметризировать запросы, чтобы в БД сначала шла форма запроса, потом уже параметры. То есть в 2 этапа. 
```python
cur.execute("select * from birthdays where name like ?", (f"%{value}%",))
cur.execute("insert into birthdays(name, date) values(?, ?)", (name, date))
```
## 2. SSTI
### Проблема
Проходит SSTI, при добавлении в таблицу, в поле имени вводим тестовый шаблон {{7 * 7}} -> видим 49 на выходе.
Можно попробовать добавить конфиг
`/add?name={{config}}&date=2020-01-01`
```html
<p>date: 2020-01-01, name: &lt;Config {&#39;DEBUG&#39;: True, &#39;TESTING&#39;: False, &#39;PROPAGATE_EXCEPTIONS&#39;: None, &#39;SECRET_KEY&#39;: None, &#39;SECRET_KEY_FALLBACKS&#39;: None, &#39;PERMANENT_SESSION_LIFETIME&#39;: datetime.timedelta(days=31), &#39;USE_X_SENDFILE&#39;: False, &#39;TRUSTED_HOSTS&#39;: None, &#39;SERVER_NAME&#39;: None, &#39;APPLICATION_ROOT&#39;: &#39;/&#39;, &#39;SESSION_COOKIE_NAME&#39;: &#39;session&#39;, &#39;SESSION_COOKIE_DOMAIN&#39;: None, &#39;SESSION_COOKIE_PATH&#39;: None, &#39;SESSION_COOKIE_HTTPONLY&#39;: True, &#39;SESSION_COOKIE_SECURE&#39;: False, &#39;SESSION_COOKIE_PARTITIONED&#39;: False, &#39;SESSION_COOKIE_SAMESITE&#39;: None, &#39;SESSION_REFRESH_EACH_REQUEST&#39;: True, &#39;MAX_CONTENT_LENGTH&#39;: None, &#39;MAX_FORM_MEMORY_SIZE&#39;: 500000, &#39;MAX_FORM_PARTS&#39;: 1000, &#39;SEND_FILE_MAX_AGE_DEFAULT&#39;: None, &#39;TRAP_BAD_REQUEST_ERRORS&#39;: None, &#39;TRAP_HTTP_EXCEPTIONS&#39;: False, &#39;EXPLAIN_TEMPLATE_LOADING&#39;: False, &#39;PREFERRED_URL_SCHEME&#39;: &#39;http&#39;, &#39;TEMPLATES_AUTO_RELOAD&#39;: None, &#39;MAX_COOKIE_SIZE&#39;: 4093, &#39;PROVIDE_AUTOMATIC_OPTIONS&#39;: True}&gt;</p>
```

### Решение 
Убрать шаблон в отдельный файл. Шаблонизатор будет экранировать сам, либо экранировать вручную.
1 Вариант
Используем `return render_template("result.html", results=data)`
И создаем новый шаблон 
```html
<!DOCTYPE html>
<html>
<body>
	{% for row in results %}
		<p>date: {{ row[1] }}, name: {{row[0]}}</p>
	{% endfor $}
</body>
</html>
```

## 3. XSS
XSS также детектируется sqlite и проэксплуатировать эту уязвимость нельзя, но после решения проблем с SSTI, XSS также экранируется и уже не работает.

# example-php
## Первичный осмотр
![[{671BEE7F-2E62-47CE-9A67-DA81C74A0D94}.png|500]]
Форма с выводом ping. Намекает на [[RCE]].
Тестируем сразу.
![[{139CDBE6-6D22-41CD-9A25-37A7B17BEF3A}.png|500]]
## 1. RCE
В Packmate ответы фиксируются в зашифрованном виде.
Запрос:
```html
GET /ping.php?ip=ya.ru && ls -a HTTP/1.1  
Host: 192.168.0.108:4000  
Upgrade-Insecure-Requests: 1  
User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36  
Accept: text/html,application/xhtml xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7  
Referer: http://192.168.0.108:4000/ping.php  
Accept-Encoding: gzip, deflate, br  
Accept-Language: ru-RU,ru;q=0.9,en-US;q=0.8,en;q=0.7  
Cookie: JSESSIONID=EDD6979D054A400CC8D5AE98F1F403CA  
Connection: keep-alive
```
Ответ:
```html
HTTP/1.1 200 OK  
Date: Mon, 02 Feb 2026 12:44:54 GMT  
Server: Apache/2.4.66 (Debian)  
X-Powered-By: PHP/8.2.30  
Vary: Accept-Encoding  
Content-Encoding: gzip  
Content-Length: 1303  
Keep-Alive: timeout=5, max=100  
Connection: Keep-Alive  
Content-Type: text/html; charset=UTF-8  
  
��W�n�6����TtM�H�/�ű�cm�O`�aZ�,�����/tO�W��uϠ��)���F6:�(���\3����/ﾻ}�BG3c�^(��bj�̜�B�?3�IL$F^�� rj�����͒$���,�����?����W,d!7۹s�oЯ�O5�H+�1�6c���`��yq��p�b|��IB����p'08� ��5Ns�[p�%�=�`�� 1����S_N���d�Z��H#RY�I?eB�`cy <I�y�$�� Gt�XT�X<,!1� �hb��.B`�w�e�H���Mmu� � �Vԗ�>�����*������C�  
A��q�p�c�f {�:�@��l��Q�F���9'�����{��ݣ�X[ k�  
a���$kii��mైqp��px�v�U < �%�5gR�x���8.�/���ubD$b�{Z[˱�=  
�� ���v"�r�Iʔ�,�⤾g�S��i7�����9��Bt����j�h4ڋ�c_�5�*7�$���r�����i�и~�5�;T+��@,�>z���A�>?`���Cơ�%#�4�5O�i0/ �X&#�1JX��[p�쫫�CA�~�J��4p�fV��g�IC���p��7y�i��>tm#yJ���v8��5����o��qȖ�|܉�{:v2J9�{^հ��"��ç� �  ��;e�*�K�,�R�<��xCV�����װ�v��~����8ml �2؁��RO���\��Ȫn��]�!���,Pg�u��/�c�)��di3�Q��$�ktaiM������ᆀ;�:j��'�p�v�J�C���j_!qg�d�� \��*'����s�+Vc��̲���y�bj�:(����Y  
&���ʪ.���̟�ׯ�*'4����kj�Ԝ��Z��Ǉ�����4���(�������?Ozz����R!P�c�"�oh<�T�����^�|xqo����c��@���k�X�(�l�}���R?P$�����%��Kd�Js��Oz�UOa53Z�j"��E��ys�  
a�����s�u��hp��ӣ��1�o$������\ 8�;����GA~������u��f��ba�e�'����B��e�!�wD���ʒ�P@�Y�.��y^�A�D�G��R�����$�^�%�"u����/�vG�c�m�b��4"T�$bط�05Ԋ(������Lɮ'5�{5�-Sq}����1  
9 �斧Y�޳o'�9����I.+#����� TQ����,�)Ko
```
Однако в ответах burp suite запросах все открыто.
```html
<pre>
PING ya.ru (77.88.55.242) 56(84) bytes of data.
64 bytes from ya.ru (77.88.55.242): icmp_seq=1 ttl=55 time=15.8 ms

--- ya.ru ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 15.805/15.805/15.805/0.000 ms
.
..
Dockerfile
download.php
files
files.php
index.php
ping.php
</pre>
```
### Исправление
1. Простое
```php
<body>
    <div class="container">
        <h1>ping</h1>
        <form method="GET">
            <label for="ip">IP-адрес или домен</label>
            <input type="text" name="ip" id="ip" placeholder="Пример: 8.8.8.8 или google.com"
                value="<?= htmlspecialchars($_GET['ip'] ?? '') ?>">
            <button type="submit">Пинг</button>
        </form>

        <?php if (isset($_GET['ip']) && $_GET['ip'] !== ''): ?>
            <pre>
                <?php
                $ip = $_GET['ip'];
                # easy way fix CMDi
                $bad_sym = [";", "|", "&&", " "];
                $safe_ip = str_replace($bad_sym, "", $ip);
                echo shell_exec("ping -c 1 $safe_ip");
                ?>
            </pre>
        <?php endif; ?>

        <div class="nav">
            <a href="ping.php">ping</a>
            <a href="files.php">files</a>
        </div>
    </div>
</body>
```
2. Посложнее
```php
<!-- Fixed version -->
		<?php if (isset($_GET['ip']) && $_GET['ip'] !== ''): ?>
            <?php
                $ip = $_GET['ip'];
				#Экранируем
				$safe_ip = escapeshellarg($ip);
				$output = shell_exec("ping -c 1 $safe_ip");
				
				#Доп проверка на наличие + вывод
				if ($output) {
					echo '<pre>' . htmlspecialchars($output) . '</pre>';
				} else {
					echo 'Sorry, problems';
				}
                
            ?>
        <?php endif; ?>
```

## 2. Path traversal
`GET /download.php?file=../../../../etc/passwd HTTP/1.1`
```http
HTTP/1.1 200 OK
Date: Tue, 10 Feb 2026 23:14:56 GMT
Server: Apache/2.4.66 (Debian)
X-Powered-By: PHP/8.2.30
Content-Description: File Transfer
Content-Disposition: attachment; filename="passwd"
Expires: 0
Cache-Control: must-revalidate
Pragma: public
Content-Length: 839
Keep-Alive: timeout=5, max=100
Connection: Keep-Alive
Content-Type: application/octet-stream

root:x:0:0:root:/root:/bin/bash
daemon:x:1:1:daemon:/usr/sbin:/usr/sbin/nologin
bin:x:2:2:bin:/bin:/usr/sbin/nologin
sys:x:3:3:sys:/dev:/usr/sbin/nologin
sync:x:4:65534:sync:/bin:/bin/sync
games:x:5:60:games:/usr/games:/usr/sbin/nologin
man:x:6:12:man:/var/cache/man:/usr/sbin/nologin
lp:x:7:7:lp:/var/spool/lpd:/usr/sbin/nologin
mail:x:8:8:mail:/var/mail:/usr/sbin/nologin
news:x:9:9:news:/var/spool/news:/usr/sbin/nologin
uucp:x:10:10:uucp:/var/spool/uucp:/usr/sbin/nologin
proxy:x:13:13:proxy:/bin:/usr/sbin/nologin
www-data:x:33:33:www-data:/var/www:/usr/sbin/nologin
backup:x:34:34:backup:/var/backups:/usr/sbin/nologin
list:x:38:38:Mailing List Manager:/var/list:/usr/sbin/nologin
irc:x:39:39:ircd:/run/ircd:/usr/sbin/nologin
_apt:x:42:65534::/nonexistent:/usr/sbin/nologin
nobody:x:65534:65534:nobody:/nonexistent:/usr/sbin/nologin
```
### Fix
```php
<?php
#easy fix path traverse
$f = $_GET['file'];
$f = str_replace("..", "", $f);

$filePath = '/var/www/html/files/' . $f;

if (file_exists($filePath)) {
    $fileName = basename($filePath);
    $fileSize = filesize($filePath);
    
    header('Content-Description: File Transfer');
    header('Content-Type: application/octet-stream'); 
    header('Content-Disposition: attachment; filename="' . $fileName . '"');
    header('Expires: 0');
    header('Cache-Control: must-revalidate');
    header('Pragma: public');
    header('Content-Length: ' . $fileSize);

    $file = fopen($filePath, 'rb');
    while (!feof($file)) {
        print fread($file, 8192);
        flush();
    }
    fclose($file);
    exit;
} else {
    header("HTTP/1.0 404 Not Found");
    echo "Error: File not found.";
}
?>
```
Response:
```http
HTTP/1.0 404 Not Found
Date: Tue, 10 Feb 2026 23:18:48 GMT
Server: Apache/2.4.66 (Debian)
X-Powered-By: PHP/8.2.30
Content-Length: 22
Connection: close
Content-Type: text/html; charset=UTF-8

Error: File not found.
```
Fix посложнее:
```php
<?php

// 1. Validation
if (!isset($_GET['file'])) || empty ($_GET['file']) {
	header("HTTP/1 400 Bad Request");
	echo "Error: File parameter required.";
	exit;
}

$requestedFile = $_GET['file'];

// 2. Проверка на опасные символы и path traversal
if (preg_match('/\.\./', $requestedFile) || preg_match('/^\//', $requestedFile)) {
    header("HTTP/1.0 400 Bad Request");
    echo "Error: Invalid file name.";
    exit;
}

// 3. Построение безопасного пути
$baseDir = realpath('/var/www/html/files/');
$filePath = realpath($baseDir . DIRECTORY_SEPARATOR . $requestedFile);

// 4. Проверка, что файл находится внутри разрешенной папки
if ($filePath === false || strpos($filePath, $baseDir) !== 0) {
    header("HTTP/1.0 404 Not Found");
    echo "Error: File not found or access denied.";
    exit;
}

// 5. Проверка существования и что это файл (не папка)
if (!file_exists($filePath) || !is_file($filePath)) {
    header("HTTP/1.0 404 Not Found");
    echo "Error: File not found.";
    exit;
}


// 6. Отправка
$fileName = basename($filePath);
$fileSize = filesize($filePath);
    
header('Content-Description: File Transfer');
header('Content-Type: application/octet-stream'); 
header('Content-Disposition: attachment; filename="' . $fileName . '"');
header('Expires: 0');
header('Cache-Control: must-revalidate');
header('Pragma: public');
header('Content-Length: ' . $fileSize);

$file = fopen($filePath, 'rb');
if ($file) {
	while (!feof($file)) {
		echo fread ($file, 8192);
		flush();
	}
	fclose($file);
}
exit;
?>
```