> [!success]
> ##### Что дано
> Тайна двух посланий **Alex** оставил два странных сообщения. Они будто бы говорят что-то важное, но понять их невозможно. Однако ты знаешь ключевую подсказку: первое из них начинается со слова **"Hello"**.
> 
> Знаем что это Alex и что в начале зашифровано слово Hello.
> 
> ##### Решение
> 1. Попытался закинуть в CyberChef - так себе затея, ничего вменяемого не получил.
> 2. ИИ сказал что тут XOR
> 3. По итогу действительно XOR
>    - Зная то, что фраза начинается с Hello, можно взять первые 5 байт шифротекста и 5 байт слова Hello.
>    - Так как XOR обратим, то получаем ключ.
>      ключ = текст XOR "Hello" 
>      Если бы тут была половина ключа, пришлось бы перебором подбирать, но тут все проще.
>      Ключ: AleXX
>    - Ключ не менялся со временем и он один на весь шифр.
>      В первой фразе зашифровано:
>      `Hello this is a key`
>      Во второй:
>      `flag{SuPeRalex$ecRetKEy}`
> 
> ##### Код решения
> 
> ```python
> def xor_bytes(data: bytes, key: bytes) -> bytes:
>     return bytes([b ^ key[i % len(key)] for i, b in enumerate(data)])
> 
> def derive_key_from_known(cipher: bytes, known_plain: bytes) -> bytes:
>     # key_bytes for first len(known_plain) positions
>     return bytes([cipher[i] ^ known_plain[i] for i in range(min(len(known_plain), len(cipher)))])
> 
> if __name__ == "__main__":
>     cipher_hex = "090909343761180d312b610516783961070021"
>     cipher = bytes.fromhex(cipher_hex)
>     known = b"Hello"
> 
>     # Step 1: derive key bytes from known plaintext prefix
>     key = derive_key_from_known(cipher, known)
>     print("Derived key bytes from known prefix (hex):", key.hex())
> 
>     # Step 2: decrypt with repeating key
>     plain = xor_bytes(cipher, key)
> 
>     # Print key in ASCII where printable, otherwise '.'
>     key_ascii = "".join(chr(b) if 32 <= b <= 126 else "." for b in key)
>     print("Key (ASCII):", key_ascii)
> 
>     # Output plain
>     text = plain.decode("utf-8")
>     print("Decrypted plaintext:")
>     print(text)
> 
> ```