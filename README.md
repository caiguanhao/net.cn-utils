``NET.CN Utils``
================

``login.sh``
------------
    Usage: login.sh [OPTIONS...]
    Options:
      -h, --help                   Show this help and exit
      -u, --username <username>    Log in with this user name
      -p, --password <password>    Log in with this password

``info.sh``
-----------
    Usage: info.sh [OPTIONS/ITEMS...]
    Options:
      -h, --help                   Show this help and exit
    Items:
      -t, --type                   Type of virtual space
      -vf, --valid-from            Start date of the bill
      -vt, --valid-to              End date of the bill
      -s, --status                 Status text of system
      -ip, --ip-address            IP Address of virtual space
      -os, --system                Name of the operating system
      -l, --languages              List of languages installed
      -web, --web-link             HTTP web link
      -ftp, --ftp-link             FTP link to the server
      -sp, --space-usage           Total space used
      -bw, --bandwidth-usage       Bandwidth used in this month

      -pma, --phpmyadmin-link      URL to log in to phpMyAdmin
      -dbn, --database-name        Name of the database
      -dbh, --database-host        Host to connect
      -dbu, --database-username    Username to connect to database
      -dbp, --database-password    Password to connect to database

``database.sh``
---------------
    Usage: database.sh [OPTIONS...]
    Options:
      -h, --help                   Show this help and exit
      -al, -la, --list-all         List all tables in database
      -b, --backup <file>          Backup database to file
      -d, --drop, --delete         Drop all tables in database
      -i, --import <file>          Import and execute SQL queries
      -v, --verbose                Show more status if possible

``upload.sh``
-------------
    Usage: upload.sh [OPTIONS...]
    Options:
      -h, --help                   Show this help and exit
      -f, -from <file>             File to upload, directory will be compressed as zip file
      -t, --to <path>              Remote path relative to /htdocs
      -e, --extract <file.zip>     Remote zip file to extract
      -d, --destination <path>     Extract files to path
      -s, --no-overwrite           Do not overwrite existing files
      -y, --assumeyes, -n, --non-interactive
                                   Execute commands without confirmations

``Developer``
-------------
* ``caiguanhao``
