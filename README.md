## Oxid CE docker image

```
$ docker build -t opstack:OxidCE-docker .
```

### Starting this container
```
$ docker run -td -p 44:22 -p 80:80 opstack:OxidCE-docker
```