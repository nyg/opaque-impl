from opaque.common import *

def register(send, recv):

    # TODO: ask user for pwd
    pw = b'pwd123'

    # choose a private and a public key
    p_u = Integer(Fn.random_element())
    P_u = p_u * G

    # choose random r
    r = Integer(Fn.random_element())

    # compute alpha
    alpha = hp(pw) * r

    # send alpha to server
    send(op='register', alpha=alpha)

    # receive beta and P_s from server
    data = recv()
    beta = j2ecp(data, E, 'beta')
    P_s = j2ecp(data, E, 'P_s')

    # compute rw
    rw = h(pw + ecp2b(beta * r.inverse_mod(n)))[:32]

    # encrypt and authenticate p_u, P_u and P_s
    c_data = pickle.dumps((p_u, P_u, P_s))
    c = auth_enc(rw, c_data)

    # send c and P_u to the server
    send(c=c, P_u=P_u)

def login(send, recv):

    # TODO: ask user for pwd
    pw = b'pwd123'

    # choose random r and x_u
    r = Integer(Fn.random_element())
    x_u = Integer(Fn.random_element())

    # compute alpha and X_u
    alpha = hp(pw) * r
    X_u = x_u * G

    # sending alpha and X_u to the server
    send(op='login', alpha=alpha, X_u=X_u)

    # receive beta, X_s, c and A_s
    data = recv()
    beta = j2ecp(data, E, 'beta')
    X_s = j2ecp(data, E, 'X_s')
    c = base64.b64decode(data['c'].encode())
    A_s = base64.b64decode(data['A_s'].encode())

    # check beta belongs to the curve
    x, y = beta.xy()
    if not E.is_on_curve(x, y):
        abort()

    # compute rw and decrypt c
    rw = h(pw + ecp2b(beta * r.inverse_mod(n)))[:32]

    # If we can decrypt and authenticate c, it means that we encrypted it and
    # therefore it's safe to deserialize it using pickle.
    p_u, P_u, P_s = pickle.loads(auth_dec(rw, c))

    # compute ssid', K, SK
    ssidp = h(sid + ssid + ecp2b(alpha))
    K = key_ex_u(p_u, x_u, P_s, X_s, X_u, id_s, id_u, ssidp)
    SK = f(K, b'\x00' + ssidp)

    # compute A_s and verify it equals the one received from the server
    if A_s != f(K, b'\x01' + ssidp):
        abort()

    # compute A_u
    A_u = f(K, b'\x02' + ssidp)

    # sending A_u to server
    send(A_u=A_u)

    return SK
