# Using a prepost strategy to create mySQL backups

Volumerize can execute scripts before and after the backup process.

With this prepost strategy you can create a .sql backup of your MySQL containers and save it with Volumerize.

## Environment Variables

Aside of the required environment variables by Volumerize, this prepost strategy will require a couple of extra variables.

| Name           | Description                                                |
| -------------- | ---------------------------------------------------------- |
| MYSQL_USERNAME | Username of the user who will perform the restore or dump. |
| MYSQL_PASSWORD | Password of the user who will perform the restore or dump. |
| MYSQL_HOST     | IP or domain of the host machine.                          |
| MYSQL_DATABASE | Database to backup / restore.                              |

## Example with Docker Compose

```YAML
version: "3"

services:
  mariadb:
    image: mariadb
    ports:
      - 3306:3306
    environment:
      - MYSQL_ROOT_PASSWORD=1234
      - MYSQL_DATABASE=somedatabase
    volumes:
      - mariadb:/var/lib/mysql

  volumerize:
    build: .
    environment:
      - VOLUMERIZE_SOURCE=/source
      - VOLUMERIZE_TARGET=file:///backup
      - MYSQL_USERNAME=root
      - MYSQL_PASSWORD=1234
      - MYSQL_HOST=mariadb
      - MYSQL_DATABASE=somedatabase
    volumes:
      - volumerize-cache:/volumerize-cache
      - backup:/backup
    depends_on:
      - mariadb

volumes:
  volumerize-cache:
  mariadb:
  backup:
```

Then execute `docker-compose exec volumerize backup` to create a backup of your database and `docker-compose exec volumerize restore` to restore it from your backup.