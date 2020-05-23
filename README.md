# OPAQUE

## Introduction

The following software is an PoC implementation of the OPAQUE protocol. This implementation uses ECDH for the OPRF. For more information on the primitives used and the protocol description, see [pdf/README.pdf](pdf/README.pdf). This PoC is written using [SageMath](https://www.sagemath.org) and the [pyca/cryptography](https://github.com/pyca/cryptography) library.

## Description

This software allows a client to register with the server and then to login. The server code is located in `server.sage` and the client code in `client.sage`.

OPAQUE-related code is located in files inside the `opaque` folder. The Sage scripts inside that folder must be compiled into Python files before they can be imported in other Sage scripts. The `build-opaque.sh` script will do just that. However, for conveniance, compiled files are already commited in this repository.

### Pickle

[Pickle](https://docs.python.org/3/library/pickle.html) is used in two places:

1. in the client, for the input of the `AuthEnc` function and
2. in the server, to serialize the database to a file.

This means that in both cases, we unpickle only data we trust (unless an attacker managed to get access to the server or to the `rw` key…).

### JSON

JSON is used to transmit data between the client and the server, and as mentioned in the Python doc, *unlike pickle, deserializing untrusted JSON does not in itself create an arbitrary code execution vulnerability*.

### Limitations

1. This PoC can register only one user.
2. The H' function is not secure.
3. The sensible cryptographic material is not erase from the memory.
4. When the client quits with an error, the corresponding socket connection on the server must be killed manually (^C).

## Execution

### `cryptography` library

As mentioned before, the `cryptography` library is used, install it with the following command:

```sh
sage --pip install cryptography
```

The server must be launched first, followed by the client with the desired operation (register or login). The client must of course register before he can log in.

```sh
sage server.sage
sage client.sage -op register
sage client.sage -op login
```
