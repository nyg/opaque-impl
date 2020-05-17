# OPAQUE

## Introduction

Proof of concept OPAQUE implementation using an elliptic curve.

## Instructions

This proof of concept is divided into a client side (`client.sage`) and a server side (`server.sage`).

There's also a file with common objects used by both the client and the server (`common.sage`). Because SAGE scripts cannot be imported directly from another SAGE script, it must first be transformed into a Python file using the `build-common.sh` script. `common.py` is the resulting script and is commited into the repository for conveniance.

The server must be launched first, followed by the client with the desired operation (register or login):

```sh
$ sage server.sage
…
$ sage client.sage -op register
…
$ sage client.sage -op login
…
```

The client must register before he can log in.

## Primitives and Protocol Description

See README.pdf.