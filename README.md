NET.CN Utils
============
**Make your NET.CN virtual hosting suck less and SAVE lots of time.**

**这是一个方便管理万网虚拟空间的 *超级* BASH工具**  
查看[如何](#i18n)将语言切换为中文

login.sh
--------
    Usage: login.sh [OPTIONS...]
    Options:
      -h, --help                   Show this help and exit
      -u, --username <username>    Log in with this user name
      -p, --password <password>    Log in with this password

info.sh
-------
    Usage: info.sh [OPTIONS/ITEMS...]
    Options:
      -h, --help                   Show this help and exit
    Items:
      -id, --site-id               User name
      -t, --type                   Type of virtual hosting
      -vf, --valid-from            Start date of the bill
      -vt, --valid-to              End date of the bill
      -s, --status                 Status text of system
      -ip, --ip-address            IP Address of virtual hosting
      -os, --system                Name of the operating system
      -l, --languages              List of languages installed
      -web, --web-link             HTTP web link
      -webs, --web-links           All links linked to this hosting
      -ftp, --ftp-link             FTP link to the server
      -sp, --space-usage           Total space used
      -bw, --bandwidth-usage       Bandwidth used in this month

      -pma, --phpmyadmin-link      URL to log in to phpMyAdmin
      -dbn, --database-name        Name of the database
      -dbh, --database-host        Host to connect
      -dbu, --database-username    Username to connect to database
      -dbp, --database-password    Password to connect to database

      -cftp, --ftp-mirror          Command to download all files
      -csql, --mysqldump           Command to backup database
      -cmysql, --mysql-connect     Command to connect to database
      -c, --cookie                 JavaScript to set cookie

database.sh
-----------
    Usage: database.sh [OPTIONS...]
    Options:
      -h, --help                   Show this help and exit
      -al, -la, --list-all         List all tables in database
      -b, --backup <file>          Backup database to file
      -d, --drop, --delete         Drop all tables in database
      -i, --import <file>          Import and execute SQL queries
      -v, --verbose                Show more status if possible

upload.sh
---------
    Usage: upload.sh [OPTIONS...]
    Options:
      -h, --help                   Show this help and exit
      -f, -from <file>             File to upload, directory will be 
                                   compressed as zip file
      -t, --to <path>              Remote path relative to /htdocs
      -e, --extract <file.zip>     Remote zip file to extract
      -d, --destination <path>     Extract files to path
      -s, --no-overwrite           Do not overwrite existing files
      -k, --keep-archive           Do not delete the archive file
      -y, --assumeyes, -n, --non-interactive
                                   Execute commands without confirmations

listing.sh
----------
    Usage: listing.sh [OPTIONS...]
    Options:
      -h, --help                   Show this help and exit
      -l, --list <path>            List of contents in path
      -rm-rf, --remove-all         Delete everything on server

Examples
--------
### Login
    $ bash login.sh -u hmu123456 -p 12345678
      [OK] You are now logged in.

### Get server info
    $ bash info.sh -csql -cftp -web -dbn
      mysqldump --set-gtid-purged=OFF -v -h "hdm-070.hichina.com" -u "hdm0700300
      " -p"1234567890" "hdm0700300_db" > hdm0700300_db@20130606000000.sql
      lftp "ftp://hmu123456:12345678@123.132.111.213" -e "mirror --continue --pa
      rallel=10 /htdocs /Users/caiguanhao/FTP"
      http://hmu123456.chinaw3.com
      hdm0700300_db

### Backup MySQL Database
    $ bash database.sh --backup my.sql
      [OK] Your database has been successfully backed up to my.sql .

### Drop all tables in database
    $ bash database.sh --drop
      Found 80 tables.
                   WARNING: ALL DATA IN DATABASE WILL BE REMOVED!               
      THIS ACTION IS IRREVERSIBLE. MAKE SURE YOU HAVE IMPORTANT DATA BACKED UP. 
      Start dropping tables in 0 seconds... Ctrl-C to cancel.
      Dropping table my_table_01 [1/80] ... Done
      ...

### Import backup
    $ bash database.sh --import my.sql
      Logging into phpMyAdmin... Done
      Sending SQL queries... Done
      phpMyAdmin says: Your SQL query has been executed successfully.

### Upload current directory to server
    $ bash upload.sh -f . -d
                                   CREATING ARCHIVE
       $ /usr/bin/zip -9 -q -r /tmp/33116860.zip . [Enter/Ctrl-C] ?

                                    UPLOADING FILE
       $ /usr/bin/curl --ftp-create-dirs -T /tmp/33116860.zip ftp://hmu123456:12
      345678@123.132.111.213/htdocs/33116860.zip [Enter/Ctrl-C] ?

                                  EXTRACTING ARCHIVE
       $ /usr/bin/curl -s -G http://cp.hichina.com/AJAXPage.aspx -d action=uncom
      mpressfilesold -d serverfilename=/33116860.zip -d serverdir=/ -d iscover=1
       ... [Enter/Ctrl-C] ?

      [OK] File has been successfully extracted.
                                   DELETING ARCHIVE
       $ /usr/bin/curl -s ftp://hmu123456:12345678@123.132.111.213 -X DELE /htdo
      cs/33116860.zip  [Enter/Ctrl-C] ?

      Deleting /htdocs/33116860.zip ... Done
      [OK] File has been deleted.

### Remove everything on server
    $ bash listing.sh -rm-rf
                  WARNING: ALL FILES AND DIRECTORIES WILL BE REMOVED!            
      THIS ACTION IS IRREVERSIBLE. MAKE SURE YOU HAVE IMPORTANT FILES BACKED UP. 
              CURRENT SPACE USAGE OF HMU123456: 500M USED, 1000M TOTAL.
      Type "hmu123456" and press Enter to continue; Ctrl-C to cancel.
      hmu123456
      Start removing all files on server in 0 seconds... Ctrl-C to cancel.
      Uploading self-deleting script... Done
      Deleting all files... Done

I18n
----

### 简体中文 (zh_CN)

如果你已选择简体中文（zh_CN.UTF-8）作为你的系统语言，则无需任何设置。如果你不清楚你的设置，可在终端执行 ``locale`` 查看 ``LC_ALL`` 对应的值。如果你不是选择这个语言，请先执行 ``locale -a`` 查看是否已安装 zh_CN.UTF-8 ，如果是，你可以通过以下命令暂时改为 zh_CN ：

    export LC_ALL=zh_CN.UTF-8

### Translation

If you want to translate this script into other language, create a directory with the locale of the language (for example zh_HK is the locale of Traditional Chinese in Hong Kong), then run ``bash locale/update.sh`` to generate template .po files in the directory. After you finish the translations in all .po files, re-run the ``bash locale/update.sh`` command and it will update the .mo files for you.

Requirements
------------
* Linux or Mac OS X
* [GNU gettext](http://www.gnu.org/software/gettext/) if you want to use other languages besides English

|           |curl|mysql|zip|
|-----------|:--:|:---:|:-:|
|login.sh   | X  |     |   |
|info.sh    | X  |     |   |
|database.sh| X  | X   |   |
|upload.sh  | X  |     | X |
|listing.sh | X  |     |   |

Specs
-----
    Basic specs of NET.CN's virtual hosting products:
    M2 - Red Hat 5.4 / Apache 2.2 / PHP 5 / SQLite / 500 MB Space
    M3 - Red Hat 5.4 / Apache 2.2 / PHP 5 / SQLite/MySQL / 1 GB Space
    Admin panel: FTP, online ZIP decompression, phpMyAdmin with queued MySQL backup.
    More info: http://www.net.cn/hosting/m3/

Developer
---------
* caiguanhao
