Пример для guacamole, так можно сделать с любым контейнером

Чтобы скачать Docker-образы Guacamole/guacd для использования на машине без интернета, нужно выполнить следующие шаги:

---

▎Шаг 1: Скачайте Docker-образы на машине с доступом к интернету

1. Убедитесь, что Docker установлен и настроен на вашей машине.

2. Выполните команды, чтобы загрузить образы:

# Скачиваем образ guacamole
docker pull guacamole/guacamole:latest

# Скачиваем образ guacd (Guacamole Proxy Daemon)
docker pull guacamole/guacd:latest


---

▎Шаг 2: Экспортируйте образы в файл

После загрузки образов экспортируйте их в архивы для переноса:

# Экспортируем guacamole в файл
docker save -o guacamole-latest.tar guacamole/guacamole:latest

# Экспортируем guacd в файл
docker save -o guacd-latest.tar guacamole/guacd:latest


Эти команды сохранят образы как .tar файлы (guacamole-latest.tar и guacd-latest.tar).

---

▎Шаг 3: Перенесите файлы на оффлайн-машину

Скопируйте созданные .tar файлы на машину без интернета. Сделать это можно любым удобным для вас способом, например, через USB.

---

▎Шаг 4: Загрузите образы на оффлайн-машине

На машине без интернета выполните команду загрузки образов из файлов:

# Импортируем guacamole
docker load -i guacamole-latest.tar

# Импортируем guacd
docker load -i guacd-latest.tar


После успешного выполнения команд образы будут доступны в списке (docker images).

---

▎Шаг 5: Запустите контейнеры

Теперь можно запустить контейнеры Guacamole и guacd на оффлайн-машине. Пример команды для запуска:

# Запускаем guacd (Guacamole Proxy Daemon)
docker run --name guacd -d guacamole/guacd

# Запускаем Guacamole
docker run --name guacamole -d --link guacd:guacd -e GUACD_HOSTNAME=guacd -p 8080:8080 guacamole/guacamole


- --link: Связывает контейнеры Guacamole и guacd.
- -p 8080:8080: Привязывает порт 8080 для доступа к интерфейсу Guacamole.

---

Теперь Guacamole доступен на оффлайн-машине, и вы можете использовать его через браузер, перейдя по адресу http://<IP адрес машины>:8080/guacamole.

Примечание: При необходимости можете адаптировать настройки подключения базы данных или других модулей.

#docker