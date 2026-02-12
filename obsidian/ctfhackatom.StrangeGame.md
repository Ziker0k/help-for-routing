> [!success] StrangeGame
> #### Что дано
> Пришельцы напали на наш сайт, все перепутали. Странная игра.
> 
> [http://ctf.hackatom.ru:17005/](http://ctf.hackatom.ru:17005/)
> 
> #### Решение
> При открытии страницы, спустя несколько секунд, идет переадресация на страницу /die/
> 
> Сначала с помощью инструментов разработчика вытащил код первой страницы:
> ```html
> <!DOCTYPE html>
> <html>
>   <head>
>     <title>Welcome to Earth</title>
>   </head>
>   <body>
>     <h1>AMBUSH!</h1>
>     <p>You've gotta escape!</p>
>     <img src="/static/img/f18.png" alt="alien mothership" style="width:60vw;" />
>     <script>
>       document.onkeydown = function(event) {
>         event = event || window.event;
>         if (event.keyCode == 27) {
>           event.preventDefault();
>           window.location = "/chase/";
>         } else die();
>       };
> 
>       function sleep(ms) {
>         return new Promise(resolve => setTimeout(resolve, ms));
>       }
> 
>       async function dietimer() {
>         await sleep(10000);
>         die();
>       }
> 
>       function die() {
>         window.location = "/die/";
>       }
> 
>       dietimer();
>     </script>
>   </body>
> </html>
> ```
> Видно, что работает скрипт JavaScript. Он ждет 10000 мс и вызывает функцию die().
> Клавиша 27 в JavaScript это `escape`. 
> 
> Далее таким же образом вытаскивал код каждой страницы и вручную переходил по адресу.
> Например на http://ctf.hackatom.ru:17005/chase/
> 
> Последняя страница:
> ```html
> <!DOCTYPE html>
> <html>
>   <head>
>     <title>Welcome to Earth</title>
>     <script src="/static/js/fight.js"></script>
>   </head>
>   <body>
>     <h1>AN ALIEN!</h1>
>     <p>What do you do?</p>
>     <img
>       src="/static/img/alien.png"
>       alt="door"
>       style="width:60vw;"
>     />
>     </br>
>     <input type="text" id="action">
>     <button onClick="check_action()">Fight!</button>
>   </body>
> </html>
> ```
> 
> Видим скрипт fight.js, нужно посмотреть поближе.
> ```js
> // Run to scramble original flag
> //console.log(scramble(flag, action));
> function scramble(flag, key) {
>   for (var i = 0; i < key.length; i++) {
>     let n = key.charCodeAt(i) % flag.length;
>     let temp = flag[i];
>     flag[i] = flag[n];
>     flag[n] = temp;
>   }
>   return flag;
> }
> 
> function check_action() {
>   var action = document.getElementById("action").value;
>   var flag = ["{he110", "_Y0u", "HACCCK", "_me$$$}", "reactf"];
> 
>   // TODO: unscramble function
> }
> ```
> В скрипте был флаг в открытом виде.
> Флаг:
> `reactf{he110_Y0uHACCCK_me$$$}`