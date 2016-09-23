# Создание юзверя в chroot

- Редактируем конфиг OpenSSH демона
```
bash

vi /etc/ssh/sshd_config 
```

- Добавить это в конец файла
```
bash

UseDNS no
Match group chroot
    ChrootDirectory /home/chroot/%u
    X11Forwarding no
```

- Перестартовываем демон
```
bash

service ssh restart
```

- Копируем скрипт
```
bash

wget -c https://raw.githubusercontent.com/dtulyakov/chrot/master/mkchroot.sh
```

- Создаём юзверя например vpupkin с ID 2000
```
bash

mkchroot.sh vpupkin 2000
```

## PS всё делаем от юзверя root
