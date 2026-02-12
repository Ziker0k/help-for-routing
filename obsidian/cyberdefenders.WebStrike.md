> [!success]
> #### Что дано
> Analyze network traffic using Wireshark to investigate a web server compromise, identify web shell deployment, reverse shell communication, and data exfiltration.
> 
> We have a lab with wireshark
> 
> #### Решение
> ##### Q1
> Identifying the geographical origin of the attack facilitates the implementation of geo-blocking measures and the analysis of threat intelligence. From which city did the attack originate?
> 💡 **Note:** The lab machines do not have internet access. To look up the IP address and complete this step, use an IP geolocation service on your local computer outside the lab environment.
> 
> В трафике всего 2 ip адреса, нужно посмотреть оба, выбрать правильный город.
> ![[{E798D9D8-2631-4017-B50D-252C313D4F7F}.png]]
> Первым делом стоит посмотреть http запросы, фильтруем. Видим 45 запросов.
> ![[{538A9DE1-7BB4-41DF-8398-347578B11E20}.png]]
> Довольно странный файл upload.php, смотрим дальше.
> В основном запросы идут с ip адреса 117.11.88.124, посмотрим этот адрес на бесплатных ресурсах. 2ip говорит, что Пекин - не подходит.
> ipwhois.io определил как Тяньцзинь или Tianjin - подошло.
> 
> ##### Q2
> Knowing the attacker's User-Agent assists in creating robust filtering rules. What's the attacker's Full User-Agent?
> - Во всех запросах фигурировал следующий User-Agent:
>   Mozilla/5.0 (X11; Linux x86_64; rv:109.0) Gecko/20100101 Firefox/115.0
>   Вводим - подходит
> 
> ##### Q3
> После одного запроса к файлу с двойным расширением пошло очень странное взаимодействие.
> ![[{0126A21D-89E8-4816-B562-C535C609BD71}.png]]
> В одном из ответов можно увидеть даже вывод пользователей /etc/passwd
> ![[{BD881658-9557-473A-A95D-A78C139AF36E}.png]]
> Определенно нужно пробовать файл с двойным расширением в ответе.
> Вводим - ответ верный.
> 
> ##### Q4
> Identifying the directory where uploaded files are stored is crucial for locating the vulnerable page and removing any malicious files. Which directory is used by the website to store the uploaded files?
> Тут без комментариев - выше уже нашли, пробуем
> /reviews/uploads/ - подошло
> 
> ##### Q5
> Which port, opened on the attacker's machine, was targeted by the malicious web shell for establishing unauthorized outbound communication?
> Также уже нашли, после запроса к файлу пошли коннекты по 8080 порту, пробуем
> 8080 - подошло
> 
> ##### Q6
> Recognizing the significance of compromised data helps prioritize incident response actions. Which file was the attacker attempting to exfiltrate?
> Также было найдено выше, пробуем passwd - подошло!