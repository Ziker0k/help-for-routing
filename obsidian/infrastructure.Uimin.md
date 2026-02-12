### Модуль A "Пуско-наладка инфраструктуры на основе ОС семейства Linux"
Оборудования и приборы:
В качестве системной ОС в организации LEFT используется Debian
В качестве системной ОС в организации RIGHT используется CentOS
Вам доступен диск CentOS-7-x86_64-Everything-1810.iso [Скачать](http://mirrors.powernet.com.ru/centos/7.6.1810/isos/x86_64/CentOS-7-x86_64-Everything-1810.iso)
Вам доступен диск debian-10.0.0-amd64-BD-1.iso [Скачать](https://cdimage.debian.org/debian-cd/current/amd64/jigdo-bd/)
Вам доступен диск debian-10.0.0-amd64-BD-2.iso [Скачать](https://cdimage.debian.org/debian-cd/current/amd64/jigdo-bd/)
Вам доступен диск debian-10.0.0-amd64-BD-3.iso [Скачать](https://cdimage.debian.org/debian-cd/current/amd64/jigdo-bd/)
Вам доступен диск debian-10.0.0-amd64-BD-4.iso [Скачать](https://cdimage.debian.org/debian-cd/current/amd64/jigdo-bd/)
Debian позволяет скачать такие файлы через jigdo [Как с ним работать?](https://www.debian.org/CD/jigdo-cd/)
Вам доступен диск Additional.iso, на котором располагаются недостающие RPM пакеты.[Скачать](https://drive.google.com/file/d/19vrJ1cyLQZViDavxpqUBhtJYPL2jTi3G/view)

Была загружена VM с pnetlab. Установлены ОС Debian и CentOS, в CentOS был выполнен сброс пароля рута, образ был сохранен и использовался в дальнейшем.


> [!NOTE] Как сбрасывать пароль в CentOS 7
> Ctrl + Alt + Del
> Выбираем OS, жмем e, видим параметры.
> Нужно поправить таким образом:
> ro -> rw
> удаляем rhgb quiet
> добавляем в конце rd.break enforcing=0
> Ctrl + x
> 
> При загрузке вводим 
> chroot /sysroot - изменяет корневой каталог, изолируя процессы в новой среде
> passwd root - чтобы сменить пароль
> touch /.autorelabel
> exit
> reboot


#### 1. Предварительная сборка лаборатории. Расстановка машин.
Создал хосты, соединил между собой по портам ethernet.
![[{89B9FC3E-3186-42F9-A2AA-628A3D6F65C0}.png]]
Для каждого хоста выделил по 1 ядру и 1024MB RAM
Пароль для CentOS - verystrong
На скачанном дистрибутиве, по видимому, существуют определенные политики безопасности, пароль P@ssw0rd не позволителен. 
Пароль для Debian - root

> [!warning]
> Пароли:
> CentOS - verystrong
> Debian - root

#### 2. Задание: выключение firewall на всех машинах

> [!NOTE] Выключение firewall CentOS
> systemctl disable --now firewalld 
> //отключаем firewalld
> vi /etc/selinux/config 
> SELINUX=disabled
> //отключаем SElinux
> reboot
> //перезагружаем
> 
> Проверка:
> systemctl status firewalld
> getenforce

> [!NOTE] Выключение firewall Debian
> systemctl disable --now apparmor
> reboot
> 
> Проверка:
> systemctl status apparmor

Порядок выполнения описан выше, вывод проверки:
![[{78E2601B-668C-47E0-9F97-7E6DD0947731}.png]]
Для более быстрой настройки в дальнейшем попробуем использовать команду замены, не заходя в vim.
![[{0A0AB828-DF49-485B-B40C-91D9E0F8128C}.png]]
Все работает, команда:
```
sed -i 's/^SELINUX=.*/SELINUX=disabled/' /etc/selinux/config

sed -i //Редактирование файла на месте
's/^SELINUX=.*/SELINUX=disabled'//Заменяет любую строку, начинающуюся с SELINUX= на SELINUX=disabled
/etc/selinux/config //Путь к файлу конфигурации
```
Не забываем перезагружать

Итоговая команда:
```
systemctl disable --now firewalld
sed -i 's/^SELINUX=.*/SELINUX=disabled/' /etc/selinux/config
reboot
```


Список CentOS машин:
- [x] R-CLI ✅ 2025-12-25
- [x] R-RTR ✅ 2025-12-25
- [x] R-FW ✅ 2025-12-25
- [x] R-SRV ✅ 2025-12-25
- [x] OUT-CLI ✅ 2025-12-25
На всех CentOS выключен firewalld

Список Debian машин:
- [x] L-SRV ✅ 2025-12-25
- [x] L-FW ✅ 2025-12-25
- [x] ISP ✅ 2025-12-25
- [x] L-RTR-A ✅ 2025-12-25
- [x] L-RTR-B ✅ 2025-12-25
- [x] L-CLI-A ✅ 2025-12-25
- [x] L-CLI-B ✅ 2025-12-25
![[{95C240A8-BA36-4CA6-8C5D-7E7465D35999}.png]]
На всех Debian выключен apparmor

#### 3. На всех маршрутизаторах и межсетевых экранов включить пересылку пакетов между интерфейсами
```
echo net.ipv4.ip_forward=1 > /etc/sysctl.conf
sysctl -p

cat /proc/sys/net/ipv4/ip_forward
```
Список VM:
- [x] L-FW ✅ 2025-12-25
      ![[{296F329B-CD3A-4DD9-8584-5BDE72871D5B}.png]]
- [x] L-RTR-A ✅ 2025-12-25
- [x] L-RTR-B ✅ 2025-12-25
- [x] R-FW ✅ 2025-12-25
      ![[{01A3777D-1F2E-40F9-A915-6F3C649BA625}.png]]
- [x] R-RTR ✅ 2025-12-25

#### 4. Задание: Подключение дисков
В pnetlab подключение дисков немного отличается от того, как это делается в VMware.
Необходимо добавить образ непосредственно в папку образа, используемого для VM в pnetlab.
Далее необходимо замонтировать диск.

Пошагово:
`Очень удобно с файлами работать по ssh через клиент MobaXTERM`
![[{6B26B8F4-BDCD-4C74-9265-2028790CF23C}.png]]
Видим репозиторий linux-centos7_3_password.....
это рабочий репозиторий CentOS в текущей лабораторной.
Полный путь до репо:
```
/opt/unetlab/addons/qemu/linux-centos7_3_password___verystrong_/
```
В него нужно положить файл cdrom.iso
![[{FCC0B36A-B5D2-47B7-B9DE-6042E4BD3953}.png]]
Файл можно заранее переименовать и положить в папку репозитория.
==Переименовывать обязательно!==

##### Монтирование дисков CentOS
После включения машины cdrom находится в каталоге `/dev`
Этот каталог файлов устройств, содержащий интерфейсы для аппаратного обеспечения(диски, внешние устройства, терминалы)
1. Создаем каталог 
   `mkdir /media/cdrom`
2. Монтируем 
   `mount /dev/cdrom /media/cdrom`
Также для закрепления, попробовал установить ПО из следующиего задания.
![[{209AF202-1B10-452D-8348-1881ABF13B81}.png]]
Как видим, ПО установлено успешно на хост R-CLI
Более подробный отчет об установке ПО будет написан в  задании 6.

#### 5. Задание: Настройте имена хостов в соответствии с Диаграммой.


> [!NOTE] Важная информация
> hostname - это имя, которое присваивается компьютеру, подключенному к сети, которое однозначно идентифицирует его и таким образом, позволяет получить доступ к нему без использования его IP-адреса.


Для задания имени машины(hostname) необходимо записать его в файл `/etc/hostname`
`echo <hostname> > /etc/hostname`
Изменения вступают в силу после перезагрузки.

Список машин:
- [x] R-CLI ✅ 2025-12-26
      ![[{C054A127-E03C-462C-8A06-856E72DB5554}.png]]
- [x] R-RTR ✅ 2025-12-26
      ![[{07E4A184-AE45-4457-AB82-E1AE4DD615B8}.png]]
- [x] R-FW ✅ 2025-12-26
      ![[{51C1FB45-C604-44EC-8D5F-2D6BC23DC761}.png]]
- [x] R-SRV ✅ 2025-12-26
      ![[{34A9A2EE-CD9B-4035-A2AE-9CE5E66BC667}.png]]
- [x] OUT-CLI ✅ 2025-12-26
      ![[{7FA3091E-EDB6-47B1-8D54-5B5CB02B9CD6}.png]]
- [x] ISP ✅ 2025-12-26
      ![[{58D2B0C7-BA61-403A-BA17-E3E44ED914C9}.png]]
- [x] L-FW ✅ 2025-12-26
- [x] L-SRV ✅ 2025-12-26
      ![[{B835229A-5AB3-4BCC-A622-A2B2247D9315}.png]]
- [x] L-RTR-A ✅ 2025-12-26
      ![[{BBB87530-4F07-404C-8684-18815ABA1FD6}.png]]
- [x] L-RTR-B ✅ 2025-12-26
      ![[{B6CBD5F7-F1CD-4780-B5CD-ADD56A78EA2F}.png]]
- [x] L-CLI-A ✅ 2025-12-26
      ![[{884D3D2C-1245-49E8-9C79-BE03A583E225}.png]]
- [x] L-CLI-B ✅ 2025-12-26
      ![[{730D8FD6-868D-4BE4-9834-9BF6B369FDA2}.png]]

#### 6. Задание: Установка ПО на все виртуальные машины.
- [x] Debian ✅ 2026-01-21
- [ ] CentOS

#### Конфигурация хостов
##### 3. Задание: На хостах сформируйте файл /etc/hosts в соответствии с диаграммой (кроме адреса хоста L-CLI-A). Данный файл будет применяться во время проверки в случае недоступности DNS-сервисов. Проверка по IP-адресам выполняться не будет.
Формируем файл /etc/hosts на одном хосте(L-CLI-A) 
![[{B5302F78-A91B-44F7-9756-4B172C4BE014}.png]]

##### 4. Задание: В случае корректной работы DNS-сервисов ответы DNS должны иметь более высокий приоритет.
Конфигурируем файлы `/etc/nsswitch.conf`
Для CentOS и Debian файлы разные. Конфигурируем под ОС и затем пересылаем по всем хостам.
L-CLI-A
![[{4762E63E-A69A-47AA-AD1C-7649B7A0FFEA}.png|400]]
R-CLI
![[{B95CC497-6DE1-403E-8574-B90B54BDFFC7}.png|400]]
Нужно также задать DNS сервер для клиентов без DHCP (OUT-CLI, R-CLI)
`/etc/resolv.conf`
R-CLI
![[{5756880E-FE18-41EE-9BDF-BACC1659A919}.png|400]]
OUT-CLI
![[{61043614-75CE-4014-A07E-1274E7B00F77}.png|400]]

##### 5. Задание: Все хосты должны быть доступны аккаунту root по SSH на стандартном порту.
На Debian был установлен OpenSSH Server. 
`apt install openssh-server -y`
Дописываем строку `PermitRootlogin yes` в файл `/etc/ssh/sshd_config`

На CentOS дополнительных действий не требуется.

#### Конфигурация сетевой инфраструктуры
##### 1. Задание: Настройте IP-адресацию на всех хостах в соответствии с диаграммой.
![[{179CD733-5E82-4E80-AA56-C71DF54CB500}.png|600]]
###### CentOS
Конфигурация производилась с помощью nmtui в графическом интерфейсе.
![[{F0A6E6C7-728C-44DB-8C52-DDF3312FE3A7}.png|400]]|
Пример одного интерфейса на машине R-FW.
Проверка всех хостов на debian, также можно пропинговать соседние хосты, либо хосты, связанные маршрутизаторами и брендмауэрами.
Проверка(осуществляется через `ip a`, `ping`):
- R-CLI
  ![[{FB460DDC-DF49-44E8-A237-181E5E1D4B56}.png|400]]
- R-RTR
  ![[{467FCAD0-D30D-4C62-8438-60C87BACA3E1}.png|400]]
- R-FW
  ![[{FD873584-EE35-4C0A-AB0E-B8D662CE9AD4}.png|400]]
- R-SRV
  ![[{CC1D3EC8-64A5-4878-B865-AF0DAAD5ABFE}.png|400]]
- OUT-CLI
  ![[{38A7D8E7-D014-4AEB-9F3C-1D07E361773F}.png|400]]

###### Debian
Учитывая, что хосты созданы на Debian 13, в них используется systemd-networkd для настройки сети.
В этом случае настройка происходит путем добавления файлов конфигурации в путь: `/etc/systemd/network`
Названия файлов - `10-ens3.network` (Пример)
Названия интерфейсов могут различаться. 
Содержание файлов:
![[{233A4715-3A21-43D5-8668-58283616A0C3}.png|400]]
Match ищет совпадения в имени интерфейса
Address - адрес хоста в данной подсети
Для каждого интерфейса - свой файл
![[{62B4AB0F-4B9E-4566-ABFC-E565DD46D5D0}.png|400]]
Проверка:
- L-FW
  ![[{1CC73910-735E-43ED-A136-CA1519059A8D}.png|400]]
- L-SRV
  ![[{FC2F220E-7DE6-457F-8B12-3D3B8448025A}.png|400]]
- ISP
  ![[{607023A3-0DF0-4501-A47B-F262B1C0E397}.png|400]]
- L-RTR-A
  ![[{C867123A-3B1E-477F-AA58-DFF50FECB61E}.png|400]]
- L-RTR-B
  ![[{10A768A3-C194-41D5-8BD6-9DDDD0655CD4}.png|400]]
- L-CLI-B
  ![[{95A50A2B-A906-4EEA-855B-8AD7DB9E0C6B}.png|400]]

##### 2. Задание: Настройте GRE-туннель между L-FW и R-FW
Использовать следующую адресацию внутри туннеля:
- L-FW: 10.5.5.1/30
- R-FW: 10.5.5.2/30

###### R-FW
Сначала необходимо с помощью ip создать сетевой интерфейс.
Чтобы после перезагрузки он не пропал, нужно использовать bash скрипт.
```bash
#!/bin/bash
ip tunnel add tun1 mode gre local 20.20.20.100 remote 10.10.10.1 ttl 255
ip link set tun1 up
up addr add 10.5.5.2/30 dev tun1
```
Выдаем права на выполнение:
```bash
chmod +x /etc/gre.up
#+x = eXecute
```
В автозагрузку добавляем через crontab
`vim /etc/crontab`
`@reboot root /etc/gre.up` - это нужно добавить в файл

###### L-FW
Тот же скрипт, но local и remote поменяны местами.
```bash
#!/bin/bash
ip tunnel add tun1 mode gre local 10.10.10.1 remote 20.20.20.100 ttl 255
ip link set tun1 up
ip addr add 10.5.5.1/30 dev tun1
```
Выдаем права на выполнение.
```bash
chmod +x /etc/gre.up
```
Чтобы скрипт правильно отработал, нужно чтобы он запустился после загрузки сетевых интерфейсов. В debian ранее можно было добавить в конец файла `/etc/network/interfaces` строчку `post-up /etc/gre.up`
В debian 13 используется другой подход, сетевые интерфейсы перекочевали в службы systemd. Теперь нужно поднимать кастомную службу. 
1. Создаем файл `/etc/systemd/system/myscript.service`
2. Содержимое:
   ```bash
   [Unit]
   Description=Custom GRE Tunnel Setup
   After=network.target
   Wants=network.target
   
   [Service]
   Type=oneshot
   ExecStart=/etc/gre.up
   RemainAfterExit=yes
   
   [Install]
   WantedBy=multi-user.target
   ```
Также понадобилось включить ip forwarding на машине ISP.
###### Проверка
Пингуем в обе стороны
![[{EBD89ABE-403C-42E6-9340-03DA11AA5D02}.png|400]]
![[{F45E50DD-E5C6-4E01-997E-2DF1FB477262}.png|400]]
##### 3. Задание: Настройте динамическую маршрутизацию по протоколу OSPF с использованием пакета FRR
a)Анонсируйте все сети, необходимые для достижения полной связности.
b)Применение статических маршрутов не допускается.
c)В обмене маршрутной информацией участвуют L-RTR-A, L-RTR-B, R-RTR, L-FW и R-FW.
d)Соседство и обмен маршрутной информацией между L-FW и R-FW должно осуществляться исключительно через настроенный GRE-туннель.
e)Анонсируйте сети локальных интерфейсов L-RTR-A и L-RTR-B.

###### 1. Установка frr
Сначала необходимо установить frr на FW и маршрутизаторы.
   ![[{B629B73A-5138-4F5C-86BB-7E7A58242EF8}.png|600]]
На Debian все довольно просто:
`apt install frr`

CentOS 7 на текущий момент не поддерживается, необходимо поменять зеркала репозиториев для обновления, указать репозиторий frr, далее установить.
1. Смена зеркал:
```bash
sed -i 's/mirror\.centos\.org/vault.centos.org/g' /etc/yum.repos.d/CentOS-*.repo
sed -i 's/^#.*baseurl=http/baseurl=http/g' /etc/yum.repos.d/CentOS-*.repo
sed -i 's/^mirrorlist=http/#mirrorlist=http/g' /etc/yum.repos.d/CentOS-*.repo
```
2. Репозиторий для frr
```bash
_# possible values for FRRVER: frr-6 frr-7 frr-8 frr-9 frr-10 frr-stable frr-rc
# frr-stable will be the latest official stable release
# frr-rc will be the release candidate of the next version_
FRRVER="frr-stable"

curl -O https://rpm.frrouting.org/repo/$FRRVER-repo.el7.noarch.rpm
sudo yum install ./$FRRVER*

sudo yum install frr frr-pythontools
```

###### 2. Включение демона ospfd
`vim /etc/frr/daemons`
1. [x] CentOS ✅
2. [x] Debian ✅
###### 3. Настройка OSPF
`vtysh`
```bash
conf t
router ospf
```
- L-FW
  ![[{1D0CD60C-70CC-475B-8EFA-3125EC657FBA}.png|400]]
- L-RTR-A
  ![[{B3A094FE-C25C-49C4-A65B-3509F97BA617}.png|400]]
- L-RTR-B
  ![[{BC3207B0-DCDF-49CE-A1C3-EB0B2773DDEB}.png|400]]
- R-FW
  ![[{24777789-91A7-4572-B5F2-7BFFAC4E907D}.png|400]]
- R-RTR
  ![[{2272F96E-92B9-4C8E-865A-6CB669320FB2}.png|400]]
- 