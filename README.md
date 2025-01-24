# Platformatory-Daily
Codes of daily tasks assigned.

**Confluent Kafka command**

To start service name
--> sudo systemctl start confluent- <service-name>

To check status of the service
--> sudo systemctl status confluent- <service-name>
--> sudo systemctl status confluent*



**Docker**

To start the docker containers
--> docker compose up -d   OR  docker compose up --build

To stop the docker containers
--> docker compose down -v  OR  docker compose down --volumes

To check status of the containers
--> docker compose ps -a 
--> watch docker compose ps -a 

To check logs of the container
--> docker compose logs <container-name>






