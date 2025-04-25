

all: build

build:
	docker compose build --progress plain

reup: down up

up:
	docker compose up --build --remove-orphans -d 

down: 
	docker compose down

run: reup


shell:
	docker run --rm -it kd2qar/allstarlink /bin/bash
