# What is this?
A way to get [HHVM](https://hhvm.com/) working on arm64.

# How to use
This requires use of [Colima](https://github.com/abiosoft/colima) and an up to date version of [QEMU](https://www.qemu.org/) in order to work. Rosetta does not currently support [some x86_64 instruction](https://developer.apple.com/documentation/apple-silicon/about-the-rosetta-translation-environment) execution which HHVM uses.

```
brew install qemu
brew install colima
git clone https://github.com/justdan6/docker-hack-dev.git
cd docker-hack-dev

colima start --arch x86_64 --cpu 4 --cpu-type "max" --memory 16 --network-address
docker compose up
```

Go to http://localhost:8080/hello.hack

Any changes in /src will be picked up by [HHVM](https://docs.hhvm.com/hhvm/).
