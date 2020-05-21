from opaque.common import *

def register(send, recv, db, data):

    # choose random key for OPRF (different for each user)
    k_s = Integer(Fn.random_element())

    # choose private and public key
    p_s = Integer(Fn.random_element())
    P_s = p_s * G

    # compute beta
    alpha = j2ecp(data, 'alpha')
    beta = k_s * alpha

    # send v_u and beta to user
    send(beta=beta, P_s=P_s)

    # receive c and P_u from user
    data = recv()
    P_u = j2ecp(data, 'P_u')
    c = data['c']

    return {
        'k_s': k_s,
        'p_s': p_s,
        'P_s': P_s,
        'P_u': P_u,
        'c' : c
    }

def login(send, recv, db, data):

    alpha = j2ecp(data, 'alpha')

    # check alpha belongs to the curve
    x, y = alpha.xy()
    if not E.is_on_curve(x, y):
        return (None, sid, ssid)

    X_u = j2ecp(data, 'X_u')

    # choose x_s
    x_s = Integer(Fn.random_element())

    client_data = db[sid]
    k_s = client_data['k_s']
    p_s = client_data['p_s']
    P_s = client_data['P_s']
    P_u = client_data['P_u']
    c = client_data['c']

    # compute beta and and X_s
    beta = alpha * k_s
    X_s = x_s * G

    # compute ssid', K, SK and A_s
    ssidp = h(sid, ssid, alpha)
    K = key_ex_s(p_s, x_s, P_u, X_u, X_s, id_s, id_u, ssidp)
    SK = f(K, 0, ssidp)
    A_s = f(K, 1, ssidp)

    # send beta, X_s, c and A_s
    send(beta=beta, X_s=X_s, c=c, A_s=A_s)

    data = recv()
    A_u = j2b(data['A_u'])

    # compute A_u and verify it equals the one received from the user
    if A_u != f(K, 2, ssidp):
        return (None, sid, ssid)

    return (SK, sid, ssid)
