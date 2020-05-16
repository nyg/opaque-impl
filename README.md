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

## Primitives

### Elliptic Curve

I chose the `secp521r1` elliptic curve defined by [secg.org](https://secg.org). According to SECG, the elliptic curve provides a security parameter of 256 bits. **Compare with keylength.**

The elliptic curve `secp521r1` is denoted $E$ and is defined over the finite field $\mathbb{F}_p$, where $p$ is prime and is the order of a point $G$ belonging to $E$.

In the protocol description below, when chosing a private and public key pair $p$ and $P$, it means that $p$ is randomly chosen in $\mathbb{F}_p$ and that $P = p \times G$. **À vérifier.**

### $H$ and $H'$

We choose SHA-512 as the hash function $H$. **À changer et expliquer pourquoi.** $H$ takes an arbitrary number of parameters which are concatenated before being hashed, i.e. $H(a, b, \dots) = \text{SHA-512}(a \parallel b \parallel \ldots)$.

$H'$ maps its input to ... It is defined as $H' = H(m) \times G$. **Note that this is not secure**.

### OPRF $F_k$

The OPRF (Oblivious Pseudo-Random Function) is defined by the OPAQUE specification as $F_k(x) = H(x, (H'(x))^k)$.

### PRF $f_k$

For the PRF I have chosen HMAC-SHA512. **À expliquer**.

### Authenticated Encryption

The OPAQUE draft proposes three posibilities for the AE. I chose AES-GCM because it requires only one key contrary to the first two solutions. Also, as we've seen AES-GCM in the previous lab, it was interesting to put it in practice.

The draft requires the AE to be "random-key robust". For this, for AES-GCM, 0s must be appended to the plaintext until its last block is composed only of 0s. **À vérifier le 0x80.** Here we are talking of 128-bit blocks because that's the size of an AES block.

### $e_u$ and $e_s$

…

## Protocol description

The OPAQUE protocol is composed of two steps: first, the user must register to the server; second, the user can login to the server to obtain a symmetric key that will be used by the client and server for all further communications.

### Registration

In this step, the client will "register" his password to the server, without the server actually seeing the password in plaintext. This is done in the following way:

1. The **client** chooses a password $pw$ and generates a private and public key, respectively $p_u$ and $P_u$. He chooses a random value $r$ and computes $\alpha = H'(\text{pw}) \times r$. He sends $\alpha$ to the server.

2. The **server** chooses a random key $k_s$ for the OPRF (must be distinct for each user), he also generates a private and public key, $p_s$ and $P_s$. He computes $\beta = k_s \times \alpha$ and sends it to the client along with $P_s$ which the client will require.

3. The **client** computes $rw = F_{k_s}(\text{pw})$ without knowing $k_s$. To do this he computes $rw = H(pw, \beta^{1/r})$. The client then computes $c = \text{AuthEnc}_{rw}(p_u, P_u, P_s)$ and sends it to the server.

4. The client erases all variables it created and the server stores $(k_s, p_s, P_s, P_u, c)$ for the corresponding client in the database of its choice.

### Login

The goal of this step is to establish a shared symmetric key between the client and the server that will be used to encrypt further communications between the two parties.

1. The **client** randomly chooses $r$ and computes $\alpha = H'(pw) \times r$. It also generates a private and public key pair $x_u$ and $X_u$. It sends $\alpha$ and $X_u$ to the server.

2. The **server** makes sure $\alpha$ is on the curve or quits. It retrieves the values of the client stored during registration, namely $k_s$, $p_s$, $P_s$, $P_u$ and $c$. It generates a private and public key pair $x_s$ and $X_s$ and computes:

   1. $\beta = k_s \times \alpha$,
   2. $K = H((X_u + e_u P_u) \times (x_s + e_s p_s))$,
   3. $ssid' = H(sid, ssid, \alpha)$,
   4. $SK = f_k(0, ssid')$ and
   5. $A_s = f_k(1, ssid')$.

   It sends $\beta$, $X_s$, $c$ and $A_s$ to the client.

3. The **client** makes sure $\beta$ is on the curve or quits. It computes the key $rw = H(pw, \beta^{1/r})$ and proceeds to decrypt $c$, i.e. $p_u, P_u, P_s = AuthDec(c)$. The tag must be valid or else the client quits. The client computes:

   1. $K = H((X_s + e_s P_s) \times (x_u + e_u p_u))$,
   2. $ssid' = H(sid, ssid, \alpha)$,
   3. $SK = f_k(0, ssid')$,
   4. $A_s = f_k(1, ssid')$ and
   5. $A_u = f_k(2, ssid')$.

   Before sending $A_u$ to the server, the client must verify the $A_s$ received is the same as the $A_s$ computed or quit.

4. The **server** computes $A_u = f_k(2, ssid')$ and verifies it equals the $A_u$ received from the client or quits.

5. The client and the server now both have the same value of $SK$.

## Implementation choices

…

## Implemented bonuses

…