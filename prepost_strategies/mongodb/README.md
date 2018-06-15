# Using a prepost strategy to create MongoDB backups

Volumerize can execute scripts before and after the backup process.

With this prepost strategy you can create dump of your MongoDB containers and save it with Volumerize.

## Environment Variables

Aside of the required environment variables by Volumerize, this prepost strategy will require a couple of extra variables.
MONGO_USERNAME MONGO_PASSWORD MONGO_HOST MONGO_PORT
| Name           | Description                                                |
| -------------- | ---------------------------------------------------------- |
| MONGO_USERNAME | Username of the user who will perform the restore or dump. |
| MONGO_PASSWORD | Password of the user who will perform the restore or dump. |
| MONGO_HOST     | MongoDB IP or domain.                                      |
| MONGO_PORT     | MongoDB port.                                              |

## Example with Docker Compose

```YAML
version: "3"

services:
  mongodb:
    image: mongo
    ports:
      - 27017:27017
    environment:
      - MONGO_INITDB_ROOT_USERNAME=root
      - MONGO_INITDB_ROOT_PASSWORD=1234
    volumes:
      - mongodb:/data/db

  volumerize:
    build: ./prepost_strategies/mongodb/
    environment:
      - VOLUMERIZE_SOURCE=/source
      - VOLUMERIZE_TARGET=file:///backup
      - MONGO_USERNAME=root
      - MONGO_PASSWORD=1234
      - MONGO_PORT=27017
      - MONGO_HOST=mongodb
    volumes:
      - volumerize-cache:/volumerize-cache
      - backup:/backup
    depends_on:
      - mongodb

volumes:
  volumerize-cache:
  mongodb:
  backup:
```

Then execute `docker-compose exec volumerize backup` to create a backup of your database and `docker-compose exec volumerize restore` to restore it from your backup.