from opaque.common import *
from cryptography.exceptions import InvalidTag


def register(send, recv, pw):
    """
    Register the client's password with the server.

    :param send: a function used to send data to the server
    :param recv: a function used to receive data from the server
    :param pw  : the password to register with
    """

    # Choose a private and public key pair (p_u, P_u).
    p_u, P_u = gen_key()

    # Choose a random r and compute alpha.
    r = Integer(Fn.random_element())
    alpha = r * hp(pw)

    # Send alpha to the server.
    send(op='register', alpha=alpha)

    # Receive beta and P_s from the server.
    data = recv()
    beta = j2ecp(data, 'beta')
    P_s = j2ecp(data, 'P_s')

    # Compute rw and harden it using a PBKDF.
    rw = pbkdf(h(pw, beta * r.inverse_mod(n)))

    # Encrypt and authenticate p_u, P_u and P_s.
    c = auth_enc(rw, pickle.dumps((p_u, P_u, P_s)))

    # Send c and P_u to the server.
    send(c=c, P_u=P_u)


def login(send, recv, pw):
    """
    Log in the client with the server.

    :param send: a function used to send data to the server
    :param recv: a function used to receive data from the server
    :param pw  : the password to log in with
    :returns   : a tuple (X, sid, ssid) where X is the symmetric key in case of
                 success, or None in case of failure.
    """

    # Choose a private and public key pair (x_u, X_u).
    x_u, X_u = gen_key()

    # Choose a random r and compute alpha.
    r = Integer(Fn.random_element())
    alpha = r * hp(pw)

    # Send alpha and X_u to the server.
    send(op='login', alpha=alpha, X_u=X_u)

    # Receive beta, X_s, c and A_s.
    data = recv()
    beta = j2ecp(data, 'beta')
    X_s = j2ecp(data, 'X_s')
    c = j2b(data['c'])
    A_s = j2b(data['A_s'])

    # Compute rw and harden it using a PBKDF.
    rw = pbkdf(h(pw, beta * r.inverse_mod(n)))

    # Decrypt and authentify c, extract p_u, P_u and P_s.
    try:
        p_u, P_u, P_s = pickle.loads(auth_dec(rw, c))
    except InvalidTag:
        return (None, sid, ssid)

    # Check beta, X_s and P_s are on the curve. P_u should be on the curve as it
    # was computed by the client.
    if not on_curve(beta, X_s, P_s):
        return (None, sid, ssid)

    # Compute ssid', K and SK.
    ssidp = h(sid, ssid, alpha)
    K = key_ex_u(p_u, x_u, P_s, X_s, X_u, id_s, id_u, ssidp)
    SK = f(K, 0, ssidp)

    # Compute A_s and verify it equals the one received from the server.
    if A_s != f(K, 1, ssidp):
        return (None, sid, ssid)

    # Compute A_u and send it to the server.
    A_u = f(K, 2, ssidp)
    send(A_u=A_u)

    return (SK, sid, ssid)
