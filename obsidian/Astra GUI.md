Установка пакета fly
```shell
apt install fly-all-main
```
Загрузка ОС с GUI по умолчанию
```shell
systemctl set-default graphical.target
```
## Примечание

Посмотреть текущую конфигурацию загрузки
```shell
systemctl get-default
```
Вернуть загрузку ОС с CLI
```shell
systemctl set-default multi-user.target
```
#gui #astrass