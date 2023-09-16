# What is this?
A docker environment for [Hack](https://hacklang.org/).

I created this as an easy way to use Hack on my M1 Macbook Pro.

# How to use
```
git pull https://github.com/justdan6/docker-hack-dev.git

cd docker-hack-dev

docker compose up
```

Go to http://localhost:8080/hello.hack

Any changes in /src will automatically be picked up by [HHVM](https://docs.hhvm.com/hhvm/).
